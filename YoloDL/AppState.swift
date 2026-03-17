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
    case recording
    case finished
    case cancelled
    case error
    
    var statusText: String {
        switch self {
        case .ready: "Ready"
        case .preparing: "Preparing download"
        case .fetchingMetadata: "Fetching metadata"
        case .downloading: "Downloading"
        case .recording: "Recording"
        case .finished: "Finished"
        case .cancelled: "Cancelled"
        case .error: "An error occurred"
        }
    }

    var showsIndeterminateProgress: Bool {
        switch self {
        case .fetchingMetadata, .recording:
            true
        default:
            false
        }
    }
}
