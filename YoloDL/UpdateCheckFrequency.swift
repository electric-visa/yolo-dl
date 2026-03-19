//
//  UpdateCheckFrequency.swift
//  YoloDL
//

import Foundation

enum UpdateCheckFrequency: String, CaseIterable {
    case daily
    case weekly
    case monthly
    case never

    var label: String {
        switch self {
        case .daily:   "Daily"
        case .weekly:  "Weekly"
        case .monthly: "Monthly"
        case .never:   "Never"
        }
    }

    var intervalSeconds: TimeInterval? {
        switch self {
        case .daily:   86_400
        case .weekly:  604_800
        case .monthly: 2_592_000
        case .never:   nil
        }
    }
}
