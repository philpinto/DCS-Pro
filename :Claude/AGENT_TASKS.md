# DCS Pro Agent Task Breakdown

This document defines all tasks broken down for autonomous agent execution. Each task includes clear acceptance criteria so agents know exactly when they're done.

---

## How to Use This Document

Each phase contains tasks that can be assigned to agents. Tasks are designed to be:

1. **Self-contained**: All context needed is in `TECHNICAL_SPEC.md`
2. **Testable**: Clear acceptance criteria define "done"
3. **Sequential within phase**: Tasks within a phase may have dependencies
4. **Parallel across groups**: Tasks in different groups can run simultaneously

### Task Format

```
### Task X.Y: [Name]
**Agent Type**: Plan | Explore | General-purpose | Bash
**Dependencies**: List of prerequisite tasks
**Estimated Complexity**: Low | Medium | High

**Description**: What needs to be done

**Acceptance Criteria**:
- [ ] Specific, verifiable criterion
- [ ] Another criterion

**Files to Create/Modify**:
- path/to/file.swift

**Reference**: TECHNICAL_SPEC.md Section X
```

---

## Phase 1: Foundation & Project Structure

### Task 1.1: Create Project Folder Structure
**Agent Type**: General-purpose
**Dependencies**: None
**Estimated Complexity**: Low

**Description**: Create the folder structure for the project in Xcode. Organize code into logical groups for maintainability.

**Folder Structure to Create**:
```
DCS Pro/
├── App/
│   ├── DCS_ProApp.swift (move existing)
│   └── AppState.swift
├── Models/
│   ├── Color/
│   │   ├── RGBColor.swift
│   │   ├── LabColor.swift
│   │   └── ColorConversion.swift
│   ├── Thread/
│   │   ├── DMCThread.swift
│   │   └── DMCDatabase.swift
│   ├── Pattern/
│   │   ├── Pattern.swift
│   │   ├── Stitch.swift
│   │   ├── PaletteEntry.swift
│   │   └── PatternSymbol.swift
│   ├── Project/
│   │   ├── Project.swift
│   │   └── GenerationSettings.swift
│   └── Errors/
│       └── AppErrors.swift
├── Services/
│   ├── ImageProcessing/
│   │   ├── ImageProcessingService.swift
│   │   └── MedianCutQuantizer.swift
│   ├── ColorMatching/
│   │   └── DMCColorMatcher.swift
│   ├── PatternGeneration/
│   │   └── PatternGenerationService.swift
│   ├── Export/
│   │   └── PDFExportService.swift
│   └── Project/
│       └── ProjectService.swift
├── Views/
│   ├── Main/
│   │   ├── ContentView.swift (modify existing)
│   │   └── MainWindowView.swift
│   ├── Welcome/
│   │   └── WelcomeView.swift
│   ├── Import/
│   │   └── ImageImportView.swift
│   ├── Generation/
│   │   ├── PatternGenerationView.swift
│   │   └── GenerationSettingsView.swift
│   ├── Pattern/
│   │   ├── PatternView.swift
│   │   ├── PatternGridView.swift
│   │   └── ColorPaletteView.swift
│   ├── Export/
│   │   └── ExportView.swift
│   └── Components/
│       ├── DropZoneView.swift
│       └── ProgressOverlayView.swift
├── ViewModels/
│   ├── ImageImportViewModel.swift
│   ├── PatternGenerationViewModel.swift
│   └── PatternViewModel.swift
└── Resources/
    └── dmc_colors.json
```

**Acceptance Criteria**:
- [ ] All folders created in Xcode project navigator
- [ ] Existing files moved to appropriate locations
- [ ] Project builds successfully after restructure
- [ ] No compiler warnings about file locations

**Reference**: TECHNICAL_SPEC.md Section 2 (Data Models)

---

### Task 1.2: Implement Color Types
**Agent Type**: General-purpose
**Dependencies**: Task 1.1
**Estimated Complexity**: Medium

**Description**: Implement `RGBColor`, `LabColor`, and color conversion functions exactly as specified in TECHNICAL_SPEC.md.

**Files to Create**:
- `DCS Pro/Models/Color/RGBColor.swift`
- `DCS Pro/Models/Color/LabColor.swift`
- `DCS Pro/Models/Color/ColorConversion.swift`

