//
//  PatternView.swift
//  DCS Pro
//
//  Main container view combining pattern grid, color palette, and toolbar
//

import SwiftUI

/// Main view for displaying and interacting with a cross-stitch pattern
struct PatternView: View {
    @Bindable var viewModel: PatternViewModel
    @Bindable var editingViewModel: PatternEditingViewModel
    var onExport: (() -> Void)?
    var onPatternChanged: ((Pattern) -> Void)?
    
    @State private var fabricCount: Int = 14
    
    init(viewModel: PatternViewModel, editingViewModel: PatternEditingViewModel? = nil, onExport: (() -> Void)? = nil, onPatternChanged: ((Pattern) -> Void)? = nil) {
        self.viewModel = viewModel
        self.editingViewModel = editingViewModel ?? PatternEditingViewModel(pattern: viewModel.pattern)
        self.onExport = onExport
        self.onPatternChanged = onPatternChanged
        
        // Wire up pattern change callback
        self.editingViewModel.onPatternChanged = { [weak viewModel] newPattern in
            viewModel?.pattern = newPattern
            onPatternChanged?(newPattern)
        }
    }
    
    var body: some View {
        HSplitView {
            // Main pattern grid area
            VStack(spacing: 0) {
                toolbar
                Divider()
                EditingToolbarView(editingViewModel: editingViewModel)
                Divider()
                patternGridArea
            }
            .frame(minWidth: 400)
            
            // Color palette sidebar
            ColorPaletteView(
                palette: viewModel.pattern.palette,
                selectedThreadId: $viewModel.selectedThreadId,
                onColorSelected: { thread in
                    editingViewModel.selectedThread = thread
                }
            )
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            editingViewModel.updatePattern(viewModel.pattern)
        }
        .touchBar {
            patternTouchBar
        }
    }
    
    // MARK: - Touch Bar
    
