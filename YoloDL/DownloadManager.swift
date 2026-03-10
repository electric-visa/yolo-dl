//
//  DownloadManager.swift
//  YoloDL
//
//  Created by Visa Uotila on 8.3.2026.
//

import Foundation
import Combine


@MainActor class DownloadManager: ObservableObject {
    
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
    @Published var sourceUrl: String = ""
    
    // Variables and constants related to download & progress bar logic
    @Published private(set) var downloadIsActive: Bool = false
    @Published private(set) var downloadIsFinished: Bool = false
    private var activeDownload: Process? = nil
    private var downloadIsCancelled: Bool = false
    @Published private(set) var totalDuration: Int = 0
    @Published private(set) var downloadProgress: Double = 0
    let progressBarFinishedSpeed: Double = 2.5
    
    // Default error state
    @Published var inputValidationError: InputValidationError? = nil
    
    // Variable for the alert message when errorParser catches something from .stderr
    @Published var downloadToolError: AlertMessage?
    
    // Default AppState
    @Published var appState: AppState = .ready
    
    // Variable for LogManager.
    var logger: LogManager? = nil
    
    // Function to check for valid user inputs.
    // Currently guards for empty URL and destination folder.
    
    func validateInputs(downloadLocation: String) -> Bool {
        guard !sourceUrl.isEmpty else { handleError(.emptyURL); return false }
        guard !downloadLocation.isEmpty else { handleError(.noFolderSelected); return false }
        return true
    }
    
    // Function to reset the download state
    func resetDownloadState() {
        downloadProgress = 1.0
        downloadIsActive = false
        Task {
            try? await Task.sleep(for: .seconds(progressBarFinishedSpeed))
            self.downloadIsFinished = true
        }
    }
    
    // Function to fetch metadata.
    func fetchMetadata() async -> Int {
        
        let metadataParsing = Process()
        metadataParsing.executableURL = URL(fileURLWithPath: pathToYleDl)
        metadataParsing.arguments = ["--ffmpeg", pathToFfmpeg, "--ffprobe", pathToFfprobe, "--showmetadata", sourceUrl]
        
        let stderrPipe = Pipe()
        metadataParsing.standardError = stderrPipe
        
        let stdoutPipe = Pipe()
        metadataParsing.standardOutput = stdoutPipe
        
        return await withCheckedContinuation { continuation in
            
            metadataParsing.terminationHandler = { _ in
                let rawErrorData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let rawErrorString = String(data: rawErrorData, encoding: .utf8) ?? ""
                
                Task { @MainActor in
                    self.logger?.appendLog(rawErrorString, from: .stderr)
                    if let errorMessage = self.errorParser.parseErrors(rawErrorString) {
                        self.appState = .error
                        self.downloadToolError = AlertMessage(text: errorMessage)
                    }
                }
                
                let parsedMetaData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let episodes = try? JSONDecoder().decode([EpisodeMetadata].self, from: parsedMetaData)
                let totalSeconds = episodes?.reduce(0) { $0 + $1.duration_seconds } ?? 0
                
                continuation.resume(returning: totalSeconds)
            }
            
            do {
                try metadataParsing.run()
            } catch {
                Task { @MainActor in
                    self.logger?.appendLog(error.localizedDescription, from: .stderr)
                    self.appState = .error
                    self.downloadToolError = AlertMessage(text: "Metadata error. Details: \(error.localizedDescription)")
                }
                continuation.resume(returning: 0)
            }
        }
    }
    
    // Function to download files. Includes metadata parsing.
    func downloadFiles(downloadLocation: String) {
        Task {
            
            // Revert from a possible cancelled state.
            downloadIsCancelled = false
            
            // Validate user inputs.
            appState = .preparing
            guard validateInputs(downloadLocation: downloadLocation) else { return }
            
            // Reset downloadIsFinished state to false
            // and flush the log buffer.
            downloadIsFinished = false
            logger?.clearLog()
            
            // Call metadata parsing and guard for total duration of 0
            // unless there are other errors.
            appState = .fetchingMetadata
            totalDuration = await fetchMetadata()
            print(totalDuration)
            
            if appState == .error { return }
            
            guard totalDuration != 0 else { handleError(.totalDurationIsZero); return }
            downloadIsActive = true
            appState = .downloading
            
            // Declare the download process.
            let downloadProcess = Process()
            activeDownload = downloadProcess
            
            // Declare the pipe for measuring progress.
            let stderrPipe = Pipe()
            
            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let output = String(data: handle.availableData, encoding: .utf8) ?? ""
                Task { @MainActor in
                    self.logger?.appendLog(output, from: .stderr)
                    if let friendlyMessage = self.errorParser.parseErrors(output) {
                        self.appState = .error
                        self.downloadToolError = AlertMessage(text: friendlyMessage)
                    }
                }
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
                        
                        Task { @MainActor in
                            self.downloadProgress = self.totalDuration > 0 ? currentSeconds / Double(self.totalDuration) : 0
                        }
                    }
                }
            }
            
            let outputPipe = Pipe()
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let output = String(data: handle.availableData, encoding: .utf8) ?? ""
                Task { @MainActor in
                    self.logger?.appendLog(output, from: .stdout)
                }
            }
            
            downloadProcess.terminationHandler = { _ in
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                outputPipe.fileHandleForReading.readabilityHandler = nil
                Task { @MainActor in
                    if !self.downloadIsCancelled {
                        self.resetDownloadState()
                        self.appState = .finished
                    }
                }
            }
            downloadProcess.standardError = stderrPipe
            downloadProcess.standardOutput = outputPipe
            downloadProcess.executableURL = URL(fileURLWithPath: pathToYleDl)
            downloadProcess.arguments = ["--ffmpeg", pathToFfmpeg, "--ffprobe", pathToFfprobe, "--destdir", downloadLocation, sourceUrl]
            do {
                try downloadProcess.run()
            } catch {
                self.logger?.appendLog(error.localizedDescription, from: .stderr)
                appState = .error
                self.downloadToolError = AlertMessage(text: "Failed to start download. Details: \(error.localizedDescription)")
            }
        }
    }
    
    func handleError(_ error: InputValidationError) {
        appState = .error
        inputValidationError = error
    }
    
    // Function to cancel an ongoing download
    // with additional actions during a debug simulation run.
    func cancelDownload () {
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
    // called from DebugWindow
    func resetForSimulation() {
        downloadProgress = 0.0
        downloadIsActive = true
        appState = .downloading
        downloadIsFinished = false
    }
    
    func setDownloadProgress(to value: Double) {
        downloadProgress = value
    }
}
