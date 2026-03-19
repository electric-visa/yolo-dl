//
//  AppMode.swift
//  YoloDL
//
// Enum for the two top-level operating modes: .download and .record.
// Provides a user-facing label string used by the mode picker in ContentView.

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
