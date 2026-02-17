//
//  PatternViewModel.swift
//  DCS Pro
//
//  View model for pattern visualization state
//

import SwiftUI

/// Observable view model managing pattern display state
@Observable
class PatternViewModel {
    // MARK: - Pattern Data
    
    var pattern: Pattern
    
    // MARK: - View State
    
    /// Current zoom level (0.25 to 4.0)
    var zoomLevel: Double = 1.0
    
    /// Pan offset for scrolling
    var panOffset: CGPoint = .zero
    
    /// Currently selected color in palette (for highlighting)
    var selectedThreadId: String?
    
    // MARK: - Display Options
    
    /// Show grid lines on pattern
    var showGrid: Bool = true
    
    /// Show symbols on each cell
    var showSymbols: Bool = true
    
    /// Show colors (false = white background with symbols only)
    var showColors: Bool = true
    
    /// Show completed stitch progress (dim completed stitches)
    var showProgress: Bool = false
    
    // MARK: - Constants
    
    let minZoom: Double = 0.25
    let maxZoom: Double = 4.0
    let zoomStep: Double = 0.25
    
    // MARK: - Computed Properties
    
    /// Pattern dimensions as string
    var dimensionsText: String {
        "\(pattern.width) × \(pattern.height)"
    }
    
    /// Color count as string
    var colorCountText: String {
        "\(pattern.palette.count) colors"
    }
    
    /// Total stitch count formatted with commas
    var stitchCountText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: pattern.totalStitchCount)) ?? "\(pattern.totalStitchCount)"
    }
    
    /// Zoom level as percentage string
    var zoomPercentageText: String {
        "\(Int(zoomLevel * 100))%"
    }
    
    /// Finished size at different fabric counts
    func finishedSizeText(fabricCount: Int) -> String {
        let size = pattern.finishedSize(fabricCount: fabricCount)
        return String(format: "%.1f\" × %.1f\"", size.widthInches, size.heightInches)
    }
    
    // MARK: - Initialization
    
    init(pattern: Pattern) {
        self.pattern = pattern
    }
    
    // MARK: - Actions
    
    /// Set zoom level with clamping
    func setZoom(_ level: Double) {
        zoomLevel = min(max(level, minZoom), maxZoom)
    }
    
    /// Zoom in by one step
    func zoomIn() {
        setZoom(zoomLevel + zoomStep)
    }
    
    /// Zoom out by one step
    func zoomOut() {
        setZoom(zoomLevel - zoomStep)
    }
    
    /// Reset zoom to 100%
    func resetZoom() {
        setZoom(1.0)
    }
    
    /// Fit pattern to view
    func fitToView(viewSize: CGSize) {
        let widthRatio = viewSize.width / CGFloat(pattern.width * 20)
        let heightRatio = viewSize.height / CGFloat(pattern.height * 20)
        setZoom(min(widthRatio, heightRatio))
    }
    
    /// Clear color selection
    func clearSelection() {
        selectedThreadId = nil
    }
    
    /// Toggle grid visibility
    func toggleGrid() {
        showGrid.toggle()
    }
    
    /// Toggle symbols visibility
    func toggleSymbols() {
        showSymbols.toggle()
    }
    
    /// Toggle colors visibility
    func toggleColors() {
        showColors.toggle()
    }
}
