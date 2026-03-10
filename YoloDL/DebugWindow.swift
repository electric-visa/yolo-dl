//
//  DebugWindow.swift
//  YoloDL
//
//  Created by Visa Uotila on 8.3.2026.
//

import SwiftUI

struct DebugWindow: View {
    
    @EnvironmentObject var downloadManager: DownloadManager
    
    // COMMENTED OUT, MAYBE TO BE USED LATER
    // @EnvironmentObject var logManager: LogManager
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            
            Button("Simulate Download") {
                downloadManager.simulateDownload()
            }
            
            Button("Simulate Metadata Failure") {
                downloadManager.simulateMetadataFailure()
            }
        }
        .padding()
    }
}

#if DEBUG
extension DownloadManager {
    
    // Function for a simulated download to test and/or debug the progress bar.
    // Calls resetForSimulation() and resetDownloadState() from DownloadManager.
    // The simulationTime variable is also stored in DownloadManager.
    func simulateDownload() {
        simulationTask?.cancel()
        resetForSimulation()
        simulationTask = Task {
            while downloadProgress < 1.0 && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds (80))
                setDownloadProgress(to: downloadProgress + 0.01)
                logger?.appendLog("Simulated download progress: \(downloadProgress)", from: .stdout)
            }
            resetDownloadState()
            try? await Task.sleep(for: .seconds(progressBarFinishedSpeed))
            appState = .finished
        }
    }
    
    // Function to simulate metadata failure
    func simulateMetadataFailure() {
        handleError(.totalDurationIsZero)
    }
}
#endif
