//
//  ProjectService.swift
//  DCS Pro
//
//  Service for saving and loading project files
//

import AppKit
import Foundation
import UniformTypeIdentifiers

/// Service for managing project file operations
/// Uses a folder-based archive format (the folder is the .dcspro file)
class ProjectService {
    
    // MARK: - Types
    
    /// Manifest containing file format metadata
    struct Manifest: Codable {
        let formatVersion: String
        let appVersion: String
        let createdDate: Date
        let modifiedDate: Date
        
        static let currentFormatVersion = "1.0"
        
        init(createdDate: Date = Date(), modifiedDate: Date = Date()) {
            self.formatVersion = Self.currentFormatVersion
            self.appVersion = Bundle.main.appVersion
            self.createdDate = createdDate
            self.modifiedDate = modifiedDate
        }
    }
    
    /// File names within the package
    private enum PackageFile {
        static let manifest = "manifest.json"
        static let pattern = "pattern.json"
        static let settings = "settings.json"
        static let sourceImage = "source_image.png"
        static let thumbnail = "thumbnail.png"
    }
    
    // MARK: - Singleton
    
    static let shared = ProjectService()
    
    private init() {}
    
    // MARK: - Save
    
    /// Save a project to a file (as a package/bundle)
    /// - Parameters:
    ///   - project: The project to save
    ///   - url: The destination URL
    /// - Throws: ProjectError if save fails
    func save(project: Project, to url: URL) throws {
        let fileManager = FileManager.default
        
        // Remove existing file/folder if present
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        
        // Create the package directory
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        // Write manifest
        let manifest = Manifest(
            createdDate: project.createdDate,
            modifiedDate: project.modifiedDate
        )
        let manifestData = try encoder.encode(manifest)
        try manifestData.write(to: url.appendingPathComponent(PackageFile.manifest))
        
        // Write pattern
        let patternData = try encoder.encode(project.pattern)
        try patternData.write(to: url.appendingPathComponent(PackageFile.pattern))
        
        // Write settings
        let settingsData = try encoder.encode(project.settings)
        try settingsData.write(to: url.appendingPathComponent(PackageFile.settings))
        
        // Write source image if present
        if let sourceImageData = project.sourceImageData {
            try sourceImageData.write(to: url.appendingPathComponent(PackageFile.sourceImage))
        }
        
        // Generate and write thumbnail
        if let thumbnailData = generateThumbnail(for: project.pattern) {
            try thumbnailData.write(to: url.appendingPathComponent(PackageFile.thumbnail))
        }
    }
    
