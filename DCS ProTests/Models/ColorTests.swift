//
//  ColorTests.swift
//  DCS ProTests
//
//  Comprehensive unit tests for RGBColor and LabColor models
//

import Testing
@testable import DCS_Pro

// MARK: - RGB to Lab Conversion Tests

@Suite("RGB to Lab Conversion")
struct RGBToLabConversionTests {
    
    @Test("Black converts to Lab correctly")
    func testBlackToLab() {
        let black = RGBColor(r: 0, g: 0, b: 0)
        let lab = black.toLab()
        
        #expect(abs(lab.l) < 0.1, "Black should have L close to 0")
        #expect(abs(lab.a) < 0.1, "Black should have a close to 0")
        #expect(abs(lab.b) < 0.1, "Black should have b close to 0")
    }
    
    @Test("White converts to Lab correctly")
    func testWhiteToLab() {
        let white = RGBColor(r: 255, g: 255, b: 255)
        let lab = white.toLab()
        
        #expect(abs(lab.l - 100) < 0.1, "White should have L close to 100")
        #expect(abs(lab.a) < 0.5, "White should have a close to 0")
        #expect(abs(lab.b) < 0.5, "White should have b close to 0")
    }
    
    @Test("Pure red has positive a value")
    func testRedHasPositiveA() {
        let red = RGBColor(r: 255, g: 0, b: 0)
        let lab = red.toLab()
        
        #expect(lab.a > 50, "Red should have positive a (green-red axis)")
        #expect(lab.l > 40 && lab.l < 60, "Red should have medium lightness")
    }
    
    @Test("Pure green has negative a value")
    func testGreenHasNegativeA() {
        let green = RGBColor(r: 0, g: 255, b: 0)
        let lab = green.toLab()
        
        #expect(lab.a < -50, "Green should have negative a (green-red axis)")
        #expect(lab.l > 80, "Green should have high lightness")
    }
    
    @Test("Pure blue has negative b value")
    func testBlueHasNegativeB() {
        let blue = RGBColor(r: 0, g: 0, b: 255)
        let lab = blue.toLab()
        
        #expect(lab.b < -50, "Blue should have negative b (blue-yellow axis)")
        #expect(lab.l > 20 && lab.l < 40, "Blue should have lower lightness")
    }
    
    @Test("Yellow has positive b value")
    func testYellowHasPositiveB() {
        let yellow = RGBColor(r: 255, g: 255, b: 0)
        let lab = yellow.toLab()
        
        #expect(lab.b > 50, "Yellow should have positive b (blue-yellow axis)")
        #expect(lab.l > 90, "Yellow should have high lightness")
    }
    
    @Test("Gray has near-zero a and b values")
    func testGrayIsNeutral() {
        let gray = RGBColor(r: 128, g: 128, b: 128)
        let lab = gray.toLab()
        
        #expect(abs(lab.a) < 1, "Gray should have a close to 0")
        #expect(abs(lab.b) < 1, "Gray should have b close to 0")
        #expect(lab.l > 45 && lab.l < 55, "Gray should have medium lightness")
    }
}

// MARK: - Hex String Initialization Tests

@Suite("RGB Hex String Initialization")
struct RGBHexInitializationTests {
    
    @Test("Valid hex without hash prefix")
    func testHexWithoutHash() {
        let color = RGBColor(hex: "FF5733")
        
        #expect(color != nil)
        #expect(color?.r == 255)
        #expect(color?.g == 87)
        #expect(color?.b == 51)
    }
    
    @Test("Valid hex with hash prefix")
    func testHexWithHash() {
        let color = RGBColor(hex: "#00FF00")
        
        #expect(color != nil)
        #expect(color?.r == 0)
        #expect(color?.g == 255)
        #expect(color?.b == 0)
    }
    
    @Test("Black hex string")
    func testBlackHex() {
        let color = RGBColor(hex: "000000")
        
        #expect(color != nil)
        #expect(color?.r == 0)
        #expect(color?.g == 0)
        #expect(color?.b == 0)
    }
    
    @Test("White hex string")
    func testWhiteHex() {
        let color = RGBColor(hex: "FFFFFF")
        
        #expect(color != nil)
        #expect(color?.r == 255)
        #expect(color?.g == 255)
        #expect(color?.b == 255)
    }
    
