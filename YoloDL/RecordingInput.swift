//
//  RecordingInput.swift
//  YoloDL
//
// @Observable @MainActor model holding the user's recording parameters.
// Exposes totalMinutes and a prefillStream() helper for populating
// the URL field from a URL paste.

import Foundation

@Observable @MainActor class RecordingInput {
    var recordSource: RecordSource = .streamURL
    var selectedChannel: TVChannel = .tv1
    var streamURL: String = ""
    var useTimeLimit: Bool = true
    var durationHours: Int = 0
    var durationMinutes: Int = 0

    var totalMinutes: Int { durationHours * 60 + durationMinutes }
    var hasInvalidDuration: Bool { totalMinutes < 0 }

    func normalize() {
        if durationMinutes < 0 { durationMinutes = 0 }
        if durationHours < 0 { durationHours = 0 }
        if durationMinutes >= 60 {
            durationHours += durationMinutes / 60
            durationMinutes = durationMinutes % 60
        }
    }

    func prefillStream(url: String) {
        recordSource = .streamURL
        streamURL = url
    }
}
