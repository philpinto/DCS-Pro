import Foundation

/// Median Cut algorithm for reducing image colors to a smaller palette
class MedianCutQuantizer {
    
    /// A bucket of pixels for the median cut algorithm
    struct ColorBucket {
        var pixels: [(r: UInt8, g: UInt8, b: UInt8, count: Int)]
        
        /// Total pixel count in bucket
        var totalCount: Int {
            pixels.reduce(0) { $0 + $1.count }
        }
        
        /// Check if bucket is empty
        var isEmpty: Bool {
            pixels.isEmpty
        }
        
        /// Find which channel (R=0, G=1, B=2) has the greatest range
        func channelWithGreatestRange() -> Int {
            guard !pixels.isEmpty else { return 0 }
            
            let rValues = pixels.map { $0.r }
            let gValues = pixels.map { $0.g }
            let bValues = pixels.map { $0.b }
            
            let rRange = Int(rValues.max()!) - Int(rValues.min()!)
            let gRange = Int(gValues.max()!) - Int(gValues.min()!)
            let bRange = Int(bValues.max()!) - Int(bValues.min()!)
            
            if rRange >= gRange && rRange >= bRange { return 0 }
            if gRange >= rRange && gRange >= bRange { return 1 }
            return 2
        }
        
        /// Get average color of bucket (weighted by pixel count)
        func averageColor() -> RGBColor {
            guard !pixels.isEmpty else {
                return RGBColor(r: 0, g: 0, b: 0)
            }
            
            var rSum: Int = 0
            var gSum: Int = 0
            var bSum: Int = 0
            var total: Int = 0
            
            for pixel in pixels {
                rSum += Int(pixel.r) * pixel.count
                gSum += Int(pixel.g) * pixel.count
                bSum += Int(pixel.b) * pixel.count
                total += pixel.count
            }
            
            guard total > 0 else {
                return RGBColor(r: 0, g: 0, b: 0)
            }
            
            return RGBColor(
                r: UInt8(clamping: rSum / total),
                g: UInt8(clamping: gSum / total),
                b: UInt8(clamping: bSum / total)
            )
        }
        
        /// Split bucket at median along the channel with greatest range
        func split() -> (ColorBucket, ColorBucket) {
            guard pixels.count > 1 else {
                return (self, ColorBucket(pixels: []))
            }
            
            let channel = channelWithGreatestRange()
            
            // Sort by the channel with greatest range
            let sorted = pixels.sorted { p1, p2 in
                switch channel {
                case 0: return p1.r < p2.r
                case 1: return p1.g < p2.g
                default: return p1.b < p2.b
                }
            }
            
            // Find median by pixel count (not just array index)
            let targetCount = totalCount / 2
            var runningCount = 0
            var splitIndex = sorted.count / 2
            
            for (index, pixel) in sorted.enumerated() {
                runningCount += pixel.count
                if runningCount >= targetCount {
                    splitIndex = index + 1
                    break
                }
            }
            
            // Ensure we don't create empty buckets
            splitIndex = max(1, min(splitIndex, sorted.count - 1))
            
            let bucket1 = ColorBucket(pixels: Array(sorted[..<splitIndex]))
            let bucket2 = ColorBucket(pixels: Array(sorted[splitIndex...]))
            
            return (bucket1, bucket2)
        }
    }
    
    /// Quantize image colors to specified count using median cut algorithm
    /// - Parameters:
    ///   - pixels: Array of RGB pixel values from image
    ///   - targetColorCount: Desired number of colors (will use next power of 2)
    /// - Returns: Array of representative colors for the palette
    func quantize(pixels: [(r: UInt8, g: UInt8, b: UInt8)], targetColorCount: Int) -> [RGBColor] {
        guard !pixels.isEmpty else { return [] }
        guard targetColorCount > 0 else { return [] }
        
        // Count unique colors to reduce memory and improve performance
        var colorCounts: [String: (r: UInt8, g: UInt8, b: UInt8, count: Int)] = [:]
        for pixel in pixels {
            let key = "\(pixel.r),\(pixel.g),\(pixel.b)"
            if let existing = colorCounts[key] {
                colorCounts[key] = (pixel.r, pixel.g, pixel.b, existing.count + 1)
            } else {
                colorCounts[key] = (pixel.r, pixel.g, pixel.b, 1)
            }
        }
        
        // If we have fewer unique colors than requested, just return them all
        if colorCounts.count <= targetColorCount {
            return colorCounts.values.map { RGBColor(r: $0.r, g: $0.g, b: $0.b) }
        }
        
        // Initial bucket with all colors
        var buckets = [ColorBucket(pixels: Array(colorCounts.values))]
        
        // Calculate iterations needed (colors = 2^iterations)
        let iterations = Int(ceil(log2(Double(targetColorCount))))
        let actualTargetCount = 1 << iterations  // Power of 2
        
        // Repeatedly split buckets until we have enough
        while buckets.count < actualTargetCount {
            // Find the bucket with the greatest color range to split
            // Prefer buckets with more pixels when ranges are similar
            guard let indexToSplit = buckets.enumerated()
                .filter({ !$0.element.isEmpty && $0.element.pixels.count > 1 })
                .max(by: { bucket1, bucket2 in
                    let range1 = bucket1.element.channelWithGreatestRange()
                    let range2 = bucket2.element.channelWithGreatestRange()
                    // Use pixel count as tiebreaker
                    if range1 == range2 {
                        return bucket1.element.totalCount < bucket2.element.totalCount
                    }
                    return bucket1.element.totalCount < bucket2.element.totalCount
                })?.offset else {
                break
            }
            
            // Split the selected bucket
            let bucketToSplit = buckets.remove(at: indexToSplit)
            let (bucket1, bucket2) = bucketToSplit.split()
            
            if !bucket1.isEmpty {
                buckets.append(bucket1)
            }
            if !bucket2.isEmpty {
                buckets.append(bucket2)
            }
        }
        
        // Get average color from each bucket
        var result = buckets.compactMap { bucket -> RGBColor? in
            guard !bucket.isEmpty else { return nil }
            return bucket.averageColor()
        }
        
        // Trim to exact target count if we have more
        if result.count > targetColorCount {
            result = Array(result.prefix(targetColorCount))
        }
        
        return result
    }
}
