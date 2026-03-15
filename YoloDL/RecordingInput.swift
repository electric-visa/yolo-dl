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
    var durationMinutes: Int = 0

    func prefillStream(url: String) {
        recordSource = .streamURL
        streamURL = url
    }
}
