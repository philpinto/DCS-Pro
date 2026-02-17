//
//  MedianCutQuantizerTests.swift
//  DCS ProTests
//
//  Unit tests for the Median Cut color quantization algorithm
//

import Testing
import Foundation
@testable import DCS_Pro

// MARK: - Basic Quantization Tests

@Suite("Median Cut Quantizer - Basic Operations")
struct MedianCutQuantizerBasicTests {
    
    let quantizer = MedianCutQuantizer()
    
    @Test("Empty pixel array returns empty result")
    func testEmptyInput() {
        let pixels: [(r: UInt8, g: UInt8, b: UInt8)] = []
        let result = quantizer.quantize(pixels: pixels, targetColorCount: 4)
        
        #expect(result.isEmpty, "Empty input should return empty result")
    }
    
    @Test("Zero target colors returns empty result")
    func testZeroTargetColors() {
        let pixels: [(r: UInt8, g: UInt8, b: UInt8)] = [
            (255, 0, 0),
            (0, 255, 0),
            (0, 0, 255)
        ]
        let result = quantizer.quantize(pixels: pixels, targetColorCount: 0)
        
        #expect(result.isEmpty, "Zero target colors should return empty result")
    }
    
    @Test("Single color input returns that color")
    func testSingleColorInput() {
        let pixels: [(r: UInt8, g: UInt8, b: UInt8)] = Array(repeating: (128, 64, 192), count: 100)
        let result = quantizer.quantize(pixels: pixels, targetColorCount: 4)
        
        #expect(result.count == 1, "Single color input should return 1 color")
        #expect(result.first?.r == 128)
        #expect(result.first?.g == 64)
        #expect(result.first?.b == 192)
    }
    
    @Test("Two colors with high target returns both colors")
    func testTwoColorsHighTarget() {
        let pixels: [(r: UInt8, g: UInt8, b: UInt8)] = [
            (0, 0, 0), (0, 0, 0), (0, 0, 0),
            (255, 255, 255), (255, 255, 255), (255, 255, 255)
        ]
        let result = quantizer.quantize(pixels: pixels, targetColorCount: 8)
        
        #expect(result.count == 2, "Two distinct colors should return 2 colors when target is higher")
    }
}

// MARK: - Color Count Tests

@Suite("Median Cut Quantizer - Color Count")
struct MedianCutQuantizerColorCountTests {
    
    let quantizer = MedianCutQuantizer()
    
    @Test("Returns at most target color count")
    func testRespectsMaxColorCount() {
        // Create diverse colors
        var pixels: [(r: UInt8, g: UInt8, b: UInt8)] = []
        for r in stride(from: 0, to: 256, by: 32) {
            for g in stride(from: 0, to: 256, by: 32) {
                for b in stride(from: 0, to: 256, by: 32) {
                    pixels.append((UInt8(r), UInt8(g), UInt8(b)))
                }
            }
        }
        
        let result = quantizer.quantize(pixels: pixels, targetColorCount: 16)
        
        #expect(result.count <= 16, "Should not exceed target color count")
        #expect(result.count > 0, "Should return at least some colors")
    }
    
    @Test("Target of 4 produces reasonable count")
    func testTargetFourColors() {
        let pixels: [(r: UInt8, g: UInt8, b: UInt8)] = [
            (255, 0, 0), (255, 0, 0), (255, 0, 0),  // Red cluster
            (0, 255, 0), (0, 255, 0), (0, 255, 0),  // Green cluster
            (0, 0, 255), (0, 0, 255), (0, 0, 255),  // Blue cluster
            (255, 255, 0), (255, 255, 0), (255, 255, 0)  // Yellow cluster
        ]
        
        let result = quantizer.quantize(pixels: pixels, targetColorCount: 4)
        
        #expect(result.count == 4, "Four distinct color clusters should yield 4 colors")
    }
    
