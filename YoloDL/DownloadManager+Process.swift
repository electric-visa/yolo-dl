//
//  DownloadManager+Process.swift
//  YoloDL
//
//  Created on 15.3.2026.
//

import Foundation

@MainActor extension DownloadManager {

    private func parseStderr(_ output: String) -> StderrFields {
        var fields = StderrFields()

        for line in output.components(separatedBy: "\r") {
            // time= → progress
            if line.contains("time="), !line.contains("time=N/A"),
               let timePart = line.components(separatedBy: "time=").last,
               let timeString = timePart.components(separatedBy: " ").first,
               timeString != "N/A" {
                let components = timeString.components(separatedBy: ":")
                if components.count == 3 {
                    let hours = Double(components[0].trimmingCharacters(in: .whitespaces)) ?? 0
                    let minutes = Double(components[1].trimmingCharacters(in: .whitespaces)) ?? 0
                    let seconds = Double(components[2].trimmingCharacters(in: .whitespaces)) ?? 0
                    let currentSeconds = hours * 3600 + minutes * 60 + seconds
                    fields.progress = totalDuration > 0 ? currentSeconds / Double(totalDuration) : 0
                }
            }

            // Lsize= (final line) or size= → fileSize
            let sizePrefix: String?
            if line.contains("Lsize=") {
                sizePrefix = "Lsize="
            } else if line.contains("size=") {
                sizePrefix = "size="
            } else {
                sizePrefix = nil
            }
            if let prefix = sizePrefix,
               let sizePart = line.components(separatedBy: prefix).last,
               let kibString = sizePart.trimmingCharacters(in: .whitespaces).components(separatedBy: "KiB").first,
               let kibValue = Double(kibString.trimmingCharacters(in: .whitespaces)) {
                let megabytes = kibValue * 1024 / 1_000_000
                if megabytes >= 1000 {
                    let gigabytes = megabytes / 1000
                    fields.fileSize = String(format: "%.1f GB", gigabytes)
                } else {
                    fields.fileSize = String(format: "%.1f MB", megabytes)
                }
            }

            // elapsed= → elapsed string and seconds
            if line.contains("elapsed="),
               let elapsedPart = line.components(separatedBy: "elapsed=").last,
               let timeString = elapsedPart.components(separatedBy: " ").first {
                let trimmed = timeString.components(separatedBy: ".").first ?? timeString
                let components = trimmed.components(separatedBy: ":")
                if components.count == 3 {
                    let hours = Int(components[0]) ?? 0
                    let minutes = Int(components[1]) ?? 0
                    let seconds = Int(components[2]) ?? 0
                    fields.elapsedSeconds = hours * 3600 + minutes * 60 + seconds
                    if hours > 0 {
                        fields.elapsed = String(format: "%d:%02d:%02d", hours, minutes, seconds)
                    } else {
                        fields.elapsed = String(format: "%d:%02d", minutes, seconds)
                    }
                }
            }

            // speed= → numeric multiplier (e.g. "32.6x" → 32.6)
            if line.contains("speed="),
               let speedPart = line.components(separatedBy: "speed=").last,
               let speedString = speedPart.components(separatedBy: "x").first,
               let speedValue = Double(speedString.trimmingCharacters(in: .whitespaces)) {
                fields.speed = speedValue
            }
        }

        return fields
    }

    var smoothedSpeed: Double? {
        guard !recentSpeeds.isEmpty else { return nil }
        return recentSpeeds.reduce(0, +) / Double(recentSpeeds.count)
    }

    var timeRemaining: Int? {
        guard let speed = smoothedSpeed, speed > 0, totalDuration > 0 else { return nil }
        let currentSeconds = Double(totalDuration) * progress
        let remaining = (Double(totalDuration) - currentSeconds) / speed
        return Int(remaining)
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
                if !self.isCancelled && self.appState != .error {
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

        guard let pending = pendingDownload else {
            handleError(.totalDurationIsZero)
            return
        }

        if let existingFilePath = pending.existingFilePath {
            do {
                try FileManager.default.removeItem(atPath: existingFilePath)
                logger.appendLog("Deleted existing file: \(existingFilePath)", from: .stdout)
            } catch {
                logger.appendLog("Failed to delete existing file: \(error.localizedDescription)", from: .stderr)
                showError(title: "File Deletion Error", text: "Could not delete existing file: \(error.localizedDescription)")
                return
            }
        }

        var arguments = [
            "--ffmpeg", pathToFfmpeg,
            "--ffprobe", pathToFfprobe,
            "--destdir", pending.downloadLocation,
            "--output-template", pending.fileNamingPattern,
            sourceURL
        ]

        let sublang = UserDefaults.standard.string(forKey: "subtitleLanguage") ?? SubtitleLanguage.finnish.rawValue
        arguments += ["--sublang", sublang]

        appendAdvancedArguments(to: &arguments)

        launchProcess(
            arguments: arguments,
            initialState: .downloading,
            onStderr: { output in
                let fields = self.parseStderr(output)
                if let progress = fields.progress {
                    self.progress = progress
                }
                if let fileSize = fields.fileSize {
                    self.recordingFileSize = fileSize
                }
                if let speed = fields.speed {
                    self.recentSpeeds.append(speed)
                    if self.recentSpeeds.count > 5 {
                        self.recentSpeeds.removeFirst()
                    }
                }
            },
            onTermination: {
                self.resetDownloadState()
                self.appState = .finished
                self.clearPendingState()
            }
        )
    }

    private func appendAdvancedArguments(to arguments: inout [String]) {
        let quality = UserDefaults.standard.string(forKey: "maxBitrate") ?? QualityPreset.best.rawValue
        if quality != QualityPreset.best.rawValue {
            arguments += ["--maxbitrate", quality]
        }

        let rateLimit = UserDefaults.standard.string(forKey: "rateLimit") ?? ""
        if !rateLimit.isEmpty {
            arguments += ["--ratelimit", rateLimit]
        }

        let customFlags = UserDefaults.standard.string(forKey: "customFlags") ?? ""
        if !customFlags.isEmpty {
            let flags = customFlags.split(separator: " ").map(String.init)
            arguments += flags
        }
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

        let sublang = UserDefaults.standard.string(forKey: "subtitleLanguage") ?? SubtitleLanguage.finnish.rawValue
        arguments += ["--sublang", sublang]

        appendAdvancedArguments(to: &arguments)

        arguments.append(source)

        launchProcess(
            arguments: arguments,
            initialState: .recording,
            onStderr: { output in
                let fields = self.parseStderr(output)
                if let elapsed = fields.elapsed {
                    self.recordingElapsed = elapsed
                }
                if let elapsedSeconds = fields.elapsedSeconds {
                    self.recordingElapsedSeconds = elapsedSeconds
                }
                if let fileSize = fields.fileSize {
                    self.recordingFileSize = fileSize
                }
            },
            onTermination: {
                self.resetDownloadState()
                self.appState = .finished
            }
        )
    }
}
