//
//  PatternEditingViewModel.swift
//  DCS Pro
//
//  View model for pattern editing operations with undo/redo support
//

import SwiftUI

// MARK: - Editing Tool

/// Available editing tools
enum EditingTool: String, CaseIterable, Identifiable {
    case select = "Select"
    case paint = "Paint"
    case fill = "Fill"
    case eraser = "Eraser"
    case progress = "Progress"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .select: return "hand.point.up.left"
        case .paint: return "paintbrush"
        case .fill: return "drop.fill"
        case .eraser: return "eraser"
        case .progress: return "checkmark.circle"
        }
    }
    
    var helpText: String {
        switch self {
        case .select: return "Select stitch to view color"
        case .paint: return "Click or drag to paint stitches"
        case .fill: return "Click to fill connected area"
        case .eraser: return "Click or drag to erase stitches"
        case .progress: return "Click to mark stitch as complete"
        }
    }
}

// MARK: - Edit Action

/// Represents a single undoable edit action
struct EditAction: Equatable {
    let changes: [StitchChange]
    let timestamp: Date
    
    init(changes: [StitchChange]) {
        self.changes = changes
        self.timestamp = Date()
    }
}

/// Represents a single stitch change
struct StitchChange: Equatable {
    let x: Int
    let y: Int
    let oldStitch: Stitch?
    let newStitch: Stitch?
}

/// Represents a progress change (marking stitch complete/incomplete)
struct ProgressChange: Equatable {
    let x: Int
    let y: Int
    let wasCompleted: Bool
    let isCompleted: Bool
}

/// Represents an undoable progress action
struct ProgressAction: Equatable {
    let changes: [ProgressChange]
    let timestamp: Date
    
    init(changes: [ProgressChange]) {
        self.changes = changes
        self.timestamp = Date()
    }
}

// MARK: - Pattern Editing ViewModel

/// Observable view model managing pattern editing state and undo/redo
@Observable
class PatternEditingViewModel {
    // MARK: - Properties
    
    /// The pattern being edited (reference to parent's pattern)
    private(set) var pattern: Pattern
    
    /// Currently selected editing tool
    var currentTool: EditingTool = .select
    
    /// Currently selected thread for painting
    var selectedThread: DMCThread?
    
    /// Is editing mode active
    var isEditingEnabled: Bool = false
    
    /// Show only remaining (incomplete) stitches
    var showOnlyRemaining: Bool = false
    
    /// Show progress overlay (dim completed stitches)
    var showProgressOverlay: Bool = true
    
    /// Undo stack
    private var undoStack: [EditAction] = []
    
    /// Redo stack
    private var redoStack: [EditAction] = []
    
    /// Progress undo stack (separate from edit undo)
    private var progressUndoStack: [ProgressAction] = []
    
    /// Progress redo stack
    private var progressRedoStack: [ProgressAction] = []
    
    /// Maximum undo history size
    private let maxUndoHistory = 100
    
    /// Callback when pattern changes
    var onPatternChanged: ((Pattern) -> Void)?
    
    // MARK: - Computed Properties
    
    var canUndo: Bool { !undoStack.isEmpty || !progressUndoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty || !progressRedoStack.isEmpty }
    var undoCount: Int { undoStack.count + progressUndoStack.count }
    var redoCount: Int { redoStack.count + progressRedoStack.count }
    
    /// Progress statistics
    var completedStitchCount: Int { pattern.completedStitchCount }
    var totalStitchCount: Int { pattern.totalStitchCount }
    var progressPercentage: Double { pattern.progressPercentage }
    
