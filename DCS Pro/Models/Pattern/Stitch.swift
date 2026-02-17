import Foundation

/// A single stitch in the pattern
struct Stitch: Codable, Equatable {
    let thread: DMCThread
    var type: StitchType
    var isCompleted: Bool
    
    init(thread: DMCThread, type: StitchType = .full, isCompleted: Bool = false) {
        self.thread = thread
        self.type = type
        self.isCompleted = isCompleted
    }
}
