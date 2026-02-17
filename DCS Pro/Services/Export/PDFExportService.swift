//
//  PDFExportService.swift
//  DCS Pro
//
//  Service for exporting patterns to PDF format
//

import AppKit
import PDFKit

/// Service for generating professional cross-stitch pattern PDFs
class PDFExportService {
    
    // MARK: - Types
    
    /// Export settings for PDF generation
    struct ExportSettings {
        var pageSize: PageSize = .letter
        var includePreview: Bool = true
        var includeThreadList: Bool = true
        var includeLegend: Bool = true
        var stitchesPerPage: Int = 50
        var symbolFontSize: CGFloat = 10
        var showGridNumbers: Bool = true
        var patternTitle: String = "Cross-Stitch Pattern"
        var chartStyle: ChartStyle = .color
        
        /// Chart rendering style
        enum ChartStyle: String, CaseIterable, Identifiable {
            case color = "Color"
            case symbolOnly = "Symbol Only"
            case traditional = "Traditional"
            
            var id: String { rawValue }
            
            var description: String {
                switch self {
                case .color: return "Colored squares with symbols"
                case .symbolOnly: return "Black & white symbols, same layout"
                case .traditional: return "Professional style with sidebar legend"
                }
            }
        }
        
        enum PageSize: String, CaseIterable, Identifiable {
            case letter = "US Letter"
            case a4 = "A4"
            case legal = "US Legal"
            
            var id: String { rawValue }
            
            var size: CGSize {
                switch self {
                case .letter: return CGSize(width: 612, height: 792)  // 8.5 x 11 inches at 72 dpi
                case .a4: return CGSize(width: 595, height: 842)       // 210 x 297 mm
                case .legal: return CGSize(width: 612, height: 1008)   // 8.5 x 14 inches
                }
            }
            
            var printableArea: CGRect {
                let margin: CGFloat = 36 // 0.5 inch margins
                let s = size
                return CGRect(x: margin, y: margin, width: s.width - margin * 2, height: s.height - margin * 2)
            }
        }
    }
    
    /// Progress callback for export operations
    typealias ProgressCallback = (Double, String) -> Void
    
    // MARK: - Properties
    
    private let dmcDatabase = DMCDatabase.shared
    
    /// Scale factor for high-resolution PDF rendering (2x for Retina-quality)
    private let renderScale: CGFloat = 2.0
    
    // MARK: - Public Methods
    
    /// Export a pattern to PDF data
    /// - Parameters:
    ///   - pattern: The pattern to export
    ///   - settings: Export settings
    ///   - progress: Optional progress callback
    /// - Returns: PDF data, or nil if export failed
    func exportPDF(
        pattern: Pattern,
        settings: ExportSettings = ExportSettings(),
        progress: ProgressCallback? = nil
    ) -> Data? {
        let pdfDocument = PDFDocument()
        var pageIndex = 0
        
        progress?(0.1, "Creating cover page...")
        
        // Add cover page
        if settings.includePreview {
            if let coverPage = createCoverPage(pattern: pattern, settings: settings) {
                pdfDocument.insert(coverPage, at: pageIndex)
                pageIndex += 1
            }
        }
        
        progress?(0.2, "Creating thread list...")
        
        // Add thread list page
        if settings.includeThreadList {
            let threadPages = createThreadListPages(pattern: pattern, settings: settings)
            for page in threadPages {
                pdfDocument.insert(page, at: pageIndex)
                pageIndex += 1
            }
        }
        
        progress?(0.3, "Creating color legend...")
        
        // Add legend page
        if settings.includeLegend {
            let legendPages = createLegendPages(pattern: pattern, settings: settings)
            for page in legendPages {
                pdfDocument.insert(page, at: pageIndex)
                pageIndex += 1
            }
        }
        
        progress?(0.4, "Creating pattern grid pages...")
        
        // Add pattern grid pages
        let patternPages = createPatternPages(pattern: pattern, settings: settings, progress: progress)
        for page in patternPages {
            pdfDocument.insert(page, at: pageIndex)
            pageIndex += 1
        }
        
        progress?(1.0, "Export complete")
        
        return pdfDocument.dataRepresentation()
    }
    
    /// Calculate the total number of pages for a pattern
    func calculatePageCount(pattern: Pattern, settings: ExportSettings) -> Int {
        var count = 0
        
        if settings.includePreview { count += 1 }
        if settings.includeThreadList { count += calculateThreadListPageCount(pattern: pattern, settings: settings) }
        if settings.includeLegend { count += calculateLegendPageCount(pattern: pattern, settings: settings) }
        
        count += calculatePatternPageCount(pattern: pattern, settings: settings)
        
        return count
    }
    
    // MARK: - Cover Page
    
