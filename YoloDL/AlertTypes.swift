//
//  AlertTypes.swift
//  YoloDL
//
// InputValidationError enum covering the three invalid-input conditions
// (emptyURL, noFolderSelected, totalDurationIsZero).

enum InputValidationError: Identifiable {
    case emptyURL
    case noFolderSelected
    case totalDurationIsZero
    case folderNotFound
    
    var id: String { String(describing: self) }
    
    var title: String {
        switch self {
        case .emptyURL: "No URL provided"
        case .noFolderSelected: "No folder selected"
        case .folderNotFound: "Folder not found"
        case .totalDurationIsZero: "Content unavailable"
        }
    }

    var message: String {
        switch self {
        case .emptyURL: "No URL was provided. Check that the URL field is not empty."
        case .noFolderSelected: "No download folder is currently selected. Please use the Folder button to select one."
        case .folderNotFound: "The selected folder no longer exists. It may have been moved or deleted. Please choose a new folder."
        case .totalDurationIsZero: "The target file's length was measured to be zero. The file might not be available. Please check the URL and try again."
        }
    }
}