**Implementation Requirements**:
1. `RGBColor`: Struct with r, g, b as UInt8, Codable, Equatable, Hashable
2. `LabColor`: Struct with l, a, b as Double, Codable, Equatable
3. RGB to XYZ conversion with sRGB gamma correction
4. XYZ to Lab conversion with D65 illuminant
5. Delta E (CIE76) calculation
6. Delta E (CIE94) calculation with textiles weighting
7. Hex string initializer for RGBColor

**Acceptance Criteria**:
- [ ] All types compile without errors
- [ ] RGBColor can be initialized from hex string "#FF5733"
- [ ] Black RGB(0,0,0) converts to Lab(0,0,0) within 0.1 tolerance
- [ ] White RGB(255,255,255) converts to Lab(100,0,0) within 0.5 tolerance
- [ ] Delta E of identical colors equals 0
- [ ] All types conform to Codable

**Reference**: TECHNICAL_SPEC.md Section 3 (Color Algorithms)

---

### Task 1.3: Create DMC Database Resource File
**Agent Type**: General-purpose
**Dependencies**: None
**Estimated Complexity**: Medium

**Description**: Create a complete DMC thread color database as a JSON resource file. This requires researching and compiling accurate RGB values for all ~489 DMC floss colors.

**File to Create**:
- `DCS Pro/Resources/dmc_colors.json`

**Data Format**:
```json
{
  "version": "1.0",
  "lastUpdated": "2026-02-16",
  "threads": [
    {"id": "BLANC", "name": "White", "rgb": {"r": 255, "g": 255, "b": 255}},
    {"id": "ECRU", "name": "Ecru", "rgb": {"r": 240, "g": 234, "b": 218}},
    {"id": "310", "name": "Black", "rgb": {"r": 0, "g": 0, "b": 0}},
    // ... continue for all colors
  ]
}
```

**Sources to Reference** (for RGB values):
- https://threadcolors.com/
- https://lordlibidan.com/dmc-color-chart/
- https://dmc.crazyartzone.com/

**Priority Colors** (verify these are accurate):
- BLANC, ECRU, 310 (Black), 3865 (Winter White)
- Skin tones: 948, 754, 3770, 945, 951, 3774, 950, 3064, 407
- Skin tones dark: 3862, 3031, 3781, 839, 838

**Acceptance Criteria**:
- [ ] JSON file is valid and parseable
- [ ] Contains at least 450 DMC thread entries
- [ ] Each entry has id, name, and rgb fields
- [ ] RGB values are UInt8 (0-255)
- [ ] BLANC maps to pure white (255, 255, 255)
- [ ] 310 maps to black (0, 0, 0)
- [ ] File is added to Xcode project bundle resources

**Reference**: TECHNICAL_SPEC.md Section 4 (DMC Thread Database)

---

### Task 1.4: Implement DMC Database Loading
**Agent Type**: General-purpose
**Dependencies**: Tasks 1.2, 1.3
**Estimated Complexity**: Medium

**Description**: Implement `DMCThread` model and `DMCDatabase` singleton that loads the JSON database and provides thread lookup functionality.

**Files to Create**:
- `DCS Pro/Models/Thread/DMCThread.swift`
- `DCS Pro/Models/Thread/DMCDatabase.swift`

**Implementation Requirements**:
1. `DMCThread` struct with id, name, rgb, and pre-computed lab values
2. `DMCDatabase` singleton that loads from bundle
3. Thread lookup by ID
4. Search by name or ID substring
5. Skein estimation function (400 stitches per skein baseline)

**Acceptance Criteria**:
- [ ] DMCDatabase.shared loads successfully
- [ ] `threads` property returns all loaded threads
- [ ] `thread(byID: "310")` returns black thread
- [ ] `thread(byID: "BLANC")` returns white thread
- [ ] `search(query: "black")` returns thread 310
- [ ] Each loaded thread has valid Lab values pre-computed
- [ ] App doesn't crash if database is missing (graceful error)

**Reference**: TECHNICAL_SPEC.md Section 4 (DMC Thread Database)

---

### Task 1.5: Implement Pattern Data Models
**Agent Type**: General-purpose
**Dependencies**: Tasks 1.2, 1.4
**Estimated Complexity**: Medium

**Description**: Implement all pattern-related data models as specified.

**Files to Create**:
- `DCS Pro/Models/Pattern/StitchType.swift`
- `DCS Pro/Models/Pattern/Stitch.swift`
- `DCS Pro/Models/Pattern/PatternSymbol.swift`
- `DCS Pro/Models/Pattern/PaletteEntry.swift`
- `DCS Pro/Models/Pattern/PatternMetadata.swift`
- `DCS Pro/Models/Pattern/Pattern.swift`

