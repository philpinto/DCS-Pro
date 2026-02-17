# DCS Pro Development Workflow

This workflow is designed for optimal Claude Code performance in Swift app development, emphasizing efficiency, safety, and tested architecture.

---

## 1. Task Intake & Classification

When receiving a task, I classify it to determine the appropriate approach:

- **Trivial**: 1-2 file changes, obvious implementation
  - → **Direct implementation**

- **Moderate**: New feature, multiple files, some unknowns
  - → **Explore first, then implement**

- **Complex**: Architectural decisions, multiple approaches possible
  - → **Use Plan agent for design**

## 2. Context Gathering

Context gathering is critical for preventing hallucination and understanding existing patterns:

- **Always use Explore agent** for "how does X work?" questions
- **Always read files before editing** - see actual code structure, never assume
- **Search before creating** - check if functionality already exists
- **Use DocumentationSearch** for Apple framework APIs beyond my training data

## 3. Implementation with Progressive Validation

### Task Tracking
- Use `TodoWrite` for multi-step tasks to track progress and provide visibility

### Validation Stages
Progressive validation catches errors early:

1. **After writing code**: `XcodeRefreshCodeIssuesInFile`
   - Catches ~80% of errors in seconds
   - Validates types, imports, syntax

2. **For UI work**: `RenderPreview`
   - Visual validation of SwiftUI views
   - Faster than full builds

3. **Before marking complete**: `BuildProject`
   - Full compilation validation
   - Ensures all files compile together

4. **For test targets**: `RunAllTests` or `RunSomeTests`
   - Validates functionality
   - Prevents regressions

## 4. Error Handling Philosophy

Clear decision framework for handling errors:

- **Attempt automatic fixes** for:
  - Syntax errors
  - Missing imports
  - Type mismatches
  - Common Swift compiler errors

- **Stop and report** for:
  - Architectural issues
  - Uncertain situations
  - Design decisions needed

- **Never silently fail**:
  - Always acknowledge errors
  - Show resolution approach
  - Report if unable to fix

## 5. Communication Pattern

Balance clarity with efficiency:

- **Show plan** with TodoWrite for non-trivial tasks
- **Work sequentially** through todos, marking progress in real-time
- **Explain significant decisions** but don't over-narrate routine operations
- **Use code references** in format `file_path:line_number` when discussing specific locations
- **Report results** clearly when tasks complete

## 6. Safety Principles

Core principles for safe, maintainable code:

- **Never force-unwrap** unless explicitly requested
- **Prefer Swift's type safety** and leverage the type system
- **Use async/await** over Combine framework
- **Follow Apple's latest patterns** - use DocumentationSearch when unsure
- **Validate work** before declaring it complete
- **Avoid over-engineering** - only implement what's requested
- **Delete unused code** completely - no backwards-compatibility hacks

## 7. Code Style Guidelines

Consistent with Apple's Swift conventions:

- **Naming**: PascalCase for types, camelCase for properties/methods
- **Properties**: `@State private var` for SwiftUI state, `let` for constants
- **Structure**: Conform views to `View` protocol, define UI in `body` property
- **Formatting**: 4-space indentation, clear method separation
- **Imports**: Simple imports at top (SwiftUI, Foundation)
- **Architecture**: Follow SwiftUI patterns with clear separation of concerns
- **Comments**: Add descriptive comments for complex logic or non-obvious code
- **Testing**: Use Testing framework for unit tests, XCUIAutomation for UI tests

## 8. Testing Requirements

Write tests after completing each phase to ensure quality and prevent regressions:

### Phase Testing Protocol
- **After each phase completion** - Write unit tests for new services and logic
- **Run all tests** before marking a phase complete
- **Tests must pass** before proceeding to next phase

### What to Test
- **Services**: Core business logic, state management, API interactions
- **ViewModels**: Data transformations, computed properties, actions
- **Utilities**: Helper functions, extensions, formatters
- **Color Algorithms**: RGB/CIELab conversion, color distance, DMC matching

### What NOT to Test (in unit tests)
- SwiftUI views directly (use previews and UI tests instead)
- Image file I/O (mock the services)
- Singleton initialization

### Test File Organization
```
DCS ProTests/
├── Services/
│   ├── ImageProcessingServiceTests.swift
│   ├── ColorMatchingServiceTests.swift
│   ├── PatternServiceTests.swift
│   └── ExportServiceTests.swift
├── Models/
│   ├── DMCThreadTests.swift
│   └── PatternTests.swift
└── Utilities/
    ├── ColorConversionTests.swift
    └── MedianCutTests.swift
```

### Testing Framework
- Use Swift Testing framework (`import Testing`)
- Use `@Test` attribute for test functions
- Use `#expect()` for assertions

---

## 9. Documentation Requirements

Maintain project documentation throughout development:

### Project-Level Documentation
- **PROJECT_PLAN.md** - Architecture, phased implementation plan, key decisions
- Update plan as phases complete or scope changes

### What to Document
- **Architectural decisions** - Why we chose specific patterns/approaches
- **Phase completions** - Mark phases done, note any deviations
- **Algorithm details** - Color quantization, matching approaches
- **Known limitations** - What doesn't work and why

### When to Document
- **Before starting complex work** - Document the plan first
- **After completing a phase** - Update status and learnings
- **When making significant decisions** - Record reasoning

### Documentation Location
- All project docs live in `:Claude/` folder
- Keep docs concise and actionable
- Avoid redundancy with code comments

---

## 10. DCS Pro Specific Guidelines

### Intel Mac Compatibility
- Target macOS 12.0+ (Monterey)
- Build Universal Binary for Intel + Apple Silicon
- Avoid Apple Silicon-only APIs
- Test on physical Intel Mac before each phase completion

### Image Processing
- Process large images on background threads
- Show progress for operations > 0.5 seconds
- Support common formats: PNG, JPEG, HEIC, TIFF

### Pattern Rendering
- Efficient grid rendering for patterns up to 500x500 stitches
- Smooth zoom/pan interactions
- Consider Metal for very large patterns if needed

### Color Accuracy
- Use CIELab color space for perceptual matching
- DMC database must be accurate - verify against official sources
- Allow user to fine-tune color matching if results look off

---

## Quick Reference: Agent Usage

- **Explore Agent**: Codebase exploration, understanding existing patterns
- **Plan Agent**: Complex feature planning, architectural decisions
- **Bash Agent**: Git operations, terminal commands
- **General-purpose Agent**: Multi-step research, complex searches

---

*This workflow evolves based on real development experience. Last updated: 2026-02-16*
