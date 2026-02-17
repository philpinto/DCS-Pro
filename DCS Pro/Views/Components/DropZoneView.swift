//
//  DropZoneView.swift
//  DCS Pro
//
//  Drag-and-drop zone for image files
//

import SwiftUI
import UniformTypeIdentifiers

/// A view that accepts dropped image files
struct DropZoneView: View {
    let onImageDropped: (NSImage, URL?) -> Void
    
    @State private var isTargeted = false
    
    private let supportedTypes: [UTType] = [.png, .jpeg, .heic, .tiff, .bmp, .gif, .image]
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
            
            Text("Drop an image here")
                .font(.title2)
                .foregroundColor(isTargeted ? .primary : .secondary)
            
            Text("or click to browse")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("PNG, JPEG, HEIC, TIFF")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            openFilePicker()
        }
        .onDrop(of: supportedTypes, isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        // Try to load as file URL first
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }
                
                DispatchQueue.main.async {
                    if let image = NSImage(contentsOf: url) {
                        onImageDropped(image, url)
                    }
                }
            }
            return true
        }
        
        // Try to load as image data
        for type in supportedTypes {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, error in
                    guard let data = data, let image = NSImage(data: data) else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        onImageDropped(image, nil)
                    }
                }
                return true
            }
        }
        
        return false
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = supportedTypes
        panel.message = "Select an image to convert to a cross-stitch pattern"
        panel.prompt = "Choose Image"
        
        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                onImageDropped(image, url)
            }
        }
    }
}

#Preview("Drop Zone") {
    DropZoneView { image, url in
        print("Image dropped: \(image.size), URL: \(url?.path ?? "none")")
    }
    .frame(width: 400, height: 300)
    .padding()
}
