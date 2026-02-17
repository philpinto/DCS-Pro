import Foundation

/// The complete cross-stitch pattern
struct Pattern: Codable, Identifiable {
    let id: UUID
    let width: Int                      // Stitch count horizontal
    let height: Int                     // Stitch count vertical
    var stitches: [[Stitch?]]           // 2D grid, nil = no stitch
    var palette: [PaletteEntry]         // Colors used with symbols
    var metadata: PatternMetadata
    
    // MARK: - Initialization
    
    init(id: UUID = UUID(), width: Int, height: Int, stitches: [[Stitch?]], palette: [PaletteEntry], metadata: PatternMetadata = PatternMetadata()) {
        self.id = id
        self.width = width
        self.height = height
        self.stitches = stitches
        self.palette = palette
        self.metadata = metadata
    }
    
    /// Create an empty pattern with given dimensions
    static func empty(width: Int, height: Int) -> Pattern {
        let emptyRow: [Stitch?] = Array(repeating: nil, count: width)
        let stitches = Array(repeating: emptyRow, count: height)
        return Pattern(width: width, height: height, stitches: stitches, palette: [])
    }
    
    // MARK: - Computed Properties
    
    /// Total number of stitches (non-nil cells)
    var totalStitchCount: Int {
        stitches.reduce(0) { rowSum, row in
            rowSum + row.reduce(0) { $0 + ($1 != nil ? 1 : 0) }
        }
    }
    
    /// Number of colors in the palette
    var colorCount: Int {
        palette.count
    }
    
    /// Number of completed stitches
    var completedStitchCount: Int {
        stitches.reduce(0) { rowSum, row in
            rowSum + row.reduce(0) { $0 + (($1?.isCompleted ?? false) ? 1 : 0) }
        }
    }
    
    /// Progress percentage (0-100)
    var progressPercentage: Double {
        let total = totalStitchCount
        guard total > 0 else { return 0 }
        return Double(completedStitchCount) / Double(total) * 100.0
    }
    
    // MARK: - Methods
    
    /// Calculate finished size for a given fabric count
    func finishedSize(fabricCount: Int) -> (widthInches: Double, heightInches: Double) {
        let widthInches = Double(width) / Double(fabricCount)
        let heightInches = Double(height) / Double(fabricCount)
        return (widthInches, heightInches)
    }
    
    /// Get stitch at position (returns nil if out of bounds or empty)
    func stitch(at x: Int, y: Int) -> Stitch? {
        guard x >= 0, x < width, y >= 0, y < height else { return nil }
        return stitches[y][x]
    }
    
    /// Set stitch at position
    mutating func setStitch(_ stitch: Stitch?, at x: Int, y: Int) {
        guard x >= 0, x < width, y >= 0, y < height else { return }
        stitches[y][x] = stitch
    }
    
    /// Mark stitch as completed
    mutating func markCompleted(at x: Int, y: Int, completed: Bool) {
        guard x >= 0, x < width, y >= 0, y < height else { return }
        stitches[y][x]?.isCompleted = completed
    }
    
    /// Get all positions for a specific thread color
    func positions(for thread: DMCThread) -> [(x: Int, y: Int)] {
        var result: [(x: Int, y: Int)] = []
        for y in 0..<height {
            for x in 0..<width {
                if let stitch = stitches[y][x], stitch.thread.id == thread.id {
                    result.append((x, y))
                }
            }
        }
        return result
    }
}