**Implementation Requirements**:
1. `StitchType` enum with all stitch types
2. `Stitch` struct with thread, type, isCompleted
3. `PatternSymbol` with character and available symbols array
4. `PaletteEntry` with thread, symbol, stitchCount
5. `PatternMetadata` with name, author, dates, notes
6. `Pattern` with all properties and computed values

**Pattern Computed Properties**:
- `totalStitchCount`: Count of non-nil stitches
- `completedStitchCount`: Count of completed stitches
- `progressPercentage`: Percentage complete
- `finishedSize(fabricCount:)`: Returns size in inches
- `stitch(at:)` and `setStitch(_:at:)` accessors
- `positions(for:)`: All positions for a thread

**Acceptance Criteria**:
- [ ] All types compile and conform to Codable
- [ ] Pattern can be created with specified dimensions
- [ ] Stitch accessors work correctly with bounds checking
- [ ] Progress percentage calculates correctly
- [ ] Finished size calculation is accurate (width/fabricCount)
- [ ] 50+ symbols available in PatternSymbol.availableSymbols

**Reference**: TECHNICAL_SPEC.md Section 2 (Data Models)

---

### Task 1.6: Implement Project and Settings Models
**Agent Type**: General-purpose
**Dependencies**: Task 1.5
**Estimated Complexity**: Low

**Description**: Implement project wrapper and generation settings models.

**Files to Create**:
- `DCS Pro/Models/Project/GenerationSettings.swift`
- `DCS Pro/Models/Project/Project.swift`

**Implementation Requirements**:
1. `GenerationSettings` with all fields and defaults
2. `ColorMatchingMethod` enum
3. Static presets: `.default` and `.portrait`
4. `Project` wrapper with pattern, settings, dates
5. File extension constant

**Acceptance Criteria**:
- [ ] GenerationSettings.default has sensible values
- [ ] GenerationSettings.portrait optimized for portraits
- [ ] Project can hold pattern and optional source image
- [ ] Project.fileExtension equals "dcspro"
- [ ] All types are Codable

**Reference**: TECHNICAL_SPEC.md Section 2 (Data Models)

---

### Task 1.7: Implement AppState and Error Types
**Agent Type**: General-purpose
**Dependencies**: Task 1.6
**Estimated Complexity**: Low

**Description**: Implement the main application state manager and custom error types.

**Files to Create**:
- `DCS Pro/App/AppState.swift`
- `DCS Pro/Models/Errors/AppErrors.swift`

**Implementation Requirements**:
1. `AppState` as @Observable class
2. Navigation state enum
3. Current project, processing state, errors
4. Custom error types for pattern, project, export operations

**Acceptance Criteria**:
- [ ] AppState can be instantiated
- [ ] Navigation view state can be changed
- [ ] Error types have localized descriptions
- [ ] AppState can hold current project

**Reference**: TECHNICAL_SPEC.md Section 2 (View Models)

---

### Task 1.8: Write Phase 1 Unit Tests
**Agent Type**: General-purpose
**Dependencies**: Tasks 1.2-1.7
**Estimated Complexity**: Medium

**Description**: Write comprehensive unit tests for all Phase 1 models and utilities.

**Files to Create**:
- `DCS ProTests/Models/RGBColorTests.swift`
- `DCS ProTests/Models/LabColorTests.swift`
- `DCS ProTests/Models/ColorConversionTests.swift`
- `DCS ProTests/Models/DMCDatabaseTests.swift`
- `DCS ProTests/Models/PatternTests.swift`

**Test Cases Required**:
- RGB to Lab conversion (black, white, primary colors)
- Delta E calculations (identical, similar, different colors)
- DMC database loading and lookup
- Pattern creation and accessors
- Progress calculation

**Acceptance Criteria**:
- [ ] All tests pass
- [ ] Color conversion tests match TECHNICAL_SPEC examples
- [ ] DMC lookup tests verify key colors (310, BLANC)
- [ ] Pattern tests cover all computed properties
- [ ] Code coverage > 80% for model classes

**Reference**: TECHNICAL_SPEC.md Section 9 (Test Specifications)

---

### Task 1.9: Build and Validate Phase 1
**Agent Type**: General-purpose
**Dependencies**: Tasks 1.1-1.8
**Estimated Complexity**: Low

**Description**: Ensure all Phase 1 code compiles, tests pass, and works on both Intel and Apple Silicon.

