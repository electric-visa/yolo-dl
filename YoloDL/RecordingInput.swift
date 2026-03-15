//
//  RecordingInput.swift
//  YoloDL
//
//  Created on 15.3.2026.
//

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
