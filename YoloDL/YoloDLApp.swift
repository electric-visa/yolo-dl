//
//  YoloDLApp.swift
//  YoloDL
//
//  Created by Visa Uotila on 5.3.2026.
//

import SwiftUI

@main
struct YoloDLApp: App {
    @State private var downloadManager: DownloadManager
    @State private var logManager: LogManager
    @State private var recordingInput: RecordingInput = RecordingInput()

    init() {
        let lm = LogManager()
        _logManager = State(initialValue: lm)
        _downloadManager = State(initialValue: DownloadManager(logger: lm))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(downloadManager)
                .environment(logManager)
                .environment(recordingInput)
        }
        .defaultSize(width: 520, height: 340)
        Window("Log Window", id: "logWindow") {
            LogWindow()
                .environment(logManager)
        }
        Settings {
            SettingsView()
        }
        #if DEBUG
        Window("Debug Window", id: "debug") {
            DebugWindow()
                .environment(downloadManager)
                .environment(recordingInput)
        }
        #endif
    }
}