    @ViewBuilder
    private var patternTouchBar: some View {
        // Zoom controls
        Button(action: viewModel.zoomOut) {
            Image(systemName: "minus.magnifyingglass")
        }
        .touchBarItemPresence(.required("com.dcspro.touchbar.zoomout"))
        
        Button(action: viewModel.zoomIn) {
            Image(systemName: "plus.magnifyingglass")
        }
        .touchBarItemPresence(.required("com.dcspro.touchbar.zoomin"))
        
        // View toggles
        Button(action: { viewModel.showGrid.toggle() }) {
            Image(systemName: viewModel.showGrid ? "grid" : "grid.circle")
        }
        .touchBarItemPresence(.default("com.dcspro.touchbar.grid"))
        
        Button(action: { viewModel.showSymbols.toggle() }) {
            Image(systemName: viewModel.showSymbols ? "textformat" : "textformat.alt")
        }
        .touchBarItemPresence(.default("com.dcspro.touchbar.symbols"))
        
        Button(action: { viewModel.showColors.toggle() }) {
            Image(systemName: viewModel.showColors ? "paintpalette.fill" : "paintpalette")
        }
        .touchBarItemPresence(.default("com.dcspro.touchbar.colors"))
        
        // Edit mode toggle
        Button(action: { editingViewModel.isEditingEnabled.toggle() }) {
            Image(systemName: editingViewModel.isEditingEnabled ? "pencil.circle.fill" : "pencil.circle")
        }
        .touchBarItemPresence(.default("com.dcspro.touchbar.edit"))
        
        // Progress display
        Text("\(String(format: "%.0f", editingViewModel.progressPercentage))%")
            .touchBarItemPresence(.optional("com.dcspro.touchbar.progress"))
        
        // Export button
        if let onExport = onExport {
            Button(action: onExport) {
                Image(systemName: "square.and.arrow.up")
            }
            .touchBarItemPresence(.required("com.dcspro.touchbar.export"))
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack(spacing: 16) {
            // Zoom controls
            zoomControls
            
            Divider()
                .frame(height: 20)
            
            // Toggle buttons
            toggleButtons
            
            Spacer()
            
            // Pattern info
            patternInfo
            
            Divider()
                .frame(height: 20)
            
            // Export button
            if let onExport = onExport {
                Button(action: onExport) {
                    Label("Export PDF", systemImage: "square.and.arrow.up")
                }
                .help("Export to PDF")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var zoomControls: some View {
        HStack(spacing: 4) {
            Button(action: viewModel.zoomOut) {
                Image(systemName: "minus.magnifyingglass")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.zoomLevel <= viewModel.minZoom)
            .help("Zoom Out (⌘-)")
            
            Text(viewModel.zoomPercentageText)
                .font(.system(.body, design: .monospaced))
                .frame(width: 50)
            
            Button(action: viewModel.zoomIn) {
                Image(systemName: "plus.magnifyingglass")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.zoomLevel >= viewModel.maxZoom)
            .help("Zoom In (⌘+)")
            
            Button(action: viewModel.resetZoom) {
                Image(systemName: "1.magnifyingglass")
            }
            .buttonStyle(.borderless)
            .help("Reset Zoom (⌘0)")
        }
    }
    
    private var toggleButtons: some View {
        HStack(spacing: 8) {
            Toggle(isOn: $viewModel.showGrid) {
                Label("Grid", systemImage: "grid")
            }
            .toggleStyle(.button)
            .help("Toggle Grid (⌘G)")
            
            Toggle(isOn: $viewModel.showSymbols) {
                Label("Symbols", systemImage: "textformat")
            }
            .toggleStyle(.button)
            .help("Toggle Symbols (⌘S)")
            
            Toggle(isOn: $viewModel.showColors) {
                Label("Colors", systemImage: "paintpalette")
            }
            .toggleStyle(.button)
            .help("Toggle Colors (⌘K)")
        }
    }
    
    private var patternInfo: some View {
        HStack(spacing: 12) {
            Label(viewModel.dimensionsText, systemImage: "rectangle.grid.2x2")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Label(viewModel.colorCountText, systemImage: "paintpalette")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Label(viewModel.stitchCountText, systemImage: "square.grid.3x3")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Pattern Grid Area
    
    private var patternGridArea: some View {
        GeometryReader { geometry in
            ZStack {
                EditablePatternGridView(
                    pattern: viewModel.pattern,
                    zoomLevel: viewModel.zoomLevel,
                    showGrid: viewModel.showGrid,
                    showSymbols: viewModel.showSymbols,
                    showColors: viewModel.showColors,
                    highlightedThreadId: viewModel.selectedThreadId,
                    isEditingEnabled: editingViewModel.isEditingEnabled,
                    currentTool: editingViewModel.currentTool,
                    selectedThread: editingViewModel.selectedThread,
                    showProgressOverlay: editingViewModel.showProgressOverlay,
                    showOnlyRemaining: editingViewModel.showOnlyRemaining,
                    onStitchClick: { x, y in
                        editingViewModel.handleClick(at: x, y: y)
                    },
                    onStitchDrag: { positions in
                        editingViewModel.handleDrag(at: positions)
                    }
                )
                
                // Zoom overlay on pinch/scroll
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        zoomIndicator
                            .padding()
                    }
                }
            }
            .gesture(magnificationGesture)
            .onAppear {
                // Fit to view on initial load
                viewModel.fitToView(viewSize: geometry.size)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var zoomIndicator: some View {
        Text(viewModel.zoomPercentageText)
            .font(.system(.caption, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.9))
            .cornerRadius(4)
            .shadow(radius: 2)
    }
    
    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let delta = value.magnification - 1.0
                viewModel.setZoom(viewModel.zoomLevel + delta * 0.5)
            }
    }
}

// MARK: - Keyboard Shortcuts

extension PatternView {
    var keyboardShortcuts: some View {
        self
            .keyboardShortcut("+", modifiers: .command) { viewModel.zoomIn() }
            .keyboardShortcut("-", modifiers: .command) { viewModel.zoomOut() }
            .keyboardShortcut("0", modifiers: .command) { viewModel.resetZoom() }
            .keyboardShortcut("g", modifiers: .command) { viewModel.toggleGrid() }
            .keyboardShortcut("k", modifiers: .command) { viewModel.toggleColors() }
            .keyboardShortcut("e", modifiers: .command) { editingViewModel.isEditingEnabled.toggle() }
            .keyboardShortcut("z", modifiers: .command) { editingViewModel.undo() }
            .keyboardShortcut("z", modifiers: [.command, .shift]) { editingViewModel.redo() }
    }
}

// Helper extension for keyboard shortcuts
extension View {
    func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        self.background(
            Button(action: action) { EmptyView() }
                .keyboardShortcut(key, modifiers: modifiers)
                .opacity(0)
        )
    }
}

// MARK: - Preview

#Preview("Pattern View") {
    let pattern = createPreviewPattern()
    let viewModel = PatternViewModel(pattern: pattern)
    let editingVM = PatternEditingViewModel(pattern: pattern)
    
    return PatternView(viewModel: viewModel, editingViewModel: editingVM)
        .frame(width: 900, height: 600)
}

#Preview("Pattern View - Small Pattern") {
    let pattern = createPreviewPattern(width: 30, height: 30, colors: 6)
    let viewModel = PatternViewModel(pattern: pattern)
    let editingVM = PatternEditingViewModel(pattern: pattern)
    
    return PatternView(viewModel: viewModel, editingViewModel: editingVM)
        .frame(width: 800, height: 500)
}

#Preview("Pattern View - Edit Mode") {
    let pattern = createPreviewPattern(width: 30, height: 30, colors: 6)
    let viewModel = PatternViewModel(pattern: pattern)
    let editingVM = PatternEditingViewModel(pattern: pattern)
    editingVM.isEditingEnabled = true
    
    return PatternView(viewModel: viewModel, editingViewModel: editingVM)
        .frame(width: 900, height: 600)
}

// Helper function for previews
private func createPreviewPattern(width: Int = 50, height: Int = 50, colors: Int = 10) -> Pattern {
    let threads = Array(DMCDatabase.shared.threads.prefix(colors))
    let symbols = PatternSymbol.availableSymbols
    
    var palette: [PaletteEntry] = []
    for (index, thread) in threads.enumerated() {
        palette.append(PaletteEntry(
            id: UUID(),
            thread: thread,
            symbol: symbols[index % symbols.count],
            stitchCount: (width * height) / colors
        ))
    }
    
    var stitches: [[Stitch?]] = []
    for y in 0..<height {
        var row: [Stitch?] = []
        for x in 0..<width {
            let colorIndex = ((x / 5) + (y / 5)) % colors
            row.append(Stitch(thread: threads[colorIndex]))
        }
        stitches.append(row)
    }
    
    return Pattern(
        width: width,
        height: height,
        stitches: stitches,
        palette: palette,
        metadata: PatternMetadata(name: "Preview Pattern")
    )
}