**Acceptance Criteria**:
- [ ] Project builds without errors or warnings
- [ ] All unit tests pass
- [ ] App launches successfully
- [ ] No runtime crashes when accessing DMCDatabase.shared
- [ ] Builds as Universal Binary

---

## Phase 2: Image Processing & Pattern Generation Engine

### Task 2.1: Implement Median Cut Quantizer
**Agent Type**: General-purpose
**Dependencies**: Phase 1 complete
**Estimated Complexity**: High

**Description**: Implement the median cut color quantization algorithm as specified.

**Files to Create**:
- `DCS Pro/Services/ImageProcessing/MedianCutQuantizer.swift`

**Implementation Requirements**:
1. `ColorBucket` struct with pixel storage
2. Channel range calculation
3. Bucket splitting at median
4. Average color calculation
5. Main `quantize(pixels:targetColorCount:)` function
6. Handle power-of-2 color counts

**Acceptance Criteria**:
- [ ] Returns correct number of colors (power of 2)
- [ ] Handles single-color input without crashing
- [ ] Produces distinct colors for varied input
- [ ] Preserves dominant colors from input
- [ ] Performance: < 2 seconds for 500x500 image

**Reference**: TECHNICAL_SPEC.md Section 3 (Median Cut)

---

### Task 2.2: Implement DMC Color Matcher
**Agent Type**: General-purpose
**Dependencies**: Task 2.1
**Estimated Complexity**: Medium

**Description**: Implement the DMC color matching service.

**Files to Create**:
- `DCS Pro/Services/ColorMatching/DMCColorMatcher.swift`

**Implementation Requirements**:
1. `closestThread(to:method:)` - find nearest DMC thread
2. Support CIELab, CIE94, and RGB distance methods
3. `matchPalette(quantizedColors:preferUnique:)` - match multiple colors
4. Unique palette matching to avoid duplicates

**Acceptance Criteria**:
- [ ] Black RGB matches DMC 310
- [ ] White RGB matches BLANC or 3865
- [ ] CIELab method produces better results than RGB for skin tones
- [ ] Unique matching avoids duplicate threads when possible
- [ ] All three matching methods work correctly

**Reference**: TECHNICAL_SPEC.md Section 3 (DMC Color Matching)

---

### Task 2.3: Implement Image Processing Service
**Agent Type**: General-purpose
**Dependencies**: Task 2.2
**Estimated Complexity**: Medium

**Description**: Implement image resizing and pixel extraction.

**Files to Create**:
- `DCS Pro/Services/ImageProcessing/ImageProcessingService.swift`

**Implementation Requirements**:
1. `resizeImage(_:to:)` - resize NSImage to target dimensions
2. `extractPixels(from:)` - get RGB values from image
3. High-quality interpolation for resize
4. Handle various image formats (PNG, JPEG, HEIC)

**Acceptance Criteria**:
- [ ] Resize produces correct dimensions
- [ ] Pixel extraction returns correct array size
- [ ] Maintains image quality during resize
- [ ] Handles images with alpha channel
- [ ] Works with common formats

**Reference**: TECHNICAL_SPEC.md Section 5 (Image Processing Pipeline)

---

### Task 2.4: Implement Pattern Generation Service
**Agent Type**: General-purpose
**Dependencies**: Tasks 2.1-2.3
**Estimated Complexity**: High

**Description**: Implement the complete pattern generation pipeline.

**Files to Create**:
- `DCS Pro/Services/PatternGeneration/PatternGenerationService.swift`

**Implementation Requirements**:
1. `generatePattern(from:settings:progress:)` async function
2. Progress reporting during generation
3. Full pipeline: resize → extract → quantize → match → map → build
4. Palette entry generation with symbols and counts
5. Error handling for all failure modes

**Acceptance Criteria**:
- [ ] Generates valid pattern from test image
- [ ] Progress callback fires at each stage
- [ ] Pattern dimensions match settings
- [ ] Color count ≤ maxColors setting
- [ ] All stitches have valid DMC threads
- [ ] Palette entries have unique symbols
- [ ] Stitch counts in palette are accurate

**Reference**: TECHNICAL_SPEC.md Section 5 (Image Processing Pipeline)

---

### Task 2.5: Write Phase 2 Unit Tests
**Agent Type**: General-purpose
**Dependencies**: Tasks 2.1-2.4
**Estimated Complexity**: Medium

**Description**: Write comprehensive tests for all Phase 2 services.

