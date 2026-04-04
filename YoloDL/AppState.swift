//
//  AppStates.swift
//  YoloDL
//
// Enum representing every distinct phase of the application lifecycle.
// Provides statusText for the UI label 
// and showsIndeterminateProgress for the progress bar.

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
        case .preparing, .fetchingMetadata, .recording:
            true
        default:
            false
        }
    }
}
