//
//  AlertTypes.swift
//  YoloDL
//
//  Created by Visa Uotila on 9.3.2026.
//

import Foundation

enum InputValidationError: Identifiable {
    case emptyURL
    case noFolderSelected
    case totalDurationIsZero
    
    var id: String { String(describing: self) }
    
    var title: String {
        switch self {
        case .emptyURL:
            return "No URL provided."
        case .noFolderSelected:
            return "No folder selected."
        case .totalDurationIsZero:
            return "Metadata error."
        }
    }
    
    var message: String {
        switch self {
        case .emptyURL:
            return "No URL was provided. Check that the URL field is not empty."
        case .noFolderSelected:
            return "No download folder is currently selected. Please use the Folder button to select one."
        case .totalDurationIsZero:
            return "The metadata shows the total duration as zero. Cannot initiate download."
        }
    }
}

