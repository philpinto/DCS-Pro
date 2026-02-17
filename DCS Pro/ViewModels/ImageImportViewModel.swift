//
//  ImageImportViewModel.swift
//  DCS Pro
//
//  View model for image import functionality
//

import SwiftUI
import UniformTypeIdentifiers

/// Observable view model for image import state
@Observable
class ImageImportViewModel {
    // MARK: - Image State
    
    /// The imported image
    var image: NSImage?
    
    /// URL of the imported image (if from file)
    var imageURL: URL?
    
    /// Error message if import failed
    var errorMessage: String?
    
    // MARK: - Computed Properties
    
    /// Whether an image has been imported
    var hasImage: Bool {
        image != nil
    }
    
    /// Image dimensions as string
    var imageDimensionsText: String {
        guard let image = image else { return "" }
        let size = image.size
        return "\(Int(size.width)) × \(Int(size.height)) pixels"
    }
    
    /// Image file name
    var imageFileName: String {
        imageURL?.lastPathComponent ?? "Dropped Image"
    }
    
    /// Image file size as string
    var imageFileSizeText: String {
        guard let url = imageURL,
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return ""
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /// Image format description
    var imageFormatText: String {
        guard let url = imageURL else { return "Image" }
        
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "png": return "PNG Image"
        case "jpg", "jpeg": return "JPEG Image"
        case "heic": return "HEIC Image"
        case "tiff", "tif": return "TIFF Image"
        case "gif": return "GIF Image"
        case "bmp": return "BMP Image"
        default: return "Image"
        }
    }
    
    // MARK: - Actions
    
    /// Import an image
    func importImage(_ image: NSImage, from url: URL?) {
        // Validate image
        guard image.size.width > 0, image.size.height > 0 else {
            errorMessage = "Invalid image: image has no dimensions"
            return
        }
        
        self.image = image
        self.imageURL = url
        self.errorMessage = nil
    }
    
    /// Clear the imported image
    func clearImage() {
        image = nil
        imageURL = nil
        errorMessage = nil
    }
    
    /// Open file picker
    func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff, .bmp, .gif, .image]
        panel.message = "Select an image to convert to a cross-stitch pattern"
        panel.prompt = "Choose Image"
        
        if panel.runModal() == .OK, let url = panel.url {
            if let loadedImage = NSImage(contentsOf: url) {
                importImage(loadedImage, from: url)
            } else {
                errorMessage = "Could not load image from file"
            }
        }
    }
}
