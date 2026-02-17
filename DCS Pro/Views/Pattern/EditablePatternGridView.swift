//
//  EditablePatternGridView.swift
//  DCS Pro
//
//  Interactive pattern grid with click/drag editing support
//

import SwiftUI

/// A view that displays an editable cross-stitch pattern grid
struct EditablePatternGridView: View {
    let pattern: Pattern
    let zoomLevel: Double
    let showGrid: Bool
    let showSymbols: Bool
    let showColors: Bool
    let highlightedThreadId: String?
    let isEditingEnabled: Bool
    let currentTool: EditingTool
    let selectedThread: DMCThread?
    let showProgressOverlay: Bool
    let showOnlyRemaining: Bool
    
    var onStitchClick: ((Int, Int) -> Void)?
    var onStitchDrag: ([(x: Int, y: Int)]) -> Void = { _ in }
    
    init(pattern: Pattern, zoomLevel: Double, showGrid: Bool, showSymbols: Bool, showColors: Bool, highlightedThreadId: String?, isEditingEnabled: Bool, currentTool: EditingTool, selectedThread: DMCThread?, showProgressOverlay: Bool = false, showOnlyRemaining: Bool = false, onStitchClick: ((Int, Int) -> Void)? = nil, onStitchDrag: @escaping ([(x: Int, y: Int)]) -> Void = { _ in }) {
        self.pattern = pattern
        self.zoomLevel = zoomLevel
        self.showGrid = showGrid
        self.showSymbols = showSymbols
        self.showColors = showColors
        self.highlightedThreadId = highlightedThreadId
        self.isEditingEnabled = isEditingEnabled
        self.currentTool = currentTool
        self.selectedThread = selectedThread
        self.showProgressOverlay = showProgressOverlay
        self.showOnlyRemaining = showOnlyRemaining
        self.onStitchClick = onStitchClick
        self.onStitchDrag = onStitchDrag
    }
    
    // Constants
    private let baseCellSize: CGFloat = 20
    
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
    
