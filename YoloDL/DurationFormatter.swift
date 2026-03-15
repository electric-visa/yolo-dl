//
//  DurationFormatter.swift
//  YoloDL
//
//  Created on 15.3.2026.
//

import Foundation

enum DurationFormatter {
    static func format(minutes: Int) -> String {
        guard minutes > 0 else { return "No limit" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours) h") }
        if remainingMinutes > 0 { parts.append("\(remainingMinutes) min") }
        return parts.joined(separator: " ")
    }

    static func formatEstimate(seconds: Int) -> String {
        if seconds < 10 {
            return "Almost done"
        } else if seconds < 60 {
            let rounded = ((seconds + 2) / 5) * 5
            return "~\(rounded) sec"
        } else if seconds < 300 {
            let rounded = ((seconds + 15) / 30) * 30
            let minutes = rounded / 60
            let secs = rounded % 60
            if secs > 0 {
                return "~\(minutes) min \(secs) sec"
            } else {
                return "~\(minutes) min"
            }
        } else {
            let minutes = (seconds + 30) / 60
            if minutes < 60 {
                return "~\(minutes) min"
            } else {
                let hours = minutes / 60
                let remainingMinutes = minutes % 60
                if remainingMinutes > 0 {
                    return "~\(hours) h \(remainingMinutes) min"
                } else {
                    return "~\(hours) h"
                }
            }
        }
    }

    static func formatCountdown(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}
