//
//  RecentProjectsManager.swift
//  DCS Pro
//
//  Manages the list of recently opened projects
//

import AppKit
import Foundation

/// Manages the list of recently opened projects
@Observable
class RecentProjectsManager {
    
    // MARK: - Constants
    
    private let maxRecentProjects = 10
    private let userDefaultsKey = "recentProjects"
    
    // MARK: - Properties
    
    /// List of recent project references
    private(set) var recentProjects: [ProjectReference] = []
    
    // MARK: - Singleton
    
    static let shared = RecentProjectsManager()
    
    private init() {
        loadRecentProjects()
    }
    
    // MARK: - Public Methods
    
    /// Add a project to the recent list
    /// - Parameters:
    ///   - project: The project that was opened/saved
    ///   - url: The file URL of the project
    func addRecentProject(_ project: Project, at url: URL) {
        // Generate thumbnail
        let thumbnailData = ProjectService.shared.generateThumbnail(for: project.pattern)
        
        // Create reference
        let reference = ProjectReference(
            from: project,
            path: url,
            previewImageData: thumbnailData
        )
        
        // Remove existing entry for this path if present
        recentProjects.removeAll { $0.path == url }
        
        // Add to front
        recentProjects.insert(reference, at: 0)
        
        // Trim to max size
        if recentProjects.count > maxRecentProjects {
            recentProjects = Array(recentProjects.prefix(maxRecentProjects))
        }
        
        // Persist
        saveRecentProjects()
    }
    
    /// Remove a project from the recent list
    /// - Parameter url: The URL to remove
    func removeRecentProject(at url: URL) {
        recentProjects.removeAll { $0.path == url }
        saveRecentProjects()
    }
    
    /// Remove a project reference by ID
    /// - Parameter id: The project reference ID
    func removeRecentProject(id: UUID) {
        recentProjects.removeAll { $0.id == id }
        saveRecentProjects()
    }
    
    /// Clear all recent projects
    func clearRecentProjects() {
        recentProjects.removeAll()
        saveRecentProjects()
    }
    
    /// Check if a recent project file still exists
    /// - Parameter reference: The project reference to check
    /// - Returns: True if the file exists
    func projectExists(_ reference: ProjectReference) -> Bool {
        FileManager.default.fileExists(atPath: reference.path.path)
    }
    
    /// Remove references to projects that no longer exist
    func pruneInvalidReferences() {
        let validProjects = recentProjects.filter { projectExists($0) }
        if validProjects.count != recentProjects.count {
            recentProjects = validProjects
            saveRecentProjects()
        }
    }
    
    /// Get thumbnail image for a recent project
    /// - Parameter reference: The project reference
    /// - Returns: The thumbnail image, or nil if not available
    func thumbnail(for reference: ProjectReference) -> NSImage? {
        // First try cached data
        if let data = reference.previewImageData,
           let image = NSImage(data: data) {
            return image
        }
        
        // Try to extract from file
        if let data = ProjectService.shared.extractThumbnail(from: reference.path),
           let image = NSImage(data: data) {
            return image
        }
        
        return nil
    }
    
    // MARK: - Persistence
    
    private func loadRecentProjects() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }
        
        let decoder = JSONDecoder()
        do {
            recentProjects = try decoder.decode([ProjectReference].self, from: data)
        } catch {
            print("Failed to load recent projects: \(error)")
            recentProjects = []
        }
    }
    
    private func saveRecentProjects() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(recentProjects)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save recent projects: \(error)")
        }
    }
}

// MARK: - ProjectReference URL Coding

extension ProjectReference {
    enum CodingKeys: String, CodingKey {
        case id, name, path, lastModified, previewImageData, colorCount, dimensions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Decode URL from string for better compatibility
        let pathString = try container.decode(String.self, forKey: .path)
        path = URL(fileURLWithPath: pathString)
        
        lastModified = try container.decode(Date.self, forKey: .lastModified)
        previewImageData = try container.decodeIfPresent(Data.self, forKey: .previewImageData)
        colorCount = try container.decode(Int.self, forKey: .colorCount)
        dimensions = try container.decode(String.self, forKey: .dimensions)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        // Encode URL as string for better compatibility
        try container.encode(path.path, forKey: .path)
        
        try container.encode(lastModified, forKey: .lastModified)
        try container.encodeIfPresent(previewImageData, forKey: .previewImageData)
        try container.encode(colorCount, forKey: .colorCount)
        try container.encode(dimensions, forKey: .dimensions)
    }
}