    // Track drag positions
    @State private var dragPositions: [(x: Int, y: Int)] = []
    @State private var isDragging = false
    @State private var hoverPosition: (x: Int, y: Int)?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                patternCanvas
                    .frame(width: gridWidth, height: gridHeight)
                    .gesture(dragGesture)
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            let x = Int(location.x / cellSize)
                            let y = Int(location.y / cellSize)
                            if x >= 0, x < pattern.width, y >= 0, y < pattern.height {
                                hoverPosition = (x, y)
                            } else {
                                hoverPosition = nil
                            }
                        case .ended:
                            hoverPosition = nil
                        }
                    }
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
                        // Skip completed stitches if showing only remaining
                        if showOnlyRemaining && stitch.isCompleted {
                            context.fill(Path(rect), with: .color(Color.gray.opacity(0.05)))
                            continue
                        }
                        
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
                            var finalColor = isHighlighted ? color : color.opacity(0.3)
                            
                            // Dim completed stitches if progress overlay is enabled
                            if showProgressOverlay && stitch.isCompleted {
                                finalColor = finalColor.opacity(0.35)
                            }
                            
                            context.fill(Path(rect), with: .color(finalColor))
                            
                            // Draw checkmark overlay for completed stitches
                            if showProgressOverlay && stitch.isCompleted && cellSize >= 12 {
                                let checkSize = cellSize * 0.4
                                let checkRect = CGRect(
                                    x: rect.maxX - checkSize - 2,
                                    y: rect.minY + 2,
                                    width: checkSize,
                                    height: checkSize
                                )
                                context.fill(Path(ellipseIn: checkRect), with: .color(Color.green.opacity(0.8)))
                            }
                        } else {
                            // White background when colors are hidden
                            let bgColor = (showProgressOverlay && stitch.isCompleted) ? Color.gray.opacity(0.2) : Color.white
                            context.fill(Path(rect), with: .color(bgColor))
                        }
                        
                        // Draw symbol
                        if showSymbols && cellSize >= 10 {
                            if let symbol = symbolLookup[stitch.thread.id] {
                                drawSymbol(context: context, symbol: symbol, in: rect, thread: stitch.thread, isCompleted: stitch.isCompleted)
                            }
                        }
                    } else {
                        // Empty cell - light gray
                        context.fill(Path(rect), with: .color(Color.gray.opacity(0.1)))
                    }
                }
            }
            
            // Draw hover highlight in edit mode
            if isEditingEnabled, let hover = hoverPosition {
                let hoverRect = CGRect(
                    x: CGFloat(hover.x) * cellSize,
                    y: CGFloat(hover.y) * cellSize,
                    width: cellSize,
                    height: cellSize
                )
                
                // Draw cursor preview based on tool
                switch currentTool {
                case .paint:
                    if let thread = selectedThread {
                        let rgb = thread.rgb
                        let previewColor = Color(
                            red: Double(rgb.r) / 255.0,
                            green: Double(rgb.g) / 255.0,
                            blue: Double(rgb.b) / 255.0
                        ).opacity(0.6)
                        context.fill(Path(hoverRect), with: .color(previewColor))
                    }
                    context.stroke(Path(hoverRect), with: .color(.blue), lineWidth: 2)
                case .fill:
                    context.stroke(Path(hoverRect), with: .color(.green), lineWidth: 2)
                case .eraser:
                    context.fill(Path(hoverRect), with: .color(Color.red.opacity(0.3)))
                    context.stroke(Path(hoverRect), with: .color(.red), lineWidth: 2)
                case .select:
                    context.stroke(Path(hoverRect), with: .color(.gray), lineWidth: 1)
                case .progress:
                    // Show check/uncheck preview based on current state
                    if let stitch = pattern.stitch(at: hover.x, y: hover.y) {
                        if stitch.isCompleted {
                            context.fill(Path(hoverRect), with: .color(Color.orange.opacity(0.3)))
                            context.stroke(Path(hoverRect), with: .color(.orange), lineWidth: 2)
                        } else {
                            context.fill(Path(hoverRect), with: .color(Color.green.opacity(0.3)))
                            context.stroke(Path(hoverRect), with: .color(.green), lineWidth: 2)
                        }
                    }
                }
            }
            
            // Draw grid lines
            if showGrid {
                drawGridLines(context: context, size: size)
            }
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let x = Int(value.location.x / cellSize)
                let y = Int(value.location.y / cellSize)
                
                guard x >= 0, x < pattern.width, y >= 0, y < pattern.height else { return }
                
                if !isDragging {
                    // First touch - single click
                    isDragging = true
                    dragPositions = [(x, y)]
                    onStitchClick?(x, y)
                } else {
                    // Dragging - accumulate positions
                    let lastPos = dragPositions.last
                    if lastPos?.x != x || lastPos?.y != y {
                        dragPositions.append((x, y))
                        // For continuous drag feedback
                        if currentTool == .paint || currentTool == .eraser {
                            onStitchDrag([(x: x, y: y)])
                        }
                    }
                }
            }
            .onEnded { _ in
                isDragging = false
                dragPositions = []
            }
    }
    
    private func drawSymbol(context: GraphicsContext, symbol: String, in rect: CGRect, thread: DMCThread, isCompleted: Bool = false) {
        // Calculate contrasting text color
        let brightness = (Double(thread.rgb.r) * 0.299 + Double(thread.rgb.g) * 0.587 + Double(thread.rgb.b) * 0.114) / 255.0
        var textColor: Color = showColors ? (brightness > 0.5 ? .black : .white) : .black
        
        // Dim text for completed stitches
        if showProgressOverlay && isCompleted {
            textColor = textColor.opacity(0.4)
        }
        
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

#Preview("Editable Grid - Paint Mode") {
    let pattern = createEditableSamplePattern(width: 20, height: 20, colors: 4)
    let selectedThread = pattern.palette.first?.thread
    
    return EditablePatternGridView(
        pattern: pattern,
        zoomLevel: 1.5,
        showGrid: true,
        showSymbols: true,
        showColors: true,
        highlightedThreadId: nil,
        isEditingEnabled: true,
        currentTool: .paint,
        selectedThread: selectedThread,
        onStitchClick: { x, y in
            print("Clicked: \(x), \(y)")
        }
    )
    .frame(width: 500, height: 500)
}

#Preview("Editable Grid - Eraser Mode") {
    let pattern = createEditableSamplePattern(width: 20, height: 20, colors: 4)
    
    return EditablePatternGridView(
        pattern: pattern,
        zoomLevel: 1.5,
        showGrid: true,
        showSymbols: true,
        showColors: true,
        highlightedThreadId: nil,
        isEditingEnabled: true,
        currentTool: .eraser,
        selectedThread: nil
    )
    .frame(width: 500, height: 500)
}

// Helper function for previews
private func createEditableSamplePattern(width: Int, height: Int, colors: Int) -> Pattern {
    let threads = Array(DMCDatabase.shared.threads.prefix(colors))
    let symbols = PatternSymbol.availableSymbols
    
    var palette: [PaletteEntry] = []
    for (index, thread) in threads.enumerated() {
        palette.append(PaletteEntry(
            id: UUID(),
            thread: thread,
            symbol: symbols[index % symbols.count],
            stitchCount: (width * height) / colors
        ))
    }
    
    var stitches: [[Stitch?]] = []
    for y in 0..<height {
        var row: [Stitch?] = []
        for x in 0..<width {
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
