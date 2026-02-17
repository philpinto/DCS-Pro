import AppKit
import Foundation

/// Service for image processing operations
class ImageProcessingService {
    
    /// Resize an image to target dimensions
    /// - Parameters:
    ///   - image: The source NSImage
    ///   - width: Target width in pixels
    ///   - height: Target height in pixels
    /// - Returns: Resized NSImage
    func resizeImage(_ image: NSImage, toWidth width: Int, toHeight height: Int) -> NSImage? {
        guard width > 0, height > 0 else { return nil }
        
        let targetSize = NSSize(width: width, height: height)
        
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        
        newImage.unlockFocus()
        return newImage
    }
    
    /// Resize image maintaining aspect ratio
    /// - Parameters:
    ///   - image: The source NSImage
    ///   - maxWidth: Maximum width
    ///   - maxHeight: Maximum height
    /// - Returns: Resized image fitting within bounds while maintaining aspect ratio
    func resizeImageMaintainingAspectRatio(
        _ image: NSImage,
        maxWidth: Int,
        maxHeight: Int
    ) -> NSImage? {
        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else { return nil }
        
        let widthRatio = CGFloat(maxWidth) / originalSize.width
        let heightRatio = CGFloat(maxHeight) / originalSize.height
        let ratio = min(widthRatio, heightRatio)
        
        let newWidth = Int(originalSize.width * ratio)
        let newHeight = Int(originalSize.height * ratio)
        
        return resizeImage(image, toWidth: newWidth, toHeight: newHeight)
    }
    
    /// Calculate target dimensions maintaining aspect ratio
    /// - Parameters:
    ///   - originalSize: Original image size
    ///   - targetWidth: Desired width
    ///   - targetHeight: Desired height
    ///   - maintainAspectRatio: Whether to maintain aspect ratio
    /// - Returns: Calculated dimensions
    func calculateTargetDimensions(
        originalSize: NSSize,
        targetWidth: Int,
        targetHeight: Int,
        maintainAspectRatio: Bool
    ) -> (width: Int, height: Int) {
        if !maintainAspectRatio {
            return (targetWidth, targetHeight)
        }
        
        guard originalSize.width > 0, originalSize.height > 0 else {
            return (targetWidth, targetHeight)
        }
        
        let aspectRatio = originalSize.width / originalSize.height
        
        // Fit within target dimensions
        let widthFromHeight = Int(CGFloat(targetHeight) * aspectRatio)
        let heightFromWidth = Int(CGFloat(targetWidth) / aspectRatio)
        
        if widthFromHeight <= targetWidth {
            return (widthFromHeight, targetHeight)
        } else {
            return (targetWidth, heightFromWidth)
        }
    }
    
    /// Extract RGB pixel values from an image
    /// - Parameter image: The source NSImage
    /// - Returns: 2D array of RGB tuples [row][column], or nil on failure
    func extractPixels(from image: NSImage) -> [[(r: UInt8, g: UInt8, b: UInt8)]]? {
        // Use NSImage's size (not CGImage) to avoid Retina scaling issues
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        
        guard width > 0, height > 0 else { return nil }
        
        // Create bitmap context with exact dimensions we want
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return nil
        }
        
        // Draw NSImage into context at exact size (1:1 pixel mapping)
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        
        image.draw(
            in: NSRect(x: 0, y: 0, width: width, height: height),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        
        NSGraphicsContext.restoreGraphicsState()
        
        // Extract pixels
        var pixels: [[(r: UInt8, g: UInt8, b: UInt8)]] = []
        
        for y in 0..<height {
            var row: [(r: UInt8, g: UInt8, b: UInt8)] = []
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let r = rawData[offset]
                let g = rawData[offset + 1]
                let b = rawData[offset + 2]
                // Alpha is at offset + 3, but we ignore it
                row.append((r, g, b))
            }
            pixels.append(row)
        }
        
        return pixels
    }
    
    /// Extract flat array of pixels (for quantization)
    /// - Parameter image: The source NSImage
    /// - Returns: Flat array of RGB tuples, or nil on failure
    func extractFlatPixels(from image: NSImage) -> [(r: UInt8, g: UInt8, b: UInt8)]? {
        guard let pixels2D = extractPixels(from: image) else {
            return nil
        }
        return pixels2D.flatMap { $0 }
    }
    
    /// Get image dimensions
    /// - Parameter image: The source NSImage
    /// - Returns: Tuple of (width, height) in pixels
    func getImageDimensions(_ image: NSImage) -> (width: Int, height: Int)? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            // Fall back to NSImage size
            let size = image.size
            if size.width > 0 && size.height > 0 {
                return (Int(size.width), Int(size.height))
            }
            return nil
        }
        return (cgImage.width, cgImage.height)
    }
    
    /// Load image from file URL
    /// - Parameter url: File URL of the image
    /// - Returns: Loaded NSImage or nil
    func loadImage(from url: URL) -> NSImage? {
        return NSImage(contentsOf: url)
    }
    
    /// Load image from Data
    /// - Parameter data: Image data
    /// - Returns: Loaded NSImage or nil
    func loadImage(from data: Data) -> NSImage? {
        return NSImage(data: data)
    }
}
