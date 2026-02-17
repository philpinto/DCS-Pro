//
//  GenerationSettingsView.swift
//  DCS Pro
//
//  Created for Delaney's Cross Stitch Pro
//

import SwiftUI

/// View for configuring pattern generation settings
struct GenerationSettingsView: View {
    var viewModel: GenerationSettingsViewModel
    let sourceImage: NSImage
    let onGenerate: (GenerationSettings) -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Main content
            HSplitView {
                // Image preview
                imagePreview
                    .frame(minWidth: 250)
                
                // Settings panel
                settingsPanel
                    .frame(minWidth: 340, idealWidth: 360)
            }
            .padding()
            
            Divider()
            
            // Footer
            footer
        }
        .frame(minWidth: 750, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            viewModel.setSourceImage(sourceImage)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pattern Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Configure dimensions, colors, and quality settings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Image Preview
    
    private var imagePreview: some View {
        VStack {
            // Image with overlay showing pattern grid
            ZStack {
                Image(nsImage: sourceImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                
                // Grid overlay to show stitch density
                PatternGridOverlay(
                    width: viewModel.targetWidth,
                    height: viewModel.targetHeight,
                    imageSize: sourceImage.size
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Size info
            HStack {
                Label("\(viewModel.targetWidth) × \(viewModel.targetHeight) stitches", systemImage: "grid")
                Spacer()
                Label(viewModel.stitchCountText + " total", systemImage: "number")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Settings Panel
    
    private var settingsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Presets
                presetsSection
                
                Divider()
                
                // Dimensions
                dimensionsSection
                
                Divider()
                
                // Fabric
                fabricSection
                
                Divider()
                
                // Colors
                colorsSection
                
                Divider()
                
                // Advanced
                advancedSection
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Presets Section
    
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Presets")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(GenerationSettingsViewModel.Preset.allCases, id: \.self) { preset in
                    Button(action: {
                        viewModel.applyPreset(preset)
                    }) {
                        VStack(spacing: 4) {
                            Text(preset.rawValue)
                                .fontWeight(.medium)
                            Text(preset.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    // MARK: - Dimensions Section
    
    private var dimensionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dimensions")
                .font(.headline)
            
            // Width
            HStack {
                Text("Width")
                    .frame(width: 60, alignment: .leading)
                
                TextField("Width", value: Binding(
                    get: { viewModel.targetWidth },
                    set: { viewModel.setWidth($0) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                
                Text("stitches")
                    .foregroundStyle(.secondary)
                
                Stepper("", value: Binding(
                    get: { viewModel.targetWidth },
                    set: { viewModel.setWidth($0) }
                ), in: 50...500, step: 10)
                .labelsHidden()
            }
            
            // Height
            HStack {
                Text("Height")
                    .frame(width: 60, alignment: .leading)
                
                TextField("Height", value: Binding(
                    get: { viewModel.targetHeight },
                    set: { viewModel.setHeight($0) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                
                Text("stitches")
                    .foregroundStyle(.secondary)
                
                Stepper("", value: Binding(
                    get: { viewModel.targetHeight },
                    set: { viewModel.setHeight($0) }
                ), in: 50...500, step: 10)
                .labelsHidden()
            }
            
            // Maintain aspect ratio toggle
            Toggle("Maintain aspect ratio", isOn: Binding(
                get: { viewModel.maintainAspectRatio },
                set: { viewModel.maintainAspectRatio = $0 }
            ))
            .toggleStyle(.checkbox)
            
            // Size category indicator
            HStack {
                Image(systemName: "info.circle")
                Text(viewModel.sizeCategory)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Fabric Section
    
    private var fabricSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fabric")
                .font(.headline)
            
            // Fabric count picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Aida Fabric Count")
                
                Picker("", selection: Binding(
                    get: { viewModel.fabricCount },
                    set: { viewModel.fabricCount = $0 }
                )) {
                    ForEach(GenerationSettings.FabricCount.allCases, id: \.self) { count in
                        Text(count.displayName).tag(count)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                
                Text(viewModel.fabricCount.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Finished size display
            HStack {
                Image(systemName: "ruler")
                Text("Finished size: \(viewModel.finishedSizeText)")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Colors Section
    
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Colors")
                .font(.headline)
            
            // Max colors slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Maximum Colors")
                    Spacer()
                    Text("\(viewModel.maxColors)")
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
                
                Slider(
                    value: Binding(
                        get: { Double(viewModel.maxColors) },
                        set: { viewModel.maxColors = Int($0) }
                    ),
                    in: 5...50,
                    step: 1
                )
                
                HStack {
                    Text("5")
                    Spacer()
                    Text("50")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            
            // Color matching method picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Color Matching")
                
                Picker("", selection: Binding(
                    get: { viewModel.colorMatchingMethod },
                    set: { viewModel.colorMatchingMethod = $0 }
                )) {
                    ForEach(GenerationSettings.ColorMatchingMethod.allCases, id: \.self) { method in
                        Text(method.displayName).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                
                Text(viewModel.colorMatchingMethod.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Advanced Section
    
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced")
                .font(.headline)
            
            Toggle(isOn: Binding(
                get: { viewModel.ditherEnabled },
                set: { viewModel.ditherEnabled = $0 }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Dithering")
                    Text("Creates smoother gradients but increases complexity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.checkbox)
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            // Summary
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.stitchCountText) stitches • \(viewModel.maxColors) colors max")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Back") {
                onBack()
            }
            .keyboardShortcut(.cancelAction)
            
            Button("Generate Pattern") {
                onGenerate(viewModel.settings)
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
    }
}

// MARK: - Pattern Grid Overlay

/// Shows a grid overlay on the image preview to visualize stitch density
struct PatternGridOverlay: View {
    let width: Int
    let height: Int
    let imageSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, _ in
                let metrics = calculateMetrics(for: geometry.size)
                
                let cellWidth = metrics.displaySize.width / CGFloat(min(width, 20))
                let cellHeight = metrics.displaySize.height / CGFloat(min(height, 25))
                
                // Vertical lines
                for i in 0...min(width, 20) {
                    let x = metrics.offsetX + CGFloat(i) * cellWidth
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: metrics.offsetY))
                    path.addLine(to: CGPoint(x: x, y: metrics.offsetY + metrics.displaySize.height))
                    context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 0.5)
                }
                
                // Horizontal lines
                for i in 0...min(height, 25) {
                    let y = metrics.offsetY + CGFloat(i) * cellHeight
                    var path = Path()
                    path.move(to: CGPoint(x: metrics.offsetX, y: y))
                    path.addLine(to: CGPoint(x: metrics.offsetX + metrics.displaySize.width, y: y))
                    context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 0.5)
                }
            }
        }
    }
    
    private struct GridMetrics {
        let displaySize: CGSize
        let offsetX: CGFloat
        let offsetY: CGFloat
    }
    
    private func calculateMetrics(for viewSize: CGSize) -> GridMetrics {
        let viewAspect = viewSize.width / viewSize.height
        let imageAspect = imageSize.width / imageSize.height
        
        let displaySize: CGSize
        if viewAspect > imageAspect {
            // View is wider than image - height limited
            let displayHeight = viewSize.height
            let displayWidth = displayHeight * imageAspect
            displaySize = CGSize(width: displayWidth, height: displayHeight)
        } else {
            // View is taller than image - width limited
            let displayWidth = viewSize.width
            let displayHeight = displayWidth / imageAspect
            displaySize = CGSize(width: displayWidth, height: displayHeight)
        }
        
        let offsetX = (viewSize.width - displaySize.width) / 2
        let offsetY = (viewSize.height - displaySize.height) / 2
        
        return GridMetrics(displaySize: displaySize, offsetX: offsetX, offsetY: offsetY)
    }
}

// MARK: - Preview

#Preview {
    let viewModel = GenerationSettingsViewModel()
    // Create sample image
    let sampleImage = NSImage(size: NSSize(width: 400, height: 500))
    sampleImage.lockFocus()
    NSColor.systemTeal.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 400, height: 500)).fill()
    sampleImage.unlockFocus()
    
    return GenerationSettingsView(
        viewModel: viewModel,
        sourceImage: sampleImage,
        onGenerate: { _ in },
        onBack: { }
    )
}
