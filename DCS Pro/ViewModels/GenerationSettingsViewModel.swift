//
//  GenerationSettingsViewModel.swift
//  DCS Pro
//
//  View model for pattern generation settings
//

import SwiftUI

/// Observable view model for generation settings
@Observable
class GenerationSettingsViewModel {
    // MARK: - Settings State
    
    /// Target width in stitches
    var targetWidth: Int = 200
    
    /// Target height in stitches
    var targetHeight: Int = 250
    
    /// Whether to maintain aspect ratio when adjusting dimensions
    var maintainAspectRatio: Bool = true
    
    /// Maximum number of colors in the palette
    var maxColors: Int = 40
    
    /// Color matching algorithm to use
    var colorMatchingMethod: GenerationSettings.ColorMatchingMethod = .cielab
    
    /// Whether dithering is enabled
    var ditherEnabled: Bool = false
    
    /// Fabric count (stitches per inch)
    var fabricCount: GenerationSettings.FabricCount = .count14
    
    // MARK: - Source Image Info
    
    /// Source image aspect ratio (width/height)
    private var sourceAspectRatio: Double = 1.0
    
    // MARK: - Computed Properties
    
    /// Current settings as GenerationSettings struct
    var settings: GenerationSettings {
        GenerationSettings(
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            maintainAspectRatio: maintainAspectRatio,
            maxColors: maxColors,
            colorMatchingMethod: colorMatchingMethod,
            ditherEnabled: ditherEnabled,
            fabricCount: fabricCount
        )
    }
    
    /// Estimated finished size based on fabric count
    var finishedSizeText: String {
        let widthInches = Double(targetWidth) / Double(fabricCount.rawValue)
        let heightInches = Double(targetHeight) / Double(fabricCount.rawValue)
        return String(format: "%.1f\" × %.1f\"", widthInches, heightInches)
    }
    
    /// Estimated stitch count
    var estimatedStitchCount: Int {
        targetWidth * targetHeight
    }
    
    /// Formatted stitch count string
    var stitchCountText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: estimatedStitchCount)) ?? "\(estimatedStitchCount)"
    }
    
    /// Size category description
    var sizeCategory: String {
        let count = estimatedStitchCount
        if count < 10_000 {
            return "Small (Quick project)"
        } else if count < 50_000 {
            return "Medium (Standard project)"
        } else if count < 100_000 {
            return "Large (Extended project)"
        } else {
            return "Very Large (Major project)"
        }
    }
    
    // MARK: - Initialization
    
    init() {}
    
    /// Initialize with specific settings
    init(settings: GenerationSettings, sourceImage: NSImage? = nil) {
        self.targetWidth = settings.targetWidth
        self.targetHeight = settings.targetHeight
        self.maintainAspectRatio = settings.maintainAspectRatio
        self.maxColors = settings.maxColors
        self.colorMatchingMethod = settings.colorMatchingMethod
        self.ditherEnabled = settings.ditherEnabled
        self.fabricCount = settings.fabricCount
        
        if let image = sourceImage {
            self.sourceAspectRatio = image.size.width / image.size.height
        }
    }
    
    // MARK: - Actions
    
    /// Set source image to calculate aspect ratio
    func setSourceImage(_ image: NSImage) {
        sourceAspectRatio = image.size.width / image.size.height
        
        // Optionally adjust target dimensions to match source aspect ratio
        if maintainAspectRatio {
            adjustHeightForAspectRatio()
        }
    }
    
    /// Update width and optionally adjust height to maintain aspect ratio
    func setWidth(_ newWidth: Int) {
        targetWidth = max(50, min(500, newWidth))
        if maintainAspectRatio {
            adjustHeightForAspectRatio()
        }
    }
    
    /// Update height and optionally adjust width to maintain aspect ratio
    func setHeight(_ newHeight: Int) {
        targetHeight = max(50, min(500, newHeight))
        if maintainAspectRatio {
            adjustWidthForAspectRatio()
        }
    }
    
    /// Apply a preset configuration
    func applyPreset(_ preset: Preset) {
        switch preset {
        case .small:
            let settings = GenerationSettings.small
            applySettings(settings)
        case .standard:
            let settings = GenerationSettings.default
            applySettings(settings)
        case .portrait:
            let settings = GenerationSettings.portrait
            applySettings(settings)
        }
        
        // Adjust for source aspect ratio if maintaining it
        if maintainAspectRatio {
            adjustHeightForAspectRatio()
        }
    }
    
    /// Apply GenerationSettings values
    func applySettings(_ settings: GenerationSettings) {
        targetWidth = settings.targetWidth
        targetHeight = settings.targetHeight
        maintainAspectRatio = settings.maintainAspectRatio
        maxColors = settings.maxColors
        colorMatchingMethod = settings.colorMatchingMethod
        ditherEnabled = settings.ditherEnabled
        fabricCount = settings.fabricCount
    }
    
    // MARK: - Private Helpers
    
    private func adjustHeightForAspectRatio() {
        targetHeight = max(50, min(500, Int(Double(targetWidth) / sourceAspectRatio)))
    }
    
    private func adjustWidthForAspectRatio() {
        targetWidth = max(50, min(500, Int(Double(targetHeight) * sourceAspectRatio)))
    }
    
    // MARK: - Presets
    
    enum Preset: String, CaseIterable {
        case small = "Small"
        case standard = "Standard"
        case portrait = "Portrait"
        
        var description: String {
            switch self {
            case .small: return "~100×125 stitches, 25 colors"
            case .standard: return "~200×250 stitches, 40 colors"
            case .portrait: return "~250×350 stitches, 45 colors"
            }
        }
    }
}
