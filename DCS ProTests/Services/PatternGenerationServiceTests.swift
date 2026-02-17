//
//  PatternGenerationServiceTests.swift
//  DCS ProTests
//
//  Unit tests for the pattern generation service
//

import Testing
import AppKit
@testable import DCS_Pro

// MARK: - Helper Functions

/// Creates a solid color test image
func createTestImage(width: Int, height: Int, color: NSColor) -> NSImage {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()
    color.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    image.unlockFocus()
    return image
}

/// Creates a test image with multiple color regions
func createMultiColorTestImage(width: Int, height: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()
    
    let halfWidth = width / 2
    let halfHeight = height / 2
    
    // Top-left: Red
    NSColor.red.setFill()
    NSRect(x: 0, y: halfHeight, width: halfWidth, height: halfHeight).fill()
    
    // Top-right: Green
    NSColor.green.setFill()
    NSRect(x: halfWidth, y: halfHeight, width: halfWidth, height: halfHeight).fill()
    
    // Bottom-left: Blue
    NSColor.blue.setFill()
    NSRect(x: 0, y: 0, width: halfWidth, height: halfHeight).fill()
    
    // Bottom-right: Yellow
    NSColor.yellow.setFill()
    NSRect(x: halfWidth, y: 0, width: halfWidth, height: halfHeight).fill()
    
    image.unlockFocus()
    return image
}

/// Helper to create GenerationSettings with all required parameters
func makeSettings(
    width: Int,
    height: Int,
    maxColors: Int,
    maintainAspectRatio: Bool = false,
    colorMatchingMethod: GenerationSettings.ColorMatchingMethod = .cielab
) -> GenerationSettings {
    return GenerationSettings(
        targetWidth: width,
        targetHeight: height,
        maintainAspectRatio: maintainAspectRatio,
        maxColors: maxColors,
        colorMatchingMethod: colorMatchingMethod,
        ditherEnabled: false
    )
}

// MARK: - Basic Generation Tests

@Suite("Pattern Generation Service - Basic Generation")
struct PatternGenerationBasicTests {
    
    @Test("Generates pattern from solid color image")
    func testSolidColorGeneration() async throws {
        let service = PatternGenerationService()
        let image = createTestImage(width: 100, height: 100, color: .red)
        let settings = makeSettings(width: 20, height: 20, maxColors: 4)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.width == 20, "Pattern width should match settings")
        #expect(pattern.height == 20, "Pattern height should match settings")
        #expect(pattern.palette.count >= 1, "Should have at least one color")
    }
    
    @Test("Generates pattern from multi-color image")
    func testMultiColorGeneration() async throws {
        let service = PatternGenerationService()
        let image = createMultiColorTestImage(width: 100, height: 100)
        let settings = makeSettings(width: 20, height: 20, maxColors: 8)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.width == 20)
        #expect(pattern.height == 20)
        #expect(pattern.palette.count >= 2, "Multi-color image should have multiple palette entries")
    }
}

// MARK: - Dimension Tests

@Suite("Pattern Generation Service - Dimensions")
struct PatternGenerationDimensionTests {
    
    @Test("Pattern dimensions match settings")
    func testDimensionsMatchSettings() async throws {
        let service = PatternGenerationService()
        let image = createTestImage(width: 200, height: 150, color: .blue)
        let settings = makeSettings(width: 50, height: 40, maxColors: 4)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.width == 50, "Width should match target")
        #expect(pattern.height == 40, "Height should match target")
    }
    
    @Test("Aspect ratio is maintained when requested")
    func testAspectRatioMaintained() async throws {
        let service = PatternGenerationService()
        // 2:1 aspect ratio image
        let image = createTestImage(width: 200, height: 100, color: .green)
        
        let settings = GenerationSettings(
            targetWidth: 50,
            targetHeight: 100,  // Will be adjusted to maintain aspect ratio
            maintainAspectRatio: true,
            maxColors: 4,
            colorMatchingMethod: .cielab,
            ditherEnabled: false
        )
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.width == 50, "Width should match target")
        #expect(pattern.height == 25, "Height should maintain 2:1 aspect ratio")
    }
    
    @Test("Small pattern dimensions work")
    func testSmallPatternDimensions() async throws {
        let service = PatternGenerationService()
        let image = createTestImage(width: 100, height: 100, color: .purple)
        let settings = makeSettings(width: 5, height: 5, maxColors: 2)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.width == 5)
        #expect(pattern.height == 5)
        #expect(pattern.totalStitchCount == 25, "5x5 pattern should have 25 stitches")
    }
}

