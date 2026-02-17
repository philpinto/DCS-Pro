//
//  EditingToolbarView.swift
//  DCS Pro
//
//  Toolbar for pattern editing tools and color selection
//

import SwiftUI

/// Toolbar view for pattern editing controls
struct EditingToolbarView: View {
    @Bindable var editingViewModel: PatternEditingViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Edit mode toggle
            editModeToggle
            
            if editingViewModel.isEditingEnabled {
                Divider()
                    .frame(height: 20)
                
                // Tool selection
                toolButtons
                
                Divider()
                    .frame(height: 20)
                
                // Color picker (for paint/fill tools)
                if editingViewModel.currentTool == .paint || editingViewModel.currentTool == .fill {
                    colorPicker
                    
                    Divider()
                        .frame(height: 20)
                }
                
                // Undo/Redo
                undoRedoButtons
            }
            
            Spacer()
            
            // Progress stats (always visible)
            progressStats
            
            Divider()
                .frame(height: 20)
            
            // Progress overlay toggle
            progressOverlayToggle
            
            // Status
            if editingViewModel.isEditingEnabled {
                statusText
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Progress Stats
    
    private var progressStats: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(editingViewModel.progressPercentage > 0 ? .green : .secondary)
            
            Text(editingViewModel.progressText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * CGFloat(editingViewModel.progressPercentage / 100), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(width: 60, height: 4)
        }
    }
    
    // MARK: - Progress Overlay Toggle
    
    private var progressOverlayToggle: some View {
        HStack(spacing: 4) {
            Toggle(isOn: $editingViewModel.showProgressOverlay) {
                Image(systemName: "eye")
            }
            .toggleStyle(.button)
            .help("Show progress overlay")
            
            Toggle(isOn: $editingViewModel.showOnlyRemaining) {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            .toggleStyle(.button)
            .help("Show only remaining stitches")
        }
    }
    
    // MARK: - Edit Mode Toggle
    
    private var editModeToggle: some View {
        Toggle(isOn: $editingViewModel.isEditingEnabled) {
            Label("Edit", systemImage: "pencil")
        }
        .toggleStyle(.button)
        .help("Toggle Edit Mode (⌘E)")
    }
    
    // MARK: - Tool Buttons
    
    private var toolButtons: some View {
        HStack(spacing: 4) {
            ForEach(EditingTool.allCases) { tool in
                Button {
                    editingViewModel.currentTool = tool
                } label: {
                    Image(systemName: tool.icon)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.bordered)
                .tint(editingViewModel.currentTool == tool ? .accentColor : nil)
                .help(tool.helpText)
            }
        }
    }
    
    // MARK: - Color Picker
    
    private var colorPicker: some View {
        HStack(spacing: 8) {
            Text("Color:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Menu {
                ForEach(editingViewModel.pattern.palette) { entry in
                    Button {
                        editingViewModel.selectedThread = entry.thread
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(
                                    red: Double(entry.thread.rgb.r) / 255.0,
                                    green: Double(entry.thread.rgb.g) / 255.0,
                                    blue: Double(entry.thread.rgb.b) / 255.0
                                ))
                                .frame(width: 12, height: 12)
                            Text("\(entry.thread.id) - \(entry.thread.name)")
                            if entry.thread.id == editingViewModel.selectedThread?.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    if let thread = editingViewModel.selectedThread {
                        Circle()
                            .fill(Color(
                                red: Double(thread.rgb.r) / 255.0,
                                green: Double(thread.rgb.g) / 255.0,
                                blue: Double(thread.rgb.b) / 255.0
                            ))
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        Text(thread.id)
                            .font(.caption)
                    } else {
                        Text("Select Color")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3)))
            }
            .menuStyle(.borderlessButton)
        }
    }
    
    // MARK: - Undo/Redo Buttons
    
    private var undoRedoButtons: some View {
        HStack(spacing: 4) {
            Button {
                editingViewModel.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(.borderless)
            .disabled(!editingViewModel.canUndo)
            .help("Undo (⌘Z)")
            
            Button {
                editingViewModel.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .buttonStyle(.borderless)
            .disabled(!editingViewModel.canRedo)
            .help("Redo (⇧⌘Z)")
            
            if editingViewModel.undoCount > 0 || editingViewModel.redoCount > 0 {
                Text("\(editingViewModel.undoCount)/\(editingViewModel.redoCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Status Text
    
    private var statusText: some View {
        Text(editingViewModel.currentTool.helpText)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

// MARK: - Preview

#Preview("Editing Toolbar") {
    let pattern = createToolbarPreviewPattern()
    let viewModel = PatternEditingViewModel(pattern: pattern)
    viewModel.isEditingEnabled = true
    
    return EditingToolbarView(editingViewModel: viewModel)
        .frame(width: 700)
}

#Preview("Editing Toolbar - Disabled") {
    let pattern = createToolbarPreviewPattern()
    let viewModel = PatternEditingViewModel(pattern: pattern)
    viewModel.isEditingEnabled = false
    
    return EditingToolbarView(editingViewModel: viewModel)
        .frame(width: 700)
}

private func createToolbarPreviewPattern() -> Pattern {
    let threads = Array(DMCDatabase.shared.threads.prefix(4))
    let symbols = PatternSymbol.availableSymbols
    
    var palette: [PaletteEntry] = []
    for (index, thread) in threads.enumerated() {
        palette.append(PaletteEntry(
            id: UUID(),
            thread: thread,
            symbol: symbols[index % symbols.count],
            stitchCount: 25
        ))
    }
    
    let stitches: [[Stitch?]] = Array(repeating: Array(repeating: nil, count: 10), count: 10)
    
    return Pattern(
        width: 10,
        height: 10,
        stitches: stitches,
        palette: palette,
        metadata: PatternMetadata(name: "Preview")
    )
}