    private func createCoverPage(pattern: Pattern, settings: ExportSettings) -> PDFPage? {
        let pageSize = settings.pageSize.size
        let scaledWidth = Int(pageSize.width * renderScale)
        let scaledHeight = Int(pageSize.height * renderScale)
        
        guard let context = CGContext(
            data: nil,
            width: scaledWidth,
            height: scaledHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        // Scale the context for high-resolution rendering
        context.scaleBy(x: renderScale, y: renderScale)
        
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        
        let printArea = settings.pageSize.printableArea
        
        // Title
        let titleFont = NSFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        
        let titleString = settings.patternTitle
        let titleSize = titleString.size(withAttributes: titleAttributes)
        let titleX = (pageSize.width - titleSize.width) / 2
        let titleY = pageSize.height - printArea.origin.y - 40
        titleString.draw(at: NSPoint(x: titleX, y: titleY), withAttributes: titleAttributes)
        
        // Pattern preview (rendered as mini grid)
        let previewSize = CGSize(width: 300, height: 300)
        let previewX = (pageSize.width - previewSize.width) / 2
        let previewY = titleY - 40 - previewSize.height
        
        drawPatternPreview(
            pattern: pattern,
            in: CGRect(x: previewX, y: previewY, width: previewSize.width, height: previewSize.height)
        )
        
        // Pattern info
        let infoFont = NSFont.systemFont(ofSize: 14)
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: infoFont,
            .foregroundColor: NSColor.darkGray
        ]
        
        let infoLines = [
            "Dimensions: \(pattern.width) × \(pattern.height) stitches",
            "Total Stitches: \(formatNumber(pattern.totalStitchCount))",
            "Colors: \(pattern.palette.count) DMC threads",
            "",
            "Finished Size (14-count): \(String(format: "%.1f", Double(pattern.width) / 14.0))\" × \(String(format: "%.1f", Double(pattern.height) / 14.0))\"",
            "Finished Size (16-count): \(String(format: "%.1f", Double(pattern.width) / 16.0))\" × \(String(format: "%.1f", Double(pattern.height) / 16.0))\"",
            "Finished Size (18-count): \(String(format: "%.1f", Double(pattern.width) / 18.0))\" × \(String(format: "%.1f", Double(pattern.height) / 18.0))\""
        ]
        
        var infoY = previewY - 40
        for line in infoLines {
            let lineSize = line.size(withAttributes: infoAttributes)
            let lineX = (pageSize.width - lineSize.width) / 2
            line.draw(at: NSPoint(x: lineX, y: infoY), withAttributes: infoAttributes)
            infoY -= 20
        }
        
        // Footer
        let footerFont = NSFont.systemFont(ofSize: 10)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: NSColor.gray
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = "Generated: \(dateFormatter.string(from: Date()))"
        let footerString = "Created with DCS Pro • \(dateString)"
        let footerSize = footerString.size(withAttributes: footerAttributes)
        let footerX = (pageSize.width - footerSize.width) / 2
        footerString.draw(at: NSPoint(x: footerX, y: printArea.origin.y), withAttributes: footerAttributes)
        
        NSGraphicsContext.restoreGraphicsState()
        
        if let cgImage = context.makeImage() {
            let nsImage = NSImage(cgImage: cgImage, size: pageSize)
            return PDFPage(image: nsImage)
        }
        
        return nil
    }
    
    // MARK: - Thread List Pages
    
    private func calculateThreadListPageCount(pattern: Pattern, settings: ExportSettings) -> Int {
        let itemsPerPage = 25
        return max(1, (pattern.palette.count + itemsPerPage - 1) / itemsPerPage)
    }
    
    private func createThreadListPages(pattern: Pattern, settings: ExportSettings) -> [PDFPage] {
        var pages: [PDFPage] = []
        let itemsPerPage = 25
        let sortedPalette = pattern.palette.sorted { $0.stitchCount > $1.stitchCount }
        
        let chunks = stride(from: 0, to: sortedPalette.count, by: itemsPerPage).map {
            Array(sortedPalette[$0..<min($0 + itemsPerPage, sortedPalette.count)])
        }
        
        for (chunkIndex, chunk) in chunks.enumerated() {
            if let page = createThreadListPage(
                entries: chunk,
                pattern: pattern,
                settings: settings,
                pageNumber: chunkIndex + 1,
                totalPages: chunks.count
            ) {
                pages.append(page)
            }
        }
        
        return pages
    }
    