**Files to Create**:
- `DCS ProTests/Services/MedianCutQuantizerTests.swift`
- `DCS ProTests/Services/DMCColorMatcherTests.swift`
- `DCS ProTests/Services/PatternGenerationServiceTests.swift`

**Test Cases**:
- Quantizer: color count, single color, distinct colors
- Matcher: black match, white match, unique palette
- Generation: full pipeline, dimensions, color limits

**Acceptance Criteria**:
- [ ] All tests pass
- [ ] Integration test for full pipeline
- [ ] Performance test for large images
- [ ] Edge cases covered (tiny images, single color)

**Reference**: TECHNICAL_SPEC.md Section 9 (Test Specifications)

---

### Task 2.6: Build and Validate Phase 2
**Agent Type**: General-purpose
**Dependencies**: Tasks 2.1-2.5
**Estimated Complexity**: Low

**Description**: Ensure Phase 2 code compiles, tests pass, and pattern generation works end-to-end.

**Acceptance Criteria**:
- [ ] All tests pass
- [ ] Can generate pattern from sample image
- [ ] Pattern has expected dimensions and colors
- [ ] No memory leaks during generation
- [ ] Works on Intel and Apple Silicon

---

## Phase 3: Pattern Visualization UI

### Task 3.1: Implement Pattern Grid View
**Agent Type**: General-purpose
**Dependencies**: Phase 2 complete
**Estimated Complexity**: High

**Description**: Implement the main pattern grid visualization with zoom and pan.

**Files to Create**:
- `DCS Pro/Views/Pattern/PatternGridView.swift`

**Implementation Requirements**:
1. Render pattern as grid of colored squares
2. Show symbols on each cell
3. Bold grid lines every 10 stitches
4. Smooth zoom (0.25x to 4x)
5. Pan with drag gesture
6. Efficient rendering (only visible cells)

**Acceptance Criteria**:
- [ ] Pattern renders correctly
- [ ] Zoom works smoothly
- [ ] Pan works with trackpad/mouse
- [ ] 10x10 grid lines visible
- [ ] Symbols render clearly at all zoom levels
- [ ] Performance: smooth at 300x400 pattern

**Reference**: TECHNICAL_SPEC.md Section 7 (UI/UX - Pattern View)

---

### Task 3.2: Implement Color Palette Panel
**Agent Type**: General-purpose
**Dependencies**: Task 3.1
**Estimated Complexity**: Medium

**Description**: Implement the color legend panel showing all pattern colors.

**Files to Create**:
- `DCS Pro/Views/Pattern/ColorPaletteView.swift`

**Implementation Requirements**:
1. List all colors with symbol, DMC code, name
2. Color swatch display
3. Stitch count per color
4. Selection highlight
5. Click to filter pattern by color

**Acceptance Criteria**:
- [ ] All palette colors displayed
- [ ] Symbols match pattern grid
- [ ] Stitch counts accurate
- [ ] Clicking highlights in grid
- [ ] Scrollable for many colors

**Reference**: TECHNICAL_SPEC.md Section 7 (UI/UX - Pattern View)

---

### Task 3.3: Implement Pattern View Container
**Agent Type**: General-purpose
**Dependencies**: Tasks 3.1, 3.2
**Estimated Complexity**: Medium

**Description**: Implement the container view that combines grid and palette with toolbar.

**Files to Create**:
- `DCS Pro/Views/Pattern/PatternView.swift`
- `DCS Pro/ViewModels/PatternViewModel.swift`

**Implementation Requirements**:
1. Toolbar with zoom controls
2. Toggle buttons for grid/symbols/colors
3. Pattern info display (dimensions, colors, stitches)
4. Split view: grid + color panel
5. Keyboard shortcuts for zoom

**Acceptance Criteria**:
- [ ] All toolbar controls work
- [ ] Toggles affect grid display
- [ ] Pattern info accurate
- [ ] Resizable split view
- [ ] Keyboard shortcuts functional

**Reference**: TECHNICAL_SPEC.md Section 7 (UI/UX - Pattern View)

---

### Task 3.4: Write Phase 3 UI Tests
**Agent Type**: General-purpose
**Dependencies**: Tasks 3.1-3.3
**Estimated Complexity**: Medium

**Description**: Write UI tests for pattern visualization.

**Files to Create**:
- `DCS ProUITests/PatternViewUITests.swift`

**Test Cases**:
- Pattern loads and displays
- Zoom controls work
- Toggle buttons function
- Color selection highlights

