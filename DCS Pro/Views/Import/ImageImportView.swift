//
//  ImageImportView.swift
//  DCS Pro
//
//  Created for Delaney's Cross Stitch Pro
//

import SwiftUI

/// Main view for importing images to convert to cross-stitch patterns
struct ImageImportView: View {
    var viewModel: ImageImportViewModel
    let onContinue: (NSImage, URL?) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Main content
            if let image = viewModel.image {
                // Show imported image preview
                imagePreviewContent(image)
            } else {
                // Show drop zone
                dropZoneContent
            }
            
            Divider()
            
            // Footer with action buttons
            footer
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Import Image")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Select a photo to convert into a cross-stitch pattern")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if viewModel.image != nil {
                Button("Change Image") {
                    viewModel.clearImage()
                }
            }
        }
        .padding()
    }
    
    // MARK: - Drop Zone Content
    
    private var dropZoneContent: some View {
        DropZoneView { image, url in
            viewModel.importImage(image, from: url)
        }
        .padding()
    }
    
    // MARK: - Image Preview Content
    
    private func imagePreviewContent(_ image: NSImage) -> some View {
        HSplitView {
            // Image preview
            imagePreview(image)
                .frame(minWidth: 300)
            
            // Image info sidebar
            imageInfoSidebar
                .frame(width: 200)
        }
        .padding()
    }
    
    private func imagePreview(_ image: NSImage) -> some View {
        VStack {
            // Image with aspect fit
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    // Checkerboard pattern for transparency
                    CheckerboardPattern()
                        .foregroundStyle(Color(white: 0.9))
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var imageInfoSidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            // File info section
            if viewModel.imageURL != nil {
                infoSection(title: "File") {
                    infoRow(label: "Name", value: viewModel.imageFileName)
                    infoRow(label: "Size", value: viewModel.imageFileSizeText)
                    infoRow(label: "Format", value: viewModel.imageFormatText)
                }
            }
            
            // Image dimensions section
            if let image = viewModel.image {
                infoSection(title: "Dimensions") {
                    infoRow(label: "Width", value: "\(Int(image.size.width)) px")
                    infoRow(label: "Height", value: "\(Int(image.size.height)) px")
                    let aspect = image.size.width / image.size.height
                    infoRow(label: "Aspect", value: String(format: "%.2f", aspect))
                }
            }
            
            Spacer()
            
            // Tips
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tips", systemImage: "lightbulb")
                        .font(.headline)
                    
                    Text("• High contrast photos work best")
                    Text("• Crop to focus on the subject")
                    Text("• Portraits should fill the frame")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 8)
    }
    
    private func infoSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            content()
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            // Error message if any
            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            Spacer()
            
            // Cancel button
            Button("Cancel") {
                onCancel()
            }
            .keyboardShortcut(.cancelAction)
            
            // Continue button
            Button("Continue") {
                if let image = viewModel.image {
                    onContinue(image, viewModel.imageURL)
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(viewModel.image == nil)
        }
        .padding()
    }
}

// MARK: - Checkerboard Pattern

/// A checkerboard pattern for showing transparency in images
struct CheckerboardPattern: View {
    let size: CGFloat = 10
    
    var body: some View {
        Canvas { context, canvasSize in
            let rows = Int(canvasSize.height / size) + 1
            let cols = Int(canvasSize.width / size) + 1
            
            for row in 0..<rows {
                for col in 0..<cols {
                    if (row + col) % 2 == 0 {
                        let rect = CGRect(
                            x: CGFloat(col) * size,
                            y: CGFloat(row) * size,
                            width: size,
                            height: size
                        )
                        context.fill(Path(rect), with: .foreground)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Empty State") {
    ImageImportView(
        viewModel: ImageImportViewModel(),
        onContinue: { _, _ in },
        onCancel: { }
    )
}

#Preview("With Image") {
    let viewModel = ImageImportViewModel()
    // Create a sample image for preview
    let sampleImage = NSImage(size: NSSize(width: 400, height: 300))
    sampleImage.lockFocus()
    NSColor.systemBlue.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 400, height: 300)).fill()
    NSColor.white.setFill()
    NSBezierPath(ovalIn: NSRect(x: 100, y: 50, width: 200, height: 200)).fill()
    sampleImage.unlockFocus()
    viewModel.importImage(sampleImage, from: URL(fileURLWithPath: "/test/sample.png"))
    
    return ImageImportView(
        viewModel: viewModel,
        onContinue: { _, _ in },
        onCancel: { }
    )
}
