import Foundation

/// Pattern symbol for display on charts
struct PatternSymbol: Codable, Hashable {
    let character: String
    
    init(_ character: String) {
        self.character = character
    }
    
    /// Available symbols for pattern charts, ordered by visual distinctiveness
    static let availableSymbols: [PatternSymbol] = [
        // Primary symbols (high contrast, easily distinguishable)
        PatternSymbol("●"), PatternSymbol("■"), PatternSymbol("▲"), PatternSymbol("◆"),
        PatternSymbol("★"), PatternSymbol("♦"), PatternSymbol("♥"), PatternSymbol("♣"),
        PatternSymbol("♠"), PatternSymbol("○"), PatternSymbol("□"), PatternSymbol("△"),
        PatternSymbol("◇"), PatternSymbol("☆"), PatternSymbol("◐"), PatternSymbol("◑"),
        PatternSymbol("◒"), PatternSymbol("◓"), PatternSymbol("▪"), PatternSymbol("▫"),
        // Secondary symbols
        PatternSymbol("×"), PatternSymbol("+"), PatternSymbol("⊕"), PatternSymbol("⊗"),
        PatternSymbol("⊙"), PatternSymbol("⊚"), PatternSymbol("◉"), PatternSymbol("◎"),
        PatternSymbol("▣"), PatternSymbol("▤"), PatternSymbol("▥"), PatternSymbol("▦"),
        PatternSymbol("▧"), PatternSymbol("▨"), PatternSymbol("▩"), PatternSymbol("⬟"),
        // Tertiary symbols (letters for high color counts)
        PatternSymbol("A"), PatternSymbol("B"), PatternSymbol("C"), PatternSymbol("D"),
        PatternSymbol("E"), PatternSymbol("F"), PatternSymbol("G"), PatternSymbol("H"),
        PatternSymbol("I"), PatternSymbol("J"), PatternSymbol("K"), PatternSymbol("L"),
        PatternSymbol("M"), PatternSymbol("N"), PatternSymbol("O"), PatternSymbol("P"),
        PatternSymbol("Q"), PatternSymbol("R"), PatternSymbol("S"), PatternSymbol("T")
    ]
}
