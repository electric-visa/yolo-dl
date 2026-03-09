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
}

struct AlertMessage: Identifiable {
    
    let id = UUID()
    let text: String
}


