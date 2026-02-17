import AppKit
import Foundation

/// Service for converting images to cross-stitch patterns
class PatternGenerationService {
    private let imageProcessor: ImageProcessingService
    private let quantizer: MedianCutQuantizer
    private let colorMatcher: DMCColorMatcher
    
    init() {
        self.imageProcessor = ImageProcessingService()
        self.quantizer = MedianCutQuantizer()
        self.colorMatcher = DMCColorMatcher()
    }
    
    /// Progress callback type: (progress: 0.0-1.0, message: String)
    typealias ProgressCallback = (Double, String) -> Void
    
    /// Generate a cross-stitch pattern from an image
    /// - Parameters:
    ///   - image: Source NSImage
    ///   - settings: Generation settings (dimensions, colors, method)
    ///   - progress: Optional callback for progress updates
    /// - Returns: Generated Pattern
    func generatePattern(
        from image: NSImage,
        settings: GenerationSettings,
        progress: ProgressCallback? = nil
    ) async throws -> Pattern {
        
        // Step 1: Calculate target dimensions
        progress?(0.05, "Calculating dimensions...")
        let (targetWidth, targetHeight) = imageProcessor.calculateTargetDimensions(
            originalSize: image.size,
            targetWidth: settings.targetWidth,
            targetHeight: settings.targetHeight,
            maintainAspectRatio: settings.maintainAspectRatio
        )
        
        guard targetWidth > 0, targetHeight > 0 else {
            throw PatternError.invalidDimensions
        }
        
        // Step 2: Resize image to target stitch dimensions
        progress?(0.1, "Resizing image...")
        guard let resizedImage = imageProcessor.resizeImage(
            image,
            toWidth: targetWidth,
            toHeight: targetHeight
        ) else {
            throw PatternError.imageConversionFailed
        }
        
        // Step 3: Extract pixels
        progress?(0.2, "Extracting colors...")
        guard let pixels2D = imageProcessor.extractPixels(from: resizedImage) else {
            throw PatternError.pixelExtractionFailed
        }
        
        let flatPixels = pixels2D.flatMap { $0 }
        guard !flatPixels.isEmpty else {
            throw PatternError.pixelExtractionFailed
        }
        
        // Step 4: Quantize colors
        progress?(0.3, "Reducing colors...")
        let quantizedColors = quantizer.quantize(
            pixels: flatPixels,
            targetColorCount: settings.maxColors
        )
        
        guard !quantizedColors.isEmpty else {
            throw PatternError.noColorsExtracted
        }
        
        // Step 5: Match to DMC palette
        progress?(0.5, "Matching to DMC threads...")
        let dmcPalette = colorMatcher.matchPalette(
            quantizedColors: quantizedColors,
            preferUnique: true,
            method: settings.colorMatchingMethod
        )
        
        guard !dmcPalette.isEmpty else {
            throw PatternError.noColorsExtracted
        }
        
        // Step 6: Map each pixel to nearest palette color
        progress?(0.6, "Creating pattern...")
        let stitches = try mapPixelsToStitches(
            pixels: pixels2D,
            palette: dmcPalette,
            method: settings.colorMatchingMethod
        )
        
        // Step 7: Build palette entries with symbols and counts
        progress?(0.9, "Finalizing...")
        let paletteEntries = buildPaletteEntries(
            stitches: stitches,
            palette: dmcPalette
        )
        
        progress?(1.0, "Complete!")
        
        return Pattern(
            id: UUID(),
            width: targetWidth,
            height: targetHeight,
            stitches: stitches,
            palette: paletteEntries,
            metadata: PatternMetadata(name: "New Pattern")
        )
    }
    
    // MARK: - Private Methods
    
    /// Map each pixel to the nearest thread in the palette
    private func mapPixelsToStitches(
        pixels: [[(r: UInt8, g: UInt8, b: UInt8)]],
        palette: [DMCThread],
        method: GenerationSettings.ColorMatchingMethod
    ) throws -> [[Stitch?]] {
        guard !palette.isEmpty else {
            throw PatternError.noColorsExtracted
        }
        
        // Pre-compute Lab values for the palette for faster matching
        let paletteLab = palette.map { $0.lab }
        
        var stitches: [[Stitch?]] = []
        
        for row in pixels {
            var stitchRow: [Stitch?] = []
            
            for pixel in row {
                let pixelColor = RGBColor(r: pixel.r, g: pixel.g, b: pixel.b)
                let pixelLab = pixelColor.toLab()
                
                // Find closest palette color
                var bestIndex = 0
                var bestDistance: Double = .infinity
                
                for (index, threadLab) in paletteLab.enumerated() {
                    let distance: Double
                    switch method {
                    case .cielab:
                        distance = pixelLab.deltaE76(to: threadLab)
                    case .cie94:
                        distance = pixelLab.deltaE94(to: threadLab)
                    case .rgb:
                        let dr = Double(pixel.r) - Double(palette[index].rgb.r)
                        let dg = Double(pixel.g) - Double(palette[index].rgb.g)
                        let db = Double(pixel.b) - Double(palette[index].rgb.b)
                        distance = sqrt(dr*dr + dg*dg + db*db)
                    }
                    
                    if distance < bestDistance {
                        bestDistance = distance
                        bestIndex = index
                    }
                }
                
                stitchRow.append(Stitch(thread: palette[bestIndex]))
            }
            
            stitches.append(stitchRow)
        }
        
        return stitches
    }
    
    /// Build palette entries with symbols and stitch counts
    private func buildPaletteEntries(
        stitches: [[Stitch?]],
        palette: [DMCThread]
    ) -> [PaletteEntry] {
        // Count stitches per thread
        var counts: [String: Int] = [:]
        for row in stitches {
            for stitch in row {
                if let s = stitch {
                    counts[s.thread.id, default: 0] += 1
                }
            }
        }
        
        // Get available symbols
        let symbols = PatternSymbol.availableSymbols
        
        // Build entries for threads that are actually used
        var entries: [PaletteEntry] = []
        var symbolIndex = 0
        
        // Sort palette by stitch count (most used first) for better symbol assignment
        let sortedPalette = palette.sorted { thread1, thread2 in
            let count1 = counts[thread1.id] ?? 0
            let count2 = counts[thread2.id] ?? 0
            return count1 > count2
        }
        
        for thread in sortedPalette {
            guard let count = counts[thread.id], count > 0 else { continue }
            
            let symbol = symbols[symbolIndex % symbols.count]
            symbolIndex += 1
            
            entries.append(PaletteEntry(
                id: UUID(),
                thread: thread,
                symbol: symbol,
                stitchCount: count
            ))
        }
        
        return entries
    }
}
