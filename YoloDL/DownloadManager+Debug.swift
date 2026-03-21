//
//  DownloadManager+Debug.swift
//  YoloDL
//
// DEBUG-only DownloadManager extension. Provides simulation methods
// (simulateDownload, simulateRecording, simulateMetadataFailure,
// simulateLiveContentAlert, simulateOverwriteConfirmation) so UI states
// can be exercised without running a real yle-dl process.

import Foundation

#if DEBUG
extension DownloadManager {

    var isSimulatedRecordingActive: Bool {
        isActive && appState == .recording && activeProcess == nil
    }
    
    func simulateDownload() {
        simulationTask?.cancel()
        reset(for: .starting)
        isActive = true
        appState = .downloading
        totalDuration = 1800

        simulationTask = Task {
            while progress < 1.0 && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(80))
                guard !Task.isCancelled else { break }
                setDownloadProgress(to: progress + 0.01)

                let simulatedMB = progress * 500.0
                if simulatedMB >= 1000 {
                    recordingFileSize = String(format: "%.1f GB", simulatedMB / 1000)
                } else {
                    recordingFileSize = String(format: "%.1f MB", simulatedMB)
                }

                let speed = 25.0 + Double.random(in: -3.0...3.0)
                recentSpeeds.append(speed)
                if recentSpeeds.count > 5 {
                    recentSpeeds.removeFirst()
                }

                logger.appendLog("Simulated download progress: \(progress)", from: .stdout)
            }
            guard !Task.isCancelled else { return }
            reset(for: .finished)
        }
    }
    
    func simulateRecording() {
        simulationTask?.cancel()
        reset(for: .starting)
        isActive = true
        appState = .recording
        logger.appendLog("Simulated recording started.", from: .stdout)
    }

    func stopSimulatedRecording() {
        simulationTask?.cancel()
        simulationTask = nil
        reset(for: .finished)
        logger.appendLog("Simulated recording stopped.", from: .stdout)
    }

    func simulateMetadataFailure() {
        handleError(.totalDurationIsZero)
    }
    
    func simulateLiveContentAlert() {
        let mockMetadata = [
            EpisodeMetadata(
                // assuming the stream is live TV, but also works with any Int
                durationSeconds: nil,
                title: "Live Stream Test",
                episodeTitle: "Live Stream: Test Channel",
                publishedTimestamp: "2026-03-14T12:00:00Z",
                flavors: [EpisodeMetadata.Flavor(url: "https://example.com/live/test-stream")]
            )
        ]
        setPendingState(PendingDownload(metadata: mockMetadata, downloadLocation: "tmp/test", fileNamingPattern: "test-pattern", existingFilePath: nil))
        totalDuration = mockMetadata.reduce(0) { $0 + ($1.durationSeconds ?? 0) }

        showLiveContentAlert = true

        logger.appendLog("Simulated live content detection. Live content alert should appear.", from: .stdout)
    }

    func simulateOverwriteConfirmation() {
        let mockMetadata = [
            EpisodeMetadata(
                durationSeconds: 3600,
                title: "Test Episode S01E01",
                episodeTitle: "Test Series: Test Episode",
                publishedTimestamp: "2026-03-12T12:00:00Z",
                flavors: [EpisodeMetadata.Flavor(url: "Test URL")]
            )
        ]
        setPendingState(PendingDownload(metadata: mockMetadata, downloadLocation: "tmp/test", fileNamingPattern: "test-pattern", existingFilePath: nil))
        totalDuration = mockMetadata.reduce(0) { $0 + ($1.durationSeconds ?? 0) }

        showFileExistsDialog = true
        
        logger.appendLog("Simulated duplicate file detection. Confirmation dialog should appear.", from: .stdout)
    }

    func simulateUpdateAvailable() {
        debugUpdateResult = UpdateResult(
            version: "99.0",
            url: URL(string: "https://github.com/electric-visa/yolo-dl/releases/latest")!
        )
        showDebugUpdateAlert = true
    }
    
}
#endif