    @Test("Lowercase hex string")
    func testLowercaseHex() {
        let color = RGBColor(hex: "aabbcc")
        
        #expect(color != nil)
        #expect(color?.r == 170)
        #expect(color?.g == 187)
        #expect(color?.b == 204)
    }
    
    @Test("Invalid hex string returns nil - too short")
    func testInvalidHexTooShort() {
        let color = RGBColor(hex: "FFF")
        #expect(color == nil)
    }
    
    @Test("Invalid hex string returns nil - too long")
    func testInvalidHexTooLong() {
        let color = RGBColor(hex: "FFFFFFF")
        #expect(color == nil)
    }
    
    @Test("Invalid hex string returns nil - invalid characters")
    func testInvalidHexCharacters() {
        let color = RGBColor(hex: "GGGGGG")
        #expect(color == nil)
    }
    
    @Test("Hex string with whitespace")
    func testHexWithWhitespace() {
        let color = RGBColor(hex: "  FF0000  ")
        
        #expect(color != nil)
        #expect(color?.r == 255)
        #expect(color?.g == 0)
        #expect(color?.b == 0)
    }
}

// MARK: - Hex String Output Tests

@Suite("RGB Hex String Output")
struct RGBHexOutputTests {
    
    @Test("Black outputs correct hex string")
    func testBlackHexOutput() {
        let black = RGBColor(r: 0, g: 0, b: 0)
        #expect(black.hexString == "000000")
    }
    
    @Test("White outputs correct hex string")
    func testWhiteHexOutput() {
        let white = RGBColor(r: 255, g: 255, b: 255)
        #expect(white.hexString == "FFFFFF")
    }
    
    @Test("Color outputs correct hex string")
    func testColorHexOutput() {
        let color = RGBColor(r: 170, g: 187, b: 204)
        #expect(color.hexString == "AABBCC")
    }
}

// MARK: - Delta E Calculation Tests

@Suite("Delta E Calculations")
struct DeltaETests {
    
    @Test("Identical colors have zero Delta E")
    func testIdenticalColorsZeroDistance() {
        let color = LabColor(l: 50, a: 25, b: -10)
        let deltaE = color.deltaE76(to: color)
        
        #expect(deltaE == 0, "Identical colors should have Delta E of 0")
    }
    
    @Test("Very similar colors have Delta E less than 2")
    func testSimilarColorsSmallDeltaE() {
        let color1 = LabColor(l: 50, a: 25, b: -10)
        let color2 = LabColor(l: 51, a: 26, b: -9)
        let deltaE = color1.deltaE76(to: color2)
        
        #expect(deltaE < 2, "Very similar colors should have Delta E < 2 (imperceptible)")
    }
    
    @Test("Black and white have Delta E greater than 90")
    func testBlackWhiteLargeDeltaE() {
        let black = RGBColor(r: 0, g: 0, b: 0).toLab()
        let white = RGBColor(r: 255, g: 255, b: 255).toLab()
        let deltaE = black.deltaE76(to: white)
        
        #expect(deltaE > 90, "Black and white should have maximum Delta E (> 90)")
    }
    
    @Test("Moderately different colors have moderate Delta E")
    func testModeratelyDifferentColors() {
        let color1 = LabColor(l: 50, a: 0, b: 0)
        let color2 = LabColor(l: 60, a: 10, b: 10)
        let deltaE = color1.deltaE76(to: color2)
        
        #expect(deltaE > 5 && deltaE < 20, "Moderately different colors should have Delta E between 5-20")
    }
    
    @Test("Delta E is symmetric")
    func testDeltaESymmetric() {
        let color1 = LabColor(l: 30, a: 50, b: -20)
        let color2 = LabColor(l: 70, a: -30, b: 40)
        
        let deltaE1 = color1.deltaE76(to: color2)
        let deltaE2 = color2.deltaE76(to: color1)
        
        #expect(abs(deltaE1 - deltaE2) < 0.0001, "Delta E should be symmetric")
    }
    
