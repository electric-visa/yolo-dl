//
//  YoloDLApp.swift
//  YoloDL
//
//  Created by Visa Uotila on 5.3.2026.
//

import SwiftUI

@main
struct YoloDLApp: App {
    @State private var downloadManager = DownloadManager()
    @State private var logManager = LogManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(downloadManager)
                .environment(logManager)
                .onAppear {
                    downloadManager.logger = logManager
                }
        }
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
