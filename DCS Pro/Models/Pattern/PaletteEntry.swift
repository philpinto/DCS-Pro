import Foundation

/// Color entry in the pattern palette
struct PaletteEntry: Codable, Identifiable {
    let id: UUID
    let thread: DMCThread
    let symbol: PatternSymbol
    var stitchCount: Int
    
    init(id: UUID = UUID(), thread: DMCThread, symbol: PatternSymbol, stitchCount: Int = 0) {
        self.id = id
        self.thread = thread
        self.symbol = symbol
        self.stitchCount = stitchCount
    }
    
    /// Percentage of total pattern this color represents
    func percentage(ofTotal total: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(stitchCount) / Double(total) * 100.0
    }
}
