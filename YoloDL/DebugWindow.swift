//
//  DebugWindow.swift
//  YoloDL
//
//  Created by Visa Uotila on 8.3.2026.
//

import SwiftUI

struct DebugWindow: View {
    
    @Environment(DownloadManager.self) var downloadManager

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            
            Button("Simulate Download") {
                downloadManager.simulateDownload()
            }
            .disabled(downloadManager.downloadIsActive)

            Button("Simulate Recording") {
                downloadManager.simulateRecording()
            }
            .disabled(downloadManager.downloadIsActive)

            Button("Simulate Metadata Failure") {
                downloadManager.simulateMetadataFailure()
            }
            .disabled(downloadManager.downloadIsActive)

            Button("Simulate Livestream Alert") {
                downloadManager.simulateLiveContentAlert()
            }
            .disabled(downloadManager.downloadIsActive)

            Button("Simulate Overwrite Confirmation") {
                downloadManager.simulateOverwriteConfirmation()
            }
            .disabled(downloadManager.downloadIsActive)
        }
        .padding()
    }
}

