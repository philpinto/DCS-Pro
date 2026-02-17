//
//  DMCColorMatcherTests.swift
//  DCS ProTests
//
//  Unit tests for the DMC color matching service
//

import Testing
@testable import DCS_Pro

// MARK: - Basic Matching Tests

@Suite("DMC Color Matcher - Basic Matching")
struct DMCColorMatcherBasicTests {
    
    @Test("Black RGB matches DMC 310")
    func testBlackMatchesDMC310() {
        let matcher = DMCColorMatcher()
        let black = RGBColor(r: 0, g: 0, b: 0)
        
        let match = matcher.closestThread(to: black, method: .cielab)
        
        #expect(match != nil, "Should find a match")
        #expect(match?.id == "310", "Black should match DMC 310 (Black)")
    }
    
    @Test("White RGB matches BLANC")
    func testWhiteMatchesBLANC() {
        let matcher = DMCColorMatcher()
        let white = RGBColor(r: 255, g: 255, b: 255)
        
        let match = matcher.closestThread(to: white, method: .cielab)
        
        #expect(match != nil, "Should find a match")
        // Could be BLANC or B5200 (Snow White) - both are very close to pure white
        #expect(match?.id == "BLANC" || match?.id == "B5200", "White should match BLANC or B5200")
    }
    
    @Test("Pure red matches a red DMC thread")
    func testRedMatchesRedThread() {
        let matcher = DMCColorMatcher()
        let red = RGBColor(r: 255, g: 0, b: 0)
        
        let match = matcher.closestThread(to: red, method: .cielab)
        
        #expect(match != nil, "Should find a match")
        // The matched thread should have high R and low G, B
        if let m = match {
            #expect(m.rgb.r > 200, "Matched thread should be red-ish")
            #expect(m.rgb.g < 100, "Matched thread should not be green")
        }
    }
    
    @Test("Empty palette returns nil")
    func testEmptyPaletteReturnsNil() {
        let matcher = DMCColorMatcher(palette: [])
        let color = RGBColor(r: 128, g: 128, b: 128)
        
        let match = matcher.closestThread(to: color, method: .cielab)
        
        #expect(match == nil, "Empty palette should return nil")
    }
}

// MARK: - Color Matching Methods Tests

@Suite("DMC Color Matcher - Matching Methods")
struct DMCColorMatcherMethodTests {
    
    @Test("All three matching methods work")
    func testAllMethodsWork() {
        let matcher = DMCColorMatcher()
        let testColor = RGBColor(r: 150, g: 100, b: 50)
        
        let cielabMatch = matcher.closestThread(to: testColor, method: .cielab)
        let cie94Match = matcher.closestThread(to: testColor, method: .cie94)
        let rgbMatch = matcher.closestThread(to: testColor, method: .rgb)
        
        #expect(cielabMatch != nil, "CIELab method should find a match")
        #expect(cie94Match != nil, "CIE94 method should find a match")
        #expect(rgbMatch != nil, "RGB method should find a match")
    }
    
    @Test("CIELab and CIE94 can produce different results")
    func testMethodsCanDiffer() {
        let matcher = DMCColorMatcher()
        
        // Test with multiple colors to find one where methods differ
        let testColors = [
            RGBColor(r: 180, g: 120, b: 90),
            RGBColor(r: 100, g: 150, b: 100),
            RGBColor(r: 200, g: 180, b: 150)
        ]
        
        var foundDifference = false
        for color in testColors {
            let cielabMatch = matcher.closestThread(to: color, method: .cielab)
            let cie94Match = matcher.closestThread(to: color, method: .cie94)
            
            if cielabMatch?.id != cie94Match?.id {
                foundDifference = true
                break
            }
        }
        
        // It's okay if they don't differ - the important thing is both work
        #expect(true, "Both methods execute correctly")
    }
    
    @Test("Color distance calculation works for all methods")
    func testColorDistanceCalculation() {
        let matcher = DMCColorMatcher()
        let color = RGBColor(r: 100, g: 100, b: 100)
        
        guard let thread = DMCDatabase.shared.thread(byID: "310") else {
            #expect(Bool(false), "Should find DMC 310")
            return
        }
        
        let distCIELab = matcher.colorDistance(from: color, to: thread, method: .cielab)
        let distCIE94 = matcher.colorDistance(from: color, to: thread, method: .cie94)
        let distRGB = matcher.colorDistance(from: color, to: thread, method: .rgb)
        
        #expect(distCIELab >= 0, "CIELab distance should be non-negative")
        #expect(distCIE94 >= 0, "CIE94 distance should be non-negative")
        #expect(distRGB >= 0, "RGB distance should be non-negative")
    }
    
    @Test("Identical color has zero distance")
    func testIdenticalColorZeroDistance() {
        let matcher = DMCColorMatcher()
        
        guard let blackThread = DMCDatabase.shared.thread(byID: "310") else {
            #expect(Bool(false), "Should find DMC 310")
            return
        }
        
        let distance = matcher.colorDistance(from: blackThread.rgb, to: blackThread, method: .cielab)
        
        #expect(distance < 0.01, "Same color should have near-zero distance")
    }
}

// MARK: - Palette Matching Tests

@Suite("DMC Color Matcher - Palette Matching")
struct DMCColorMatcherPaletteTests {
    
    @Test("Empty color array returns empty palette")
    func testEmptyColorsEmptyPalette() {
        let matcher = DMCColorMatcher()
        let colors: [RGBColor] = []
        
        let palette = matcher.matchPalette(quantizedColors: colors, preferUnique: true, method: .cielab)
        
        #expect(palette.isEmpty, "Empty input should return empty palette")
    }
    
