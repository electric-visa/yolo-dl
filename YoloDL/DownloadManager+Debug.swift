//
//  DownloadManager+Debug.swift
//  YoloDL
//
//  Created by Visa Uotila on 9.3.2026.
//

import Foundation

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
                guard !Task.isCancelled else { break }
                setDownloadProgress(to: downloadProgress + 0.01)
                logger?.appendLog("Simulated download progress: \(downloadProgress)", from: .stdout)
            }
            guard !Task.isCancelled else { return }
            resetDownloadState()
            do {
                try await Task.sleep(for: .seconds(progressBarFinishedSpeed))
                appState = .finished
            } catch {
            }
        }
    }
    
    // Function to simulate metadata failure
    func simulateMetadataFailure() {
        handleError(.totalDurationIsZero)
    }
}
#endif
