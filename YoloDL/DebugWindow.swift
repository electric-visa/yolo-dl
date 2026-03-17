//
//  DebugWindow.swift
//  YoloDL
//
//  Created by Visa Uotila on 8.3.2026.
//
#if DEBUG

import SwiftUI

struct DebugWindow: View {
    
    @Environment(DownloadManager.self) var downloadManager

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            
            Button("Simulate Download") {
                downloadManager.simulateDownload()
            }
            .disabled(downloadManager.isActive)

            Button("Simulate Recording") {
                downloadManager.simulateRecording()
            }
            .disabled(downloadManager.isActive)

            Button("Simulate Metadata Failure") {
                downloadManager.simulateMetadataFailure()
            }
            .disabled(downloadManager.isActive)

            Button("Simulate Livestream Alert") {
                downloadManager.simulateLiveContentAlert()
            }
            .disabled(downloadManager.isActive)

            Button("Simulate Overwrite Confirmation") {
                downloadManager.simulateOverwriteConfirmation()
            }
            .disabled(downloadManager.isActive)
            
            Button("Reset Splash Screen") {
                UserDefaults.standard.set(false, forKey: "hasSeenWelcome")
            }
        }
        .padding()
    }
}

#endif
