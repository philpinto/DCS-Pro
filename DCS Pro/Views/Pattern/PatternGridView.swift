//
//  PatternGridView.swift
//  DCS Pro
//
//  Zoomable, pannable grid view for displaying cross-stitch patterns
//

import SwiftUI

/// A view that displays a cross-stitch pattern as a grid of colored cells with symbols
struct PatternGridView: View {
    let pattern: Pattern
    let zoomLevel: Double
    let showGrid: Bool
    let showSymbols: Bool
    let showColors: Bool
    let highlightedThreadId: String?
    
    @Binding var panOffset: CGPoint
    
    // Constants
    private let baseCellSize: CGFloat = 20
    private let minZoom: CGFloat = 0.25
    private let maxZoom: CGFloat = 4.0
    
    private var cellSize: CGFloat {
        baseCellSize * CGFloat(zoomLevel)
    }
    
    private var gridWidth: CGFloat {
        CGFloat(pattern.width) * cellSize
    }
    
    private var gridHeight: CGFloat {
        CGFloat(pattern.height) * cellSize
    }
    
    // Build a lookup from thread ID to symbol for efficient rendering
    private var symbolLookup: [String: String] {
        var lookup: [String: String] = [:]
        for entry in pattern.palette {
            lookup[entry.thread.id] = entry.symbol.character
        }
        return lookup
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                patternCanvas
                    .frame(width: gridWidth, height: gridHeight)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
    
    @ViewBuilder
    private var patternCanvas: some View {
        Canvas { context, size in
            // Draw cells
            for y in 0..<pattern.height {
                for x in 0..<pattern.width {
                    let rect = CGRect(
                        x: CGFloat(x) * cellSize,
                        y: CGFloat(y) * cellSize,
                        width: cellSize,
                        height: cellSize
                    )
                    
                    if let stitch = pattern.stitch(at: x, y: y) {
                        // Draw cell background color
                        if showColors {
                            let rgb = stitch.thread.rgb
                            let color = Color(
                                red: Double(rgb.r) / 255.0,
                                green: Double(rgb.g) / 255.0,
                                blue: Double(rgb.b) / 255.0
                            )
                            
                            // Dim if not highlighted (when a color is selected)
                            let isHighlighted = highlightedThreadId == nil || highlightedThreadId == stitch.thread.id
                            let finalColor = isHighlighted ? color : color.opacity(0.3)
                            
                            context.fill(Path(rect), with: .color(finalColor))
                        } else {
                            // White background when colors are hidden
                            context.fill(Path(rect), with: .color(.white))
                        }
                        
                        // Draw symbol
                        if showSymbols && cellSize >= 10 {
                            if let symbol = symbolLookup[stitch.thread.id] {
                                drawSymbol(context: context, symbol: symbol, in: rect, thread: stitch.thread)
                            }
                        }
                    } else {
                        // Empty cell - light gray
                        context.fill(Path(rect), with: .color(Color.gray.opacity(0.1)))
                    }
                }
            }
            
            // Draw grid lines
            if showGrid {
                drawGridLines(context: context, size: size)
            }
        }
    }
    
    private func drawSymbol(context: GraphicsContext, symbol: String, in rect: CGRect, thread: DMCThread) {
        // Calculate contrasting text color
        let brightness = (Double(thread.rgb.r) * 0.299 + Double(thread.rgb.g) * 0.587 + Double(thread.rgb.b) * 0.114) / 255.0
        let textColor: Color = showColors ? (brightness > 0.5 ? .black : .white) : .black
        
        // Font size scales with cell size
        let fontSize = max(8, cellSize * 0.6)
        
        let text = Text(symbol)
            .font(.system(size: fontSize, weight: .medium, design: .monospaced))
            .foregroundColor(textColor)
        
        // Center the text in the cell
        let textPoint = CGPoint(
            x: rect.midX,
            y: rect.midY
        )
        
        context.draw(text, at: textPoint, anchor: .center)
    }
    
    private func drawGridLines(context: GraphicsContext, size: CGSize) {
        // Regular grid lines (light)
        let lightLineColor = Color.gray.opacity(0.3)
        let lightLineWidth: CGFloat = 0.5
        
        // Bold grid lines every 10 stitches (standard cross-stitch convention)
        let boldLineColor = Color.gray.opacity(0.7)
        let boldLineWidth: CGFloat = 1.5
        
        // Vertical lines
        for x in 0...pattern.width {
            let xPos = CGFloat(x) * cellSize
            let isBold = x % 10 == 0
            
            var path = Path()
            path.move(to: CGPoint(x: xPos, y: 0))
            path.addLine(to: CGPoint(x: xPos, y: gridHeight))
            
            context.stroke(
                path,
                with: .color(isBold ? boldLineColor : lightLineColor),
                lineWidth: isBold ? boldLineWidth : lightLineWidth
            )
        }
        
        // Horizontal lines
        for y in 0...pattern.height {
            let yPos = CGFloat(y) * cellSize
            let isBold = y % 10 == 0
            
            var path = Path()
            path.move(to: CGPoint(x: 0, y: yPos))
            path.addLine(to: CGPoint(x: gridWidth, y: yPos))
            
            context.stroke(
                path,
                with: .color(isBold ? boldLineColor : lightLineColor),
                lineWidth: isBold ? boldLineWidth : lightLineWidth
            )
        }
    }
}

// MARK: - Preview

#Preview("Pattern Grid - Small") {
    let pattern = createSamplePattern(width: 20, height: 20, colors: 4)
    
