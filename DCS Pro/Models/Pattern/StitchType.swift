import Foundation

/// Types of stitches supported in cross-stitch patterns
enum StitchType: String, Codable, CaseIterable {
    case full           // Standard X stitch
    case half           // Single diagonal (/ or \)
    case quarterTL      // Quarter stitch, top-left
    case quarterTR      // Quarter stitch, top-right
    case quarterBL      // Quarter stitch, bottom-left
    case quarterBR      // Quarter stitch, bottom-right
    case threeQuarter   // 3/4 stitch
    case backstitch     // Outline stitch (line between grid points)
    case frenchKnot     // Decorative knot
    
    var displayName: String {
        switch self {
        case .full: return "Full Stitch"
        case .half: return "Half Stitch"
        case .quarterTL: return "Quarter (Top-Left)"
        case .quarterTR: return "Quarter (Top-Right)"
        case .quarterBL: return "Quarter (Bottom-Left)"
        case .quarterBR: return "Quarter (Bottom-Right)"
        case .threeQuarter: return "Three-Quarter"
        case .backstitch: return "Backstitch"
        case .frenchKnot: return "French Knot"
        }
    }
}
