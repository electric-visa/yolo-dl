//
//  DebugWindow.swift
//  YoloDL
//
// DEBUG-only Window scene used during development.
// Mostly used for UI/UX testing with various simulated events.

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

            Button(downloadManager.isSimulatedRecordingActive ? "Stop Simulated Recording" : "Simulate Recording") {
                if downloadManager.isSimulatedRecordingActive {
                    downloadManager.stopSimulatedRecording()
                } else {
                    downloadManager.simulateRecording()
                }
            }
            .disabled(downloadManager.isActive && !downloadManager.isSimulatedRecordingActive)

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

            Button("Simulate Update Available") {
                downloadManager.simulateUpdateAvailable()
            }
        }
        .padding()
    }
}

#endif
