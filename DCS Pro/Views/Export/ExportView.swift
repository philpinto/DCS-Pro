//
//  ExportView.swift
//  DCS Pro
//
//  View for configuring and executing PDF export
//

import SwiftUI

/// View for exporting patterns to PDF
struct ExportView: View {
    var viewModel: ExportViewModel
    let pattern: Pattern
    let onDismiss: () -> Void
    
    @State private var pdfData: Data?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title field
            headerSection
            
            Divider()
            
            // Main content - two columns
            HStack(spacing: 0) {
                // Left: Settings
                settingsPanel
                    .frame(width: 300)
                
                Divider()
                
                // Right: Summary and Preview
                summaryPanel
            }
            
            Divider()
            
            // Footer with buttons
            footerSection
        }
        .frame(minWidth: 680, minHeight: 520)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Title input
            VStack(alignment: .leading, spacing: 4) {
                Text("Export Pattern")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Configure PDF export options")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Pattern info
            HStack(spacing: 12) {
                Label("\(pattern.width)×\(pattern.height)", systemImage: "grid")
                Label("\(pattern.palette.count) colors", systemImage: "paintpalette")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // MARK: - Settings Panel (Left Side)
    
    private var settingsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Pattern Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pattern Title")
                        .font(.headline)
                    
                    TextField("Enter title", text: Binding(
                        get: { viewModel.patternTitle },
                        set: { viewModel.patternTitle = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
                
                // Page Size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Page Size")
                        .font(.headline)
                    
                    Picker("", selection: Binding(
                        get: { viewModel.pageSize },
                        set: { viewModel.pageSize = $0 }
                    )) {
                        ForEach(PDFExportService.ExportSettings.PageSize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                // Include Pages
                VStack(alignment: .leading, spacing: 10) {
                    Text("Include Pages")
                        .font(.headline)
                    
                    Toggle("Cover page with preview", isOn: Binding(
                        get: { viewModel.includePreview },
                        set: { viewModel.includePreview = $0 }
                    ))
                    .toggleStyle(.checkbox)
                    
                    Toggle("Thread list with quantities", isOn: Binding(
                        get: { viewModel.includeThreadList },
                        set: { viewModel.includeThreadList = $0 }
                    ))
                    .toggleStyle(.checkbox)
                    
                    Toggle("Color legend with symbols", isOn: Binding(
                        get: { viewModel.includeLegend },
                        set: { viewModel.includeLegend = $0 }
                    ))
                    .toggleStyle(.checkbox)
                }
                
                // Pattern Grid Options
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pattern Grid")
                        .font(.headline)
                    
                    Toggle("Show row and column numbers", isOn: Binding(
                        get: { viewModel.showGridNumbers },
                        set: { viewModel.showGridNumbers = $0 }
                    ))
                    .toggleStyle(.checkbox)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Stitches per page")
                            Spacer()
                            Text("\(viewModel.stitchesPerPage)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(viewModel.stitchesPerPage) },
                                set: { viewModel.stitchesPerPage = Int($0) }
                            ),
                            in: 30...80,
                            step: 5
                        )
                        
                        HStack {
                            Text("Larger symbols")
                            Spacer()
                            Text("More stitches")
                        }
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
            }
            .padding(20)
        }
    }
    
    // MARK: - Summary Panel (Right Side)
    
    private var summaryPanel: some View {
        VStack(spacing: 20) {
            // Page Summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Export Summary")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    summaryRow("Pattern Pages", "\(calculatePatternPages())")
                    
                    if viewModel.includePreview {
                        summaryRow("Cover Page", "1")
                    }
                    
                    if viewModel.includeThreadList {
                        summaryRow("Thread List", "\(calculateThreadListPages())")
                    }
                    
                    if viewModel.includeLegend {
                        summaryRow("Color Legend", "\(calculateLegendPages())")
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    HStack {
                        Text("Total Pages")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(viewModel.estimatedPageCount(for: pattern))")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Pattern Preview
            VStack(alignment: .leading, spacing: 12) {
                Text("Pattern Preview")
                    .font(.headline)
                
                patternThumbnail
                    .frame(height: 180)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            // Export progress
            if viewModel.isExporting {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.exportProgress)
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
        .padding(20)
    }
    
    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.callout)
    }
    
    private var patternThumbnail: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                var colorLookup: [String: Color] = [:]
                for entry in pattern.palette {
                    colorLookup[entry.thread.id] = Color(
                        red: Double(entry.thread.rgb.r) / 255.0,
                        green: Double(entry.thread.rgb.g) / 255.0,
                        blue: Double(entry.thread.rgb.b) / 255.0
                    )
                }
                
                let cellWidth = size.width / CGFloat(pattern.width)
                let cellHeight = size.height / CGFloat(pattern.height)
                let cellSize = min(cellWidth, cellHeight)
                
                let offsetX = (size.width - cellSize * CGFloat(pattern.width)) / 2
                let offsetY = (size.height - cellSize * CGFloat(pattern.height)) / 2
                
                for row in 0..<pattern.height {
                    for col in 0..<pattern.width {
                        if let stitch = pattern.stitches[row][col],
                           let color = colorLookup[stitch.thread.id] {
                            let rect = CGRect(
                                x: offsetX + CGFloat(col) * cellSize,
                                y: offsetY + CGFloat(row) * cellSize,
                                width: cellSize,
                                height: cellSize
                            )
                            context.fill(Path(rect), with: .color(color))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        HStack {
            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            Spacer()
            
            Button("Cancel") {
                onDismiss()
            }
            .keyboardShortcut(.cancelAction)
            
            Button("Export PDF") {
                Task {
                    if let data = await viewModel.exportPDF(pattern: pattern) {
                        pdfData = data
                        let suggestedName = "\(viewModel.patternTitle).pdf"
                        if await viewModel.savePDF(data, suggestedName: suggestedName) {
                            onDismiss()
                        }
                    }
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(viewModel.isExporting)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func calculatePatternPages() -> Int {
        let stitchesPerPage = viewModel.stitchesPerPage
        let pagesWide = (pattern.width + stitchesPerPage - 1) / stitchesPerPage
        let pagesHigh = (pattern.height + stitchesPerPage - 1) / stitchesPerPage
        return pagesWide * pagesHigh
    }
    
    private func calculateThreadListPages() -> Int {
        let itemsPerPage = 25
        return max(1, (pattern.palette.count + itemsPerPage - 1) / itemsPerPage)
    }
    
    private func calculateLegendPages() -> Int {
        let itemsPerPage = 40
        return max(1, (pattern.palette.count + itemsPerPage - 1) / itemsPerPage)
    }
}

// MARK: - Preview

#Preview {
    let thread1 = DMCThread(
        id: "310",
        name: "Black",
        rgb: RGBColor(r: 0, g: 0, b: 0),
        lab: LabColor(l: 0, a: 0, b: 0)
    )
    let thread2 = DMCThread(
        id: "BLANC",
        name: "White",
        rgb: RGBColor(r: 255, g: 255, b: 255),
        lab: LabColor(l: 100, a: 0, b: 0)
    )
    
    let symbol1 = PatternSymbol("●")
    let symbol2 = PatternSymbol("○")
    
    var stitches: [[Stitch?]] = Array(repeating: Array(repeating: nil, count: 50), count: 50)
    for row in 0..<50 {
        for col in 0..<50 {
            let thread = (row + col) % 2 == 0 ? thread1 : thread2
            stitches[row][col] = Stitch(thread: thread)
        }
    }
    
    let pattern = Pattern(
        width: 50,
        height: 50,
        stitches: stitches,
        palette: [
            PaletteEntry(thread: thread1, symbol: symbol1, stitchCount: 1250),
            PaletteEntry(thread: thread2, symbol: symbol2, stitchCount: 1250)
        ]
    )
    
    return ExportView(
        viewModel: ExportViewModel(),
        pattern: pattern,
        onDismiss: { }
    )
}