    private func createThreadListPage(
        entries: [PaletteEntry],
        pattern: Pattern,
        settings: ExportSettings,
        pageNumber: Int,
        totalPages: Int
    ) -> PDFPage? {
        let pageSize = settings.pageSize.size
        let scaledWidth = Int(pageSize.width * renderScale)
        let scaledHeight = Int(pageSize.height * renderScale)
        
        guard let context = CGContext(
            data: nil,
            width: scaledWidth,
            height: scaledHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.scaleBy(x: renderScale, y: renderScale)
        
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        
        let printArea = settings.pageSize.printableArea
        
        // Title
        let titleFont = NSFont.boldSystemFont(ofSize: 18)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        
        let title = totalPages > 1 ? "Thread List (Page \(pageNumber) of \(totalPages))" : "Thread List"
        title.draw(at: NSPoint(x: printArea.origin.x, y: pageSize.height - printArea.origin.y - 30), withAttributes: titleAttributes)
        
        // Column headers
        let headerFont = NSFont.boldSystemFont(ofSize: 11)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: NSColor.darkGray
        ]
        
        let startY = pageSize.height - printArea.origin.y - 70
        let rowHeight: CGFloat = 24
        
        // Draw headers
        "Color".draw(at: NSPoint(x: printArea.origin.x, y: startY), withAttributes: headerAttributes)
        "DMC".draw(at: NSPoint(x: printArea.origin.x + 50, y: startY), withAttributes: headerAttributes)
        "Name".draw(at: NSPoint(x: printArea.origin.x + 100, y: startY), withAttributes: headerAttributes)
        "Stitches".draw(at: NSPoint(x: printArea.origin.x + 300, y: startY), withAttributes: headerAttributes)
        "Skeins".draw(at: NSPoint(x: printArea.origin.x + 380, y: startY), withAttributes: headerAttributes)
        
        // Draw separator line
        let linePath = NSBezierPath()
        linePath.move(to: NSPoint(x: printArea.origin.x, y: startY - 5))
        linePath.line(to: NSPoint(x: printArea.origin.x + printArea.width, y: startY - 5))
        NSColor.lightGray.setStroke()
        linePath.stroke()
        
        // Draw entries
        let entryFont = NSFont.systemFont(ofSize: 10)
        let entryAttributes: [NSAttributedString.Key: Any] = [
            .font: entryFont,
            .foregroundColor: NSColor.black
        ]
        
        for (index, entry) in entries.enumerated() {
            let y = startY - CGFloat(index + 1) * rowHeight - 10
            
            // Color swatch
            let swatchRect = NSRect(x: printArea.origin.x, y: y - 4, width: 30, height: 16)
            let color = NSColor(
                red: CGFloat(entry.thread.rgb.r) / 255.0,
                green: CGFloat(entry.thread.rgb.g) / 255.0,
                blue: CGFloat(entry.thread.rgb.b) / 255.0,
                alpha: 1.0
            )
            color.setFill()
            NSBezierPath(rect: swatchRect).fill()
            NSColor.darkGray.setStroke()
            NSBezierPath(rect: swatchRect).stroke()
            
            // DMC code
            entry.thread.id.draw(at: NSPoint(x: printArea.origin.x + 50, y: y), withAttributes: entryAttributes)
            
            // Name (truncated if needed)
            let name = entry.thread.name
            let truncatedName = name.count > 30 ? String(name.prefix(27)) + "..." : name
            truncatedName.draw(at: NSPoint(x: printArea.origin.x + 100, y: y), withAttributes: entryAttributes)
            
            // Stitch count
            formatNumber(entry.stitchCount).draw(at: NSPoint(x: printArea.origin.x + 300, y: y), withAttributes: entryAttributes)
            
            // Estimated skeins (1 skein ≈ 800-1000 stitches for full cross)
            let skeins = ceil(Double(entry.stitchCount) / 800.0 * 10) / 10
            String(format: "%.1f", skeins).draw(at: NSPoint(x: printArea.origin.x + 380, y: y), withAttributes: entryAttributes)
        }
        
        // Footer
        drawPageFooter(pageSize: pageSize, printArea: printArea, title: settings.patternTitle)
        
        NSGraphicsContext.restoreGraphicsState()
        
        if let cgImage = context.makeImage() {
            let nsImage = NSImage(cgImage: cgImage, size: pageSize)
            return PDFPage(image: nsImage)
        }
        
        return nil
    }
    
    // MARK: - Legend Pages
    
    private func calculateLegendPageCount(pattern: Pattern, settings: ExportSettings) -> Int {
        let itemsPerPage = 40
        return max(1, (pattern.palette.count + itemsPerPage - 1) / itemsPerPage)
    }
    
    private func createLegendPages(pattern: Pattern, settings: ExportSettings) -> [PDFPage] {
        var pages: [PDFPage] = []
        let itemsPerPage = 40
        let sortedPalette = pattern.palette.sorted { $0.stitchCount > $1.stitchCount }
        
        let chunks = stride(from: 0, to: sortedPalette.count, by: itemsPerPage).map {
            Array(sortedPalette[$0..<min($0 + itemsPerPage, sortedPalette.count)])
        }
        
        for (chunkIndex, chunk) in chunks.enumerated() {
            if let page = createLegendPage(
                entries: chunk,
                settings: settings,
                pageNumber: chunkIndex + 1,
                totalPages: chunks.count
            ) {
                pages.append(page)
            }
        }
        
        return pages
    }
    
