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
    let pathToYleDl: String = "/opt/homebrew/bin/yle-dl"
    let pathToFfmpeg: String = "/opt/homebrew/bin/ffmpeg"
    let pathToFfprobe: String = "/opt/homebrew/bin/ffprobe"
    
    // Wiring ErrorParser to DownloadManager for parsing stderr outputs.
    let errorParser = ErrorParser()
    
    // Variables to be passed to yle-dl
    var sourceURL: String = ""

    // Variables and constants related to download & progress bar logic
    private(set) var downloadIsActive: Bool = false
    private(set) var downloadIsFinished: Bool = false
    private var activeDownload: Process? = nil
    private var downloadIsCancelled: Bool = false
    private var finishAnimationTask: Task<Void, any Error>?
    var totalDuration: Int = 0
    private(set) var downloadProgress: Double = 0
    private(set) var recordingElapsed: String = ""
    private(set) var recordingFileSize: String = ""
    private(set) var recordingElapsedSeconds: Int = 0
    private(set) var recordingDurationSeconds: Int? = nil
    private var recordingTimerTask: Task<Void, any Error>?

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
    
    // Temporary storage for metadata while user alert is shown
    private(set) var pendingMetadata: [EpisodeMetadata]? = nil
    
    // Booleans to trigger confirmation dialogs
    var showDuplicateConfirmation: Bool = false
    var showLiveContentAlert: Bool = false
    
    // Stored parameters for Phase B execution after confirmation
    private(set) var pendingDownloadLocation: String = ""
    private(set) var pendingFileNamingPattern: String = ""
    private(set) var duplicateFilePath: String? = nil
    
    // Function to check for valid user inputs.
    // Currently guards for empty URL and destination folder.
    
    func validateInputs(downloadLocation: String) -> Bool {
        guard !sourceURL.isEmpty else { handleError(.emptyURL); return false }
        guard !downloadLocation.isEmpty else { handleError(.noFolderSelected); return false }
        return true
    }
    
    // Parse progress from stderr output containing ffmpeg time= values
    private func parseProgressFromStderr(_ output: String) -> Double? {
        for line in output.components(separatedBy: "\r") {
            guard line.contains("time="), !line.contains("time=N/A"),
                  let timePart = line.components(separatedBy: "time=").last,
                  let timeString = timePart.components(separatedBy: " ").first,
                  timeString != "N/A" else { continue }
            
            let components = timeString.components(separatedBy: ":")
            if components.count == 3 {
                let hours = Double(components[0].trimmingCharacters(in: .whitespaces)) ?? 0
                let minutes = Double(components[1].trimmingCharacters(in: .whitespaces)) ?? 0
                let seconds = Double(components[2].trimmingCharacters(in: .whitespaces)) ?? 0
                let currentSeconds = hours * 3600 + minutes * 60 + seconds
                
                return totalDuration > 0 ? currentSeconds / Double(totalDuration) : 0
            }
        }
        return nil
    }
    
    private func parseRecordingFromStderr(_ output: String) {
        for line in output.components(separatedBy: "\r") {
            if line.contains("elapsed="),
               let elapsedPart = line.components(separatedBy: "elapsed=").last,
               let timeString = elapsedPart.components(separatedBy: " ").first {
                let trimmed = timeString.components(separatedBy: ".").first ?? timeString
                let components = trimmed.components(separatedBy: ":")
                if components.count == 3 {
                    let hours = Int(components[0]) ?? 0
                    let minutes = Int(components[1]) ?? 0
                    let seconds = Int(components[2]) ?? 0
                    recordingElapsedSeconds = hours * 3600 + minutes * 60 + seconds
                    if hours > 0 {
                        recordingElapsed = String(format: "%d:%02d:%02d", hours, minutes, seconds)
                    } else {
                        recordingElapsed = String(format: "%d:%02d", minutes, seconds)
                    }
                }
            }

            if line.contains("size="),
               let sizePart = line.components(separatedBy: "size=").last,
               let kibString = sizePart.trimmingCharacters(in: .whitespaces).components(separatedBy: "KiB").first,
               let kibValue = Double(kibString.trimmingCharacters(in: .whitespaces)) {
                let megabytes = kibValue * 1024 / 1_000_000
                if megabytes >= 1000 {
                    let gigabytes = megabytes / 1000
                    recordingFileSize = String(format: "%.1f GB", gigabytes)
                } else {
                    recordingFileSize = String(format: "%.1f MB", megabytes)
                }
            }
        }
    }

    // Function to reset the download state
    func resetDownloadState() {
        finishAnimationTask?.cancel()
        downloadProgress = 1.0
        downloadIsActive = false
        finishAnimationTask = Task {
            try await Task.sleep(for: .seconds(ProgressBarView.progressBarFinishedSpeed))
            self.downloadIsFinished = true
        }
    }
    
    // Function to fetch metadata.
    func fetchMetadata() async -> [EpisodeMetadata]? {
        
        let metadataParsing = Process()
        metadataParsing.executableURL = URL(fileURLWithPath: pathToYleDl)
        metadataParsing.arguments = ["--ffmpeg", pathToFfmpeg, "--ffprobe", pathToFfprobe, "--showmetadata", sourceURL]
        
        let stderrPipe = Pipe()
        metadataParsing.standardError = stderrPipe
        
        let stdoutPipe = Pipe()
        metadataParsing.standardOutput = stdoutPipe
        
        return await withCheckedContinuation { continuation in
            
            metadataParsing.terminationHandler = { _ in
                let rawErrorData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let rawErrorString = String(data: rawErrorData, encoding: .utf8) ?? ""
                
                Task { @MainActor in
                    self.logger.appendLog(rawErrorString, from: .stderr)
                    if let errorMessage = self.errorParser.parseErrors(rawErrorString) {
                        self.showError(title: "Metadata error", text: errorMessage)
                    }
                }
                
                let parsedMetaData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let episodes = try? JSONDecoder().decode([EpisodeMetadata].self, from: parsedMetaData)
                
                continuation.resume(returning: episodes)
            }
            
            do {
                try metadataParsing.run()
            } catch {
                Task { @MainActor in
                    self.logger.appendLog(error.localizedDescription, from: .stderr)
                    self.showError(title: "Metadata error", text: "Metadata error Details: \(error.localizedDescription)")
                }
                continuation.resume(returning: nil)
            }
        }
    }
    
    // PHASE A: Validate inputs, fetch metadata, and check for duplicates.
    func downloadFiles(downloadLocation: String, fileNamingPattern: String, namingPreset: NamingPreset, appMode: AppMode) async {
            
            // Revert from a possible cancelled state.
            downloadIsCancelled = false
            
            // Validate user inputs.
            appState = .preparing
            guard validateInputs(downloadLocation: downloadLocation) else { return }
            
            // Reset downloadIsFinished state to false
            // and flush the log buffer.
            downloadIsFinished = false
            logger.clearLog()
            recordingElapsed = ""
            recordingElapsedSeconds = 0
            recordingFileSize = ""

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
            var duplicateFound = false
            if let episodes = episodes, !episodes.isEmpty {
                let stem = episodes[0].predictedFileStem(for: namingPreset)
                if !stem.isEmpty {
                    for ext in ["mkv", "mp4"] {
                        let path = (downloadLocation as NSString).appendingPathComponent("\(stem).\(ext)")
                        if FileManager.default.fileExists(atPath: path) {
                            duplicateFound = true
                            duplicateFilePath = path
                            break
                        }
                    }
                }
            }
            
            // Store the parameters for potential Phase B execution
            pendingMetadata = episodes
            pendingDownloadLocation = downloadLocation
            pendingFileNamingPattern = fileNamingPattern
            
            // If duplicate found, trigger confirmation dialog
            if duplicateFound {
                showDuplicateConfirmation = true
                return
            }
            
            // No duplicates found, proceed directly to Phase B
            startDownloadProcess()
    }
    
    private func launchProcess(
        arguments: [String],
        initialState: AppState,
        onStderr: (@MainActor @Sendable (String) -> Void)? = nil,
        onTermination: (@MainActor @Sendable () -> Void)? = nil
    ) {
        downloadIsActive = true
        appState = initialState
        
        let process = Process()
        activeDownload = process
        
        let stderrPipe = Pipe()
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let output = String(data: handle.availableData, encoding: .utf8) ?? ""
            Task { @MainActor in
                self.logger.appendLog(output, from: .stderr)
                if let friendlyMessage = self.errorParser.parseErrors(output) {
                    self.showError(title: "Error", text: friendlyMessage)
                }
                onStderr?(output)
            }
        }
        
        let outputPipe = Pipe()
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let output = String(data: handle.availableData, encoding: .utf8) ?? ""
            Task { @MainActor in
                self.logger.appendLog(output, from: .stdout)
            }
        }
        
        process.terminationHandler = { _ in
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            outputPipe.fileHandleForReading.readabilityHandler = nil
            Task { @MainActor in
                if !self.downloadIsCancelled {
                    onTermination?()
                }
            }
        }
        
        process.standardError = stderrPipe
        process.standardOutput = outputPipe
        process.executableURL = URL(fileURLWithPath: self.pathToYleDl)
        process.arguments = arguments
        
        do {
            try process.run()
        } catch {
            self.logger.appendLog(error.localizedDescription, from: .stderr)
            self.showError(title: "Process error", text: "Failed to start. Details: \(error.localizedDescription)")
        }
    }
    
    // PHASE B: Execute the actual download process using stored metadata.
    func startDownloadProcess() {
        
        // Arguments to be passed to launchProcess()
        let arguments = [
            "--ffmpeg", pathToFfmpeg,
            "--ffprobe", pathToFfprobe,
            "--destdir", pendingDownloadLocation,
            "--output-template", pendingFileNamingPattern,
            sourceURL
        ]
        
        // Ensure we have metadata and parameters to work with
        guard let episodes = pendingMetadata else {
            handleError(.totalDurationIsZero)
            return
        }
        
        // Delete existing file if this is an overwrite operation
        if let duplicatePath = duplicateFilePath {
            do {
                try FileManager.default.removeItem(atPath: duplicatePath)
                logger.appendLog("Deleted existing file: \(duplicatePath)", from: .stdout)
                duplicateFilePath = nil // Clear after successful deletion
            } catch {
                logger.appendLog("Failed to delete existing file: \(error.localizedDescription)", from: .stderr)
                showError(title: "File Deletion Error", text: "Could not delete existing file: \(error.localizedDescription)")
                return
            }
        }
        
        launchProcess(
            arguments: arguments,
            initialState: .downloading,
            onStderr: { output in
                if let progress = self.parseProgressFromStderr(output) {
                    self.downloadProgress = progress
                }
            },
            onTermination: {
                self.resetDownloadState()
                self.appState = .finished
                self.clearPendingState()
            }
        )
    }
    
    func startRecording(source: String, downloadLocation: String, recordSource: RecordSource, duration: Int? = nil) {
        downloadIsCancelled = false
        downloadIsFinished = false
        logger.clearLog()
        if let duration {
            recordingDurationSeconds = duration
            recordingTimerTask = Task {
                try await Task.sleep(for: .seconds(duration))
                stopRecording()
            }
        }
        recordingElapsed = ""
        recordingElapsedSeconds = 0
        recordingFileSize = ""

        guard !downloadLocation.isEmpty else { handleError(.noFolderSelected); return }
        guard !source.isEmpty else { handleError(.emptyURL); return }

        var arguments = [
            "--ffmpeg", pathToFfmpeg,
            "--ffprobe", pathToFfprobe,
            "--destdir", downloadLocation
        ]

        if recordSource == .streamURL, let duration {
            arguments += ["--duration", String(duration)]
        }

        arguments.append(source)

        launchProcess(
            arguments: arguments,
            initialState: .recording,
            onStderr: { output in
                self.parseRecordingFromStderr(output)
            },
            onTermination: {
                self.resetDownloadState()
                self.appState = .finished
            }
        )
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
        pendingMetadata = nil
        pendingDownloadLocation = ""
        pendingFileNamingPattern = ""
        duplicateFilePath = nil
    }
    
    func stopRecording() {
        recordingTimerTask?.cancel()
        recordingTimerTask = nil
        recordingDurationSeconds = nil
        activeDownload?.terminate()
        activeDownload = nil
    }

    // Function to cancel an ongoing download
    // with additional actions during a debug simulation run.
    func cancelDownload() {
        recordingTimerTask?.cancel()
        recordingTimerTask = nil
        recordingDurationSeconds = nil
        downloadIsCancelled = true
        activeDownload?.terminate()
        activeDownload = nil
        appState = .cancelled
        downloadIsActive = false
        downloadProgress = 0.0
#if DEBUG
        simulationTask?.cancel()
        simulationTask = nil
#endif
    }
    
    // Function to reset download parameters for a simulated run
    // called from DownloadManager+Debug
    func resetForSimulation() {
        downloadProgress = 0.0
        downloadIsActive = true
        appState = .downloading
        downloadIsFinished = false
    }
    
    func setPendingState(metadata: [EpisodeMetadata], location: String, pattern: String, duplicatePath: String?) {
        pendingMetadata = metadata
        pendingDownloadLocation = location
        pendingFileNamingPattern = pattern
        duplicateFilePath = duplicatePath
    }
    
    func setDownloadProgress(to value: Double) {
        downloadProgress = value
    }
}