    @Test("Large target with few unique colors returns unique count")
    func testLargeTargetFewColors() {
        let pixels: [(r: UInt8, g: UInt8, b: UInt8)] = [
            (100, 100, 100),
            (150, 150, 150),
            (200, 200, 200)
        ]
        
        let result = quantizer.quantize(pixels: pixels, targetColorCount: 256)
        
        #expect(result.count == 3, "Should return actual unique color count when fewer than target")
    }
}

// MARK: - Color Distinctiveness Tests

@Suite("Median Cut Quantizer - Color Quality")
struct MedianCutQuantizerColorQualityTests {
    
    let quantizer = MedianCutQuantizer()
    
    @Test("Distinct colors remain distinct after quantization")
    func testDistinctColorsPreserved() {
        let pixels: [(r: UInt8, g: UInt8, b: UInt8)] = [
            (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0),      // Black
            (255, 255, 255), (255, 255, 255), (255, 255, 255), (255, 255, 255), (255, 255, 255),  // White
            (255, 0, 0), (255, 0, 0), (255, 0, 0), (255, 0, 0), (255, 0, 0),      // Red
            (0, 0, 255), (0, 0, 255), (0, 0, 255), (0, 0, 255), (0, 0, 255)       // Blue
        ]
        
        let result = quantizer.quantize(pixels: pixels, targetColorCount: 4)
        
        // Check that we have colors in different regions
        let hasBlack = result.contains { $0.r < 50 && $0.g < 50 && $0.b < 50 }
        let hasWhite = result.contains { $0.r > 200 && $0.g > 200 && $0.b > 200 }
        let hasRed = result.contains { $0.r > 200 && $0.g < 50 && $0.b < 50 }
        let hasBlue = result.contains { $0.r < 50 && $0.g < 50 && $0.b > 200 }
        
        #expect(hasBlack, "Black should be preserved")
        #expect(hasWhite, "White should be preserved")
        #expect(hasRed, "Red should be preserved")
        #expect(hasBlue, "Blue should be preserved")
    }
    
    @Test("Dominant color is represented in output")
    func testDominantColorPreserved() {
        var pixels: [(r: UInt8, g: UInt8, b: UInt8)] = []
        
        // 80% red pixels
        for _ in 0..<800 {
            pixels.append((255, 0, 0))
        }
        // 20% blue pixels
        for _ in 0..<200 {
            pixels.append((0, 0, 255))
        }
        
        let result = quantizer.quantize(pixels: pixels, targetColorCount: 2)
        
        let hasRed = result.contains { $0.r > 200 && $0.g < 50 && $0.b < 50 }
        #expect(hasRed, "Dominant red color should be preserved")
    }
    
    @Test("Gradient produces reasonable color distribution")
    func testGradientQuantization() {
        // Create a grayscale gradient
        var pixels: [(r: UInt8, g: UInt8, b: UInt8)] = []
        for i in 0..<256 {
            let gray = UInt8(i)
            pixels.append((gray, gray, gray))
        }
        
        let result = quantizer.quantize(pixels: pixels, targetColorCount: 4)
        
        #expect(result.count == 4, "Should produce 4 colors from gradient")
        
        // Check that colors span the range
        let lightnesses = result.map { Int($0.r) + Int($0.g) + Int($0.b) }
        let minL = lightnesses.min() ?? 0
        let maxL = lightnesses.max() ?? 0
        
        #expect(maxL - minL > 300, "Colors should span significant range of gradient")
    }
}

// MARK: - ColorBucket Tests

@Suite("Median Cut Quantizer - ColorBucket")
struct ColorBucketTests {
    
    @Test("Channel with greatest range identifies red")
    func testChannelWithGreatestRangeRed() {
        let bucket = MedianCutQuantizer.ColorBucket(pixels: [
            (r: 0, g: 100, b: 100, count: 1),
            (r: 255, g: 110, b: 105, count: 1)
        ])
        
        let channel = bucket.channelWithGreatestRange()
        #expect(channel == 0, "Red channel has greatest range")
    }
    
