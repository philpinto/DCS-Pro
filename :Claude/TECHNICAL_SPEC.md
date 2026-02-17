# DCS Pro Technical Specification

This document provides the complete technical specification for implementing DCS Pro. It is designed to be self-contained so that agents can implement features autonomously without additional research.

---

## Table of Contents

1. [Domain Knowledge](#1-domain-knowledge)
2. [Data Models](#2-data-models)
3. [Color Algorithms](#3-color-algorithms)
4. [DMC Thread Database](#4-dmc-thread-database)
5. [Image Processing Pipeline](#5-image-processing-pipeline)
6. [PDF Export Specification](#6-pdf-export-specification)
7. [UI/UX Design](#7-uiux-design)
8. [File Formats](#8-file-formats)
9. [Test Specifications](#9-test-specifications)

---

## 1. Domain Knowledge

### Cross-Stitch Fundamentals

**What is Cross-Stitch?**
Cross-stitch is a form of counted-thread embroidery where X-shaped stitches are made on fabric with an even, grid-like weave. Each stitch corresponds to one cell in a pattern grid.

**Key Terms:**
- **Stitch**: A single X-shaped mark on fabric, corresponds to one pixel in a pattern
- **Floss/Thread**: Embroidery thread (typically DMC brand), usually 6 strands that can be separated
- **Fabric Count**: Number of squares (stitches) per inch. Common counts: 14, 16, 18
- **Aida**: Most common cross-stitch fabric with visible grid holes
- **Full Coverage**: Pattern where every grid square has a stitch (no blank fabric showing)
- **Chart/Pattern**: Grid diagram showing which color goes in each square

**Fabric Count Impact:**
| Fabric Count | Stitches/Inch | Best For | Detail Level |
|-------------|---------------|----------|--------------|
| 14-count | 14 | General projects | Medium |
| 16-count | 16 | Detailed work | Good |
| 18-count | 18 | Portraits, fine detail | Excellent |
| 22+ count | 22+ | Museum quality | Maximum |

**Calculating Finished Size:**
```
finished_size_inches = stitch_count / fabric_count
```
Example: 200 stitches wide on 14-count = 14.3 inches wide

### Portrait-Specific Considerations

Portraits require special attention due to:

1. **Skin Tones**: Need smooth gradients, typically 3+ shades per skin area (highlight, midtone, shadow)
2. **Color Count**: Portraits benefit from higher color counts (30-50+ colors for realism)
3. **Size**: Larger patterns (200x300+ stitches) allow better detail rendering
4. **Blending**: Some stitchers "tweed" (combine strands from different colors) for smoother transitions

**Recommended Portrait Settings:**
- Minimum stitch count: 150x200 for recognizable features
- Optimal stitch count: 250x350 for good detail
- Color count: 35-50 colors for realistic skin tones
- Fabric: 18-count for fine detail

### Pattern PDF Requirements

A professional cross-stitch pattern PDF must include:

1. **Cover Page**: Pattern name, preview image, dimensions, color count
2. **Pattern Grid**:
   - 10x10 grid lines (bold every 10 stitches)
   - Center arrows (marks center of pattern)
   - Unique symbol per color
   - Line numbers along edges
3. **Color Legend**:
   - Symbol for each color
   - DMC code
   - Color name
   - Stitch count for that color
   - Color swatch
4. **Thread List**:
   - All DMC codes needed
   - Estimated skein quantities
5. **Pattern Info**:
   - Dimensions (W x H in stitches)
   - Finished size at various fabric counts
   - Total stitch count

---

## 2. Data Models

### Core Types

```swift
// MARK: - Color Types

/// RGB color with 8-bit components
struct RGBColor: Codable, Equatable, Hashable {
    let r: UInt8
    let g: UInt8
    let b: UInt8

    /// Initialize from hex string (e.g., "FF5733" or "#FF5733")
    init?(hex: String)

    /// Convert to CIELab for perceptual comparison
    func toLab() -> LabColor
}

/// CIELab color for perceptual color comparison
struct LabColor: Codable, Equatable {
    let l: Double  // Lightness: 0-100
    let a: Double  // Green-Red: -128 to +127
    let b: Double  // Blue-Yellow: -128 to +127

    /// Calculate Delta E (CIE76) distance to another color
    func deltaE(to other: LabColor) -> Double
}

// MARK: - Thread Types

/// Represents a DMC embroidery thread color
struct DMCThread: Codable, Identifiable, Hashable {
    let id: String           // DMC code, e.g., "310", "3865", "BLANC"
    let name: String         // Color name, e.g., "Black", "Winter White"
    let rgb: RGBColor        // RGB value for display
    let lab: LabColor        // CIELab value for matching (pre-computed)

    /// Estimated skeins needed for a given stitch count
    /// Based on: ~400 stitches per skein on 14-count with 2 strands
    func skeinsNeeded(forStitchCount count: Int, fabricCount: Int = 14) -> Double
}

// MARK: - Stitch Types

/// Types of stitches supported
enum StitchType: String, Codable, CaseIterable {
    case full           // Standard X stitch
    case half           // Single diagonal (/ or \)
    case quarterTL      // Quarter stitch, top-left
    case quarterTR      // Quarter stitch, top-right
    case quarterBL      // Quarter stitch, bottom-left
    case quarterBR      // Quarter stitch, bottom-right
    case threeQuarter   // 3/4 stitch
    case backstitch     // Outline stitch (line between grid points)
    case frenchKnot     // Decorative knot
}

/// A single stitch in the pattern
struct Stitch: Codable, Equatable {
    let thread: DMCThread
    var type: StitchType
    var isCompleted: Bool

    init(thread: DMCThread, type: StitchType = .full, isCompleted: Bool = false)
}

// MARK: - Pattern Types

/// Pattern symbol for display on charts
struct PatternSymbol: Codable, Hashable {
    let character: String    // Single character symbol
    let unicodeScalar: UInt32  // For reliable encoding

    static let availableSymbols: [PatternSymbol] = [
        // Primary symbols (high contrast, easily distinguishable)
        "●", "■", "▲", "◆", "★", "♦", "♥", "♣", "♠", "○",
        "□", "△", "◇", "☆", "◐", "◑", "◒", "◓", "▪", "▫",
        // Secondary symbols
        "×", "+", "⊕", "⊗", "⊙", "⊚", "◉", "◎", "▣", "▤",
        "▥", "▦", "▧", "▨", "▩", "⬟", "⬡", "⬢", "⬣", "⬤",
        // Tertiary symbols (for high color counts)
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
        "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"
    ]
}

/// Color entry in the pattern palette
struct PaletteEntry: Codable, Identifiable {
    let id: UUID
    let thread: DMCThread
    let symbol: PatternSymbol
    var stitchCount: Int

    /// Percentage of total pattern this color represents
    func percentage(ofTotal total: Int) -> Double
}

/// Metadata about the pattern
struct PatternMetadata: Codable {
    var name: String
    var author: String
    var createdDate: Date
    var modifiedDate: Date
    var notes: String
    var sourceImageName: String?

    init(name: String = "Untitled Pattern")
}

/// The complete cross-stitch pattern
struct Pattern: Codable, Identifiable {
    let id: UUID
    let width: Int                      // Stitch count horizontal
    let height: Int                     // Stitch count vertical
    var stitches: [[Stitch?]]           // 2D grid, nil = no stitch
    var palette: [PaletteEntry]         // Colors used with symbols
    var metadata: PatternMetadata

    // Computed properties
    var totalStitchCount: Int
    var colorCount: Int { palette.count }
    var completedStitchCount: Int
    var progressPercentage: Double

    /// Calculate finished size for a given fabric count
    func finishedSize(fabricCount: Int) -> (widthInches: Double, heightInches: Double)

    /// Get stitch at position (returns nil if out of bounds or empty)
    func stitch(at x: Int, y: Int) -> Stitch?

    /// Set stitch at position
    mutating func setStitch(_ stitch: Stitch?, at x: Int, y: Int)

    /// Mark stitch as completed
    mutating func markCompleted(at x: Int, y: Int, completed: Bool)

    /// Get all positions for a specific thread color
    func positions(for thread: DMCThread) -> [(x: Int, y: Int)]
}

// MARK: - Project Types

/// User project containing pattern and state
struct Project: Codable, Identifiable {
    let id: UUID
    var pattern: Pattern
    var sourceImage: Data?              // Original image data (optional, for reference)
    var settings: GenerationSettings    // Settings used to create pattern
    var createdDate: Date
    var modifiedDate: Date

    /// File extension for project files
    static let fileExtension = "dcspro"
}

/// Settings for pattern generation
struct GenerationSettings: Codable {
    var targetWidth: Int                // Target width in stitches
    var targetHeight: Int               // Target height in stitches
    var maintainAspectRatio: Bool       // Lock aspect ratio
    var maxColors: Int                  // Maximum colors in palette (5-50)
    var colorMatchingMethod: ColorMatchingMethod
    var ditherEnabled: Bool             // Apply dithering for smoother gradients

    enum ColorMatchingMethod: String, Codable, CaseIterable {
        case cielab     // CIE76 Delta E (recommended)
        case cie94      // CIE94 (more perceptually accurate)
        case rgb        // Simple RGB Euclidean (fast but less accurate)
    }

    static let `default` = GenerationSettings(
        targetWidth: 200,
        targetHeight: 250,
        maintainAspectRatio: true,
        maxColors: 40,
        colorMatchingMethod: .cielab,
        ditherEnabled: false
    )

    static let portrait = GenerationSettings(
        targetWidth: 250,
        targetHeight: 350,
        maintainAspectRatio: true,
        maxColors: 45,
        colorMatchingMethod: .cielab,
        ditherEnabled: false
    )
}
```

### View Models

```swift
// MARK: - View Models

/// Main application state
@Observable
class AppState {
    var currentProject: Project?
    var recentProjects: [ProjectReference]
    var isProcessing: Bool
    var processingProgress: Double
    var errorMessage: String?

    // Navigation state
    var selectedView: NavigationView

    enum NavigationView {
        case welcome
        case imageImport
        case patternGeneration
        case patternView
        case export
    }
}

/// Reference to a saved project (for recent files list)
struct ProjectReference: Codable, Identifiable {
    let id: UUID
    let name: String
    let path: URL
    let lastModified: Date
    let previewImageData: Data?
}

/// State for image import view
@Observable
class ImageImportViewModel {
    var selectedImage: NSImage?
    var imageURL: URL?
    var imageInfo: ImageInfo?
    var isDraggingOver: Bool

    struct ImageInfo {
        let width: Int
        let height: Int
        let fileSize: Int64
        let format: String
    }
}

/// State for pattern generation view
@Observable
class PatternGenerationViewModel {
    var sourceImage: NSImage
    var settings: GenerationSettings
    var previewPattern: Pattern?
    var isGenerating: Bool
    var generationProgress: Double
    var error: GenerationError?

    // Computed preview dimensions
    var previewWidth: Int
    var previewHeight: Int
    var estimatedFinishedSize: (width: Double, height: Double)
}

/// State for pattern view
@Observable
class PatternViewModel {
    var pattern: Pattern
    var zoomLevel: Double           // 0.25 to 4.0
    var panOffset: CGPoint
    var selectedColor: DMCThread?
    var highlightedColor: DMCThread?
    var showGrid: Bool
    var showSymbols: Bool
    var showColors: Bool
    var showProgress: Bool          // Dim completed stitches

    // Editing state
    var isEditing: Bool
    var selectedTool: EditTool
    var undoStack: [PatternEdit]
    var redoStack: [PatternEdit]

    enum EditTool {
        case select
        case paint
        case fill
        case erase
    }
}

/// Represents an edit operation for undo/redo
struct PatternEdit: Codable {
    let timestamp: Date
    let changes: [StitchChange]

    struct StitchChange: Codable {
        let x: Int
        let y: Int
        let oldStitch: Stitch?
        let newStitch: Stitch?
    }
}
```

---

## 3. Color Algorithms

### RGB to CIELab Conversion

The conversion requires two steps: RGB → XYZ → Lab

#### Step 1: RGB to XYZ

```swift
/// Convert sRGB to XYZ color space
/// Reference white: D65 illuminant
func rgbToXyz(r: UInt8, g: UInt8, b: UInt8) -> (x: Double, y: Double, z: Double) {
    // 1. Normalize RGB to 0-1 range
    var rLinear = Double(r) / 255.0
    var gLinear = Double(g) / 255.0
    var bLinear = Double(b) / 255.0

    // 2. Apply inverse sRGB companding (gamma correction)
    // If value <= 0.04045, use linear; otherwise apply gamma
    func inverseCompand(_ c: Double) -> Double {
        if c <= 0.04045 {
            return c / 12.92
        } else {
            return pow((c + 0.055) / 1.055, 2.4)
        }
    }

    rLinear = inverseCompand(rLinear)
    gLinear = inverseCompand(gLinear)
    bLinear = inverseCompand(bLinear)

    // 3. Scale to 0-100 range
    rLinear *= 100
    gLinear *= 100
    bLinear *= 100

    // 4. Apply transformation matrix (sRGB to XYZ, D65 illuminant)
    let x = rLinear * 0.4124564 + gLinear * 0.3575761 + bLinear * 0.1804375
    let y = rLinear * 0.2126729 + gLinear * 0.7151522 + bLinear * 0.0721750
    let z = rLinear * 0.0193339 + gLinear * 0.1191920 + bLinear * 0.9503041

    return (x, y, z)
}
```

#### Step 2: XYZ to Lab

```swift
/// Convert XYZ to CIELab color space
/// Reference white: D65 illuminant (Xn=95.047, Yn=100.000, Zn=108.883)
func xyzToLab(x: Double, y: Double, z: Double) -> (l: Double, a: Double, b: Double) {
    // D65 reference white point
    let xn = 95.047
    let yn = 100.000
    let zn = 108.883

    // Normalize by reference white
    var xr = x / xn
    var yr = y / yn
    var zr = z / zn

    // Apply f(t) transformation
    // If t > (6/29)^3 ≈ 0.008856, use cube root
    // Otherwise use linear approximation
    let epsilon = 0.008856  // (6/29)^3
    let kappa = 903.3       // (29/3)^3

    func f(_ t: Double) -> Double {
        if t > epsilon {
            return pow(t, 1.0/3.0)
        } else {
            return (kappa * t + 16.0) / 116.0
        }
    }

    let fx = f(xr)
    let fy = f(yr)
    let fz = f(zr)

    // Calculate Lab values
    let l = 116.0 * fy - 16.0       // L*: 0 to 100
    let a = 500.0 * (fx - fy)       // a*: roughly -128 to +127
    let b = 200.0 * (fy - fz)       // b*: roughly -128 to +127

    return (l, a, b)
}
```

#### Complete RGB to Lab

```swift
extension RGBColor {
    func toLab() -> LabColor {
        let xyz = rgbToXyz(r: r, g: g, b: b)
        let lab = xyzToLab(x: xyz.x, y: xyz.y, z: xyz.z)
        return LabColor(l: lab.l, a: lab.a, b: lab.b)
    }
}
```

### Color Distance (Delta E)

#### CIE76 Formula (Simple Euclidean in Lab space)

```swift
extension LabColor {
    /// CIE76 Delta E - simple Euclidean distance in Lab space
    /// Good enough for most cross-stitch applications
    func deltaE76(to other: LabColor) -> Double {
        let dL = self.l - other.l
        let dA = self.a - other.a
        let dB = self.b - other.b
        return sqrt(dL * dL + dA * dA + dB * dB)
    }
}
```

**Interpretation of Delta E values:**
| Delta E | Perception |
|---------|------------|
| 0 - 1 | Imperceptible difference |
| 1 - 2 | Perceptible through close observation |
| 2 - 3.5 | Perceptible at a glance |
| 3.5 - 5 | Clear difference |
| > 5 | Colors appear different |

#### CIE94 Formula (More Perceptually Accurate)

```swift
extension LabColor {
    /// CIE94 Delta E - better perceptual accuracy than CIE76
    /// Uses weighting factors for lightness, chroma, and hue
    func deltaE94(to other: LabColor, textiles: Bool = true) -> Double {
        // Weighting factors (textiles vs graphic arts)
        let kL: Double = textiles ? 2.0 : 1.0
        let k1: Double = textiles ? 0.048 : 0.045
        let k2: Double = textiles ? 0.014 : 0.015

        let kC: Double = 1.0
        let kH: Double = 1.0

        // Calculate chroma
        let c1 = sqrt(self.a * self.a + self.b * self.b)
        let c2 = sqrt(other.a * other.a + other.b * other.b)

        // Differences
        let dL = self.l - other.l
        let dC = c1 - c2
        let dA = self.a - other.a
        let dB = self.b - other.b

        // Delta H (hue difference)
        let dH2 = dA * dA + dB * dB - dC * dC
        let dH = dH2 > 0 ? sqrt(dH2) : 0

        // Weighting functions
        let sL: Double = 1.0
        let sC = 1.0 + k1 * c1
        let sH = 1.0 + k2 * c1

        // Calculate Delta E 94
        let term1 = dL / (kL * sL)
        let term2 = dC / (kC * sC)
        let term3 = dH / (kH * sH)

        return sqrt(term1 * term1 + term2 * term2 + term3 * term3)
    }
}
```

### Median Cut Color Quantization

```swift
/// Median Cut algorithm for reducing image colors
class MedianCutQuantizer {

    struct ColorBucket {
        var pixels: [(r: UInt8, g: UInt8, b: UInt8, count: Int)]

        /// Total pixel count in bucket
        var totalCount: Int {
            pixels.reduce(0) { $0 + $1.count }
        }

        /// Find which channel (R=0, G=1, B=2) has the greatest range
        func channelWithGreatestRange() -> Int {
            let rRange = pixels.map(\.r).max()! - pixels.map(\.r).min()!
            let gRange = pixels.map(\.g).max()! - pixels.map(\.g).min()!
            let bRange = pixels.map(\.b).max()! - pixels.map(\.b).min()!

            if rRange >= gRange && rRange >= bRange { return 0 }
            if gRange >= rRange && gRange >= bRange { return 1 }
            return 2
        }

        /// Get average color of bucket
        func averageColor() -> RGBColor {
            var rSum: Int = 0
            var gSum: Int = 0
            var bSum: Int = 0
            var total: Int = 0

            for pixel in pixels {
                rSum += Int(pixel.r) * pixel.count
                gSum += Int(pixel.g) * pixel.count
                bSum += Int(pixel.b) * pixel.count
                total += pixel.count
            }

            return RGBColor(
                r: UInt8(rSum / total),
                g: UInt8(gSum / total),
                b: UInt8(bSum / total)
            )
        }

        /// Split bucket at median along specified channel
        func split() -> (ColorBucket, ColorBucket) {
            let channel = channelWithGreatestRange()

            // Sort by the channel with greatest range
            let sorted = pixels.sorted { p1, p2 in
                switch channel {
                case 0: return p1.r < p2.r
                case 1: return p1.g < p2.g
                default: return p1.b < p2.b
                }
            }

            // Find median by pixel count
            let targetCount = totalCount / 2
            var runningCount = 0
            var splitIndex = sorted.count / 2

            for (index, pixel) in sorted.enumerated() {
                runningCount += pixel.count
                if runningCount >= targetCount {
                    splitIndex = index + 1
                    break
                }
            }

            // Ensure we don't create empty buckets
            splitIndex = max(1, min(splitIndex, sorted.count - 1))

            let bucket1 = ColorBucket(pixels: Array(sorted[..<splitIndex]))
            let bucket2 = ColorBucket(pixels: Array(sorted[splitIndex...]))

            return (bucket1, bucket2)
        }
    }

    /// Quantize image colors to specified count
    /// - Parameters:
    ///   - pixels: Array of RGB values from image
    ///   - targetColorCount: Desired number of colors (will be rounded to power of 2)
    /// - Returns: Array of representative colors
    func quantize(pixels: [(r: UInt8, g: UInt8, b: UInt8)], targetColorCount: Int) -> [RGBColor] {
        // Count unique colors
        var colorCounts: [String: (r: UInt8, g: UInt8, b: UInt8, count: Int)] = [:]
        for pixel in pixels {
            let key = "\(pixel.r),\(pixel.g),\(pixel.b)"
            if let existing = colorCounts[key] {
                colorCounts[key] = (pixel.r, pixel.g, pixel.b, existing.count + 1)
            } else {
                colorCounts[key] = (pixel.r, pixel.g, pixel.b, 1)
            }
        }

        // Initial bucket with all colors
        var buckets = [ColorBucket(pixels: Array(colorCounts.values))]

        // Calculate iterations needed (colors = 2^iterations)
        let iterations = Int(ceil(log2(Double(targetColorCount))))

        // Repeatedly split buckets
        for _ in 0..<iterations {
            // Find bucket with greatest range to split
            guard let indexToSplit = buckets.indices.max(by: { i1, i2 in
                let range1 = buckets[i1].channelWithGreatestRange()
                let range2 = buckets[i2].channelWithGreatestRange()
                // Prefer buckets with more pixels
                return buckets[i1].totalCount < buckets[i2].totalCount
            }) else { break }

            // Split the bucket
            let bucketToSplit = buckets.remove(at: indexToSplit)
            let (bucket1, bucket2) = bucketToSplit.split()
            buckets.append(bucket1)
            buckets.append(bucket2)
        }

        // Get average color from each bucket
        return buckets.map { $0.averageColor() }
    }
}
```

### DMC Color Matching

```swift
/// Service for matching colors to DMC thread palette
class DMCColorMatcher {
    private let dmcPalette: [DMCThread]

    init(palette: [DMCThread]) {
        self.dmcPalette = palette
    }

    /// Find the closest DMC thread to a given RGB color
    func closestThread(to color: RGBColor, method: GenerationSettings.ColorMatchingMethod = .cielab) -> DMCThread {
        let sourceLab = color.toLab()

        var bestMatch: DMCThread = dmcPalette[0]
        var bestDistance: Double = .infinity

        for thread in dmcPalette {
            let distance: Double
            switch method {
            case .cielab:
                distance = sourceLab.deltaE76(to: thread.lab)
            case .cie94:
                distance = sourceLab.deltaE94(to: thread.lab)
            case .rgb:
                let dr = Double(color.r) - Double(thread.rgb.r)
                let dg = Double(color.g) - Double(thread.rgb.g)
                let db = Double(color.b) - Double(thread.rgb.b)
                distance = sqrt(dr*dr + dg*dg + db*db)
            }

            if distance < bestDistance {
                bestDistance = distance
                bestMatch = thread
            }
        }

        return bestMatch
    }

    /// Find closest threads for multiple colors, avoiding duplicates when possible
    func matchPalette(quantizedColors: [RGBColor], preferUnique: Bool = true) -> [DMCThread] {
        if !preferUnique {
            return quantizedColors.map { closestThread(to: $0) }
        }

        // Match with uniqueness preference
        var usedThreads: Set<String> = []
        var result: [DMCThread] = []

        // Sort colors by how "distinctive" they are (furthest from others)
        let sortedColors = quantizedColors.sorted { c1, c2 in
            let lab1 = c1.toLab()
            let lab2 = c2.toLab()
            let minDist1 = quantizedColors.filter { $0 != c1 }.map { lab1.deltaE76(to: $0.toLab()) }.min() ?? 0
            let minDist2 = quantizedColors.filter { $0 != c2 }.map { lab2.deltaE76(to: $0.toLab()) }.min() ?? 0
            return minDist1 > minDist2
        }

        for color in sortedColors {
            let sourceLab = color.toLab()

            // Find best unused match
            var bestMatch: DMCThread?
            var bestDistance: Double = .infinity

            for thread in dmcPalette {
                if usedThreads.contains(thread.id) { continue }

                let distance = sourceLab.deltaE76(to: thread.lab)
                if distance < bestDistance {
                    bestDistance = distance
                    bestMatch = thread
                }
            }

            // If no unused match found (more colors than DMC threads), allow reuse
            let finalMatch = bestMatch ?? closestThread(to: color)
            usedThreads.insert(finalMatch.id)
            result.append(finalMatch)
        }

        return result
    }
}
```

---

## 4. DMC Thread Database

The DMC database should be stored as a JSON resource file bundled with the app.

### Database Format

```json
{
  "version": "1.0",
  "lastUpdated": "2026-02-16",
  "threads": [
    {
      "id": "BLANC",
      "name": "White",
      "rgb": {"r": 255, "g": 255, "b": 255}
    },
    {
      "id": "ECRU",
      "name": "Ecru",
      "rgb": {"r": 240, "g": 234, "b": 218}
    },
    {
      "id": "310",
      "name": "Black",
      "rgb": {"r": 0, "g": 0, "b": 0}
    }
    // ... all ~489 DMC colors
  ]
}
```

### Key DMC Colors for Portraits

These colors are particularly important for skin tones and should be verified for accuracy:

**Light Skin Tones:**
- 3865 Winter White
- 948 Very Light Peach
- 754 Light Peach
- 3770 Very Light Tawny
- 945 Tawny

**Medium Skin Tones:**
- 951 Light Tawny
- 3774 Very Light Desert Sand
- 950 Light Desert Sand
- 3064 Desert Sand
- 407 Dark Desert Sand

**Dark Skin Tones:**
- 3862 Dark Mocha Beige
- 3031 Very Dark Mocha Brown
- 3781 Dark Mocha Brown
- 839 Dark Beige Brown
- 838 Very Dark Beige Brown

### Loading the Database

```swift
class DMCDatabase {
    static let shared = DMCDatabase()

    private(set) var threads: [DMCThread] = []
    private var threadsByID: [String: DMCThread] = [:]

    private init() {
        loadDatabase()
    }

    private func loadDatabase() {
        guard let url = Bundle.main.url(forResource: "dmc_colors", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("DMC database not found in bundle")
        }

        let decoder = JSONDecoder()
        guard let database = try? decoder.decode(DMCDatabaseFile.self, from: data) else {
            fatalError("Failed to decode DMC database")
        }

        // Convert to DMCThread with pre-computed Lab values
        threads = database.threads.map { entry in
            let rgb = RGBColor(r: entry.rgb.r, g: entry.rgb.g, b: entry.rgb.b)
            return DMCThread(
                id: entry.id,
                name: entry.name,
                rgb: rgb,
                lab: rgb.toLab()
            )
        }

        // Build lookup dictionary
        for thread in threads {
            threadsByID[thread.id] = thread
        }
    }

    func thread(byID id: String) -> DMCThread? {
        threadsByID[id]
    }

    func search(query: String) -> [DMCThread] {
        let lowercased = query.lowercased()
        return threads.filter {
            $0.id.lowercased().contains(lowercased) ||
            $0.name.lowercased().contains(lowercased)
        }
    }
}

// Database file structure
private struct DMCDatabaseFile: Codable {
    let version: String
    let lastUpdated: String
    let threads: [ThreadEntry]

    struct ThreadEntry: Codable {
        let id: String
        let name: String
        let rgb: RGBEntry
    }

    struct RGBEntry: Codable {
        let r: UInt8
        let g: UInt8
        let b: UInt8
    }
}
```

---

## 5. Image Processing Pipeline

### Complete Pipeline

```swift
/// Service for converting images to cross-stitch patterns
class PatternGenerationService {
    private let colorMatcher: DMCColorMatcher
    private let quantizer: MedianCutQuantizer

    init() {
        self.colorMatcher = DMCColorMatcher(palette: DMCDatabase.shared.threads)
        self.quantizer = MedianCutQuantizer()
    }

    /// Generate pattern from image with progress reporting
    func generatePattern(
        from image: NSImage,
        settings: GenerationSettings,
        progress: @escaping (Double, String) -> Void
    ) async throws -> Pattern {

        // Step 1: Resize image to target dimensions
        progress(0.1, "Resizing image...")
        let resized = try resizeImage(image, to: settings)

        // Step 2: Extract pixels
        progress(0.2, "Extracting colors...")
        let pixels = try extractPixels(from: resized)

        // Step 3: Quantize colors
        progress(0.3, "Reducing colors...")
        let quantizedColors = quantizer.quantize(
            pixels: pixels.flatMap { $0 },
            targetColorCount: settings.maxColors
        )

        // Step 4: Match to DMC palette
        progress(0.5, "Matching to DMC threads...")
        let dmcPalette = colorMatcher.matchPalette(
            quantizedColors: quantizedColors,
            preferUnique: true
        )

        // Step 5: Map each pixel to nearest DMC color
        progress(0.6, "Creating pattern...")
        let stitches = try mapPixelsToStitches(
            pixels: pixels,
            palette: dmcPalette,
            method: settings.colorMatchingMethod
        )

        // Step 6: Build palette entries with symbols and counts
        progress(0.9, "Finalizing...")
        let paletteEntries = buildPaletteEntries(
            stitches: stitches,
            palette: dmcPalette
        )

        progress(1.0, "Complete!")

        return Pattern(
            id: UUID(),
            width: settings.targetWidth,
            height: settings.targetHeight,
            stitches: stitches,
            palette: paletteEntries,
            metadata: PatternMetadata(name: "New Pattern")
        )
    }

    // MARK: - Private Methods

    private func resizeImage(_ image: NSImage, to settings: GenerationSettings) throws -> NSImage {
        let targetSize = NSSize(
            width: settings.targetWidth,
            height: settings.targetHeight
        )

        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )

        newImage.unlockFocus()
        return newImage
    }

    private func extractPixels(from image: NSImage) throws -> [[(r: UInt8, g: UInt8, b: UInt8)]] {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw PatternError.imageConversionFailed
        }

        let width = cgImage.width
        let height = cgImage.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw PatternError.contextCreationFailed
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else {
            throw PatternError.pixelExtractionFailed
        }

        let buffer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)

        var pixels: [[(r: UInt8, g: UInt8, b: UInt8)]] = []

        for y in 0..<height {
            var row: [(r: UInt8, g: UInt8, b: UInt8)] = []
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = buffer[offset]
                let g = buffer[offset + 1]
                let b = buffer[offset + 2]
                row.append((r, g, b))
            }
            pixels.append(row)
        }

        return pixels
    }

    private func mapPixelsToStitches(
        pixels: [[(r: UInt8, g: UInt8, b: UInt8)]],
        palette: [DMCThread],
        method: GenerationSettings.ColorMatchingMethod
    ) throws -> [[Stitch?]] {

        // Pre-compute Lab values for palette
        let paletteLab = palette.map { $0.lab }

        var stitches: [[Stitch?]] = []

        for row in pixels {
            var stitchRow: [Stitch?] = []
            for pixel in row {
                let pixelLab = RGBColor(r: pixel.r, g: pixel.g, b: pixel.b).toLab()

                // Find closest palette color
                var bestIndex = 0
                var bestDistance: Double = .infinity

                for (index, threadLab) in paletteLab.enumerated() {
                    let distance: Double
                    switch method {
                    case .cielab:
                        distance = pixelLab.deltaE76(to: threadLab)
                    case .cie94:
                        distance = pixelLab.deltaE94(to: threadLab)
                    case .rgb:
                        let dr = Double(pixel.r) - Double(palette[index].rgb.r)
                        let dg = Double(pixel.g) - Double(palette[index].rgb.g)
                        let db = Double(pixel.b) - Double(palette[index].rgb.b)
                        distance = sqrt(dr*dr + dg*dg + db*db)
                    }

                    if distance < bestDistance {
                        bestDistance = distance
                        bestIndex = index
                    }
                }

                stitchRow.append(Stitch(thread: palette[bestIndex]))
            }
            stitches.append(stitchRow)
        }

        return stitches
    }

    private func buildPaletteEntries(
        stitches: [[Stitch?]],
        palette: [DMCThread]
    ) -> [PaletteEntry] {

        // Count stitches per thread
        var counts: [String: Int] = [:]
        for row in stitches {
            for stitch in row {
                if let s = stitch {
                    counts[s.thread.id, default: 0] += 1
                }
            }
        }

        // Build entries with symbols, sorted by count descending
        let symbols = PatternSymbol.availableSymbols

        let entries = palette.enumerated().compactMap { index, thread -> PaletteEntry? in
            guard let count = counts[thread.id], count > 0 else { return nil }
            return PaletteEntry(
                id: UUID(),
                thread: thread,
                symbol: symbols[index % symbols.count],
                stitchCount: count
            )
        }.sorted { $0.stitchCount > $1.stitchCount }

        return entries
    }
}

enum PatternError: Error, LocalizedError {
    case imageConversionFailed
    case contextCreationFailed
    case pixelExtractionFailed
    case invalidDimensions

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "Failed to convert image"
        case .contextCreationFailed: return "Failed to create graphics context"
        case .pixelExtractionFailed: return "Failed to extract pixel data"
        case .invalidDimensions: return "Invalid pattern dimensions"
        }
    }
}
```

---

## 6. PDF Export Specification

### PDF Structure

```
┌─────────────────────────────────────────┐
│              COVER PAGE                 │
│  - Pattern preview image                │
│  - Pattern name                         │
│  - Dimensions (stitches)                │
│  - Color count                          │
│  - Generated date                       │
├─────────────────────────────────────────┤
│            THREAD LIST                  │
│  - All DMC codes needed                 │
│  - Estimated skeins per color           │
│  - Color swatches                       │
├─────────────────────────────────────────┤
│           COLOR LEGEND                  │
│  - Symbol | DMC Code | Name | Count     │
│  - Sorted by stitch count               │
├─────────────────────────────────────────┤
│          PATTERN PAGES                  │
│  - Grid with symbols                    │
│  - 10x10 bold grid lines                │
│  - Page coordinates (e.g., "A1", "A2")  │
│  - Row/column numbers                   │
└─────────────────────────────────────────┘
```

### PDF Generation

```swift
import PDFKit

class PDFExportService {

    struct ExportSettings {
        var pageSize: PageSize = .letter
        var includeColorPreview: Bool = true
        var stitchesPerPage: Int = 70  // How many stitches fit per page
        var fontSize: CGFloat = 8
        var showGridNumbers: Bool = true

        enum PageSize {
            case letter  // 8.5 x 11 inches
            case a4      // 210 x 297 mm
            case legal   // 8.5 x 14 inches

            var size: CGSize {
                switch self {
                case .letter: return CGSize(width: 612, height: 792)  // 72 dpi
                case .a4: return CGSize(width: 595, height: 842)
                case .legal: return CGSize(width: 612, height: 1008)
                }
            }
        }
    }

    func exportPDF(pattern: Pattern, settings: ExportSettings = ExportSettings()) -> Data? {
        let pdfDocument = PDFDocument()
        var pageIndex = 0

        // Add cover page
        if let coverPage = createCoverPage(pattern: pattern, settings: settings) {
            pdfDocument.insert(coverPage, at: pageIndex)
            pageIndex += 1
        }

        // Add thread list page
        if let threadPage = createThreadListPage(pattern: pattern, settings: settings) {
            pdfDocument.insert(threadPage, at: pageIndex)
            pageIndex += 1
        }

        // Add legend page
        if let legendPage = createLegendPage(pattern: pattern, settings: settings) {
            pdfDocument.insert(legendPage, at: pageIndex)
            pageIndex += 1
        }

        // Add pattern grid pages
        let patternPages = createPatternPages(pattern: pattern, settings: settings)
        for page in patternPages {
            pdfDocument.insert(page, at: pageIndex)
            pageIndex += 1
        }

        return pdfDocument.dataRepresentation()
    }

    // Implementation details for each page type...
    // (Full implementation would be several hundred lines)
}
```

### Pattern Grid Layout

Each pattern page should follow this layout:

```
┌──────────────────────────────────────────────┐
│  Page: A1                    DCS Pro         │  <- Header
├──────────────────────────────────────────────┤
│     1    11    21    31    41    51    61    │  <- Column numbers
│  ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐ │
│1 │●■▲◆│●■▲◆│●■▲◆│●■▲◆│●■▲◆│●■▲◆│●■▲◆│     │
│  │●■▲◆│●■▲◆│●■▲◆│●■▲◆│●■▲◆│●■▲◆│●■▲◆│     │
│  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤ │
│11│●■▲◆│●■▲◆│●■▲◆│●■▲◆│●■▲◆│●■▲◆│●■▲◆│     │
│  │●■▲◆│●■▲◆│●■▲◆│●■▲◆│●■▲◆│●■▲◆│●■▲◆│     │
│  └─────┴─────┴─────┴─────┴─────┴─────┴─────┘ │
├──────────────────────────────────────────────┤
│  Center markers: ↓ (col 35)  → (row 25)      │  <- Footer with center info
└──────────────────────────────────────────────┘
```

---

## 7. UI/UX Design

### App Window Structure

```
┌────────────────────────────────────────────────────────────────┐
│  DCS Pro                                           [─] [□] [×] │
├──────────┬─────────────────────────────────────────────────────┤
│          │                                                     │
│  [📁]    │                                                     │
│  Import  │                                                     │
│          │                                                     │
│  [🎨]    │              MAIN CONTENT AREA                      │
│  Pattern │                                                     │
│          │     (Changes based on sidebar selection)            │
│  [📊]    │                                                     │
│  Colors  │                                                     │
│          │                                                     │
│  [📄]    │                                                     │
│  Export  │                                                     │
│          │                                                     │
├──────────┴─────────────────────────────────────────────────────┤
│  Status: Ready                              Progress: ████░░ 67%│
└────────────────────────────────────────────────────────────────┘
```

### View Flows

#### 1. Welcome/Import View
```
┌────────────────────────────────────────────┐
│                                            │
│         Welcome to DCS Pro                 │
│                                            │
│    ┌────────────────────────────────┐      │
│    │                                │      │
│    │   Drop an image here           │      │
│    │         or                     │      │
│    │   [Choose Image...]            │      │
│    │                                │      │
│    └────────────────────────────────┘      │
│                                            │
│    Recent Projects:                        │
│    ○ Portrait_Mom.dcspro (Feb 14)          │
│    ○ Landscape_Beach.dcspro (Feb 10)       │
│                                            │
└────────────────────────────────────────────┘
```

#### 2. Pattern Generation View
```
┌──────────────────────────────────────────────────────────────┐
│  Source Image          │  Preview                            │
│ ┌──────────────────┐   │ ┌──────────────────────────────┐    │
│ │                  │   │ │                              │    │
│ │   [Original]     │   │ │   [Pattern Preview]          │    │
│ │                  │   │ │                              │    │
│ └──────────────────┘   │ └──────────────────────────────┘    │
├────────────────────────┴─────────────────────────────────────┤
│  Settings                                                    │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Width:  [200▼] stitches    Height: [250▼] stitches     │ │
│  │ [✓] Maintain aspect ratio                               │ │
│  │                                                         │ │
│  │ Colors: [====●=====] 35                                 │ │
│  │         5          50                                   │ │
│  │                                                         │ │
│  │ Color Matching: [CIELab (Recommended) ▼]                │ │
│  │ [ ] Enable dithering                                    │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  Finished size at 14-count: 14.3" × 17.9"                   │
│  Total stitches: 50,000                                      │
│                                          [Generate Pattern]  │
└──────────────────────────────────────────────────────────────┘
```

#### 3. Pattern View
```
┌──────────────────────────────────────────────────────────────┐
│  Toolbar: [Zoom -] [100%] [Zoom +]  [Grid ✓] [Symbols ✓]    │
├────────────────────────────────────────────┬─────────────────┤
│                                            │  Colors (35)    │
│    ┌────────────────────────────────┐      │ ┌─────────────┐ │
│    │ ● ● ■ ■ ▲ ▲ ◆ ◆ ● ● ■ ■ ▲ ▲  │      │ │[●] 310 Blk │ │
│    │ ● ● ■ ■ ▲ ▲ ◆ ◆ ● ● ■ ■ ▲ ▲  │      │ │[■] 3865 Wht│ │
│    │ ● ● ■ ■ ▲ ▲ ◆ ◆ ● ● ■ ■ ▲ ▲  │      │ │[▲] 948 Pch │ │
│    │ ● ● ■ ■ ▲ ▲ ◆ ◆ ● ● ■ ■ ▲ ▲  │      │ │[◆] 754 LPch│ │
│    │ ─────────────────────────────  │      │ │    ...      │ │
│    │ ● ● ■ ■ ▲ ▲ ◆ ◆ ● ● ■ ■ ▲ ▲  │      │ └─────────────┘ │
│    │ ● ● ■ ■ ▲ ▲ ◆ ◆ ● ● ■ ■ ▲ ▲  │      │                 │
│    └────────────────────────────────┘      │  Pattern Info   │
│                                            │  200 × 250      │
│    [Pan and zoom with mouse/trackpad]      │  35 colors      │
│                                            │  50,000 stitches│
└────────────────────────────────────────────┴─────────────────┘
```

#### 4. Export View
```
┌──────────────────────────────────────────────────────────────┐
│  Export Pattern                                              │
│                                                              │
│  Format: [PDF Pattern ▼]                                     │
│                                                              │
│  PDF Options:                                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Page Size:    [Letter (8.5×11") ▼]                      │ │
│  │                                                         │ │
│  │ Include:                                                │ │
│  │ [✓] Cover page with preview                             │ │
│  │ [✓] Thread list with quantities                         │ │
│  │ [✓] Color legend                                        │ │
│  │ [✓] Grid line numbers                                   │ │
│  │                                                         │ │
│  │ Symbol size: [Medium ▼]                                 │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  Preview: 12 pages                                           │
│                                                              │
│                              [Cancel]  [Export PDF...]       │
└──────────────────────────────────────────────────────────────┘
```

### Touch Bar Support (for Delaney's MacBook Pro)

The Touch Bar should show contextual controls:

**Pattern View Touch Bar:**
```
[Esc] [Zoom Slider ══●══════] [Grid] [Symbols] [Colors] [Export]
```

**Generation View Touch Bar:**
```
[Esc] [Width -/+] [Height -/+] [Colors Slider ══●══] [Generate]
```

---

## 8. File Formats

### Project File (.dcspro)

The project file is a ZIP archive containing:

```
project.dcspro (ZIP)
├── manifest.json        # File format version, app version
├── pattern.json         # Pattern data (stitches, palette, metadata)
├── settings.json        # Generation settings used
├── source_image.png     # Original source image (optional)
└── thumbnail.png        # Preview thumbnail for recent files
```

### Manifest Format

```json
{
  "formatVersion": "1.0",
  "appVersion": "1.0.0",
  "createdDate": "2026-02-16T10:30:00Z",
  "modifiedDate": "2026-02-16T14:45:00Z"
}
```

### Reading/Writing Projects

```swift
class ProjectService {

    func save(project: Project, to url: URL) throws {
        let archive = Archive(url: url, accessMode: .create)

        // Write manifest
        let manifest = Manifest(
            formatVersion: "1.0",
            appVersion: Bundle.main.appVersion
        )
        try archive.addEntry(
            named: "manifest.json",
            data: JSONEncoder().encode(manifest)
        )

        // Write pattern
        try archive.addEntry(
            named: "pattern.json",
            data: JSONEncoder().encode(project.pattern)
        )

        // Write settings
        try archive.addEntry(
            named: "settings.json",
            data: JSONEncoder().encode(project.settings)
        )

        // Write source image if present
        if let imageData = project.sourceImage {
            try archive.addEntry(named: "source_image.png", data: imageData)
        }

        // Generate and write thumbnail
        if let thumbnail = generateThumbnail(for: project.pattern) {
            try archive.addEntry(named: "thumbnail.png", data: thumbnail)
        }
    }

    func load(from url: URL) throws -> Project {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw ProjectError.invalidFile
        }

        // Read and validate manifest
        guard let manifestEntry = archive["manifest.json"],
              let manifestData = try? archive.extractData(from: manifestEntry),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData) else {
            throw ProjectError.invalidManifest
        }

        // Check version compatibility
        guard isCompatible(formatVersion: manifest.formatVersion) else {
            throw ProjectError.incompatibleVersion(manifest.formatVersion)
        }

        // Read pattern
        guard let patternEntry = archive["pattern.json"],
              let patternData = try? archive.extractData(from: patternEntry),
              let pattern = try? JSONDecoder().decode(Pattern.self, from: patternData) else {
            throw ProjectError.invalidPattern
        }

        // Read settings
        guard let settingsEntry = archive["settings.json"],
              let settingsData = try? archive.extractData(from: settingsEntry),
              let settings = try? JSONDecoder().decode(GenerationSettings.self, from: settingsData) else {
            throw ProjectError.invalidSettings
        }

        // Read source image (optional)
        var sourceImage: Data? = nil
        if let imageEntry = archive["source_image.png"] {
            sourceImage = try? archive.extractData(from: imageEntry)
        }

        return Project(
            id: UUID(),
            pattern: pattern,
            sourceImage: sourceImage,
            settings: settings,
            createdDate: manifest.createdDate,
            modifiedDate: manifest.modifiedDate
        )
    }
}
```

---

## 9. Test Specifications

### Unit Test Coverage Requirements

Each component should have comprehensive tests. Here are the key test cases:

#### Color Conversion Tests

```swift
import Testing

@Suite("RGB to Lab Conversion")
struct RGBToLabTests {

    @Test("Black converts correctly")
    func testBlack() {
        let black = RGBColor(r: 0, g: 0, b: 0)
        let lab = black.toLab()
        #expect(abs(lab.l - 0) < 0.1)
        #expect(abs(lab.a - 0) < 0.1)
        #expect(abs(lab.b - 0) < 0.1)
    }

    @Test("White converts correctly")
    func testWhite() {
        let white = RGBColor(r: 255, g: 255, b: 255)
        let lab = white.toLab()
        #expect(abs(lab.l - 100) < 0.1)
        #expect(abs(lab.a - 0) < 0.5)
        #expect(abs(lab.b - 0) < 0.5)
    }

    @Test("Pure red has positive a")
    func testRed() {
        let red = RGBColor(r: 255, g: 0, b: 0)
        let lab = red.toLab()
        #expect(lab.a > 50)  // Red is positive on a axis
    }

    @Test("Pure green has negative a")
    func testGreen() {
        let green = RGBColor(r: 0, g: 255, b: 0)
        let lab = green.toLab()
        #expect(lab.a < -50)  // Green is negative on a axis
    }

    @Test("Pure blue has negative b")
    func testBlue() {
        let blue = RGBColor(r: 0, g: 0, b: 255)
        let lab = blue.toLab()
        #expect(lab.b < -50)  // Blue is negative on b axis
    }
}

@Suite("Delta E Calculations")
struct DeltaETests {

    @Test("Identical colors have zero distance")
    func testIdenticalColors() {
        let color = LabColor(l: 50, a: 25, b: -10)
        #expect(color.deltaE76(to: color) == 0)
    }

    @Test("Similar colors have small Delta E")
    func testSimilarColors() {
        let color1 = LabColor(l: 50, a: 25, b: -10)
        let color2 = LabColor(l: 51, a: 26, b: -9)
        let deltaE = color1.deltaE76(to: color2)
        #expect(deltaE < 2)  // Should be imperceptible
    }

    @Test("Different colors have large Delta E")
    func testDifferentColors() {
        let black = RGBColor(r: 0, g: 0, b: 0).toLab()
        let white = RGBColor(r: 255, g: 255, b: 255).toLab()
        let deltaE = black.deltaE76(to: white)
        #expect(deltaE > 90)  // Maximum possible difference
    }
}
```

#### Median Cut Tests

```swift
@Suite("Median Cut Quantization")
struct MedianCutTests {

    @Test("Returns requested color count (power of 2)")
    func testColorCount() {
        let quantizer = MedianCutQuantizer()
        let pixels = generateRandomPixels(count: 1000)

        let result16 = quantizer.quantize(pixels: pixels, targetColorCount: 16)
        #expect(result16.count == 16)

        let result32 = quantizer.quantize(pixels: pixels, targetColorCount: 32)
        #expect(result32.count == 32)
    }

    @Test("Handles single color input")
    func testSingleColor() {
        let quantizer = MedianCutQuantizer()
        let pixels = Array(repeating: (r: UInt8(128), g: UInt8(64), b: UInt8(192)), count: 100)

        let result = quantizer.quantize(pixels: pixels, targetColorCount: 8)
        // All colors should be very close to input
        for color in result {
            #expect(abs(Int(color.r) - 128) < 10)
            #expect(abs(Int(color.g) - 64) < 10)
            #expect(abs(Int(color.b) - 192) < 10)
        }
    }

    @Test("Produces distinct colors for varied input")
    func testDistinctColors() {
        let quantizer = MedianCutQuantizer()
        // Create pixels with clear color clusters
        var pixels: [(r: UInt8, g: UInt8, b: UInt8)] = []
        pixels.append(contentsOf: Array(repeating: (r: 255, g: 0, b: 0), count: 100))  // Red
        pixels.append(contentsOf: Array(repeating: (r: 0, g: 255, b: 0), count: 100))  // Green
        pixels.append(contentsOf: Array(repeating: (r: 0, g: 0, b: 255), count: 100))  // Blue
        pixels.append(contentsOf: Array(repeating: (r: 255, g: 255, b: 0), count: 100))  // Yellow

        let result = quantizer.quantize(pixels: pixels, targetColorCount: 4)

        // Should have 4 distinct colors
        let uniqueColors = Set(result.map { "\($0.r),\($0.g),\($0.b)" })
        #expect(uniqueColors.count == 4)
    }
}
```

#### DMC Matching Tests

```swift
@Suite("DMC Color Matching")
struct DMCMatchingTests {

    let matcher = DMCColorMatcher(palette: DMCDatabase.shared.threads)

    @Test("Black matches DMC 310")
    func testBlackMatch() {
        let black = RGBColor(r: 0, g: 0, b: 0)
        let match = matcher.closestThread(to: black)
        #expect(match.id == "310")
    }

    @Test("White matches BLANC or 3865")
    func testWhiteMatch() {
        let white = RGBColor(r: 255, g: 255, b: 255)
        let match = matcher.closestThread(to: white)
        #expect(match.id == "BLANC" || match.id == "3865")
    }

    @Test("Unique palette matching avoids duplicates")
    func testUniquePalette() {
        let colors = [
            RGBColor(r: 100, g: 50, b: 50),
            RGBColor(r: 102, g: 51, b: 51),  // Very similar
            RGBColor(r: 104, g: 52, b: 52),  // Very similar
        ]

        let matches = matcher.matchPalette(quantizedColors: colors, preferUnique: true)
        let uniqueIDs = Set(matches.map { $0.id })
        #expect(uniqueIDs.count == 3)  // Should all be different
    }
}
```

#### Pattern Tests

```swift
@Suite("Pattern Operations")
struct PatternTests {

    @Test("Pattern dimensions are correct")
    func testDimensions() {
        let pattern = createTestPattern(width: 100, height: 150)
        #expect(pattern.width == 100)
        #expect(pattern.height == 150)
        #expect(pattern.stitches.count == 150)  // Rows
        #expect(pattern.stitches[0].count == 100)  // Columns
    }

    @Test("Stitch count calculation")
    func testStitchCount() {
        var pattern = createTestPattern(width: 10, height: 10)
        // Set some stitches
        for y in 0..<5 {
            for x in 0..<10 {
                pattern.setStitch(Stitch(thread: DMCDatabase.shared.threads[0]), at: x, y: y)
            }
        }
        #expect(pattern.totalStitchCount == 50)
    }

    @Test("Progress tracking")
    func testProgress() {
        var pattern = createTestPattern(width: 10, height: 10)
        // Fill all stitches
        for y in 0..<10 {
            for x in 0..<10 {
                pattern.setStitch(Stitch(thread: DMCDatabase.shared.threads[0]), at: x, y: y)
            }
        }

        // Mark half as completed
        for y in 0..<5 {
            for x in 0..<10 {
                pattern.markCompleted(at: x, y: y, completed: true)
            }
        }

        #expect(pattern.completedStitchCount == 50)
        #expect(abs(pattern.progressPercentage - 50.0) < 0.1)
    }

    @Test("Finished size calculation")
    func testFinishedSize() {
        let pattern = createTestPattern(width: 140, height: 200)

        let size14 = pattern.finishedSize(fabricCount: 14)
        #expect(abs(size14.widthInches - 10.0) < 0.1)
        #expect(abs(size14.heightInches - 14.29) < 0.1)

        let size18 = pattern.finishedSize(fabricCount: 18)
        #expect(abs(size18.widthInches - 7.78) < 0.1)
    }
}
```

### Integration Test Specifications

```swift
@Suite("Pattern Generation Integration")
struct PatternGenerationIntegrationTests {

    @Test("Full pipeline produces valid pattern")
    func testFullPipeline() async throws {
        let service = PatternGenerationService()
        let testImage = createTestImage(width: 500, height: 500)

        let settings = GenerationSettings(
            targetWidth: 100,
            targetHeight: 100,
            maintainAspectRatio: true,
            maxColors: 16,
            colorMatchingMethod: .cielab,
            ditherEnabled: false
        )

        let pattern = try await service.generatePattern(
            from: testImage,
            settings: settings,
            progress: { _, _ in }
        )

        #expect(pattern.width == 100)
        #expect(pattern.height == 100)
        #expect(pattern.palette.count <= 16)
        #expect(pattern.totalStitchCount == 10000)
    }
}
```

---

## Appendix: Symbol Reference

Standard cross-stitch symbols in order of visual distinctiveness:

```
Primary (1-10):   ● ■ ▲ ◆ ★ ♦ ♥ ♣ ♠ ○
Secondary (11-20): □ △ ◇ ☆ ◐ ◑ ◒ ◓ ▪ ▫
Tertiary (21-30):  × + ⊕ ⊗ ⊙ ⊚ ◉ ◎ ▣ ▤
Extended (31-50):  A B C D E F G H I J K L M N O P Q R S T
```

---

*Document Version: 1.0 | Last Updated: 2026-02-16*
