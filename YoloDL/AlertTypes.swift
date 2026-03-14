//
//  AlertTypes.swift
//  YoloDL
//
//  Created by Visa Uotila on 9.3.2026.
//

enum InputValidationError: Identifiable {
    case emptyURL
    case noFolderSelected
    case totalDurationIsZero
    
    var id: String { String(describing: self) }
    
    var title: String {
        switch self {
        case .emptyURL: "No URL provided"
        case .noFolderSelected: "No folder selected"
        case .totalDurationIsZero: "Content unavailable"
        }
    }

    var message: String {
        switch self {
        case .emptyURL: "No URL was provided. Check that the URL field is not empty."
        case .noFolderSelected: "No download folder is currently selected. Please use the Folder button to select one."
        case .totalDurationIsZero: "The target file's length was measured to be zero. The file might not be available. Please check the URL and try again."
        }
    }
}