    @Test("Delta E satisfies triangle inequality")
    func testDeltaETriangleInequality() {
        let a = LabColor(l: 20, a: 10, b: 10)
        let b = LabColor(l: 50, a: 30, b: -20)
        let c = LabColor(l: 80, a: -10, b: 40)
        
        let ab = a.deltaE76(to: b)
        let bc = b.deltaE76(to: c)
        let ac = a.deltaE76(to: c)
        
        #expect(ac <= ab + bc, "Delta E should satisfy triangle inequality")
    }
}

// MARK: - CIE94 Delta E Tests

@Suite("CIE94 Delta E Calculations")
struct DeltaE94Tests {
    
    @Test("Identical colors have zero CIE94 Delta E")
    func testIdenticalColorsZeroDistance() {
        let color = LabColor(l: 50, a: 25, b: -10)
        let deltaE = color.deltaE94(to: color)
        
        #expect(deltaE == 0, "Identical colors should have CIE94 Delta E of 0")
    }
    
    @Test("CIE94 gives different result than CIE76 for chromatic colors")
    func testCIE94DifferentFromCIE76() {
        let color1 = LabColor(l: 50, a: 60, b: 20)
        let color2 = LabColor(l: 50, a: 50, b: 30)
        
        let deltaE76 = color1.deltaE76(to: color2)
        let deltaE94 = color1.deltaE94(to: color2)
        
        #expect(deltaE76 != deltaE94, "CIE94 should differ from CIE76 for chromatic colors")
    }
    
    @Test("CIE94 textiles mode differs from graphic arts mode")
    func testCIE94TextilesVsGraphicArts() {
        let color1 = LabColor(l: 50, a: 30, b: 10)
        let color2 = LabColor(l: 60, a: 40, b: 20)
        
        let textilesDE = color1.deltaE94(to: color2, textiles: true)
        let graphicsDE = color1.deltaE94(to: color2, textiles: false)
        
        #expect(textilesDE != graphicsDE, "Textiles and graphic arts modes should produce different results")
    }
}

// MARK: - RGB Color Equality and Hashability Tests

@Suite("RGB Color Equality and Hashability")
struct RGBColorEqualityTests {
    
    @Test("Equal colors are equal")
    func testEqualColors() {
        let color1 = RGBColor(r: 100, g: 150, b: 200)
        let color2 = RGBColor(r: 100, g: 150, b: 200)
        
        #expect(color1 == color2)
    }
    
    @Test("Different colors are not equal")
    func testDifferentColors() {
        let color1 = RGBColor(r: 100, g: 150, b: 200)
        let color2 = RGBColor(r: 100, g: 150, b: 201)
        
        #expect(color1 != color2)
    }
    
    @Test("Equal colors have same hash")
    func testEqualColorsHashEqual() {
        let color1 = RGBColor(r: 100, g: 150, b: 200)
        let color2 = RGBColor(r: 100, g: 150, b: 200)
        
        #expect(color1.hashValue == color2.hashValue)
    }
    
    @Test("Colors work in Set")
    func testColorsInSet() {
        let color1 = RGBColor(r: 100, g: 150, b: 200)
        let color2 = RGBColor(r: 100, g: 150, b: 200)
        let color3 = RGBColor(r: 200, g: 100, b: 50)
        
        var colorSet: Set<RGBColor> = []
        colorSet.insert(color1)
        colorSet.insert(color2)
        colorSet.insert(color3)
        
        #expect(colorSet.count == 2, "Set should contain only 2 unique colors")
    }
}

// MARK: - Lab Color Equality Tests

@Suite("Lab Color Equality")
struct LabColorEqualityTests {
    
    @Test("Equal Lab colors are equal")
    func testEqualLabColors() {
        let lab1 = LabColor(l: 50.0, a: 25.5, b: -10.3)
        let lab2 = LabColor(l: 50.0, a: 25.5, b: -10.3)
        
        #expect(lab1 == lab2)
    }
    
    @Test("Different Lab colors are not equal")
    func testDifferentLabColors() {
        let lab1 = LabColor(l: 50.0, a: 25.5, b: -10.3)
        let lab2 = LabColor(l: 50.1, a: 25.5, b: -10.3)
        
        #expect(lab1 != lab2)
    }
}
