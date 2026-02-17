import Foundation

/// CIELab color for perceptual color comparison
struct LabColor: Codable, Equatable, Hashable {
    let l: Double  // Lightness: 0-100
    let a: Double  // Green-Red: -128 to +127
    let b: Double  // Blue-Yellow: -128 to +127
    
    /// CIE76 Delta E - simple Euclidean distance in Lab space
    func deltaE76(to other: LabColor) -> Double {
        let dL = self.l - other.l
        let dA = self.a - other.a
        let dB = self.b - other.b
        return sqrt(dL * dL + dA * dA + dB * dB)
    }
    
    /// CIE94 Delta E - better perceptual accuracy than CIE76
    /// Uses weighting factors for lightness, chroma, and hue
    func deltaE94(to other: LabColor, textiles: Bool = true) -> Double {
        // Weighting factors (textiles vs graphic arts)
        let kL: Double = textiles ? 2.0 : 1.0
        let k1: Double = textiles ? 0.048 : 0.045
        let k2: Double = textiles ? 0.014 : 0.015
        
        let kC: Double = 1.0
        let kH: Double = 1.0
        
        // Calculate chroma
        let c1 = sqrt(self.a * self.a + self.b * self.b)
        let c2 = sqrt(other.a * other.a + other.b * other.b)
        
        // Differences
        let dL = self.l - other.l
        let dC = c1 - c2
        let dA = self.a - other.a
        let dB = self.b - other.b
        
        // Delta H (hue difference)
        let dH2 = dA * dA + dB * dB - dC * dC
        let dH = dH2 > 0 ? sqrt(dH2) : 0
        
        // Weighting functions
        let sL: Double = 1.0
        let sC = 1.0 + k1 * c1
        let sH = 1.0 + k2 * c1
        
        // Calculate Delta E 94
        let term1 = dL / (kL * sL)
        let term2 = dC / (kC * sC)
        let term3 = dH / (kH * sH)
        
        return sqrt(term1 * term1 + term2 * term2 + term3 * term3)
    }
}
