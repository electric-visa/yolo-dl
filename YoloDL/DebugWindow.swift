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
        simulationTimer?.invalidate()
        resetForSimulation()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            DispatchQueue.main.async {
                if self.downloadProgress < 1.0 {
                    self.setDownloadProgress(to: self.downloadProgress + 0.01)
                    self.logger?.appendLog("Simulated download progress: \(self.downloadProgress)", from: .stdout)
                } else {
                    self.resetDownloadState()
                    timer.invalidate()
                    self.simulationTimer = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.progressBarFinishedSpeed) {
                        self.appState = .finished
                    }
                }
            }
        }
    }
    
    // Function to simulate metadata failure
    func simulateMetadataFailure() {
        handleError(.totalDurationIsZero)
    }
    
}
#endif
