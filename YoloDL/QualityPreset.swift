//
//  QualityPreset.swift
//  YoloDL
//
// Enum for quality settings.
// The selected value maps to a bitrate argument passed to yle-dl via
// --maxbitrate. Exposed in the Advanced Options section of SettingsView.

enum QualityPreset: String, CaseIterable {
    case best = "best"
    case worst = "worst"

    var label: String {
        switch self {
        case .best: "Best quality"
        case .worst: "Smallest file"
        }
    }
}
