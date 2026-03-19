//
//  RecordSource.swift
//  YoloDL
//
// Enum for the recording source types.
// Drives the source picker in RecordModeView and determines which
// argument yle-dl receives at launch time.

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
