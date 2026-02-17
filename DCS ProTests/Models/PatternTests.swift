//
//  PatternTests.swift
//  DCS ProTests
//
//  Comprehensive unit tests for Pattern and related models
//

import Foundation
import Testing
@testable import DCS_Pro

// MARK: - Test Helpers

/// Helper to create a test DMC thread
private func createTestThread(id: String = "310", name: String = "Black") -> DMCThread {
    let rgb = RGBColor(r: 0, g: 0, b: 0)
    return DMCThread(id: id, name: name, rgb: rgb, lab: rgb.toLab())
}

/// Helper to create a test pattern with optional filled stitches
private func createTestPattern(width: Int, height: Int, filled: Bool = false) -> Pattern {
    if filled {
        let thread = createTestThread()
        let filledRow: [Stitch?] = Array(repeating: Stitch(thread: thread), count: width)
        let stitches = Array(repeating: filledRow, count: height)
        return Pattern(width: width, height: height, stitches: stitches, palette: [])
    } else {
        return Pattern.empty(width: width, height: height)
    }
}

// MARK: - Pattern Dimension Tests

@Suite("Pattern Dimensions")
struct PatternDimensionTests {
    
    @Test("Pattern dimensions are correct")
    func testPatternDimensions() {
        let pattern = createTestPattern(width: 100, height: 150)
        
        #expect(pattern.width == 100, "Width should be 100")
        #expect(pattern.height == 150, "Height should be 150")
    }
    
    @Test("Pattern stitches array has correct dimensions")
    func testStitchesArrayDimensions() {
        let pattern = createTestPattern(width: 100, height: 150)
        
        #expect(pattern.stitches.count == 150, "Should have 150 rows")
        #expect(pattern.stitches[0].count == 100, "Each row should have 100 columns")
    }
    
    @Test("Small pattern dimensions")
    func testSmallPatternDimensions() {
        let pattern = createTestPattern(width: 1, height: 1)
        
        #expect(pattern.width == 1)
        #expect(pattern.height == 1)
        #expect(pattern.stitches.count == 1)
        #expect(pattern.stitches[0].count == 1)
    }
    
    @Test("Large pattern dimensions")
    func testLargePatternDimensions() {
        let pattern = createTestPattern(width: 500, height: 700)
        
        #expect(pattern.width == 500)
        #expect(pattern.height == 700)
        #expect(pattern.stitches.count == 700)
        #expect(pattern.stitches[0].count == 500)
    }
}

// MARK: - Empty Pattern Tests

@Suite("Empty Pattern Creation")
struct EmptyPatternTests {
    
    @Test("Empty pattern has no stitches")
    func testEmptyPatternNoStitches() {
        let pattern = Pattern.empty(width: 50, height: 50)
        
        #expect(pattern.totalStitchCount == 0, "Empty pattern should have 0 stitches")
    }
    
    @Test("Empty pattern has all nil cells")
    func testEmptyPatternAllNil() {
        let pattern = Pattern.empty(width: 10, height: 10)
        
        for row in pattern.stitches {
            for stitch in row {
                #expect(stitch == nil, "All cells should be nil in empty pattern")
            }
        }
    }
    
    @Test("Empty pattern has empty palette")
    func testEmptyPatternEmptyPalette() {
        let pattern = Pattern.empty(width: 20, height: 20)
        
        #expect(pattern.palette.isEmpty, "Empty pattern should have empty palette")
    }
    
    @Test("Empty pattern has correct dimensions")
    func testEmptyPatternDimensions() {
        let pattern = Pattern.empty(width: 75, height: 100)
        
        #expect(pattern.width == 75)
        #expect(pattern.height == 100)
    }
}

// MARK: - Stitch Count Tests

@Suite("Stitch Count Calculation")
struct StitchCountTests {
    
    @Test("Empty pattern has zero stitch count")
    func testEmptyPatternStitchCount() {
        let pattern = Pattern.empty(width: 10, height: 10)
        
        #expect(pattern.totalStitchCount == 0)
    }
    
    @Test("Fully filled pattern has correct stitch count")
    func testFullyFilledStitchCount() {
        let pattern = createTestPattern(width: 10, height: 10, filled: true)
        
        #expect(pattern.totalStitchCount == 100, "10x10 filled pattern should have 100 stitches")
    }
    