    var progressText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let completed = formatter.string(from: NSNumber(value: completedStitchCount)) ?? "\(completedStitchCount)"
        let total = formatter.string(from: NSNumber(value: totalStitchCount)) ?? "\(totalStitchCount)"
        return "\(completed) / \(total) (\(String(format: "%.1f", progressPercentage))%)"
    }
    
    // MARK: - Initialization
    
    init(pattern: Pattern) {
        self.pattern = pattern
        // Default to first palette color
        if let firstEntry = pattern.palette.first {
            self.selectedThread = firstEntry.thread
        }
    }
    
    // MARK: - Pattern Updates
    
    /// Update the pattern reference (when loading a new project)
    func updatePattern(_ newPattern: Pattern) {
        self.pattern = newPattern
        clearHistory()
        if let firstEntry = newPattern.palette.first {
            self.selectedThread = firstEntry.thread
        }
    }
    
    // MARK: - Editing Operations
    
    /// Paint a single stitch with the selected thread
    func paintStitch(at x: Int, y: Int) {
        guard isEditingEnabled, let thread = selectedThread else { return }
        
        let oldStitch = pattern.stitch(at: x, y: y)
        let newStitch = Stitch(thread: thread)
        
        // Don't record if no change
        if oldStitch?.thread.id == thread.id { return }
        
        let change = StitchChange(x: x, y: y, oldStitch: oldStitch, newStitch: newStitch)
        applyChanges([change])
    }
    
    /// Paint multiple stitches (for drag operations)
    func paintStitches(at positions: [(x: Int, y: Int)]) {
        guard isEditingEnabled, let thread = selectedThread else { return }
        
        var changes: [StitchChange] = []
        for pos in positions {
            let oldStitch = pattern.stitch(at: pos.x, y: pos.y)
            if oldStitch?.thread.id != thread.id {
                let newStitch = Stitch(thread: thread)
                changes.append(StitchChange(x: pos.x, y: pos.y, oldStitch: oldStitch, newStitch: newStitch))
            }
        }
        
        if !changes.isEmpty {
            applyChanges(changes)
        }
    }
    
    /// Erase a single stitch
    func eraseStitch(at x: Int, y: Int) {
        guard isEditingEnabled else { return }
        
        let oldStitch = pattern.stitch(at: x, y: y)
        guard oldStitch != nil else { return }
        
        let change = StitchChange(x: x, y: y, oldStitch: oldStitch, newStitch: nil)
        applyChanges([change])
    }
    
    /// Erase multiple stitches
    func eraseStitches(at positions: [(x: Int, y: Int)]) {
        guard isEditingEnabled else { return }
        
        var changes: [StitchChange] = []
        for pos in positions {
            let oldStitch = pattern.stitch(at: pos.x, y: pos.y)
            if oldStitch != nil {
                changes.append(StitchChange(x: pos.x, y: pos.y, oldStitch: oldStitch, newStitch: nil))
            }
        }
        
        if !changes.isEmpty {
            applyChanges(changes)
        }
    }
    
    /// Fill connected area with the selected thread
    func fillArea(startingAt x: Int, y: Int) {
        guard isEditingEnabled, let thread = selectedThread else { return }
        guard x >= 0, x < pattern.width, y >= 0, y < pattern.height else { return }
        
        let targetStitch = pattern.stitch(at: x, y: y)
        let targetThreadId = targetStitch?.thread.id
        
        // Don't fill if already the same color
        if targetThreadId == thread.id { return }
        
        // Flood fill algorithm
        var visited = Set<String>()
        var toVisit = [(x, y)]
        var changes: [StitchChange] = []
        
        while !toVisit.isEmpty {
            let (cx, cy) = toVisit.removeFirst()
            let key = "\(cx),\(cy)"
            
            guard !visited.contains(key) else { continue }
            guard cx >= 0, cx < pattern.width, cy >= 0, cy < pattern.height else { continue }
            
            let currentStitch = pattern.stitch(at: cx, y: cy)
            let currentThreadId = currentStitch?.thread.id
            
            // Only fill if matches target color (or both are empty)
            guard currentThreadId == targetThreadId else { continue }
            
            visited.insert(key)
            
            let newStitch = Stitch(thread: thread)
            changes.append(StitchChange(x: cx, y: cy, oldStitch: currentStitch, newStitch: newStitch))
            
            // Add neighbors
            toVisit.append((cx + 1, cy))
            toVisit.append((cx - 1, cy))
            toVisit.append((cx, cy + 1))
            toVisit.append((cx, cy - 1))
        }
        
        if !changes.isEmpty {
            applyChanges(changes)
        }
    }
    
    // MARK: - Progress Marking
    
    /// Toggle completion status of a stitch
    func toggleProgress(at x: Int, y: Int) {
        guard let stitch = pattern.stitch(at: x, y: y) else { return }
        
        let wasCompleted = stitch.isCompleted
        let isCompleted = !wasCompleted
        
        pattern.markCompleted(at: x, y: y, completed: isCompleted)
        
        let change = ProgressChange(x: x, y: y, wasCompleted: wasCompleted, isCompleted: isCompleted)
        let action = ProgressAction(changes: [change])
        progressUndoStack.append(action)
        progressRedoStack.removeAll()
        
        // Limit history
        if progressUndoStack.count > maxUndoHistory {
            progressUndoStack.removeFirst()
        }
        
        onPatternChanged?(pattern)
    }
    
    /// Mark multiple stitches as complete
    func markProgress(at positions: [(x: Int, y: Int)], completed: Bool) {
        var changes: [ProgressChange] = []
        
        for pos in positions {
            if let stitch = pattern.stitch(at: pos.x, y: pos.y) {
                if stitch.isCompleted != completed {
                    changes.append(ProgressChange(x: pos.x, y: pos.y, wasCompleted: stitch.isCompleted, isCompleted: completed))
                    pattern.markCompleted(at: pos.x, y: pos.y, completed: completed)
                }
            }
        }
        
        if !changes.isEmpty {
            let action = ProgressAction(changes: changes)
            progressUndoStack.append(action)
            progressRedoStack.removeAll()
            
            if progressUndoStack.count > maxUndoHistory {
                progressUndoStack.removeFirst()
            }
            
            onPatternChanged?(pattern)
        }
    }
    
    /// Mark all stitches as complete or incomplete
    func markAllProgress(completed: Bool) {
        var changes: [ProgressChange] = []
        
        for y in 0..<pattern.height {
            for x in 0..<pattern.width {
                if let stitch = pattern.stitch(at: x, y: y) {
                    if stitch.isCompleted != completed {
                        changes.append(ProgressChange(x: x, y: y, wasCompleted: stitch.isCompleted, isCompleted: completed))
                        pattern.markCompleted(at: x, y: y, completed: completed)
                    }
                }
            }
        }
        
        if !changes.isEmpty {
            let action = ProgressAction(changes: changes)
            progressUndoStack.append(action)
            progressRedoStack.removeAll()
            onPatternChanged?(pattern)
        }
    }
    
    // MARK: - Apply Changes
    
    private func applyChanges(_ changes: [StitchChange]) {
        // Apply to pattern
        for change in changes {
            pattern.setStitch(change.newStitch, at: change.x, y: change.y)
        }
        
        // Record for undo
        let action = EditAction(changes: changes)
        undoStack.append(action)
        
        // Clear redo stack on new action
        redoStack.removeAll()
        
        // Limit undo history
        if undoStack.count > maxUndoHistory {
            undoStack.removeFirst()
        }
        
        // Update palette counts
        updatePaletteCounts()
        
        // Notify
        onPatternChanged?(pattern)
    }
    
    // MARK: - Undo/Redo
    
    /// Undo the last action
    func undo() {
        guard let action = undoStack.popLast() else { return }
        
        // Apply reverse changes
        for change in action.changes {
            pattern.setStitch(change.oldStitch, at: change.x, y: change.y)
        }
        
        // Move to redo stack
        redoStack.append(action)
        
        // Update palette counts
        updatePaletteCounts()
        
        // Notify
        onPatternChanged?(pattern)
    }
    
    /// Redo the last undone action
    func redo() {
        guard let action = redoStack.popLast() else { return }
        
        // Apply changes again
        for change in action.changes {
            pattern.setStitch(change.newStitch, at: change.x, y: change.y)
        }
        
        // Move back to undo stack
        undoStack.append(action)
        
        // Update palette counts
        updatePaletteCounts()
        
        // Notify
        onPatternChanged?(pattern)
    }
    
    /// Clear all history (called on save)
    func clearHistory() {
        undoStack.removeAll()
        redoStack.removeAll()
        progressUndoStack.removeAll()
        progressRedoStack.removeAll()
    }
    
    /// Undo progress marking
    func undoProgress() {
        guard let action = progressUndoStack.popLast() else { return }
        
        for change in action.changes {
            pattern.markCompleted(at: change.x, y: change.y, completed: change.wasCompleted)
        }
        
        progressRedoStack.append(action)
        onPatternChanged?(pattern)
    }
    
    /// Redo progress marking
    func redoProgress() {
        guard let action = progressRedoStack.popLast() else { return }
        
        for change in action.changes {
            pattern.markCompleted(at: change.x, y: change.y, completed: change.isCompleted)
        }
        
        progressUndoStack.append(action)
        onPatternChanged?(pattern)
    }
    
    // MARK: - Palette Management
    
    /// Update stitch counts in palette after edits
    private func updatePaletteCounts() {
        // Count stitches per thread
        var counts: [String: Int] = [:]
        for y in 0..<pattern.height {
            for x in 0..<pattern.width {
                if let stitch = pattern.stitch(at: x, y: y) {
                    counts[stitch.thread.id, default: 0] += 1
                }
            }
        }
        
        // Update palette entries
        for i in 0..<pattern.palette.count {
            let threadId = pattern.palette[i].thread.id
            pattern.palette[i].stitchCount = counts[threadId] ?? 0
        }
    }
    
    // MARK: - Tool Actions
    
    /// Handle a click/tap at grid position
    func handleClick(at x: Int, y: Int) {
        switch currentTool {
        case .select:
            // Select the thread at this position
            if let stitch = pattern.stitch(at: x, y: y) {
                selectedThread = stitch.thread
            }
        case .paint:
            paintStitch(at: x, y: y)
        case .fill:
            fillArea(startingAt: x, y: y)
        case .eraser:
            eraseStitch(at: x, y: y)
        case .progress:
            toggleProgress(at: x, y: y)
        }
    }
    
    /// Handle drag at grid positions
    func handleDrag(at positions: [(x: Int, y: Int)]) {
        switch currentTool {
        case .select:
            break // No drag for select
        case .paint:
            paintStitches(at: positions)
        case .fill:
            break // No drag for fill
        case .eraser:
            eraseStitches(at: positions)
        case .progress:
            // Mark all dragged positions as complete
            markProgress(at: positions, completed: true)
        }
    }
}