**Acceptance Criteria**:
- [ ] All UI tests pass
- [ ] Tests cover main interactions
- [ ] No crashes during tests

---

## Phase 4: Image Import & Generation UI

### Task 4.1: Implement Image Import View
**Agent Type**: General-purpose
**Dependencies**: Phase 3 complete
**Estimated Complexity**: Medium

**Description**: Implement drag-drop image import and file picker.

**Files to Create**:
- `DCS Pro/Views/Import/ImageImportView.swift`
- `DCS Pro/Views/Components/DropZoneView.swift`
- `DCS Pro/ViewModels/ImageImportViewModel.swift`

**Implementation Requirements**:
1. Drag-drop zone with visual feedback
2. File picker button
3. Image preview after selection
4. Image info display (dimensions, size, format)
5. Support PNG, JPEG, HEIC, TIFF

**Acceptance Criteria**:
- [ ] Drag-drop works with image files
- [ ] File picker opens and selects images
- [ ] Preview shows selected image
- [ ] Image info displays correctly
- [ ] Invalid files rejected with message

**Reference**: TECHNICAL_SPEC.md Section 7 (UI/UX - Welcome/Import View)

---

### Task 4.2: Implement Generation Settings View
**Agent Type**: General-purpose
**Dependencies**: Task 4.1
**Estimated Complexity**: Medium

**Description**: Implement the pattern generation settings UI.

**Files to Create**:
- `DCS Pro/Views/Generation/GenerationSettingsView.swift`

**Implementation Requirements**:
1. Width/height stitch count inputs
2. Aspect ratio lock toggle
3. Color count slider (5-50)
4. Color matching method picker
5. Dither toggle
6. Finished size preview

**Acceptance Criteria**:
- [ ] All controls work correctly
- [ ] Aspect ratio lock functions
- [ ] Finished size updates in real-time
- [ ] Settings bind to view model
- [ ] Presets (default, portrait) work

**Reference**: TECHNICAL_SPEC.md Section 7 (UI/UX - Generation View)

---

### Task 4.3: Implement Pattern Generation View
**Agent Type**: General-purpose
**Dependencies**: Tasks 4.1, 4.2
**Estimated Complexity**: High

**Description**: Implement the full generation view with preview.

**Files to Create**:
- `DCS Pro/Views/Generation/PatternGenerationView.swift`
- `DCS Pro/ViewModels/PatternGenerationViewModel.swift`
- `DCS Pro/Views/Components/ProgressOverlayView.swift`

**Implementation Requirements**:
1. Side-by-side source image and preview
2. Real-time preview updates (debounced)
3. Generate button
4. Progress overlay during generation
5. Error display
6. Transition to pattern view on complete

**Acceptance Criteria**:
- [ ] Source image displays
- [ ] Preview updates with settings
- [ ] Generation shows progress
- [ ] Errors display clearly
- [ ] Smooth transition to pattern view

**Reference**: TECHNICAL_SPEC.md Section 7 (UI/UX - Generation View)

---

### Task 4.4: Implement Welcome View
**Agent Type**: General-purpose
**Dependencies**: Tasks 4.1-4.3
**Estimated Complexity**: Low

**Description**: Implement the welcome/start screen.

**Files to Create**:
- `DCS Pro/Views/Welcome/WelcomeView.swift`

**Implementation Requirements**:
1. App branding/title
2. Drag-drop zone for quick start
3. Recent projects list
4. "Choose Image" button

**Acceptance Criteria**:
- [ ] Welcome screen displays on launch
- [ ] Drop zone works
- [ ] Recent projects show (if any)
- [ ] Navigation to import works

**Reference**: TECHNICAL_SPEC.md Section 7 (UI/UX - Welcome/Import View)

---

### Task 4.5: Implement Main Window Navigation
**Agent Type**: General-purpose
**Dependencies**: Tasks 4.1-4.4
**Estimated Complexity**: Medium

**Description**: Implement the main window with sidebar navigation.

**Files to Create**:
- `DCS Pro/Views/Main/MainWindowView.swift`
- Modify `DCS Pro/Views/Main/ContentView.swift`
- Modify `DCS Pro/App/DCS_ProApp.swift`

**Implementation Requirements**:
1. Sidebar with navigation icons
2. Main content area switching
3. Status bar at bottom
4. Window sizing and constraints
5. App menu integration

**Acceptance Criteria**:
- [ ] Sidebar navigation works
- [ ] Views switch correctly
- [ ] Status bar shows current state
- [ ] Window remembers size
- [ ] Menu items functional

