//
//  YoloDLApp.swift
//  YoloDL
//
//  Created by Visa Uotila on 5.3.2026.
//

import SwiftUI

@main
struct YoloDLApp: App {
    @StateObject private var downloadManager = DownloadManager()
    @StateObject private var logManager = LogManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(downloadManager)
                .environmentObject(logManager)
                .onAppear {
                    downloadManager.logger = logManager
                }
        }
        #if DEBUG
        Window("Debug Window", id: "debug") {
            DebugWindow()
                .environmentObject(downloadManager)
                .environmentObject(logManager)
        }
        #endif
    }
}