    private func createLegendPage(
        entries: [PaletteEntry],
        settings: ExportSettings,
        pageNumber: Int,
        totalPages: Int
    ) -> PDFPage? {
        let pageSize = settings.pageSize.size
        let scaledWidth = Int(pageSize.width * renderScale)
        let scaledHeight = Int(pageSize.height * renderScale)
        
        guard let context = CGContext(
            data: nil,
            width: scaledWidth,
            height: scaledHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.scaleBy(x: renderScale, y: renderScale)
        
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        
        let printArea = settings.pageSize.printableArea
        
        // Title
        let titleFont = NSFont.boldSystemFont(ofSize: 18)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        
        let title = totalPages > 1 ? "Color Legend (Page \(pageNumber) of \(totalPages))" : "Color Legend"
        title.draw(at: NSPoint(x: printArea.origin.x, y: pageSize.height - printArea.origin.y - 30), withAttributes: titleAttributes)
        
        // Draw legend in 2 columns
        let columnWidth = printArea.width / 2 - 20
        let startY = pageSize.height - printArea.origin.y - 70
        let rowHeight: CGFloat = 18
        
        let symbolFont = NSFont(name: "Menlo", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let entryFont = NSFont.systemFont(ofSize: 10)
        
        for (index, entry) in entries.enumerated() {
            let column = index / 20
            let row = index % 20
            
            let x = printArea.origin.x + CGFloat(column) * (columnWidth + 40)
            let y = startY - CGFloat(row) * rowHeight
            
            // Symbol box
            let boxRect = NSRect(x: x, y: y - 2, width: 16, height: 14)
            let bgColor = NSColor(
                red: CGFloat(entry.thread.rgb.r) / 255.0,
                green: CGFloat(entry.thread.rgb.g) / 255.0,
                blue: CGFloat(entry.thread.rgb.b) / 255.0,
                alpha: 1.0
            )
            bgColor.setFill()
            NSBezierPath(rect: boxRect).fill()
            NSColor.darkGray.setStroke()
            NSBezierPath(rect: boxRect).stroke()
            
            // Symbol
            let symbolAttributes: [NSAttributedString.Key: Any] = [
                .font: symbolFont,
                .foregroundColor: contrastColor(for: entry.thread.rgb)
            ]
            let symbolStr = entry.symbol.character
            let symbolSize = symbolStr.size(withAttributes: symbolAttributes)
            let symbolX = x + (16 - symbolSize.width) / 2
            let symbolY = y - 2 + (14 - symbolSize.height) / 2
            symbolStr.draw(at: NSPoint(x: symbolX, y: symbolY), withAttributes: symbolAttributes)
            
            // DMC code and name
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: entryFont,
                .foregroundColor: NSColor.black
            ]
            let text = "\(entry.thread.id) - \(entry.thread.name)"
            let truncated = text.count > 35 ? String(text.prefix(32)) + "..." : text
            truncated.draw(at: NSPoint(x: x + 22, y: y), withAttributes: textAttributes)
        }
        
        // Footer
        drawPageFooter(pageSize: pageSize, printArea: printArea, title: settings.patternTitle)
        
        NSGraphicsContext.restoreGraphicsState()
        
        if let cgImage = context.makeImage() {
            let nsImage = NSImage(cgImage: cgImage, size: pageSize)
            return PDFPage(image: nsImage)
        }
        
        return nil
    }
    
    // MARK: - Pattern Grid Pages
    
    private func calculatePatternPageCount(pattern: Pattern, settings: ExportSettings) -> Int {
        let stitchesPerPage = settings.stitchesPerPage
        let pagesWide = (pattern.width + stitchesPerPage - 1) / stitchesPerPage
        let pagesHigh = (pattern.height + stitchesPerPage - 1) / stitchesPerPage
        return pagesWide * pagesHigh
    }
    
    private func createPatternPages(
        pattern: Pattern,
        settings: ExportSettings,
        progress: ProgressCallback?
    ) -> [PDFPage] {
        // Use traditional chart renderer for traditional style
        if settings.chartStyle == .traditional {
            return createTraditionalChartPages(pattern: pattern, settings: settings, progress: progress)
        }
        
        var pages: [PDFPage] = []
        
        let stitchesPerPage = settings.stitchesPerPage
        let pagesWide = (pattern.width + stitchesPerPage - 1) / stitchesPerPage
        let pagesHigh = (pattern.height + stitchesPerPage - 1) / stitchesPerPage
        let totalPages = pagesWide * pagesHigh
        
        // Build symbol lookup
        var symbolLookup: [String: PaletteEntry] = [:]
        for entry in pattern.palette {
            symbolLookup[entry.thread.id] = entry
        }
        
        var pageCount = 0
        for pageRow in 0..<pagesHigh {
            for pageCol in 0..<pagesWide {
                let startX = pageCol * stitchesPerPage
                let startY = pageRow * stitchesPerPage
                let endX = min(startX + stitchesPerPage, pattern.width)
                let endY = min(startY + stitchesPerPage, pattern.height)
                
                let pageLabel = "\(Character(UnicodeScalar(65 + pageCol)!))\(pageRow + 1)"
                
                if let page = createPatternPage(
                    pattern: pattern,
                    startX: startX, startY: startY,
                    endX: endX, endY: endY,
                    pageLabel: pageLabel,
                    settings: settings,
                    symbolLookup: symbolLookup
                ) {
                    pages.append(page)
                }
                
                pageCount += 1
                let progressValue = 0.4 + 0.6 * Double(pageCount) / Double(totalPages)
                progress?(progressValue, "Creating pattern page \(pageCount) of \(totalPages)...")
            }
        }
        
        return pages
    }
    
    private func createPatternPage(
        pattern: Pattern,
        startX: Int, startY: Int,
        endX: Int, endY: Int,
        pageLabel: String,
        settings: ExportSettings,
        symbolLookup: [String: PaletteEntry]
    ) -> PDFPage? {
        let pageSize = settings.pageSize.size
        let scaledWidth = Int(pageSize.width * renderScale)
        let scaledHeight = Int(pageSize.height * renderScale)
        
        guard let context = CGContext(
            data: nil,
            width: scaledWidth,
            height: scaledHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.scaleBy(x: renderScale, y: renderScale)
        
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        
        let printArea = settings.pageSize.printableArea
        
        // Header
        let headerFont = NSFont.boldSystemFont(ofSize: 12)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: NSColor.black
        ]
        
        let header = "Pattern Grid - Section \(pageLabel) (Columns \(startX + 1)-\(endX), Rows \(startY + 1)-\(endY))"
        header.draw(at: NSPoint(x: printArea.origin.x, y: pageSize.height - printArea.origin.y - 20), withAttributes: headerAttributes)
        
        // Calculate cell size
        let gridWidth = endX - startX
        let gridHeight = endY - startY
        let availableWidth = printArea.width - 30  // Leave room for row numbers
        let availableHeight = printArea.height - 80  // Leave room for header, footer, col numbers
        
        let cellSize = min(availableWidth / CGFloat(gridWidth), availableHeight / CGFloat(gridHeight))
        
        // Grid origin (account for column numbers at top)
        let gridOriginX = printArea.origin.x + 25
        let gridOriginY = pageSize.height - printArea.origin.y - 60 - CGFloat(gridHeight) * cellSize
        
        // Draw column numbers
        if settings.showGridNumbers {
            let numberFont = NSFont.monospacedDigitSystemFont(ofSize: 7, weight: .regular)
            let numberAttributes: [NSAttributedString.Key: Any] = [
                .font: numberFont,
                .foregroundColor: NSColor.darkGray
            ]
            
            // Column numbers (every 5)
            for col in stride(from: startX, to: endX, by: 5) {
                let x = gridOriginX + CGFloat(col - startX) * cellSize
                let numStr = "\(col + 1)"
                numStr.draw(at: NSPoint(x: x, y: gridOriginY + CGFloat(gridHeight) * cellSize + 5), withAttributes: numberAttributes)
            }
            
            // Row numbers (every 5)
            for row in stride(from: startY, to: endY, by: 5) {
                let y = gridOriginY + CGFloat(endY - row - 1) * cellSize
                let numStr = "\(row + 1)"
                numStr.draw(at: NSPoint(x: printArea.origin.x, y: y + cellSize / 2 - 4), withAttributes: numberAttributes)
            }
        }
        
        // Draw grid cells
        let symbolFont = NSFont(name: "Menlo", size: settings.symbolFontSize) ?? NSFont.monospacedSystemFont(ofSize: settings.symbolFontSize, weight: .medium)
        let isSymbolOnly = settings.chartStyle == .symbolOnly
        
        for row in startY..<endY {
            for col in startX..<endX {
                let cellX = gridOriginX + CGFloat(col - startX) * cellSize
                let cellY = gridOriginY + CGFloat(endY - row - 1) * cellSize
                let cellRect = NSRect(x: cellX, y: cellY, width: cellSize, height: cellSize)
                
                if let stitch = pattern.stitches[row][col],
                   let entry = symbolLookup[stitch.thread.id] {
                    
                    if isSymbolOnly {
                        // Symbol-only mode: white background, black symbol
                        NSColor.white.setFill()
                        NSBezierPath(rect: cellRect).fill()
                        
                        let symbolAttributes: [NSAttributedString.Key: Any] = [
                            .font: symbolFont,
                            .foregroundColor: NSColor.black
                        ]
                        let symbol = entry.symbol.character
                        let symbolSize = symbol.size(withAttributes: symbolAttributes)
                        let symbolX = cellX + (cellSize - symbolSize.width) / 2
                        let symbolY = cellY + (cellSize - symbolSize.height) / 2
                        symbol.draw(at: NSPoint(x: symbolX, y: symbolY), withAttributes: symbolAttributes)
                    } else {
                        // Color mode: colored background with contrasting symbol
                        let bgColor = NSColor(
                            red: CGFloat(entry.thread.rgb.r) / 255.0,
                            green: CGFloat(entry.thread.rgb.g) / 255.0,
                            blue: CGFloat(entry.thread.rgb.b) / 255.0,
                            alpha: 1.0
                        )
                        bgColor.setFill()
                        NSBezierPath(rect: cellRect).fill()
                        
                        let symbolAttributes: [NSAttributedString.Key: Any] = [
                            .font: symbolFont,
                            .foregroundColor: contrastColor(for: entry.thread.rgb)
                        ]
                        let symbol = entry.symbol.character
                        let symbolSize = symbol.size(withAttributes: symbolAttributes)
                        let symbolX = cellX + (cellSize - symbolSize.width) / 2
                        let symbolY = cellY + (cellSize - symbolSize.height) / 2
                        symbol.draw(at: NSPoint(x: symbolX, y: symbolY), withAttributes: symbolAttributes)
                    }
                } else if isSymbolOnly {
                    // Symbol-only mode: fill empty cells with white
                    NSColor.white.setFill()
                    NSBezierPath(rect: cellRect).fill()
                }
                
                // Draw cell border
                NSColor(white: 0.8, alpha: 1.0).setStroke()
                NSBezierPath(rect: cellRect).stroke()
            }
        }
        
        // Draw bold lines every 10 stitches
        NSColor.black.setStroke()
        let boldPath = NSBezierPath()
        boldPath.lineWidth = 1.5
        
        // Vertical bold lines
        for col in stride(from: ((startX / 10) + 1) * 10, to: endX, by: 10) {
            let x = gridOriginX + CGFloat(col - startX) * cellSize
            boldPath.move(to: NSPoint(x: x, y: gridOriginY))
            boldPath.line(to: NSPoint(x: x, y: gridOriginY + CGFloat(gridHeight) * cellSize))
        }
        
        // Horizontal bold lines
        for row in stride(from: ((startY / 10) + 1) * 10, to: endY, by: 10) {
            let y = gridOriginY + CGFloat(endY - row) * cellSize
            boldPath.move(to: NSPoint(x: gridOriginX, y: y))
            boldPath.line(to: NSPoint(x: gridOriginX + CGFloat(gridWidth) * cellSize, y: y))
        }
        
        boldPath.stroke()
        
        // Grid border
        let borderRect = NSRect(
            x: gridOriginX,
            y: gridOriginY,
            width: CGFloat(gridWidth) * cellSize,
            height: CGFloat(gridHeight) * cellSize
        )
        NSColor.black.setStroke()
        let borderPath = NSBezierPath(rect: borderRect)
        borderPath.lineWidth = 2.0
        borderPath.stroke()
        
        // Footer
        drawPageFooter(pageSize: pageSize, printArea: printArea, title: settings.patternTitle)
        
        NSGraphicsContext.restoreGraphicsState()
        
        if let cgImage = context.makeImage() {
            let nsImage = NSImage(cgImage: cgImage, size: pageSize)
            return PDFPage(image: nsImage)
        }
        
        return nil
    }
    
    // MARK: - Traditional Chart Pages
    
    /// Creates pattern pages in traditional cross-stitch chart style
    /// - Smaller cells to fit more stitches per page
    /// - Sidebar legend on each page
    /// - Uniform thin grid lines
    /// - Professional look matching commercial patterns
    private func createTraditionalChartPages(
        pattern: Pattern,
        settings: ExportSettings,
        progress: ProgressCallback?
    ) -> [PDFPage] {
        var pages: [PDFPage] = []
        
        // Traditional charts fit more stitches per page (about 100-120 stitches wide)
        // Use approximately 100 stitches for the grid area (leaving room for legend)
        let traditionalStitchesPerPage = 100
        let pagesWide = (pattern.width + traditionalStitchesPerPage - 1) / traditionalStitchesPerPage
        let pagesHigh = (pattern.height + traditionalStitchesPerPage - 1) / traditionalStitchesPerPage
        let totalPages = pagesWide * pagesHigh
        
        // Build symbol lookup
        var symbolLookup: [String: PaletteEntry] = [:]
        for entry in pattern.palette {
            symbolLookup[entry.thread.id] = entry
        }
        
        var pageCount = 0
        for pageRow in 0..<pagesHigh {
            for pageCol in 0..<pagesWide {
                let startX = pageCol * traditionalStitchesPerPage
                let startY = pageRow * traditionalStitchesPerPage
                let endX = min(startX + traditionalStitchesPerPage, pattern.width)
                let endY = min(startY + traditionalStitchesPerPage, pattern.height)
                
                let pageLabel = "\(Character(UnicodeScalar(65 + pageCol)!))\(pageRow + 1)"
                
                if let page = createTraditionalChartPage(
                    pattern: pattern,
                    startX: startX, startY: startY,
                    endX: endX, endY: endY,
                    pageLabel: pageLabel,
                    pageNumber: pageCount + 1,
                    totalPages: totalPages,
                    settings: settings,
                    symbolLookup: symbolLookup
                ) {
                    pages.append(page)
                }
                
                pageCount += 1
                let progressValue = 0.4 + 0.6 * Double(pageCount) / Double(totalPages)
                progress?(progressValue, "Creating chart page \(pageCount) of \(totalPages)...")
            }
        }
        
        return pages
    }
    
    private func createTraditionalChartPage(
        pattern: Pattern,
        startX: Int, startY: Int,
        endX: Int, endY: Int,
        pageLabel: String,
        pageNumber: Int,
        totalPages: Int,
        settings: ExportSettings,
        symbolLookup: [String: PaletteEntry]
    ) -> PDFPage? {
        let pageSize = settings.pageSize.size
        let scaledWidth = Int(pageSize.width * renderScale)
        let scaledHeight = Int(pageSize.height * renderScale)
        
        guard let context = CGContext(
            data: nil,
            width: scaledWidth,
            height: scaledHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.scaleBy(x: renderScale, y: renderScale)
        
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        
        // Fill with white background
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: pageSize)).fill()
        
        let printArea = settings.pageSize.printableArea
        
        // Layout: Grid on left (about 75% width), Legend on right (about 25% width)
        let legendWidth: CGFloat = 130
        let gridAreaWidth = printArea.width - legendWidth - 10  // 10pt gap
        let gridAreaHeight = printArea.height - 50  // Room for header and footer
        
        // Calculate grid dimensions
        let gridWidth = endX - startX
        let gridHeight = endY - startY
        
        // Cell size - make cells small but readable (about 5-6 points)
        let cellSize = min(gridAreaWidth / CGFloat(gridWidth), gridAreaHeight / CGFloat(gridHeight), 6.0)
        
        // Actual grid size
        let actualGridWidth = CGFloat(gridWidth) * cellSize
        let actualGridHeight = CGFloat(gridHeight) * cellSize
        
        // Grid origin - center horizontally in grid area
        let gridOriginX = printArea.origin.x + (gridAreaWidth - actualGridWidth) / 2 + 15  // 15pt for row numbers
        let gridOriginY = printArea.origin.y + 25 + (gridAreaHeight - actualGridHeight) / 2
        
        // Header
        let headerFont = NSFont.boldSystemFont(ofSize: 10)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: NSColor.black
        ]
        
