//
//  QualityPreset.swift
//  YoloDL
//
//  Created on 16.3.2026.
//

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