    @Test("Channel with greatest range identifies green")
    func testChannelWithGreatestRangeGreen() {
        let bucket = MedianCutQuantizer.ColorBucket(pixels: [
            (r: 100, g: 0, b: 100, count: 1),
            (r: 110, g: 255, b: 105, count: 1)
        ])
        
        let channel = bucket.channelWithGreatestRange()
        #expect(channel == 1, "Green channel has greatest range")
    }
    
    @Test("Channel with greatest range identifies blue")
    func testChannelWithGreatestRangeBlue() {
        let bucket = MedianCutQuantizer.ColorBucket(pixels: [
            (r: 100, g: 100, b: 0, count: 1),
            (r: 110, g: 105, b: 255, count: 1)
        ])
        
        let channel = bucket.channelWithGreatestRange()
        #expect(channel == 2, "Blue channel has greatest range")
    }
    
    @Test("Average color is weighted by pixel count")
    func testAverageColorWeighted() {
        let bucket = MedianCutQuantizer.ColorBucket(pixels: [
            (r: 0, g: 0, b: 0, count: 3),    // 3 black pixels
            (r: 255, g: 255, b: 255, count: 1) // 1 white pixel
        ])
        
        let avg = bucket.averageColor()
        
        // Average should be closer to black (weighted)
        // (0*3 + 255*1) / 4 = 63.75
        #expect(avg.r < 100, "Average should be weighted toward black")
        #expect(avg.g < 100, "Average should be weighted toward black")
        #expect(avg.b < 100, "Average should be weighted toward black")
    }
    
    @Test("Empty bucket returns black average")
    func testEmptyBucketAverage() {
        let bucket = MedianCutQuantizer.ColorBucket(pixels: [])
        let avg = bucket.averageColor()
        
        #expect(avg.r == 0)
        #expect(avg.g == 0)
        #expect(avg.b == 0)
    }
    
    @Test("Bucket split produces two non-empty buckets")
    func testBucketSplit() {
        let bucket = MedianCutQuantizer.ColorBucket(pixels: [
            (r: 0, g: 0, b: 0, count: 1),
            (r: 50, g: 50, b: 50, count: 1),
            (r: 200, g: 200, b: 200, count: 1),
            (r: 255, g: 255, b: 255, count: 1)
        ])
        
        let (bucket1, bucket2) = bucket.split()
        
        #expect(!bucket1.isEmpty, "First bucket should not be empty")
        #expect(!bucket2.isEmpty, "Second bucket should not be empty")
        #expect(bucket1.pixels.count + bucket2.pixels.count == 4, "Total pixels should be preserved")
    }
    
    @Test("Single pixel bucket split returns self and empty")
    func testSinglePixelSplit() {
        let bucket = MedianCutQuantizer.ColorBucket(pixels: [
            (r: 128, g: 128, b: 128, count: 1)
        ])
        
        let (bucket1, bucket2) = bucket.split()
        
        #expect(bucket1.pixels.count == 1, "First bucket should have the pixel")
        #expect(bucket2.isEmpty, "Second bucket should be empty")
    }
}

// MARK: - Performance Tests

@Suite("Median Cut Quantizer - Performance")
struct MedianCutQuantizerPerformanceTests {
    
    let quantizer = MedianCutQuantizer()
    
    @Test("Handles large pixel count efficiently")
    func testLargeImagePerformance() {
        // Simulate a 300x300 image (90,000 pixels)
        var pixels: [(r: UInt8, g: UInt8, b: UInt8)] = []
        for _ in 0..<90_000 {
            let r = UInt8.random(in: 0...255)
            let g = UInt8.random(in: 0...255)
            let b = UInt8.random(in: 0...255)
            pixels.append((r, g, b))
        }
        
        let startTime = Date()
        let result = quantizer.quantize(pixels: pixels, targetColorCount: 32)
        let elapsed = Date().timeIntervalSince(startTime)
        
        #expect(result.count <= 32, "Should respect color limit")
        #expect(result.count > 0, "Should produce colors")
        #expect(elapsed < 5.0, "Should complete in under 5 seconds")
    }
}
