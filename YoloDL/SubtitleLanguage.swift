//
//  SubtitleLanguage.swift
//  YoloDL
//
// Enum for subtitle embedding options.
// Provides both the yle-dl language code and a localised label shown
// in the SettingsView subtitle picker.

enum SubtitleLanguage: String, CaseIterable {
    case finnish = "fin"
    case swedish = "swe"
    case none = "none"

    var label: String {
        switch self {
        case .finnish: "Finnish"
        case .swedish: "Swedish"
        case .none: "None"
        }
    }
}
