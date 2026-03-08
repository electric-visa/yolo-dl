//
//  YoloDLApp.swift
//  YoloDL
//
//  Created by Visa Uotila on 5.3.2026.
//

import SwiftUI

@main
struct YoloDLApp: App {
    @StateObject private var manager = DownloadManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
        }
        #if DEBUG
        Window("Debug Window", id: "debug") {
            DebugWindow()
                .environmentObject(manager)
        }
        #endif
    }
}
