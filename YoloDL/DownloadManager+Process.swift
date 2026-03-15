//
//  DownloadManager+Process.swift
//  YoloDL
//
//  Created on 15.3.2026.
//

import Foundation

@MainActor extension DownloadManager {

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

    func launchProcess(
        arguments: [String],
        initialState: AppState,
        onStderr: (@MainActor @Sendable (String) -> Void)? = nil,
        onTermination: (@MainActor @Sendable () -> Void)? = nil
    ) {
        isActive = true
        appState = initialState

        let process = Process()
        activeProcess = process

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
                if !self.isCancelled {
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
                    self.progress = progress
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
        isCancelled = false
        isFinished = false
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
}
