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
    var durationHours: Int = 0
    var durationMinutes: Int = 0

    var totalMinutes: Int { durationHours * 60 + durationMinutes }

    func prefillStream(url: String) {
        recordSource = .streamURL
        streamURL = url
    }
}
