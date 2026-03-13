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
    
    init() {
        let lm = LogManager()
        _logManager = State(initialValue: lm)
        _downloadManager = State(initialValue: DownloadManager(logger: lm))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(downloadManager)
                .environment(logManager)        }
        Window("Log Window", id: "logWindow") {
            LogWindow()
                .environment(logManager)
        }
        #if DEBUG
        Window("Debug Window", id: "debug") {
            DebugWindow()
                .environment(downloadManager)
        }
        #endif
    }
}