    return PatternGridView(
        pattern: pattern,
        zoomLevel: 1.0,
        showGrid: true,
        showSymbols: true,
        showColors: true,
        highlightedThreadId: nil,
        panOffset: .constant(.zero)
    )
    .frame(width: 500, height: 500)
}

#Preview("Pattern Grid - Zoomed Out") {
    let pattern = createSamplePattern(width: 50, height: 50, colors: 8)
    
    return PatternGridView(
        pattern: pattern,
        zoomLevel: 0.5,
        showGrid: true,
        showSymbols: true,
        showColors: true,
        highlightedThreadId: nil,
        panOffset: .constant(.zero)
    )
    .frame(width: 600, height: 600)
}

#Preview("Pattern Grid - No Colors") {
    let pattern = createSamplePattern(width: 20, height: 20, colors: 4)
    
    return PatternGridView(
        pattern: pattern,
        zoomLevel: 1.5,
        showGrid: true,
        showSymbols: true,
        showColors: false,
        highlightedThreadId: nil,
        panOffset: .constant(.zero)
    )
    .frame(width: 500, height: 500)
}

// Helper function to create sample patterns for previews
private func createSamplePattern(width: Int, height: Int, colors: Int) -> Pattern {
    let threads = Array(DMCDatabase.shared.threads.prefix(colors))
    let symbols = PatternSymbol.availableSymbols
    
    // Create palette entries
    var palette: [PaletteEntry] = []
    for (index, thread) in threads.enumerated() {
        palette.append(PaletteEntry(
            id: UUID(),
            thread: thread,
            symbol: symbols[index % symbols.count],
            stitchCount: (width * height) / colors
        ))
    }
    
    // Create stitches grid with alternating colors in a pattern
    var stitches: [[Stitch?]] = []
    for y in 0..<height {
        var row: [Stitch?] = []
        for x in 0..<width {
            // Create a simple pattern based on position
            let colorIndex = ((x / 5) + (y / 5)) % colors
            row.append(Stitch(thread: threads[colorIndex]))
        }
        stitches.append(row)
    }
    
    return Pattern(
        width: width,
        height: height,
        stitches: stitches,
        palette: palette,
        metadata: PatternMetadata(name: "Sample Pattern")
    )
}