    /// Show save dialog and save project
    /// - Parameter project: The project to save
    /// - Returns: The URL where the file was saved, or nil if cancelled
    @MainActor
    func saveWithDialog(project: Project) throws -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: Project.fileExtension) ?? .data]
        savePanel.nameFieldStringValue = "\(project.pattern.metadata.name).\(Project.fileExtension)"
        savePanel.title = "Save Project"
        savePanel.message = "Choose where to save your cross-stitch project"
        
        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            return nil
        }
        
        try save(project: project, to: url)
        return url
    }
    
    // MARK: - Load
    
    /// Load a project from a file
    /// - Parameter url: The URL to load from
    /// - Returns: The loaded project
    /// - Throws: ProjectError if load fails
    func load(from url: URL) throws -> Project {
        let fileManager = FileManager.default
        
        // Check if it's a directory (package)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw ProjectError.invalidFormat
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Read manifest
        let manifestURL = url.appendingPathComponent(PackageFile.manifest)
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            throw ProjectError.missingManifest
        }
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try decoder.decode(Manifest.self, from: manifestData)
        
        // Check version compatibility
        if !isVersionCompatible(manifest.formatVersion) {
            throw ProjectError.incompatibleVersion(manifest.formatVersion)
        }
        
        // Read pattern
        let patternURL = url.appendingPathComponent(PackageFile.pattern)
        guard fileManager.fileExists(atPath: patternURL.path) else {
            throw ProjectError.missingPattern
        }
        let patternData = try Data(contentsOf: patternURL)
        let pattern = try decoder.decode(Pattern.self, from: patternData)
        
        // Read settings
        let settingsURL = url.appendingPathComponent(PackageFile.settings)
        guard fileManager.fileExists(atPath: settingsURL.path) else {
            throw ProjectError.missingSettings
        }
        let settingsData = try Data(contentsOf: settingsURL)
        let settings = try decoder.decode(GenerationSettings.self, from: settingsData)
        
        // Read source image (optional)
        var sourceImageData: Data?
        let sourceImageURL = url.appendingPathComponent(PackageFile.sourceImage)
        if fileManager.fileExists(atPath: sourceImageURL.path) {
            sourceImageData = try Data(contentsOf: sourceImageURL)
        }
        
        return Project(
            pattern: pattern,
            sourceImageData: sourceImageData,
            settings: settings,
            createdDate: manifest.createdDate,
            modifiedDate: manifest.modifiedDate
        )
    }
    
    /// Show open dialog and load project
    /// - Returns: The loaded project and its URL, or nil if cancelled
    @MainActor
    func loadWithDialog() throws -> (project: Project, url: URL)? {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType(filenameExtension: Project.fileExtension) ?? .data]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true  // Package is a directory
        openPanel.canChooseFiles = true
        openPanel.title = "Open Project"
        openPanel.message = "Select a cross-stitch project to open"
        
        guard openPanel.runModal() == .OK, let url = openPanel.url else {
            return nil
        }
        
        let project = try load(from: url)
        return (project, url)
    }
    
    // MARK: - Thumbnail Generation
    
    /// Generate a thumbnail image for a pattern
    /// - Parameter pattern: The pattern to thumbnail
    /// - Returns: PNG data for the thumbnail, or nil if generation fails
    func generateThumbnail(for pattern: Pattern, size: CGSize = CGSize(width: 200, height: 200)) -> Data? {
        // Build color lookup
        var colorLookup: [String: NSColor] = [:]
        for entry in pattern.palette {
            colorLookup[entry.thread.id] = NSColor(
                red: CGFloat(entry.thread.rgb.r) / 255.0,
                green: CGFloat(entry.thread.rgb.g) / 255.0,
                blue: CGFloat(entry.thread.rgb.b) / 255.0,
                alpha: 1.0
            )
        }
        
        // Calculate dimensions maintaining aspect ratio
        let patternAspect = CGFloat(pattern.width) / CGFloat(pattern.height)
        let thumbnailAspect = size.width / size.height
        
        let drawSize: CGSize
        if patternAspect > thumbnailAspect {
            drawSize = CGSize(width: size.width, height: size.width / patternAspect)
        } else {
            drawSize = CGSize(width: size.height * patternAspect, height: size.height)
        }
        
        let offsetX = (size.width - drawSize.width) / 2
        let offsetY = (size.height - drawSize.height) / 2
        
        // Create image
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Fill background
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        // Draw pattern
        let cellWidth = drawSize.width / CGFloat(pattern.width)
        let cellHeight = drawSize.height / CGFloat(pattern.height)
        
        for row in 0..<pattern.height {
            for col in 0..<pattern.width {
                if let stitch = pattern.stitches[row][col],
                   let color = colorLookup[stitch.thread.id] {
                    let rect = NSRect(
                        x: offsetX + CGFloat(col) * cellWidth,
                        y: offsetY + CGFloat(pattern.height - row - 1) * cellHeight,
                        width: cellWidth,
                        height: cellHeight
                    )
                    color.setFill()
                    rect.fill()
                }
            }
        }
        
        image.unlockFocus()
        
        // Convert to PNG data
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        return pngData
    }
    
    /// Extract thumbnail from a project file without loading the full project
    /// - Parameter url: The project file URL
    /// - Returns: The thumbnail image data, or nil if not found
    func extractThumbnail(from url: URL) -> Data? {
        let thumbnailURL = url.appendingPathComponent(PackageFile.thumbnail)
        return try? Data(contentsOf: thumbnailURL)
    }
    
    // MARK: - Version Compatibility
    
    private func isVersionCompatible(_ version: String) -> Bool {
        // For now, we only support version 1.0
        return version == "1.0"
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
