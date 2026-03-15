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
}
