//
//  SubtitleLanguage.swift
//  YoloDL
//
//  Created on 15.3.2026.
//

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