    @Test("Partially filled pattern has correct stitch count")
    func testPartiallyFilledStitchCount() {
        var pattern = Pattern.empty(width: 10, height: 10)
        let thread = createTestThread()
        
        // Fill only 5 rows (50 stitches)
        for y in 0..<5 {
            for x in 0..<10 {
                pattern.setStitch(Stitch(thread: thread), at: x, y: y)
            }
        }
        
        #expect(pattern.totalStitchCount == 50, "Should have 50 stitches")
    }
    
    @Test("Single stitch is counted correctly")
    func testSingleStitchCount() {
        var pattern = Pattern.empty(width: 10, height: 10)
        let thread = createTestThread()
        
        pattern.setStitch(Stitch(thread: thread), at: 5, y: 5)
        
        #expect(pattern.totalStitchCount == 1, "Should have exactly 1 stitch")
    }
}

// MARK: - Progress Tracking Tests

@Suite("Progress Tracking")
struct ProgressTrackingTests {
    
    @Test("Empty pattern has zero progress")
    func testEmptyPatternProgress() {
        let pattern = Pattern.empty(width: 10, height: 10)
        
        #expect(pattern.completedStitchCount == 0)
        #expect(pattern.progressPercentage == 0)
    }
    
    @Test("Completed stitch count is correct")
    func testCompletedStitchCount() {
        var pattern = createTestPattern(width: 10, height: 10, filled: true)
        
        // Mark half as completed
        for y in 0..<5 {
            for x in 0..<10 {
                pattern.markCompleted(at: x, y: y, completed: true)
            }
        }
        
        #expect(pattern.completedStitchCount == 50, "Should have 50 completed stitches")
    }
    
    @Test("Progress percentage calculation is correct")
    func testProgressPercentage() {
        var pattern = createTestPattern(width: 10, height: 10, filled: true)
        
        // Mark half as completed (50 out of 100)
        for y in 0..<5 {
            for x in 0..<10 {
                pattern.markCompleted(at: x, y: y, completed: true)
            }
        }
        
        #expect(abs(pattern.progressPercentage - 50.0) < 0.1, "Progress should be 50%")
    }
    
    @Test("Full completion shows 100%")
    func testFullCompletionProgress() {
        var pattern = createTestPattern(width: 5, height: 5, filled: true)
        
        // Mark all as completed
        for y in 0..<5 {
            for x in 0..<5 {
                pattern.markCompleted(at: x, y: y, completed: true)
            }
        }
        
        #expect(pattern.completedStitchCount == 25)
        #expect(abs(pattern.progressPercentage - 100.0) < 0.1, "Progress should be 100%")
    }
    
    @Test("Can unmark completed stitch")
    func testUnmarkCompleted() {
        var pattern = createTestPattern(width: 10, height: 10, filled: true)
        
        // Mark all completed
        for y in 0..<10 {
            for x in 0..<10 {
                pattern.markCompleted(at: x, y: y, completed: true)
            }
        }
        
        #expect(pattern.completedStitchCount == 100)
        
        // Unmark some
        for y in 0..<5 {
            for x in 0..<10 {
                pattern.markCompleted(at: x, y: y, completed: false)
            }
        }
        
        #expect(pattern.completedStitchCount == 50, "Should have 50 completed after unmarking")
    }
}

// MARK: - Finished Size Tests

@Suite("Finished Size Calculation")
struct FinishedSizeTests {
    
    @Test("Finished size at 14-count fabric")
    func testFinishedSize14Count() {
        let pattern = createTestPattern(width: 140, height: 200)
        let size = pattern.finishedSize(fabricCount: 14)
        
        #expect(abs(size.widthInches - 10.0) < 0.01, "Width should be 10 inches at 14-count")
        #expect(abs(size.heightInches - 14.29) < 0.01, "Height should be ~14.29 inches at 14-count")
    }
    
    @Test("Finished size at 18-count fabric")
    func testFinishedSize18Count() {
        let pattern = createTestPattern(width: 180, height: 270)
        let size = pattern.finishedSize(fabricCount: 18)
        
        #expect(abs(size.widthInches - 10.0) < 0.01, "Width should be 10 inches at 18-count")
        #expect(abs(size.heightInches - 15.0) < 0.01, "Height should be 15 inches at 18-count")
    }
    
    @Test("Finished size at 16-count fabric")
    func testFinishedSize16Count() {
        let pattern = createTestPattern(width: 160, height: 160)
        let size = pattern.finishedSize(fabricCount: 16)
        
        #expect(abs(size.widthInches - 10.0) < 0.01)
        #expect(abs(size.heightInches - 10.0) < 0.01)
    }
    