        let header = "\(settings.patternTitle) - Section \(pageLabel) (Page \(pageNumber) of \(totalPages))"
        header.draw(at: NSPoint(x: printArea.origin.x, y: pageSize.height - printArea.origin.y - 15), withAttributes: headerAttributes)
        
        // Sub-header with stitch range
        let subHeaderFont = NSFont.systemFont(ofSize: 8)
        let subHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: subHeaderFont,
            .foregroundColor: NSColor.darkGray
        ]
        let subHeader = "Columns \(startX + 1)-\(endX), Rows \(startY + 1)-\(endY)"
        subHeader.draw(at: NSPoint(x: printArea.origin.x, y: pageSize.height - printArea.origin.y - 28), withAttributes: subHeaderAttributes)
        
        // Draw row numbers (every 10, on the left)
        let numberFont = NSFont.monospacedDigitSystemFont(ofSize: 6, weight: .regular)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: NSColor.black
        ]
        
        for row in stride(from: ((startY / 10) * 10), through: endY, by: 10) {
            if row >= startY && row <= endY {
                let y = gridOriginY + CGFloat(endY - row) * cellSize - cellSize / 2
                let numStr = "\(row)"
                let numSize = numStr.size(withAttributes: numberAttributes)
                numStr.draw(at: NSPoint(x: gridOriginX - numSize.width - 3, y: y - numSize.height / 2), withAttributes: numberAttributes)
            }
        }
        
        // Draw column numbers (every 10, at top)
        for col in stride(from: ((startX / 10) * 10), through: endX, by: 10) {
            if col >= startX && col <= endX {
                let x = gridOriginX + CGFloat(col - startX) * cellSize
                let numStr = "\(col)"
                numStr.draw(at: NSPoint(x: x, y: gridOriginY + actualGridHeight + 3), withAttributes: numberAttributes)
            }
        }
        
        // Draw grid cells with symbols only
        let symbolFont = NSFont(name: "Menlo", size: cellSize * 0.75) ?? NSFont.monospacedSystemFont(ofSize: cellSize * 0.75, weight: .regular)
        
        for row in startY..<endY {
            for col in startX..<endX {
                let cellX = gridOriginX + CGFloat(col - startX) * cellSize
                let cellY = gridOriginY + CGFloat(endY - row - 1) * cellSize
                let cellRect = NSRect(x: cellX, y: cellY, width: cellSize, height: cellSize)
                
                if let stitch = pattern.stitches[row][col],
                   let entry = symbolLookup[stitch.thread.id] {
                    // Draw symbol in black
                    let symbolAttributes: [NSAttributedString.Key: Any] = [
                        .font: symbolFont,
                        .foregroundColor: NSColor.black
                    ]
                    let symbol = entry.symbol.character
                    let symbolSize = symbol.size(withAttributes: symbolAttributes)
                    let symbolX = cellX + (cellSize - symbolSize.width) / 2
                    let symbolY = cellY + (cellSize - symbolSize.height) / 2
                    symbol.draw(at: NSPoint(x: symbolX, y: symbolY), withAttributes: symbolAttributes)
                }
                
                // Draw thin cell border
                NSColor(white: 0.7, alpha: 1.0).setStroke()
                let cellPath = NSBezierPath(rect: cellRect)
                cellPath.lineWidth = 0.25
                cellPath.stroke()
            }
        }
        
        // Draw bolder lines every 10 stitches
        NSColor(white: 0.3, alpha: 1.0).setStroke()
        let boldPath = NSBezierPath()
        boldPath.lineWidth = 0.75
        
        // Vertical bold lines every 10
        for col in stride(from: ((startX / 10) + 1) * 10, to: endX, by: 10) {
            let x = gridOriginX + CGFloat(col - startX) * cellSize
            boldPath.move(to: NSPoint(x: x, y: gridOriginY))
            boldPath.line(to: NSPoint(x: x, y: gridOriginY + actualGridHeight))
        }
        
        // Horizontal bold lines every 10
        for row in stride(from: ((startY / 10) + 1) * 10, to: endY, by: 10) {
            let y = gridOriginY + CGFloat(endY - row) * cellSize
            boldPath.move(to: NSPoint(x: gridOriginX, y: y))
            boldPath.line(to: NSPoint(x: gridOriginX + actualGridWidth, y: y))
        }
        
        boldPath.stroke()
        
        // Grid border
        NSColor.black.setStroke()
        let borderPath = NSBezierPath(rect: NSRect(x: gridOriginX, y: gridOriginY, width: actualGridWidth, height: actualGridHeight))
        borderPath.lineWidth = 1.0
        borderPath.stroke()
        
        // Draw legend on right side
        let legendX = printArea.origin.x + gridAreaWidth + 20
        let legendStartY = pageSize.height - printArea.origin.y - 45
        
        // Legend title
        let legendTitleFont = NSFont.boldSystemFont(ofSize: 8)
        let legendTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: legendTitleFont,
            .foregroundColor: NSColor.black
        ]
        "COLOR KEY".draw(at: NSPoint(x: legendX, y: legendStartY), withAttributes: legendTitleAttributes)
        
        // Draw legend entries
        let legendEntryFont = NSFont.systemFont(ofSize: 6)
        let legendSymbolFont = NSFont(name: "Menlo", size: 7) ?? NSFont.monospacedSystemFont(ofSize: 7, weight: .regular)
        let rowHeight: CGFloat = 11
        
        var legendY = legendStartY - 15
        for entry in pattern.palette.prefix(50) {  // Limit to 50 colors per page
            // Symbol box
            let boxRect = NSRect(x: legendX, y: legendY - 1, width: 10, height: 9)
            NSColor.white.setFill()
            NSBezierPath(rect: boxRect).fill()
            NSColor.black.setStroke()
            let boxPath = NSBezierPath(rect: boxRect)
            boxPath.lineWidth = 0.5
            boxPath.stroke()
            
            // Symbol
            let symbolAttributes: [NSAttributedString.Key: Any] = [
                .font: legendSymbolFont,
                .foregroundColor: NSColor.black
            ]
            let symbol = entry.symbol.character
            let symbolSize = symbol.size(withAttributes: symbolAttributes)
            symbol.draw(at: NSPoint(x: legendX + (10 - symbolSize.width) / 2, y: legendY - 1 + (9 - symbolSize.height) / 2), withAttributes: symbolAttributes)
            
            // DMC code and name
            let entryAttributes: [NSAttributedString.Key: Any] = [
                .font: legendEntryFont,
                .foregroundColor: NSColor.black
            ]
            let entryText = "\(entry.thread.id) \(entry.thread.name)"
            let truncated = entryText.count > 18 ? String(entryText.prefix(15)) + "..." : entryText
            truncated.draw(at: NSPoint(x: legendX + 13, y: legendY), withAttributes: entryAttributes)
            
            legendY -= rowHeight
            
            // Stop if we run out of space
            if legendY < printArea.origin.y + 30 {
                break
            }
        }
        
        // Footer
        drawPageFooter(pageSize: pageSize, printArea: printArea, title: settings.patternTitle)
        
        NSGraphicsContext.restoreGraphicsState()
        
        if let cgImage = context.makeImage() {
            let nsImage = NSImage(cgImage: cgImage, size: pageSize)
            return PDFPage(image: nsImage)
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func drawPatternPreview(pattern: Pattern, in rect: CGRect) {
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
        
        let cellWidth = rect.width / CGFloat(pattern.width)
        let cellHeight = rect.height / CGFloat(pattern.height)
        
        for row in 0..<pattern.height {
            for col in 0..<pattern.width {
                if let stitch = pattern.stitches[row][col],
                   let color = colorLookup[stitch.thread.id] {
                    let cellRect = NSRect(
                        x: rect.origin.x + CGFloat(col) * cellWidth,
                        y: rect.origin.y + CGFloat(pattern.height - row - 1) * cellHeight,
                        width: cellWidth,
                        height: cellHeight
                    )
                    color.setFill()
                    NSBezierPath(rect: cellRect).fill()
                }
            }
        }
        
        // Border
        NSColor.darkGray.setStroke()
        NSBezierPath(rect: rect).stroke()
    }
    
    private func drawPageFooter(pageSize: CGSize, printArea: CGRect, title: String) {
        let footerFont = NSFont.systemFont(ofSize: 9)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: NSColor.gray
        ]
        
        let footerLeft = title
        footerLeft.draw(at: NSPoint(x: printArea.origin.x, y: printArea.origin.y - 5), withAttributes: footerAttributes)
        
        let footerRight = "DCS Pro"
        let rightSize = footerRight.size(withAttributes: footerAttributes)
        footerRight.draw(at: NSPoint(x: printArea.origin.x + printArea.width - rightSize.width, y: printArea.origin.y - 5), withAttributes: footerAttributes)
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    /// Calculate contrast color (black or white) for a given RGB color
    private func contrastColor(for rgb: RGBColor) -> NSColor {
        // Calculate relative luminance
        let luminance = 0.299 * Double(rgb.r) + 0.587 * Double(rgb.g) + 0.114 * Double(rgb.b)
        return luminance > 128 ? NSColor.black : NSColor.white
    }
}
