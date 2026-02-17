//
//  ColorPaletteView.swift
//  DCS Pro
//
//  Sidebar panel showing all colors in a pattern with their DMC codes and stitch counts
//

import SwiftUI

/// A view that displays the color palette legend for a cross-stitch pattern
struct ColorPaletteView: View {
    let palette: [PaletteEntry]
    @Binding var selectedThreadId: String?
    var onColorSelected: ((DMCThread) -> Void)?
    
    /// Sort options for the palette
    enum SortOrder: String, CaseIterable {
        case symbol = "Symbol"
        case stitchCount = "Count"
        case dmcCode = "DMC Code"
        case name = "Name"
    }
    
    @State private var sortOrder: SortOrder = .stitchCount
    @State private var searchText: String = ""
    
    private var sortedPalette: [PaletteEntry] {
        let filtered = searchText.isEmpty ? palette : palette.filter {
            $0.thread.id.localizedCaseInsensitiveContains(searchText) ||
            $0.thread.name.localizedCaseInsensitiveContains(searchText)
        }
        
        switch sortOrder {
        case .symbol:
            return filtered.sorted { $0.symbol.character < $1.symbol.character }
        case .stitchCount:
            return filtered.sorted { $0.stitchCount > $1.stitchCount }
        case .dmcCode:
            return filtered.sorted { $0.thread.id.localizedStandardCompare($1.thread.id) == .orderedAscending }
        case .name:
            return filtered.sorted { $0.thread.name < $1.thread.name }
        }
    }
    
    private var totalStitches: Int {
        palette.reduce(0) { $0 + $1.stitchCount }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Search field
            searchField
            
            Divider()
            
            // Color list
            colorList
            
            Divider()
            
            // Footer with totals
            footer
        }
        .frame(minWidth: 220, maxWidth: 280)
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Colors")
                    .font(.headline)
                Spacer()
                Text("\(palette.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Sort picker - use menu style for narrow sidebar
            HStack {
                Text("Sort by:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)
                .labelsHidden()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search colors...", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
    
    private var colorList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(sortedPalette) { entry in
                    ColorPaletteRow(
                        entry: entry,
                        isSelected: selectedThreadId == entry.thread.id,
                        totalStitches: totalStitches
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if selectedThreadId == entry.thread.id {
                                selectedThreadId = nil
                            } else {
                                selectedThreadId = entry.thread.id
                                onColorSelected?(entry.thread)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var footer: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Total Stitches")
                    .font(.subheadline)
                Spacer()
                Text(formatNumber(totalStitches))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            if let selected = selectedThreadId,
               let entry = palette.first(where: { $0.thread.id == selected }) {
                HStack {
                    Text("Selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(entry.thread.id) - \(formatNumber(entry.stitchCount))")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Color Palette Row

struct ColorPaletteRow: View {
    let entry: PaletteEntry
    let isSelected: Bool
    let totalStitches: Int
    
    private var percentage: Double {
        guard totalStitches > 0 else { return 0 }
        return Double(entry.stitchCount) / Double(totalStitches) * 100
    }
    
    private var threadColor: Color {
        let rgb = entry.thread.rgb
        return Color(
            red: Double(rgb.r) / 255.0,
            green: Double(rgb.g) / 255.0,
            blue: Double(rgb.b) / 255.0
        )
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Color swatch with symbol
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(threadColor)
                    .frame(width: 32, height: 32)
                
                Text(entry.symbol.character)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(contrastingTextColor)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
            
            // Thread info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.thread.id)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    Spacer()
                    Text(formatNumber(entry.stitchCount))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(entry.thread.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Progress bar showing percentage
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 3)
                            .cornerRadius(1.5)
                        
                        Rectangle()
                            .fill(threadColor)
                            .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
    }
    
    private var contrastingTextColor: Color {
        let brightness = (Double(entry.thread.rgb.r) * 0.299 +
                         Double(entry.thread.rgb.g) * 0.587 +
                         Double(entry.thread.rgb.b) * 0.114) / 255.0
        return brightness > 0.5 ? .black : .white
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Preview

#Preview("Color Palette") {
    let threads = Array(DMCDatabase.shared.threads.prefix(12))
    let symbols = PatternSymbol.availableSymbols
    
    let palette = threads.enumerated().map { index, thread in
        PaletteEntry(
            id: UUID(),
            thread: thread,
            symbol: symbols[index],
            stitchCount: Int.random(in: 100...5000)
        )
    }
    
    return ColorPaletteView(
        palette: palette,
        selectedThreadId: .constant(nil)
    )
    .frame(height: 500)
}

#Preview("Color Palette - Selected") {
    let threads = Array(DMCDatabase.shared.threads.prefix(8))
    let symbols = PatternSymbol.availableSymbols
    
    let palette = threads.enumerated().map { index, thread in
        PaletteEntry(
            id: UUID(),
            thread: thread,
            symbol: symbols[index],
            stitchCount: Int.random(in: 500...3000)
        )
    }
    
    return ColorPaletteView(
        palette: palette,
        selectedThreadId: .constant(threads[2].id)
    )
    .frame(height: 400)
}