    @Test("Smaller fabric count produces larger finished size")
    func testFabricCountImpact() {
        let pattern = createTestPattern(width: 100, height: 100)
        
        let size14 = pattern.finishedSize(fabricCount: 14)
        let size18 = pattern.finishedSize(fabricCount: 18)
        
        #expect(size14.widthInches > size18.widthInches, 
               "14-count should produce larger finished size than 18-count")
    }
}

// MARK: - Stitch Accessor Tests

@Suite("Stitch Accessors")
struct StitchAccessorTests {
    
    @Test("Get stitch at valid position")
    func testGetStitchValidPosition() {
        var pattern = Pattern.empty(width: 10, height: 10)
        let thread = createTestThread()
        let stitch = Stitch(thread: thread)
        
        pattern.setStitch(stitch, at: 5, y: 5)
        
        let retrieved = pattern.stitch(at: 5, y: 5)
        #expect(retrieved != nil, "Should retrieve stitch at valid position")
        #expect(retrieved?.thread.id == "310")
    }
    
    @Test("Get stitch at empty position returns nil")
    func testGetStitchEmptyPosition() {
        let pattern = Pattern.empty(width: 10, height: 10)
        
        let stitch = pattern.stitch(at: 5, y: 5)
        #expect(stitch == nil, "Empty position should return nil")
    }
    
    @Test("Get stitch out of bounds returns nil")
    func testGetStitchOutOfBounds() {
        let pattern = Pattern.empty(width: 10, height: 10)
        
        #expect(pattern.stitch(at: -1, y: 0) == nil, "Negative x should return nil")
        #expect(pattern.stitch(at: 0, y: -1) == nil, "Negative y should return nil")
        #expect(pattern.stitch(at: 10, y: 0) == nil, "x >= width should return nil")
        #expect(pattern.stitch(at: 0, y: 10) == nil, "y >= height should return nil")
    }
    
    @Test("Set stitch at valid position")
    func testSetStitchValidPosition() {
        var pattern = Pattern.empty(width: 10, height: 10)
        let thread = createTestThread()
        
        pattern.setStitch(Stitch(thread: thread), at: 3, y: 7)
        
        #expect(pattern.stitch(at: 3, y: 7) != nil)
        #expect(pattern.totalStitchCount == 1)
    }
    
    @Test("Set stitch out of bounds is ignored")
    func testSetStitchOutOfBoundsIgnored() {
        var pattern = Pattern.empty(width: 10, height: 10)
        let thread = createTestThread()
        
        pattern.setStitch(Stitch(thread: thread), at: 100, y: 100)
        
        #expect(pattern.totalStitchCount == 0, "Out of bounds set should be ignored")
    }
    
    @Test("Set stitch to nil removes stitch")
    func testSetStitchToNil() {
        var pattern = Pattern.empty(width: 10, height: 10)
        let thread = createTestThread()
        
        pattern.setStitch(Stitch(thread: thread), at: 5, y: 5)
        #expect(pattern.totalStitchCount == 1)
        
        pattern.setStitch(nil, at: 5, y: 5)
        #expect(pattern.totalStitchCount == 0, "Setting to nil should remove stitch")
    }
    
    @Test("Overwrite existing stitch")
    func testOverwriteStitch() {
        var pattern = Pattern.empty(width: 10, height: 10)
        let thread1 = createTestThread(id: "310", name: "Black")
        let thread2 = createTestThread(id: "BLANC", name: "White")
        
        pattern.setStitch(Stitch(thread: thread1), at: 5, y: 5)
        pattern.setStitch(Stitch(thread: thread2), at: 5, y: 5)
        
        let stitch = pattern.stitch(at: 5, y: 5)
        #expect(stitch?.thread.id == "BLANC", "Should have overwritten with new thread")
        #expect(pattern.totalStitchCount == 1, "Should still have only 1 stitch")
    }
}

// MARK: - Pattern Positions Tests

@Suite("Pattern Thread Positions")
struct PatternPositionsTests {
    
    @Test("Find all positions for a thread")
    func testFindPositionsForThread() {
        var pattern = Pattern.empty(width: 10, height: 10)
        let thread = createTestThread(id: "310", name: "Black")
        
        // Set some stitches
        pattern.setStitch(Stitch(thread: thread), at: 0, y: 0)
        pattern.setStitch(Stitch(thread: thread), at: 5, y: 5)
        pattern.setStitch(Stitch(thread: thread), at: 9, y: 9)
        
        let positions = pattern.positions(for: thread)
        
        #expect(positions.count == 3, "Should find 3 positions")
    }
    