// MARK: - Color Limit Tests

@Suite("Pattern Generation Service - Color Limits")
struct PatternGenerationColorLimitTests {
    
    @Test("Color count respects maxColors setting")
    func testColorCountRespectsMax() async throws {
        let service = PatternGenerationService()
        let image = createMultiColorTestImage(width: 100, height: 100)
        let settings = makeSettings(width: 20, height: 20, maxColors: 4)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.palette.count <= 4, "Palette should not exceed maxColors")
    }
    
    @Test("Single color limit works")
    func testSingleColorLimit() async throws {
        let service = PatternGenerationService()
        let image = createMultiColorTestImage(width: 100, height: 100)
        let settings = makeSettings(width: 20, height: 20, maxColors: 1)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.palette.count == 1, "Should have exactly 1 color")
    }
}

// MARK: - Palette Entry Tests

@Suite("Pattern Generation Service - Palette Entries")
struct PatternGenerationPaletteTests {
    
    @Test("Palette entries have unique symbols")
    func testPaletteEntriesHaveUniqueSymbols() async throws {
        let service = PatternGenerationService()
        let image = createMultiColorTestImage(width: 100, height: 100)
        let settings = makeSettings(width: 20, height: 20, maxColors: 8)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        let symbols = pattern.palette.map { $0.symbol.character }
        let uniqueSymbols = Set(symbols)
        
        #expect(uniqueSymbols.count == pattern.palette.count, "All palette entries should have unique symbols")
    }
    
    @Test("Stitch counts in palette are accurate")
    func testStitchCountsAccurate() async throws {
        let service = PatternGenerationService()
        let image = createTestImage(width: 100, height: 100, color: .black)
        let settings = makeSettings(width: 10, height: 10, maxColors: 4)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        // Sum of all palette stitch counts should equal total stitches
        let paletteTotal = pattern.palette.reduce(0) { $0 + $1.stitchCount }
        
        #expect(paletteTotal == pattern.totalStitchCount, "Palette stitch counts should sum to total")
    }
    
    @Test("All stitches have valid DMC threads")
    func testAllStitchesHaveValidThreads() async throws {
        let service = PatternGenerationService()
        let image = createMultiColorTestImage(width: 100, height: 100)
        let settings = makeSettings(width: 15, height: 15, maxColors: 8)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        // Check that all stitches have threads that exist in the palette
        let paletteThreadIds = Set(pattern.palette.map { $0.thread.id })
        
        for y in 0..<pattern.height {
            for x in 0..<pattern.width {
                if let stitch = pattern.stitch(at: x, y: y) {
                    #expect(paletteThreadIds.contains(stitch.thread.id),
                           "Stitch thread should be in palette")
                }
            }
        }
    }
}

// MARK: - Progress Callback Tests

@Suite("Pattern Generation Service - Progress Callback")
struct PatternGenerationProgressTests {
    
    @Test("Progress callback is called")
    func testProgressCallbackFires() async throws {
        let service = PatternGenerationService()
        let image = createTestImage(width: 100, height: 100, color: .orange)
        let settings = makeSettings(width: 20, height: 20, maxColors: 4)
        
        var progressValues: [Double] = []
        var messages: [String] = []
        
        _ = try await service.generatePattern(from: image, settings: settings) { progress, message in
            progressValues.append(progress)
            messages.append(message)
        }
        
        #expect(!progressValues.isEmpty, "Progress callback should have been called")
        #expect(!messages.isEmpty, "Messages should have been received")
        #expect(progressValues.last == 1.0, "Final progress should be 1.0")
    }
    
