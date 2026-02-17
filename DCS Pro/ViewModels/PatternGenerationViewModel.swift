//
//  PatternGenerationViewModel.swift
//  DCS Pro
//
//  View model for pattern generation process
//

import SwiftUI

/// Observable view model for pattern generation state
@Observable
class PatternGenerationViewModel {
    // MARK: - State
    
    /// Current generation phase
    var phase: GenerationPhase = .idle
    
    /// Progress within current phase (0.0 to 1.0)
    var progress: Double = 0.0
    
    /// Status message describing current operation
    var statusMessage: String = "Ready to generate"
    
    /// Error message if generation failed
    var errorMessage: String?
    
    /// The generated pattern (set when complete)
    var generatedPattern: Pattern?
    
    /// Whether generation is currently running
    var isGenerating: Bool {
        switch phase {
        case .idle, .complete, .failed:
            return false
        case .resizing, .quantizing, .matching, .building:
            return true
        }
    }
    
    /// Overall progress combining all phases
    var overallProgress: Double {
        switch phase {
        case .idle: return 0.0
        case .resizing: return progress * 0.1
        case .quantizing: return 0.1 + progress * 0.3
        case .matching: return 0.4 + progress * 0.3
        case .building: return 0.7 + progress * 0.3
        case .complete: return 1.0
        case .failed: return progress
        }
    }
    
    // MARK: - Generation Phases
    
    enum GenerationPhase: String {
        case idle = "Ready"
        case resizing = "Resizing Image"
        case quantizing = "Analyzing Colors"
        case matching = "Matching DMC Threads"
        case building = "Building Pattern"
        case complete = "Complete"
        case failed = "Failed"
        
        var description: String {
            switch self {
            case .idle: return "Ready to generate pattern"
            case .resizing: return "Resizing image to target dimensions..."
            case .quantizing: return "Reducing colors using median cut algorithm..."
            case .matching: return "Finding best matching DMC thread colors..."
            case .building: return "Creating stitch pattern from pixel data..."
            case .complete: return "Pattern generation complete!"
            case .failed: return "Generation failed"
            }
        }
        
        var icon: String {
            switch self {
            case .idle: return "circle"
            case .resizing: return "arrow.down.right.and.arrow.up.left"
            case .quantizing: return "paintpalette"
            case .matching: return "target"
            case .building: return "square.grid.3x3"
            case .complete: return "checkmark.circle.fill"
            case .failed: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    // MARK: - Services
    
    private let patternService = PatternGenerationService()
    
    // MARK: - Actions
    
    /// Start pattern generation
    @MainActor
    func generate(from image: NSImage, with settings: GenerationSettings) async {
        // Reset state
        generatedPattern = nil
        errorMessage = nil
        
        do {
            // Phase 1: Resizing
            updatePhase(.resizing, progress: 0.0)
            
            // Small delay to show UI update
            try await Task.sleep(for: .milliseconds(100))
            updatePhase(.resizing, progress: 0.5)
            
            // Phase 2: Quantizing
            updatePhase(.quantizing, progress: 0.0)
            try await Task.sleep(for: .milliseconds(100))
            
            // Simulate progress during quantization
            for i in 1...5 {
                updatePhase(.quantizing, progress: Double(i) / 5.0)
                try await Task.sleep(for: .milliseconds(50))
            }
            
            // Phase 3: Color Matching
            updatePhase(.matching, progress: 0.0)
            try await Task.sleep(for: .milliseconds(100))
            
            // Simulate progress during matching
            for i in 1...5 {
                updatePhase(.matching, progress: Double(i) / 5.0)
                try await Task.sleep(for: .milliseconds(50))
            }
            
            // Phase 4: Building Pattern
            updatePhase(.building, progress: 0.0)
            
            // Actually generate the pattern (run on background thread)
            let pattern = try await patternService.generatePattern(from: image, settings: settings)
            
            updatePhase(.building, progress: 1.0)
            
            // Complete
            generatedPattern = pattern
            updatePhase(.complete, progress: 1.0)
            statusMessage = "Generated \(pattern.width)×\(pattern.height) pattern with \(pattern.palette.count) colors"
            
        } catch {
            updatePhase(.failed, progress: overallProgress)
            errorMessage = error.localizedDescription
            statusMessage = "Generation failed: \(error.localizedDescription)"
        }
    }
    
    /// Cancel generation (if possible)
    func cancel() {
        // In a full implementation, this would cancel the async task
        updatePhase(.idle, progress: 0.0)
        statusMessage = "Generation cancelled"
    }
    
    /// Reset to initial state
    func reset() {
        phase = .idle
        progress = 0.0
        statusMessage = "Ready to generate"
        errorMessage = nil
        generatedPattern = nil
    }
    
    // MARK: - Private Helpers
    
    private func updatePhase(_ newPhase: GenerationPhase, progress: Double) {
        self.phase = newPhase
        self.progress = progress
        self.statusMessage = newPhase.description
    }
}
