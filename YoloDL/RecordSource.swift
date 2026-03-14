//
//  RecordSource.swift
//  YoloDL 0.1
//
//  Created on 13.3.2026.
//

enum RecordSource: String, CaseIterable {
    case tvChannel
    case streamURL
    
    var label: String {
        switch self {
        case .tvChannel:
            return "TV Channel"
        case .streamURL:
            return "Stream URL"
        }
    }
}
