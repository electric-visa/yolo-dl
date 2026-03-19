//
//  FileFormat.swift
//  YoloDL
//
// Enum for the supported output container formats.
// The raw value is passed directly to yle-dl via --preferformat.
// User-facing labels are provided for the SettingsView picker.

enum FileFormat: String, CaseIterable {
    case mp4
    case mkv

    var label: String {
        switch self {
        case .mp4: "MP4"
        case .mkv: "MKV"
        }
    }
}