**Reference**: TECHNICAL_SPEC.md Section 7 (UI/UX - App Window Structure)

---

### Task 4.6: Write Phase 4 Tests
**Agent Type**: General-purpose
**Dependencies**: Tasks 4.1-4.5
**Estimated Complexity**: Medium

**Description**: Write UI and unit tests for Phase 4.

**Acceptance Criteria**:
- [ ] All tests pass
- [ ] Import flow tested
- [ ] Generation flow tested
- [ ] Navigation tested

---

## Phase 5: PDF Export

### Task 5.1: Implement PDF Document Structure
**Agent Type**: General-purpose
**Dependencies**: Phase 4 complete
**Estimated Complexity**: High

**Description**: Implement PDF generation with all required pages.

**Files to Create**:
- `DCS Pro/Services/Export/PDFExportService.swift`

**Implementation Requirements**:
1. Cover page with preview and info
2. Thread list page with quantities
3. Color legend page with symbols
4. Paginated pattern grid
5. Page headers/footers
6. Support multiple page sizes

**Acceptance Criteria**:
- [ ] PDF generates without errors
- [ ] All page types render correctly
- [ ] Pattern grid paginates properly
- [ ] Symbols legible in PDF
- [ ] File size reasonable

**Reference**: TECHNICAL_SPEC.md Section 6 (PDF Export Specification)

---

### Task 5.2: Implement Export View
**Agent Type**: General-purpose
**Dependencies**: Task 5.1
**Estimated Complexity**: Medium

**Description**: Implement the export settings UI.

**Files to Create**:
- `DCS Pro/Views/Export/ExportView.swift`

**Implementation Requirements**:
1. Format selection
2. PDF options (page size, includes)
3. Preview page count
4. Export button with file picker
5. Progress during export

**Acceptance Criteria**:
- [ ] All options work
- [ ] Page count preview accurate
- [ ] Export saves to chosen location
- [ ] Progress shows for large patterns

**Reference**: TECHNICAL_SPEC.md Section 7 (UI/UX - Export View)

---

### Task 5.3: Write Phase 5 Tests
**Agent Type**: General-purpose
**Dependencies**: Tasks 5.1-5.2
**Estimated Complexity**: Medium

**Description**: Test PDF export functionality.

**Acceptance Criteria**:
- [ ] PDF generates from test pattern
- [ ] Page count correct
- [ ] No crashes during export

---

## Phase 6: Project Persistence

### Task 6.1: Implement Project File Format
**Agent Type**: General-purpose
**Dependencies**: Phase 5 complete
**Estimated Complexity**: Medium

**Description**: Implement saving and loading projects.

**Files to Create**:
- `DCS Pro/Services/Project/ProjectService.swift`

**Implementation Requirements**:
1. ZIP-based file format
2. Manifest, pattern, settings files
3. Optional source image storage
4. Thumbnail generation
5. Version compatibility checking

**Acceptance Criteria**:
- [ ] Projects save correctly
- [ ] Projects load correctly
- [ ] Source image preserved
- [ ] Thumbnail generates
- [ ] Old versions handled gracefully

**Reference**: TECHNICAL_SPEC.md Section 8 (File Formats)

---

### Task 6.2: Implement Recent Projects
**Agent Type**: General-purpose
**Dependencies**: Task 6.1
**Estimated Complexity**: Low

**Description**: Track and display recent projects.

**Implementation Requirements**:
1. Store recent project references
2. Display in welcome view
3. Quick open from list
4. Handle missing files gracefully

**Acceptance Criteria**:
- [ ] Recent list populates
- [ ] Opening from list works
- [ ] Missing files handled
- [ ] List persists across launches

---

### Task 6.3: Implement Auto-Save
**Agent Type**: General-purpose
**Dependencies**: Task 6.2
**Estimated Complexity**: Medium

**Description**: Implement auto-save and unsaved changes handling.

**Implementation Requirements**:
1. Auto-save drafts periodically
2. Detect unsaved changes
3. Prompt on close with unsaved
4. Recover from auto-save

**Acceptance Criteria**:
- [ ] Changes trigger dirty flag
- [ ] Auto-save occurs periodically
- [ ] Close prompts to save
- [ ] Recovery works after crash

---

## Phase 7: Pattern Editing

### Task 7.1: Implement Stitch Editing
**Agent Type**: General-purpose
**Dependencies**: Phase 6 complete
**Estimated Complexity**: High