    @Test("Progress values are monotonically increasing")
    func testProgressMonotonicallyIncreasing() async throws {
        let service = PatternGenerationService()
        let image = createMultiColorTestImage(width: 100, height: 100)
        let settings = makeSettings(width: 30, height: 30, maxColors: 8)
        
        var progressValues: [Double] = []
        
        _ = try await service.generatePattern(from: image, settings: settings) { progress, _ in
            progressValues.append(progress)
        }
        
        // Check monotonically increasing
        for i in 1..<progressValues.count {
            #expect(progressValues[i] >= progressValues[i-1],
                   "Progress should be monotonically increasing")
        }
    }
}

// MARK: - Color Matching Method Tests

@Suite("Pattern Generation Service - Color Matching Methods")
struct PatternGenerationColorMatchingTests {
    
    @Test("CIELab matching method works")
    func testCIELabMatching() async throws {
        let service = PatternGenerationService()
        let image = createTestImage(width: 100, height: 100, color: .cyan)
        let settings = makeSettings(width: 10, height: 10, maxColors: 4, colorMatchingMethod: .cielab)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.palette.count >= 1, "Should generate with CIELab method")
    }
    
    @Test("CIE94 matching method works")
    func testCIE94Matching() async throws {
        let service = PatternGenerationService()
        let image = createTestImage(width: 100, height: 100, color: .magenta)
        let settings = makeSettings(width: 10, height: 10, maxColors: 4, colorMatchingMethod: .cie94)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.palette.count >= 1, "Should generate with CIE94 method")
    }
    
    @Test("RGB matching method works")
    func testRGBMatching() async throws {
        let service = PatternGenerationService()
        let image = createTestImage(width: 100, height: 100, color: .brown)
        let settings = makeSettings(width: 10, height: 10, maxColors: 4, colorMatchingMethod: .rgb)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.palette.count >= 1, "Should generate with RGB method")
    }
}

// MARK: - Edge Case Tests

@Suite("Pattern Generation Service - Edge Cases")
struct PatternGenerationEdgeCaseTests {
    
    @Test("Handles very small image")
    func testVerySmallImage() async throws {
        let service = PatternGenerationService()
        let image = createTestImage(width: 5, height: 5, color: .gray)
        let settings = makeSettings(width: 3, height: 3, maxColors: 2)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.width == 3)
        #expect(pattern.height == 3)
    }
    
    @Test("Handles rectangular image (wide)")
    func testWideRectangularImage() async throws {
        let service = PatternGenerationService()
        let image = createTestImage(width: 200, height: 50, color: .blue)
        let settings = makeSettings(width: 40, height: 10, maxColors: 4)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.width == 40)
        #expect(pattern.height == 10)
    }
    
    @Test("Handles rectangular image (tall)")
    func testTallRectangularImage() async throws {
        let service = PatternGenerationService()
        let image = createTestImage(width: 50, height: 200, color: .green)
        let settings = makeSettings(width: 10, height: 40, maxColors: 4)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        #expect(pattern.width == 10)
        #expect(pattern.height == 40)
    }
}

// MARK: - Integration Tests

@Suite("Pattern Generation Service - Integration")
struct PatternGenerationIntegrationTests {
    
    @Test("Full pipeline produces valid pattern")
    func testFullPipelineProducesValidPattern() async throws {
        let service = PatternGenerationService()
        let image = createMultiColorTestImage(width: 100, height: 100)
        let settings = makeSettings(width: 25, height: 25, maxColors: 16, colorMatchingMethod: .cielab)
        
        let pattern = try await service.generatePattern(from: image, settings: settings)
        
        // Comprehensive validation
        #expect(pattern.width == 25, "Width should match")
        #expect(pattern.height == 25, "Height should match")
        #expect(pattern.palette.count <= 16, "Should not exceed max colors")
        #expect(pattern.palette.count >= 1, "Should have at least one color")
        #expect(pattern.totalStitchCount == 625, "25x25 should have 625 stitches")
        
        // All stitches should be assigned
        var stitchCount = 0
        for y in 0..<pattern.height {
            for x in 0..<pattern.width {
                if pattern.stitch(at: x, y: y) != nil {
                    stitchCount += 1
                }
            }
        }
        #expect(stitchCount == 625, "All positions should have stitches")
        
        // Palette entries should have correct counts
        let totalFromPalette = pattern.palette.reduce(0) { $0 + $1.stitchCount }
        #expect(totalFromPalette == 625, "Palette counts should sum to total")
    }
}
