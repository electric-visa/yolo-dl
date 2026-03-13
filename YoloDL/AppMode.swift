//
//  AppMode.swift
//  YoloDL
//
//  Created on 13.3.2026.
//

enum AppMode: String, CaseIterable {
    case download
    case record
    
    var label: String {
        switch self {
        case .download: "Download"
        case .record: "Record"
        }
    }
}
