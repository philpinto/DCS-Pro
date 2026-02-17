//
//  ContentView.swift
//  DCS Pro
//
//  Main content view managing the application workflow
//

import SwiftUI

/// Main content view that manages navigation through the app workflow
struct ContentView: View {
    /// Current navigation state
    @State private var navigationState: NavigationState = .welcome
    
    /// View models for each step
    @State private var importViewModel = ImageImportViewModel()
    @State private var settingsViewModel = GenerationSettingsViewModel()
    @State private var generationViewModel = PatternGenerationViewModel()
    @State private var patternViewModel: PatternViewModel?
    @State private var editingViewModel: PatternEditingViewModel?
    @State private var exportViewModel = ExportViewModel()
    
    /// Recent projects manager
    private var recentProjectsManager = RecentProjectsManager.shared
    
    /// Imported image (passed between steps)
    @State private var sourceImage: NSImage?
    @State private var sourceImageData: Data?
    
    /// Generation settings (passed to generation step)
    @State private var generationSettings: GenerationSettings = .default
    
    /// Whether the export sheet is showing
    @State private var showingExportSheet = false
    
    /// Current project file URL (for save operations)
    @State private var currentProjectURL: URL?
    
    /// Whether the project has unsaved changes
    @State private var hasUnsavedChanges = false
    
