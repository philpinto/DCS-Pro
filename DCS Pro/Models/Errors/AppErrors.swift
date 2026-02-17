import Foundation

/// Errors that can occur during pattern generation
enum PatternError: Error, LocalizedError {
    case imageConversionFailed
    case contextCreationFailed
    case pixelExtractionFailed
    case invalidDimensions
    case noColorsExtracted
    case generationCancelled
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image for processing"
        case .contextCreationFailed:
            return "Failed to create graphics context"
        case .pixelExtractionFailed:
            return "Failed to extract pixel data from image"
        case .invalidDimensions:
            return "Invalid pattern dimensions specified"
        case .noColorsExtracted:
            return "No colors could be extracted from the image"
        case .generationCancelled:
            return "Pattern generation was cancelled"
        }
    }
}

/// Errors that can occur during project operations
enum ProjectError: Error, LocalizedError {
    case invalidFile
    case invalidFormat
    case invalidManifest
    case missingManifest
    case invalidPattern
    case missingPattern
    case invalidSettings
    case missingSettings
    case incompatibleVersion(String)
    case fileNotFound(URL)
    case saveFailed(String)
    case loadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "The file is not a valid DCS Pro project"
        case .invalidFormat:
            return "The project file format is invalid"
        case .invalidManifest:
            return "The project manifest is invalid"
        case .missingManifest:
            return "The project manifest is missing"
        case .invalidPattern:
            return "The pattern data is corrupted or invalid"
        case .missingPattern:
            return "The pattern data is missing from the project"
        case .invalidSettings:
            return "The project settings are invalid"
        case .missingSettings:
            return "The project settings are missing"
        case .incompatibleVersion(let version):
            return "This project was created with an incompatible version (\(version))"
        case .fileNotFound(let url):
            return "File not found: \(url.lastPathComponent)"
        case .saveFailed(let reason):
            return "Failed to save project: \(reason)"
        case .loadFailed(let reason):
            return "Failed to load project: \(reason)"
        }
    }
}

/// Errors that can occur during PDF export
enum ExportError: Error, LocalizedError {
    case pdfCreationFailed
    case invalidPattern
    case noDestination
    case writeFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .pdfCreationFailed:
            return "Failed to create PDF document"
        case .invalidPattern:
            return "The pattern is invalid for export"
        case .noDestination:
            return "No destination specified for export"
        case .writeFailed(let reason):
            return "Failed to write file: \(reason)"
        }
    }
}

/// Errors during image import
enum ImportError: Error, LocalizedError {
    case unsupportedFormat(String)
    case fileTooLarge(Int64)
    case readFailed
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "Unsupported image format: \(format)"
        case .fileTooLarge(let bytes):
            let mb = Double(bytes) / 1_000_000
            return String(format: "File too large: %.1f MB (max 50 MB)", mb)
        case .readFailed:
            return "Failed to read image file"
        case .invalidImage:
            return "The file is not a valid image"
        }
    }
}
