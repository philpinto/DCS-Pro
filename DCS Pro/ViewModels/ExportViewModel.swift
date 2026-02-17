//
//  ExportViewModel.swift
//  DCS Pro
//
//  View model for PDF export functionality
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

/// Observable view model for export state
@Observable
class ExportViewModel {
    // MARK: - Export Settings
    
    /// Page size for PDF
    var pageSize: PDFExportService.ExportSettings.PageSize = .letter
    
    /// Whether to include the cover page
    var includePreview: Bool = true
    
    /// Whether to include the thread list
    var includeThreadList: Bool = true
    
    /// Whether to include the color legend
    var includeLegend: Bool = true
    
    /// Show grid numbers on pattern pages
    var showGridNumbers: Bool = true
    
    /// Stitches per page (affects page count)
    var stitchesPerPage: Int = 50
    
    /// Pattern title for the PDF
    var patternTitle: String = "Cross-Stitch Pattern"
    
    /// Fabric count for finished size calculations
    var fabricCount: GenerationSettings.FabricCount = .count14
    
    /// Chart rendering style (color or symbol-only)
    var chartStyle: PDFExportService.ExportSettings.ChartStyle = .color
    
    // MARK: - Export State
    
    /// Whether export is in progress
    var isExporting: Bool = false
    
    /// Export progress (0.0 to 1.0)
    var exportProgress: Double = 0.0
    
    /// Current status message
    var statusMessage: String = ""
    
    /// Error message if export failed
    var errorMessage: String?
    
    /// Whether export completed successfully
    var exportComplete: Bool = false
    
    // MARK: - Services
    
    private let exportService = PDFExportService()
    
    // MARK: - Computed Properties
    
    /// Current export settings
    var settings: PDFExportService.ExportSettings {
        PDFExportService.ExportSettings(
            pageSize: pageSize,
            includePreview: includePreview,
            includeThreadList: includeThreadList,
            includeLegend: includeLegend,
            stitchesPerPage: stitchesPerPage,
            symbolFontSize: 10,
            showGridNumbers: showGridNumbers,
            patternTitle: patternTitle,
            chartStyle: chartStyle
        )
    }
    
    /// Calculate estimated page count for a pattern
    func estimatedPageCount(for pattern: Pattern) -> Int {
        exportService.calculatePageCount(pattern: pattern, settings: settings)
    }
    
    /// Calculate finished size text for a pattern
    func finishedSizeText(for pattern: Pattern) -> String {
        let widthInches = Double(pattern.width) / Double(fabricCount.rawValue)
        let heightInches = Double(pattern.height) / Double(fabricCount.rawValue)
        return String(format: "%.1f\" × %.1f\"", widthInches, heightInches)
    }
    
    // MARK: - Actions
    
    /// Export pattern to PDF
    @MainActor
    func exportPDF(pattern: Pattern) async -> Data? {
        isExporting = true
        exportProgress = 0.0
        errorMessage = nil
        exportComplete = false
        statusMessage = "Preparing export..."
        
        let currentSettings = self.settings
        let pdfData = exportService.exportPDF(pattern: pattern, settings: currentSettings) { progress, message in
            Task { @MainActor in
                self.exportProgress = progress
                self.statusMessage = message
            }
        }
        
        isExporting = false
        
        if pdfData != nil {
            exportComplete = true
            statusMessage = "Export complete!"
        } else {
            errorMessage = "Failed to generate PDF"
            statusMessage = "Export failed"
        }
        
        return pdfData
    }
    
    /// Save PDF data to a file
    @MainActor
    func savePDF(_ data: Data, suggestedName: String) async -> Bool {
        // Sanitize the filename - remove invalid characters
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let sanitizedName = suggestedName
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = sanitizedName
        savePanel.canCreateDirectories = true
        savePanel.title = "Save Pattern PDF"
        savePanel.message = "Choose where to save your cross-stitch pattern"
        
        let response = await savePanel.begin()
        
        guard response == .OK, let url = savePanel.url else {
            return false
        }
        
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            errorMessage = "Failed to save file: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Reset export state
    func reset() {
        isExporting = false
        exportProgress = 0.0
        statusMessage = ""
        errorMessage = nil
        exportComplete = false
    }
}