    /// Error alert state
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Group {
            switch navigationState {
            case .welcome:
                WelcomeView(
                    recentProjects: recentProjectsManager.recentProjects,
                    onNewProject: { navigateTo(.import) },
                    onOpenProject: { openProject() },
                    onOpenRecentProject: { reference in
                        openProject(at: reference.path)
                    },
                    onRemoveRecentProject: { reference in
                        recentProjectsManager.removeRecentProject(id: reference.id)
                    }
                )
                
            case .import:
                ImageImportView(
                    viewModel: importViewModel,
                    onContinue: { image, url in
                        sourceImage = image
                        if let url = url {
                            sourceImageData = try? Data(contentsOf: url)
                        }
                        settingsViewModel.setSourceImage(image)
                        navigateTo(.settings)
                    },
                    onCancel: { navigateTo(.welcome) }
                )
                
            case .settings:
                if let image = sourceImage {
                    GenerationSettingsView(
                        viewModel: settingsViewModel,
                        sourceImage: image,
                        onGenerate: { settings in
                            generationSettings = settings
                            generationViewModel.reset()
                            navigateTo(.generating)
                        },
                        onBack: { navigateTo(.import) }
                    )
                }
                
            case .generating:
                if let image = sourceImage {
                    PatternGenerationView(
                        viewModel: generationViewModel,
                        sourceImage: image,
                        settings: generationSettings,
                        onComplete: { pattern in
                            patternViewModel = PatternViewModel(pattern: pattern)
                            editingViewModel = PatternEditingViewModel(pattern: pattern)
                            hasUnsavedChanges = true
                            navigateTo(.pattern)
                        },
                        onCancel: { navigateTo(.settings) }
                    )
                }
                
            case .pattern:
                if let viewModel = patternViewModel, let editVM = editingViewModel {
                    PatternView(
                        viewModel: viewModel,
                        editingViewModel: editVM,
                        onExport: { showingExportSheet = true },
                        onPatternChanged: { newPattern in
                            hasUnsavedChanges = true
                        }
                    )
                    .toolbar {
                        ToolbarItemGroup(placement: .navigation) {
                            Button(action: { startNewProject() }) {
                                Label("New Project", systemImage: "plus")
                            }
                            .help("New Project (⌘N)")
                            
                            Button(action: { openProject() }) {
                                Label("Open", systemImage: "folder")
                            }
                            .help("Open Project (⌘O)")
                        }
                        
                        ToolbarItemGroup(placement: .primaryAction) {
                            Button(action: { saveProject() }) {
                                Label("Save", systemImage: "square.and.arrow.down")
                            }
                            .help("Save Project (⌘S)")
                            
                            if currentProjectURL != nil {
                                Button(action: { saveProjectAs() }) {
                                    Label("Save As", systemImage: "square.and.arrow.down.on.square")
                                }
                                .help("Save As (⇧⌘S)")
                            }
                        }
                    }
                    .sheet(isPresented: $showingExportSheet) {
                        ExportView(
                            viewModel: exportViewModel,
                            pattern: viewModel.pattern,
                            onDismiss: { showingExportSheet = false }
                        )
                    }
                }
            
            case .export:
                if let viewModel = patternViewModel {
                    ExportView(
                        viewModel: exportViewModel,
                        pattern: viewModel.pattern,
                        onDismiss: { navigateTo(.pattern) }
                    )
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            recentProjectsManager.pruneInvalidReferences()
        }
    }
    
    // MARK: - Navigation
    
    private func navigateTo(_ state: NavigationState) {
        withAnimation(.easeInOut(duration: 0.2)) {
            navigationState = state
        }
    }
    
    private func startNewProject() {
        // Reset all state
        importViewModel = ImageImportViewModel()
        settingsViewModel = GenerationSettingsViewModel()
        generationViewModel = PatternGenerationViewModel()
        patternViewModel = nil
        editingViewModel = nil
        sourceImage = nil
        sourceImageData = nil
        generationSettings = .default
        currentProjectURL = nil
        hasUnsavedChanges = false
        
        navigateTo(.welcome)
    }
    
    // MARK: - Project Operations
    
    private func openProject() {
        do {
            if let result = try ProjectService.shared.loadWithDialog() {
                loadProject(result.project, from: result.url)
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func openProject(at url: URL) {
        do {
            let project = try ProjectService.shared.load(from: url)
            loadProject(project, from: url)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func loadProject(_ project: Project, from url: URL) {
        patternViewModel = PatternViewModel(pattern: project.pattern)
        editingViewModel = PatternEditingViewModel(pattern: project.pattern)
        generationSettings = project.settings
        currentProjectURL = url
        hasUnsavedChanges = false
        
        // Restore source image if available
        if let imageData = project.sourceImageData {
            sourceImage = NSImage(data: imageData)
            sourceImageData = imageData
        }
        
        // Add to recent projects
        recentProjectsManager.addRecentProject(project, at: url)
        
        navigateTo(.pattern)
    }
    
    private func saveProject() {
        guard let viewModel = patternViewModel else { return }
        
        if let url = currentProjectURL {
            // Save to existing location
            do {
                let project = createProject(from: viewModel.pattern)
                try ProjectService.shared.save(project: project, to: url)
                hasUnsavedChanges = false
                editingViewModel?.clearHistory()
                recentProjectsManager.addRecentProject(project, at: url)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        } else {
            // No existing location, show save dialog
            saveProjectAs()
        }
    }
    
    private func saveProjectAs() {
        guard let viewModel = patternViewModel else { return }
        
        do {
            let project = createProject(from: viewModel.pattern)
            if let url = try ProjectService.shared.saveWithDialog(project: project) {
                currentProjectURL = url
                hasUnsavedChanges = false
                editingViewModel?.clearHistory()
                recentProjectsManager.addRecentProject(project, at: url)
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func createProject(from pattern: Pattern) -> Project {
        Project(
            pattern: pattern,
            sourceImageData: sourceImageData,
            settings: generationSettings
        )
    }
}

// MARK: - Navigation State

enum NavigationState {
    case welcome
    case `import`
    case settings
    case generating
    case pattern
    case export
}

// MARK: - Welcome View

/// Initial welcome screen with options to create new or open existing project
struct WelcomeView: View {
    let recentProjects: [ProjectReference]
    let onNewProject: () -> Void
    let onOpenProject: () -> Void
    let onOpenRecentProject: (ProjectReference) -> Void
    let onRemoveRecentProject: (ProjectReference) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side: Branding and actions
            VStack(spacing: 32) {
                Spacer()
                
                // App icon/logo
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)
                
                // App name
                VStack(spacing: 8) {
                    Text("DCS Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Delaney's Cross Stitch Pro")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // Description
                Text("Convert your favorite photos into beautiful cross-stitch patterns")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onNewProject) {
                        Label("New Pattern", systemImage: "plus.circle.fill")
                            .frame(width: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button(action: onOpenProject) {
                        Label("Open Project", systemImage: "folder")
                            .frame(width: 200)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.top, 16)
                
                Spacer()
                
                // Footer
                VStack(spacing: 4) {
                    Text("Monkey Never Cramp")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Text("Version 1.0")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
                .padding(.bottom, 16)
            }
            .frame(minWidth: 400)
            
            // Right side: Recent projects
            if !recentProjects.isEmpty {
                Divider()
                
                RecentProjectsListView(
                    projects: recentProjects,
                    onOpen: onOpenRecentProject,
                    onRemove: onRemoveRecentProject
                )
                .frame(width: 300)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Recent Projects List

struct RecentProjectsListView: View {
    let projects: [ProjectReference]
    let onOpen: (ProjectReference) -> Void
    let onRemove: (ProjectReference) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Projects")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 16)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(projects) { project in
                        RecentProjectRow(
                            project: project,
                            onOpen: { onOpen(project) },
                            onRemove: { onRemove(project) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct RecentProjectRow: View {
    let project: ProjectReference
    let onOpen: () -> Void
    let onRemove: () -> Void
    
    @State private var isHovering = false
    
    private var thumbnail: NSImage? {
        RecentProjectsManager.shared.thumbnail(for: project)
    }
    
    private var fileExists: Bool {
        RecentProjectsManager.shared.projectExists(project)
    }
    
    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                // Thumbnail
                Group {
                    if let image = thumbnail {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(project.dimensions + " • " + "\(project.colorCount) colors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(formatDate(project.lastModified))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                // Remove button (shown on hover)
                if isHovering {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove from recent")
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .opacity(fileExists ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!fileExists)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Previews

#Preview("Welcome") {
    ContentView()
}

#Preview("Welcome with Recent") {
    let thread = DMCThread(
        id: "310",
        name: "Black",
        rgb: RGBColor(r: 0, g: 0, b: 0),
        lab: LabColor(l: 0, a: 0, b: 0)
    )
    let pattern = Pattern(
        width: 100,
        height: 150,
        stitches: [[nil]],
        palette: [PaletteEntry(thread: thread, symbol: PatternSymbol("●"), stitchCount: 1000)]
    )
    let project = Project(pattern: pattern)
    let reference = ProjectReference(
        from: project,
        path: URL(fileURLWithPath: "/test/Sample.dcspro")
    )
    
    return WelcomeView(
        recentProjects: [reference],
        onNewProject: { },
        onOpenProject: { },
        onOpenRecentProject: { _ in },
        onRemoveRecentProject: { _ in }
    )
}