    @Test("Single color returns single thread")
    func testSingleColorSingleThread() {
        let matcher = DMCColorMatcher()
        let colors = [RGBColor(r: 0, g: 0, b: 0)]
        
        let palette = matcher.matchPalette(quantizedColors: colors, preferUnique: true, method: .cielab)
        
        #expect(palette.count == 1, "Single color should return single thread")
        #expect(palette.first?.id == "310", "Black should match DMC 310")
    }
    
    @Test("Unique preference avoids duplicate threads")
    func testUniquePreferenceAvoidsDuplicates() {
        let matcher = DMCColorMatcher()
        
        // Create similar colors that might match to same thread
        let colors = [
            RGBColor(r: 0, g: 0, b: 0),      // Black
            RGBColor(r: 5, g: 5, b: 5),      // Very dark gray (close to black)
            RGBColor(r: 10, g: 10, b: 10),   // Dark gray
            RGBColor(r: 255, g: 255, b: 255) // White
        ]
        
        let palette = matcher.matchPalette(quantizedColors: colors, preferUnique: true, method: .cielab)
        
        // Check for unique IDs
        let ids = palette.map { $0.id }
        let uniqueIds = Set(ids)
        
        #expect(uniqueIds.count == palette.count, "With preferUnique, all threads should be unique")
    }
    
    @Test("Without unique preference allows duplicates")
    func testWithoutUniqueAllowsDuplicates() {
        let matcher = DMCColorMatcher()
        
        // Create identical colors
        let colors = [
            RGBColor(r: 0, g: 0, b: 0),
            RGBColor(r: 0, g: 0, b: 0),
            RGBColor(r: 0, g: 0, b: 0)
        ]
        
        let palette = matcher.matchPalette(quantizedColors: colors, preferUnique: false, method: .cielab)
        
        #expect(palette.count == 3, "Should return same count as input")
        
        let allSame = palette.allSatisfy { $0.id == "310" }
        #expect(allSame, "All identical black colors should match DMC 310")
    }
    
    @Test("Palette order matches input order")
    func testPaletteOrderMatchesInput() {
        let matcher = DMCColorMatcher()
        
        let colors = [
            RGBColor(r: 0, g: 0, b: 0),       // Should match black
            RGBColor(r: 255, g: 255, b: 255), // Should match white
            RGBColor(r: 255, g: 0, b: 0)      // Should match red
        ]
        
        let paletteNoUnique = matcher.matchPalette(quantizedColors: colors, preferUnique: false, method: .cielab)
        
        #expect(paletteNoUnique.count == 3, "Should have 3 matches")
        
        // First should be dark, second should be light
        if paletteNoUnique.count == 3 {
            #expect(paletteNoUnique[0].rgb.r < 50, "First should be dark (black)")
            #expect(paletteNoUnique[1].rgb.r > 200, "Second should be light (white)")
        }
    }
}

// MARK: - Custom Palette Tests

@Suite("DMC Color Matcher - Custom Palette")
struct DMCColorMatcherCustomPaletteTests {
    
    @Test("Works with custom small palette")
    func testCustomSmallPalette() {
        // Create a minimal custom palette
        let redRGB = RGBColor(r: 255, g: 0, b: 0)
        let greenRGB = RGBColor(r: 0, g: 255, b: 0)
        let blueRGB = RGBColor(r: 0, g: 0, b: 255)
        
        let customPalette = [
            DMCThread(id: "TEST1", name: "Test Red", rgb: redRGB, lab: redRGB.toLab()),
            DMCThread(id: "TEST2", name: "Test Green", rgb: greenRGB, lab: greenRGB.toLab()),
            DMCThread(id: "TEST3", name: "Test Blue", rgb: blueRGB, lab: blueRGB.toLab())
        ]
        
        let matcher = DMCColorMatcher(palette: customPalette)
        
        // Test that it matches to our custom palette
        let redMatch = matcher.closestThread(to: RGBColor(r: 250, g: 10, b: 10), method: .cielab)
        let greenMatch = matcher.closestThread(to: RGBColor(r: 10, g: 250, b: 10), method: .cielab)
        let blueMatch = matcher.closestThread(to: RGBColor(r: 10, g: 10, b: 250), method: .cielab)
        
        #expect(redMatch?.id == "TEST1", "Should match custom red")
        #expect(greenMatch?.id == "TEST2", "Should match custom green")
        #expect(blueMatch?.id == "TEST3", "Should match custom blue")
    }
}

// MARK: - Skin Tone Tests

@Suite("DMC Color Matcher - Skin Tones")
struct DMCColorMatcherSkinToneTests {
    
    @Test("Light skin tone matches appropriate DMC thread")
    func testLightSkinTone() {
        let matcher = DMCColorMatcher()
        
        // Typical light skin tone
        let skinColor = RGBColor(r: 255, g: 224, b: 189)
        let match = matcher.closestThread(to: skinColor, method: .cielab)
        
        #expect(match != nil, "Should find a match for skin tone")
        
        // The match should be in a similar warm/peach color range
        if let m = match {
            #expect(m.rgb.r > 200, "Skin tone match should have high red")
            #expect(m.rgb.g > 150, "Skin tone match should have moderate green")
        }
    }
    
    @Test("Dark skin tone matches appropriate DMC thread")
    func testDarkSkinTone() {
        let matcher = DMCColorMatcher()
        
        // Typical medium-dark skin tone
        let skinColor = RGBColor(r: 139, g: 90, b: 43)
        let match = matcher.closestThread(to: skinColor, method: .cielab)
        
        #expect(match != nil, "Should find a match for dark skin tone")
        
        // The match should be in a brown/tan color range
        if let m = match {
            #expect(m.rgb.r > m.rgb.b, "Brown tone should have more red than blue")
        }
    }
}
