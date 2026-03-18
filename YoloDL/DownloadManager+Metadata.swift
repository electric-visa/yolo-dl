//
//  DownloadManager+Metadata.swift
//  YoloDL
//
//  Created on 15.3.2026.
//

import Foundation

@MainActor extension DownloadManager {

    // Function to fetch metadata.
    func fetchMetadata() async -> [EpisodeMetadata]? {

        let metadataParsing = Process()
        metadataParsing.executableURL = URL(fileURLWithPath: pathToYleDl)
        metadataParsing.arguments = ["--ffmpeg", pathToFfmpeg, "--ffprobe", pathToFfprobe, "--showmetadata", sourceURL]

        let stderrPipe = Pipe()
        metadataParsing.standardError = stderrPipe

        let stdoutPipe = Pipe()
        metadataParsing.standardOutput = stdoutPipe

        let stdoutAccumulator = PipeAccumulator()
        let stderrAccumulator = PipeAccumulator()

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            stdoutAccumulator.append(handle.availableData)
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            stderrAccumulator.append(handle.availableData)
        }

        return await withCheckedContinuation { continuation in
            nonisolated(unsafe) var hasResumed = false

            metadataParsing.terminationHandler = { _ in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil

                stdoutAccumulator.append(stdoutPipe.fileHandleForReading.readDataToEndOfFile())
                stderrAccumulator.append(stderrPipe.fileHandleForReading.readDataToEndOfFile())

                let rawErrorString = stderrAccumulator.string

                Task { @MainActor in
                    self.logger.appendLog(rawErrorString, from: .stderr)
                    if let errorMessage = self.errorParser.parseErrors(rawErrorString) {
                        self.showError(title: "Metadata error", text: errorMessage)
                    }
                }

                var episodes: [EpisodeMetadata]? = nil
                do {
                    episodes = try JSONDecoder().decode([EpisodeMetadata].self, from: stdoutAccumulator.data)
                } catch {
                    Task { @MainActor in
                        self.logger.appendLog("Metadata decode failed: \(error.localizedDescription)", from: .stderr)
                        self.showError(title: "Metadata error", text: "Failed to read metadata from yle-dl. The content may not be available.")
                    }
                }

                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: episodes)
            }

            do {
                try metadataParsing.run()
            } catch {
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                Task { @MainActor in
                    self.logger.appendLog(error.localizedDescription, from: .stderr)
                    self.showError(title: "Metadata error", text: "Metadata error Details: \(error.localizedDescription)")
                }
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: nil)
            }
        }
    }
}
