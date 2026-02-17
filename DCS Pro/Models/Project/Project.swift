import Foundation

/// User project containing pattern and state
struct Project: Codable, Identifiable {
    let id: UUID
    var pattern: Pattern
    var sourceImageData: Data?          // Original image data (optional, for reference)
    var settings: GenerationSettings    // Settings used to create pattern
    var createdDate: Date
    var modifiedDate: Date
    
    /// File extension for project files
    static let fileExtension = "dcspro"
    
    /// MIME type for project files
    static let mimeType = "application/x-dcspro"
    
    init(
        id: UUID = UUID(),
        pattern: Pattern,
        sourceImageData: Data? = nil,
        settings: GenerationSettings = .default,
        createdDate: Date = Date(),
        modifiedDate: Date = Date()
    ) {
        self.id = id
        self.pattern = pattern
        self.sourceImageData = sourceImageData
        self.settings = settings
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }
    
    /// Create a new project with an empty pattern
    static func new(width: Int, height: Int, settings: GenerationSettings = .default) -> Project {
        let pattern = Pattern.empty(width: width, height: height)
        return Project(pattern: pattern, settings: settings)
    }
    
    /// Update the modified date
    mutating func touch() {
        modifiedDate = Date()
    }
}

/// Reference to a saved project (for recent files list)
struct ProjectReference: Codable, Identifiable {
    let id: UUID
    let name: String
    let path: URL
    let lastModified: Date
    let previewImageData: Data?
    let colorCount: Int
    let dimensions: String
    
    init(from project: Project, path: URL, previewImageData: Data? = nil) {
        self.id = project.id
        self.name = project.pattern.metadata.name
        self.path = path
        self.lastModified = project.modifiedDate
        self.previewImageData = previewImageData
        self.colorCount = project.pattern.colorCount
        self.dimensions = "\(project.pattern.width) × \(project.pattern.height)"
    }
}
