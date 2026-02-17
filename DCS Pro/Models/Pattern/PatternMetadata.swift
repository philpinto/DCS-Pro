import Foundation

/// Metadata about the pattern
struct PatternMetadata: Codable {
    var name: String
    var author: String
    var createdDate: Date
    var modifiedDate: Date
    var notes: String
    var sourceImageName: String?
    
    init(name: String = "Untitled Pattern", author: String = "", notes: String = "") {
        self.name = name
        self.author = author
        self.notes = notes
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.sourceImageName = nil
    }
}
