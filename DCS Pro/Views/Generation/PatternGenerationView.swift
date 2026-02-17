//
//  PatternGenerationView.swift
//  DCS Pro
//
//  Created for Delaney's Cross Stitch Pro
//

import SwiftUI

/// View showing pattern generation progress
struct PatternGenerationView: View {
    var viewModel: PatternGenerationViewModel
    let sourceImage: NSImage
    let settings: GenerationSettings
    let onComplete: (Pattern) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Main content
            mainContent
            
            Divider()
            
            // Footer
            footer
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .task {
            await viewModel.generate(from: sourceImage, with: settings)
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase == .complete, let pattern = viewModel.generatedPattern {
                // Small delay to show completion state
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    onComplete(pattern)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Generating Pattern")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(settings.targetWidth)×\(settings.targetHeight) stitches • \(settings.maxColors) colors max")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Image preview with processing overlay
            imagePreview
            
            // Progress section
            progressSection
            
            // Phase indicators
            phaseIndicators
            
            Spacer()
        }
        .padding()
    }
    
    private var imagePreview: some View {
        ZStack {
            Image(nsImage: sourceImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200, maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            
            // Processing overlay
            if viewModel.isGenerating {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .frame(maxWidth: 200, maxHeight: 200)
                
                ProgressView()
                    .scaleEffect(1.5)
            }
            
            // Success overlay
            if viewModel.phase == .complete {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.2))
                    .frame(maxWidth: 200, maxHeight: 200)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
            }
            
            // Error overlay
            if viewModel.phase == .failed {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.2))
                    .frame(maxWidth: 200, maxHeight: 200)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
            }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            // Overall progress bar
            ProgressView(value: viewModel.overallProgress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 300)
            
            // Status message
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Percentage
            Text("\(Int(viewModel.overallProgress * 100))%")
                .font(.title)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
    
    private var phaseIndicators: some View {
        HStack(spacing: 16) {
            phaseIndicator(for: .resizing)
            phaseConnector(after: .resizing)
            phaseIndicator(for: .quantizing)
            phaseConnector(after: .quantizing)
            phaseIndicator(for: .matching)
            phaseConnector(after: .matching)
            phaseIndicator(for: .building)
        }
        .padding(.top, 8)
    }
    
    private func phaseIndicator(for phase: PatternGenerationViewModel.GenerationPhase) -> some View {
        let isActive = viewModel.phase == phase
        let isComplete = phaseOrder(viewModel.phase) > phaseOrder(phase)
        let isFailed = viewModel.phase == .failed
        
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isComplete ? Color.green : (isActive ? Color.accentColor : Color.secondary.opacity(0.3)))
                    .frame(width: 32, height: 32)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                } else if isActive && !isFailed {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: phase.icon)
                        .font(.caption)
                        .foregroundStyle(isActive ? .white : .secondary)
                }
            }
            
            Text(phase.rawValue)
                .font(.caption2)
                .foregroundStyle(isActive || isComplete ? .primary : .secondary)
        }
    }
    
    private func phaseConnector(after phase: PatternGenerationViewModel.GenerationPhase) -> some View {
        let isComplete = phaseOrder(viewModel.phase) > phaseOrder(phase)
        
        return Rectangle()
            .fill(isComplete ? Color.green : Color.secondary.opacity(0.3))
            .frame(width: 20, height: 2)
    }
    
    private func phaseOrder(_ phase: PatternGenerationViewModel.GenerationPhase) -> Int {
        switch phase {
        case .idle: return 0
        case .resizing: return 1
        case .quantizing: return 2
        case .matching: return 3
        case .building: return 4
        case .complete: return 5
        case .failed: return -1
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            // Error message
            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if viewModel.phase == .failed {
                Button("Try Again") {
                    viewModel.reset()
                    Task {
                        await viewModel.generate(from: sourceImage, with: settings)
                    }
                }
            }
            
            Button("Cancel") {
                viewModel.cancel()
                onCancel()
            }
            .keyboardShortcut(.cancelAction)
            .disabled(viewModel.phase == .complete)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("Generating") {
    let viewModel = PatternGenerationViewModel()
    
    // Create sample image
    let sampleImage = NSImage(size: NSSize(width: 400, height: 500))
    sampleImage.lockFocus()
    NSColor.systemBlue.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 400, height: 500)).fill()
    sampleImage.unlockFocus()
    
    return PatternGenerationView(
        viewModel: viewModel,
        sourceImage: sampleImage,
        settings: .default,
        onComplete: { _ in },
        onCancel: { }
    )
}
