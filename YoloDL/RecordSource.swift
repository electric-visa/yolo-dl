//
//  RecordSource.swift
//  YoloDL 0.1
//
//  Created on 13.3.2026.
//

enum RecordSource: String, CaseIterable {
    case streamURL
    case tvChannel
    
    var label: String {
        switch self {
        case .streamURL:
            return "Stream URL"
        case .tvChannel:
            return "TV Channel"

        }
    }
}