**Description**: Implement click-to-edit stitch color.

**Implementation Requirements**:
1. Click stitch to select
2. Color picker to change
3. Paint tool for multiple stitches
4. Fill tool for areas
5. Eraser tool

**Acceptance Criteria**:
- [ ] Click editing works
- [ ] Paint tool works
- [ ] Fill tool works
- [ ] Eraser clears stitches

---

### Task 7.2: Implement Undo/Redo
**Agent Type**: General-purpose
**Dependencies**: Task 7.1
**Estimated Complexity**: Medium

**Description**: Implement undo/redo system.

**Implementation Requirements**:
1. Track all edits
2. Unlimited undo
3. Keyboard shortcuts (Cmd+Z, Cmd+Shift+Z)
4. Clear history on save

**Acceptance Criteria**:
- [ ] Undo reverses edits
- [ ] Redo restores edits
- [ ] Shortcuts work
- [ ] History clears appropriately

---

## Phase 8: Progress Tracking

### Task 8.1: Implement Progress Marking
**Agent Type**: General-purpose
**Dependencies**: Phase 7 complete
**Estimated Complexity**: Medium

**Description**: Implement marking stitches as complete.

**Implementation Requirements**:
1. Click to mark complete
2. Visual dimming of complete stitches
3. Progress statistics
4. Filter to show remaining only
5. Persist progress in project

**Acceptance Criteria**:
- [ ] Marking works
- [ ] Visual feedback clear
- [ ] Stats update correctly
- [ ] Progress saves with project

---

## Phase 9: Polish & Personalization

### Task 9.1: App Icon and Branding
**Agent Type**: General-purpose
**Dependencies**: Phase 8 complete
**Estimated Complexity**: Low

**Description**: Create app icon and About screen.

**Implementation Requirements**:
1. App icon (multiple sizes)
2. About screen with dedication to Delaney
3. Version info

**Acceptance Criteria**:
- [ ] Icon displays in Dock
- [ ] About screen shows
- [ ] Dedication text present

---

### Task 9.2: Touch Bar Support
**Agent Type**: General-purpose
**Dependencies**: Task 9.1
**Estimated Complexity**: Medium

**Description**: Implement Touch Bar controls for her MacBook Pro.

**Implementation Requirements**:
1. Contextual Touch Bar per view
2. Pattern view: zoom, toggles
3. Generation view: sliders, generate button
4. Test on physical Touch Bar Mac

**Acceptance Criteria**:
- [ ] Touch Bar shows controls
- [ ] Controls functional
- [ ] Works on Intel Mac with Touch Bar

---

### Task 9.3: Keyboard Shortcuts
**Agent Type**: General-purpose
**Dependencies**: Task 9.2
**Estimated Complexity**: Low

**Description**: Implement comprehensive keyboard shortcuts.

**Implementation Requirements**:
1. Standard macOS shortcuts
2. Custom app shortcuts
3. Menu items show shortcuts
4. Help > Keyboard Shortcuts list

**Acceptance Criteria**:
- [ ] All shortcuts work
- [ ] Menu shows shortcuts
- [ ] No conflicts with system

---

### Task 9.4: Final Testing and Optimization
**Agent Type**: General-purpose
**Dependencies**: Tasks 9.1-9.3
**Estimated Complexity**: Medium

**Description**: Final testing, optimization, and bug fixes.

**Acceptance Criteria**:
- [ ] All features work on Intel Mac
- [ ] All features work on Apple Silicon
- [ ] No memory leaks
- [ ] Performance acceptable for large patterns
- [ ] All tests pass
- [ ] No compiler warnings

---

## Appendix: Agent Execution Commands

### Running a Phase

To execute an entire phase, use prompts like:

```
Execute Phase 1 of DCS Pro development.
Reference: :Claude/TECHNICAL_SPEC.md and :Claude/AGENT_TASKS.md
Complete all tasks 1.1 through 1.9 in order.
Validate with build and tests before marking phase complete.
```

### Running Individual Tasks

```
Execute Task 2.1 (Implement Median Cut Quantizer) for DCS Pro.
Reference: :Claude/TECHNICAL_SPEC.md Section 3 for algorithm details.
Reference: :Claude/AGENT_TASKS.md for acceptance criteria.
Create the file and ensure it compiles.
```

### Running Tests

```
Run all unit tests for DCS Pro and report results.
Fix any failing tests.
```

---

*Document Version: 1.0 | Last Updated: 2026-02-16*
