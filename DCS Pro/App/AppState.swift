import SwiftUI

/// Main application state manager
@Observable
class AppState {
    // MARK: - Current Project
    var currentProject: Project?
    var hasUnsavedChanges: Bool = false
    
    // MARK: - Recent Projects
    var recentProjects: [ProjectReference] = []
    
    // MARK: - Processing State
    var isProcessing: Bool = false
    var processingProgress: Double = 0
    var processingMessage: String = ""
    
    // MARK: - Error State
    var currentError: Error?
    var showError: Bool = false
    
    // MARK: - Navigation
    var selectedView: NavigationView = .welcome
    
    enum NavigationView: String, CaseIterable {
        case welcome = "Welcome"
        case imageImport = "Import"
        case patternGeneration = "Generate"
        case patternView = "Pattern"
        case export = "Export"
        
        var systemImage: String {
            switch self {
            case .welcome: return "house"
            case .imageImport: return "photo"
            case .patternGeneration: return "wand.and.stars"
            case .patternView: return "square.grid.3x3"
            case .export: return "square.and.arrow.up"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        loadRecentProjects()
    }
    
    // MARK: - Project Management
    
    func newProject(pattern: Pattern, settings: GenerationSettings, sourceImageData: Data? = nil) {
        currentProject = Project(
            pattern: pattern,
            sourceImageData: sourceImageData,
            settings: settings
        )
        hasUnsavedChanges = true
        selectedView = .patternView
    }
    
    func closeProject() {
        currentProject = nil
        hasUnsavedChanges = false
        selectedView = .welcome
    }
    
    func markAsChanged() {
        hasUnsavedChanges = true
        currentProject?.touch()
    }
    
    // MARK: - Error Handling
    
    func showError(_ error: Error) {
        currentError = error
        showError = true
    }
    
    func clearError() {
        currentError = nil
        showError = false
    }
    
    // MARK: - Processing State
    
    func startProcessing(message: String = "Processing...") {
        isProcessing = true
        processingProgress = 0
        processingMessage = message
    }
    
    func updateProgress(_ progress: Double, message: String? = nil) {
        processingProgress = progress
        if let message = message {
            processingMessage = message
        }
    }
    
    func finishProcessing() {
        isProcessing = false
        processingProgress = 1.0
        processingMessage = ""
    }
    
    // MARK: - Recent Projects
    
    private func loadRecentProjects() {
        // TODO: Load from UserDefaults
    }
    
    func addToRecentProjects(_ reference: ProjectReference) {
        // Remove existing entry with same ID
        recentProjects.removeAll { $0.id == reference.id }
        // Add to front
        recentProjects.insert(reference, at: 0)
        // Keep only last 10
        if recentProjects.count > 10 {
            recentProjects = Array(recentProjects.prefix(10))
        }
        // TODO: Save to UserDefaults
    }
}
