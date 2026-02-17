import Foundation

/// Settings for pattern generation
struct GenerationSettings: Codable, Equatable {
    var targetWidth: Int                // Target width in stitches
    var targetHeight: Int               // Target height in stitches
    var maintainAspectRatio: Bool       // Lock aspect ratio
    var maxColors: Int                  // Maximum colors in palette (5-50)
    var colorMatchingMethod: ColorMatchingMethod
    var ditherEnabled: Bool             // Apply dithering for smoother gradients
    
    enum ColorMatchingMethod: String, Codable, CaseIterable {
        case cielab     // CIE76 Delta E (recommended)
        case cie94      // CIE94 (more perceptually accurate)
        case rgb        // Simple RGB Euclidean (fast but less accurate)
        
        var displayName: String {
            switch self {
            case .cielab: return "CIELab (Recommended)"
            case .cie94: return "CIE94 (Most Accurate)"
            case .rgb: return "RGB (Fast)"
            }
        }
        
        var description: String {
            switch self {
            case .cielab: return "Good balance of accuracy and speed. Best for most patterns."
            case .cie94: return "Most perceptually accurate. Best for portraits and skin tones."
            case .rgb: return "Simple and fast, but less accurate color matching."
            }
        }
    }
    
    /// Default settings for general use
    static let `default` = GenerationSettings(
        targetWidth: 200,
        targetHeight: 250,
        maintainAspectRatio: true,
        maxColors: 40,
        colorMatchingMethod: .cielab,
        ditherEnabled: false
    )
    
    /// Optimized settings for portrait photos
    static let portrait = GenerationSettings(
        targetWidth: 250,
        targetHeight: 350,
        maintainAspectRatio: true,
        maxColors: 45,
        colorMatchingMethod: .cie94,
        ditherEnabled: false
    )
    
    /// Settings for smaller projects
    static let small = GenerationSettings(
        targetWidth: 100,
        targetHeight: 125,
        maintainAspectRatio: true,
        maxColors: 25,
        colorMatchingMethod: .cielab,
        ditherEnabled: false
    )
}
