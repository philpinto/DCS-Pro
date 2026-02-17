import Foundation

/// Represents a DMC embroidery thread color
struct DMCThread: Codable, Identifiable, Hashable {
    let id: String           // DMC code, e.g., "310", "3865", "BLANC"
    let name: String         // Color name, e.g., "Black", "Winter White"
    let rgb: RGBColor        // RGB value for display
    let lab: LabColor        // CIELab value for matching (pre-computed)
    
    /// Estimated skeins needed for a given stitch count
    /// Based on: ~400 stitches per skein on 14-count with 2 strands
    func skeinsNeeded(forStitchCount count: Int, fabricCount: Int = 14) -> Double {
        // Base calculation: 400 stitches per skein at 14-count
        // Adjust for fabric count (higher count = more thread per stitch)
        let baseStitchesPerSkein = 400.0
        let adjustmentFactor = Double(fabricCount) / 14.0
        let adjustedStitchesPerSkein = baseStitchesPerSkein * adjustmentFactor
        
        return Double(count) / adjustedStitchesPerSkein
    }
}
