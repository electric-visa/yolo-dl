//
//  DownloadManager.swift
//  YoloDL
//
//  Created by Visa Uotila on 8.3.2026.
//

import Foundation


@MainActor @Observable class DownloadManager {
    
#if DEBUG
    // Timer variable for a simulation run.
    var simulationTask: Task<Void, Never>? = nil
#endif
    
    // Paths to binaries
    let pathToYleDl: String = DownloadManager.bundledPath(for: "yle-dl", fallback: "/opt/homebrew/bin/yle-dl")
    let pathToFfmpeg: String = DownloadManager.bundledPath(for: "ffmpeg", fallback: "/opt/homebrew/bin/ffmpeg")
    let pathToFfprobe: String = DownloadManager.bundledPath(for: "ffprobe", fallback: "/opt/homebrew/bin/ffprobe")

    private static func bundledPath(for name: String, fallback: String) -> String {
        Bundle.main.path(forResource: name, ofType: nil) ?? fallback
    }
    
    // Wiring ErrorParser to DownloadManager for parsing stderr outputs.
    let errorParser = ErrorParser()
    
    // Variables to be passed to yle-dl
    var sourceURL: String = ""

    // Variables and constants related to download & progress bar logic
    var isActive: Bool = false
    var isFinished: Bool = false
    var activeProcess: Process? = nil
    var isCancelled: Bool = false
    var totalDuration: Int = 0
    var progress: Double = 0
    var recordingElapsed: String = ""
    var recordingFileSize: String = ""
    var recordingElapsedSeconds: Int = 0
    var recordingDurationSeconds: Int? = nil
    var recordingTimerTask: Task<Void, any Error>?
    var recentSpeeds: [Double] = []

    var alertToShow: AlertMessage? = nil
    
    var isShowingAlert: Bool {
        get { alertToShow != nil }
        set { if !newValue { alertToShow = nil } }
    }

    var appState: AppState = .ready
    
    let logger: LogManager
    
    init(logger: LogManager) {
        self.logger = logger
    }
    
    var pendingDownload: PendingDownload? = nil
    var showFileExistsDialog: Bool = false

    // Booleans to trigger confirmation dialogs
    var showLiveContentAlert: Bool = false
    
    // Function to check for valid user inputs.
    // Currently guards for empty URL and destination folder.
    
    func validateInputs(downloadLocation: String) -> Bool {
        guard !sourceURL.isEmpty else { handleError(.emptyURL); return false }
        guard !downloadLocation.isEmpty else { handleError(.noFolderSelected); return false }
        return true
    }
    
    // Function to reset the download state
    func resetDownloadState() {
        progress = 1.0
        isActive = false
        isFinished = true
        recordingFileSize = ""
        recentSpeeds = []
    }
    
    // PHASE A: Validate inputs, fetch metadata, and check for duplicates.
    func downloadFiles(downloadLocation: String, fileNamingPattern: String, namingPreset: NamingPreset, appMode: AppMode) async {
            
            // Revert from a possible cancelled state.
            isCancelled = false
            
            // Validate user inputs.
            appState = .preparing
            guard validateInputs(downloadLocation: downloadLocation) else { return }
            
            // Reset isFinished state to false
            // and flush the log buffer.
            isFinished = false
            logger.clearLog()
            recordingElapsed = ""
            recordingElapsedSeconds = 0
            recordingFileSize = ""
            recentSpeeds = []

            // Fetch metadata, calculate total duration and check for duplicate files.
            // Includes guards for invalid metadata.
            appState = .fetchingMetadata
            let episodes = await fetchMetadata()

            totalDuration = episodes?.reduce(0) { $0 + ($1.durationSeconds ?? 0) } ?? 0
            
            if appState == .error { return }
        
            let firstEpisode = episodes?.first
            let contentType = firstEpisode?.contentType
            let isVOD = contentType == .vod
            
            if isVOD {
                guard totalDuration != 0 else { handleError(.totalDurationIsZero); return }
            }
        
            if !isVOD && appMode == .download {
                showLiveContentAlert = true
                return
            }
            
            // Check for duplicate files
            var existingFilePath: String? = nil
            if let episodes = episodes, !episodes.isEmpty {
                let stem = episodes[0].predictedFileStem(for: namingPreset)
                if !stem.isEmpty {
                    for ext in ["mkv", "mp4"] {
                        let path = (downloadLocation as NSString).appendingPathComponent("\(stem).\(ext)")
                        if FileManager.default.fileExists(atPath: path) {
                            existingFilePath = path
                            break
                        }
                    }
                }
            }

            pendingDownload = PendingDownload(
                metadata: episodes ?? [],
                downloadLocation: downloadLocation,
                fileNamingPattern: fileNamingPattern,
                existingFilePath: existingFilePath
            )

            // If duplicate found, trigger confirmation dialog
            if existingFilePath != nil {
                showFileExistsDialog = true
                return
            }

            // No duplicates found, proceed directly to Phase B
            startDownloadProcess()
    }
    
    func showError(title: String, text: String) {
        appState = .error
        alertToShow = AlertMessage(title: title, text: text)
    }

    func handleError(_ error: InputValidationError) {
        showError(title: error.title, text: error.message)
    }
    
    // Function to clear pending state after cancellation or successful download
    func clearPendingState() {
        pendingDownload = nil
    }
    
    func stopRecording() {
        recordingTimerTask?.cancel()
        recordingTimerTask = nil
        recordingDurationSeconds = nil
#if DEBUG
        if isSimulatedRecordingActive {
            stopSimulatedRecording()
            return
        }
#endif
        activeProcess?.terminate()
        activeProcess = nil
    }

    // Function to cancel an ongoing download
    // with additional actions during a debug simulation run.
    func cancelDownload() {
        recordingTimerTask?.cancel()
        recordingTimerTask = nil
        recordingDurationSeconds = nil
        isCancelled = true
        activeProcess?.terminate()
        activeProcess = nil
        appState = .cancelled
        isActive = false
        progress = 0.0
        recentSpeeds = []
#if DEBUG
        simulationTask?.cancel()
        simulationTask = nil
#endif
    }
    
    // Function to reset download parameters for a simulated run
    // called from DownloadManager+Debug
    func resetForSimulation() {
        progress = 0.0
        isActive = true
        appState = .downloading
        isFinished = false
        recentSpeeds = []
    }
    
    func setPendingState(_ download: PendingDownload) {
        pendingDownload = download
    }
    
    func setDownloadProgress(to value: Double) {
        progress = value
    }
}