    @Test("Positions are empty for unused thread")
    func testNoPositionsForUnusedThread() {
        let pattern = Pattern.empty(width: 10, height: 10)
        let thread = createTestThread()
        
        let positions = pattern.positions(for: thread)
        
        #expect(positions.isEmpty, "Should have no positions for unused thread")
    }
}

// MARK: - Color Count Tests

@Suite("Color Count")
struct ColorCountTests {
    
    @Test("Empty pattern has zero color count")
    func testEmptyPatternColorCount() {
        let pattern = Pattern.empty(width: 10, height: 10)
        
        #expect(pattern.colorCount == 0)
    }
    
    @Test("Color count matches palette size")
    func testColorCountMatchesPalette() {
        let thread = createTestThread()
        let entry = PaletteEntry(id: UUID(), thread: thread, symbol: PatternSymbol("X"), stitchCount: 10)
        
        let pattern = Pattern(
            width: 10,
            height: 10,
            stitches: Array(repeating: Array(repeating: nil, count: 10), count: 10),
            palette: [entry]
        )
        
        #expect(pattern.colorCount == 1)
    }
}

// MARK: - Pattern Identity Tests

@Suite("Pattern Identity")
struct PatternIdentityTests {
    
    @Test("Pattern has unique ID")
    func testPatternHasUniqueID() {
        let pattern1 = Pattern.empty(width: 10, height: 10)
        let pattern2 = Pattern.empty(width: 10, height: 10)
        
        #expect(pattern1.id != pattern2.id, "Each pattern should have unique ID")
    }
    
    @Test("Pattern is Identifiable")
    func testPatternIdentifiable() {
        let pattern = Pattern.empty(width: 10, height: 10)
        
        // Pattern conforms to Identifiable
        let _: UUID = pattern.id
        #expect(true, "Pattern should be Identifiable")
    }
}

// MARK: - Pattern Codable Tests

@Suite("Pattern Codable")
struct PatternCodableTests {
    
    @Test("Empty pattern encodes and decodes")
    func testEmptyPatternCodable() throws {
        let original = Pattern.empty(width: 5, height: 5)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Pattern.self, from: data)
        
        #expect(decoded.width == original.width)
        #expect(decoded.height == original.height)
        #expect(decoded.totalStitchCount == 0)
    }
    
    @Test("Filled pattern encodes and decodes")
    func testFilledPatternCodable() throws {
        var original = Pattern.empty(width: 3, height: 3)
        let thread = createTestThread()
        original.setStitch(Stitch(thread: thread), at: 1, y: 1)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Pattern.self, from: data)
        
        #expect(decoded.width == 3)
        #expect(decoded.height == 3)
        #expect(decoded.totalStitchCount == 1)
        #expect(decoded.stitch(at: 1, y: 1) != nil)
    }
}

// MARK: - Stitch Model Tests

@Suite("Stitch Model")
struct StitchModelTests {
    
    @Test("Stitch defaults to full type")
    func testStitchDefaultType() {
        let thread = createTestThread()
        let stitch = Stitch(thread: thread)
        
        #expect(stitch.type == .full)
    }
    
    @Test("Stitch defaults to not completed")
    func testStitchDefaultNotCompleted() {
        let thread = createTestThread()
        let stitch = Stitch(thread: thread)
        
        #expect(stitch.isCompleted == false)
    }
    
    @Test("Stitch with custom type")
    func testStitchCustomType() {
        let thread = createTestThread()
        let stitch = Stitch(thread: thread, type: .half)
        
        #expect(stitch.type == .half)
    }
    
    @Test("Stitch with completed flag")
    func testStitchCompleted() {
        let thread = createTestThread()
        let stitch = Stitch(thread: thread, isCompleted: true)
        
        #expect(stitch.isCompleted == true)
    }
    
    @Test("Stitch is Equatable")
    func testStitchEquatable() {
        let thread = createTestThread()
        let stitch1 = Stitch(thread: thread, type: .full, isCompleted: false)
        let stitch2 = Stitch(thread: thread, type: .full, isCompleted: false)
        
        #expect(stitch1 == stitch2)
    }
}
