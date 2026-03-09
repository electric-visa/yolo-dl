//
//  AppStates.swift
//  YoloDL
//
//  Created by Visa Uotila on 9.3.2026.
//

enum AppState {
    case ready
    case preparing
    case fetchingMetadata
    case downloading
    case finished
    case cancelled
    case error
    
    var statusText: String {
        switch self {
        case .ready: return "Ready"
        case .preparing: return "Preparing download"
        case .fetchingMetadata: return "Fetching metadata"
        case .downloading: return "Downloading"
        case .finished: return "Finished"
        case .cancelled: return "Cancelled"
        case .error: return "An error occurred"
        }
    }
}
