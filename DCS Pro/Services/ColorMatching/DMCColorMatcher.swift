import Foundation

/// Service for matching colors to DMC thread palette
class DMCColorMatcher {
    private let dmcPalette: [DMCThread]
    
    /// Initialize with the full DMC palette
    init() {
        self.dmcPalette = DMCDatabase.shared.threads
    }
    
    /// Initialize with a custom palette (for testing)
    init(palette: [DMCThread]) {
        self.dmcPalette = palette
    }
    
    /// Find the closest DMC thread to a given RGB color
    /// - Parameters:
    ///   - color: The RGB color to match
    ///   - method: The color matching method to use
    /// - Returns: The closest DMC thread
    func closestThread(to color: RGBColor, method: GenerationSettings.ColorMatchingMethod = .cielab) -> DMCThread? {
        guard !dmcPalette.isEmpty else { return nil }
        
        let sourceLab = color.toLab()
        
        var bestMatch: DMCThread = dmcPalette[0]
        var bestDistance: Double = .infinity
        
        for thread in dmcPalette {
            let distance: Double
            switch method {
            case .cielab:
                distance = sourceLab.deltaE76(to: thread.lab)
            case .cie94:
                distance = sourceLab.deltaE94(to: thread.lab)
            case .rgb:
                let dr = Double(color.r) - Double(thread.rgb.r)
                let dg = Double(color.g) - Double(thread.rgb.g)
                let db = Double(color.b) - Double(thread.rgb.b)
                distance = sqrt(dr*dr + dg*dg + db*db)
            }
            
            if distance < bestDistance {
                bestDistance = distance
                bestMatch = thread
            }
        }
        
        return bestMatch
    }
    
    /// Find closest threads for multiple colors
    /// - Parameters:
    ///   - quantizedColors: Array of colors from quantization
    ///   - preferUnique: If true, try to avoid duplicate thread matches
    ///   - method: The color matching method to use
    /// - Returns: Array of matched DMC threads (same order as input)
    func matchPalette(
        quantizedColors: [RGBColor],
        preferUnique: Bool = true,
        method: GenerationSettings.ColorMatchingMethod = .cielab
    ) -> [DMCThread] {
        guard !quantizedColors.isEmpty else { return [] }
        guard !dmcPalette.isEmpty else { return [] }
        
        if !preferUnique {
            return quantizedColors.compactMap { closestThread(to: $0, method: method) }
        }
        
        // Match with uniqueness preference
        var usedThreadIDs: Set<String> = []
        var result: [DMCThread] = []
        
        // Process colors in order of "distinctiveness" (furthest from others)
        // This helps ensure distinctive colors get their best match first
        let colorLabValues = quantizedColors.map { ($0, $0.toLab()) }
        
        // Sort by how distinctive each color is (min distance to any other color)
        let sortedIndices = quantizedColors.indices.sorted { i1, i2 in
            let lab1 = colorLabValues[i1].1
            let lab2 = colorLabValues[i2].1
            
            let minDist1 = colorLabValues.enumerated()
                .filter { $0.offset != i1 }
                .map { lab1.deltaE76(to: $0.element.1) }
                .min() ?? Double.infinity
            
            let minDist2 = colorLabValues.enumerated()
                .filter { $0.offset != i2 }
                .map { lab2.deltaE76(to: $0.element.1) }
                .min() ?? Double.infinity
            
            // Most distinctive (highest min distance) first
            return minDist1 > minDist2
        }
        
        // Create result array with placeholders
        var resultByIndex: [Int: DMCThread] = [:]
        
        for index in sortedIndices {
            let color = quantizedColors[index]
            let sourceLab = color.toLab()
            
            // Find best unused match
            var bestMatch: DMCThread?
            var bestDistance: Double = .infinity
            
            for thread in dmcPalette {
                if usedThreadIDs.contains(thread.id) { continue }
                
                let distance: Double
                switch method {
                case .cielab:
                    distance = sourceLab.deltaE76(to: thread.lab)
                case .cie94:
                    distance = sourceLab.deltaE94(to: thread.lab)
                case .rgb:
                    let dr = Double(color.r) - Double(thread.rgb.r)
                    let dg = Double(color.g) - Double(thread.rgb.g)
                    let db = Double(color.b) - Double(thread.rgb.b)
                    distance = sqrt(dr*dr + dg*dg + db*db)
                }
                
                if distance < bestDistance {
                    bestDistance = distance
                    bestMatch = thread
                }
            }
            
            // If no unused match found (more colors than DMC threads), allow reuse
            let finalMatch = bestMatch ?? closestThread(to: color, method: method)
            
            if let match = finalMatch {
                usedThreadIDs.insert(match.id)
                resultByIndex[index] = match
            }
        }
        
        // Build result in original order
        for index in quantizedColors.indices {
            if let thread = resultByIndex[index] {
                result.append(thread)
            }
        }
        
        return result
    }
    
    /// Calculate the color distance between a color and a DMC thread
    func colorDistance(
        from color: RGBColor,
        to thread: DMCThread,
        method: GenerationSettings.ColorMatchingMethod = .cielab
    ) -> Double {
        let sourceLab = color.toLab()
        
        switch method {
        case .cielab:
            return sourceLab.deltaE76(to: thread.lab)
        case .cie94:
            return sourceLab.deltaE94(to: thread.lab)
        case .rgb:
            let dr = Double(color.r) - Double(thread.rgb.r)
            let dg = Double(color.g) - Double(thread.rgb.g)
            let db = Double(color.b) - Double(thread.rgb.b)
            return sqrt(dr*dr + dg*dg + db*db)
        }
    }
}
