import Foundation

/// RGB color with 8-bit components
struct RGBColor: Codable, Equatable, Hashable {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    
    /// Initialize from RGB component values
    init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }
    
    /// Initialize from hex string (e.g., "FF5733" or "#FF5733")
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        guard hexSanitized.count == 6,
              let hexValue = UInt32(hexSanitized, radix: 16) else {
            return nil
        }
        
        self.r = UInt8((hexValue >> 16) & 0xFF)
        self.g = UInt8((hexValue >> 8) & 0xFF)
        self.b = UInt8(hexValue & 0xFF)
    }
    
    /// Convert to CIELab for perceptual comparison
    func toLab() -> LabColor {
        let xyz = self.toXYZ()
        return xyz.toLab()
    }
    
    /// Convert to XYZ color space (intermediate step)
    func toXYZ() -> XYZColor {
        // Normalize RGB to 0-1 range and apply inverse sRGB companding
        func inverseCompand(_ c: Double) -> Double {
            if c <= 0.04045 {
                return c / 12.92
            } else {
                return pow((c + 0.055) / 1.055, 2.4)
            }
        }
        
        var rLinear = inverseCompand(Double(r) / 255.0)
        var gLinear = inverseCompand(Double(g) / 255.0)
        var bLinear = inverseCompand(Double(b) / 255.0)
        
        // Scale to 0-100 range
        rLinear *= 100
        gLinear *= 100
        bLinear *= 100
        
        // Apply transformation matrix (sRGB to XYZ, D65 illuminant)
        let x = rLinear * 0.4124564 + gLinear * 0.3575761 + bLinear * 0.1804375
        let y = rLinear * 0.2126729 + gLinear * 0.7151522 + bLinear * 0.0721750
        let z = rLinear * 0.0193339 + gLinear * 0.1191920 + bLinear * 0.9503041
        
        return XYZColor(x: x, y: y, z: z)
    }
    
    /// Hex string representation (uppercase, without # prefix)
    var hexString: String {
        String(format: "%02X%02X%02X", r, g, b)
    }
}
