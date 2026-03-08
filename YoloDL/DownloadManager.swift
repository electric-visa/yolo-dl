//
//  DownloadManager.swift
//  YoloDL
//
//  Created by Visa Uotila on 8.3.2026.
//

import Foundation
import Combine

struct EpisodeMetadata: Codable {
    let duration_seconds: Int
}

enum AppState {
    case ready
    case preparing
    case fetchingMetadata
    case downloading
    case finished
    case cancelled
    case error
    
    var statusText: String {
        switch self {
        case .ready: return "Ready"
        case .preparing: return "Preparing download"
        case .fetchingMetadata: return "Fetching metadata"
        case .downloading: return "Downloading"
        case .finished: return "Finished"
        case .cancelled: return "Cancelled"
        case .error: return "An error occurred"
        }
    }
}

enum DownloadError: Identifiable {
    case emptyURL
    case noFolderSelected
    case totalDurationIsZero
    
    var id: String { String(describing: self) }
}

class DownloadManager: ObservableObject {
    
    #if DEBUG
    // Timer variable for a simulation run.
    var simulationTimer: Timer? = nil
    #endif
    
    // Paths to binaries
    let pathToYleDl: String = "/opt/homebrew/bin/yle-dl"
    let pathToFfmpeg: String = "/opt/homebrew/bin/ffmpeg"
    let pathToFfprobe: String = "/opt/homebrew/bin/ffprobe"
    
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
    @Published var currentError: DownloadError? = nil
    
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
    @MainActor func resetDownloadState() {
        DispatchQueue.main.async {
            self.downloadProgress = 1.0
            self.downloadIsActive = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + self.progressBarFinishedSpeed) {
            self.downloadIsFinished = true
        }
    }
    
    // Function to fetch metadata.
    func fetchMetadata() async -> Int {
        let metadataParsing = Process()
        metadataParsing.executableURL = URL(fileURLWithPath: pathToYleDl)
        metadataParsing.arguments = ["--ffmpeg", pathToFfmpeg, "--ffprobe", pathToFfprobe, "--showmetadata", sourceUrl]
        
        let pipe = Pipe()
        metadataParsing.standardOutput = pipe
        
        do {
            try
            metadataParsing.run()
            metadataParsing.waitUntilExit()
        } catch {
            print(error)
            return 0
        }
        
        let parsedMetaData = pipe.fileHandleForReading.readDataToEndOfFile()
        let episodes = try? JSONDecoder().decode([EpisodeMetadata].self, from: parsedMetaData)
        let totalSeconds = episodes?.reduce(0) { $0 + $1.duration_seconds} ?? 0
        return totalSeconds
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
            
            // Call metadata parsing and guard for total duration of 0.
            appState = .fetchingMetadata
            totalDuration = await fetchMetadata()
            print(totalDuration)
            
            guard totalDuration != 0 else { handleError(.totalDurationIsZero); return }
            downloadIsActive = true
            appState = .downloading
            
            // Declare the download process.
            let downloadProcess = Process()
            activeDownload = downloadProcess
            
            // Declare the pipe for measuring progress.
            let progressPipe = Pipe()
            
            progressPipe.fileHandleForReading.readabilityHandler = { handle in
                let output = String(data: handle.availableData, encoding: .utf8) ?? ""
                DispatchQueue.main.async {
                    self.logger?.appendLog(output, from: .stderr)
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
                        
                        DispatchQueue.main.async {
                            self.downloadProgress = self.totalDuration > 0 ? currentSeconds / Double(self.totalDuration) : 0
                        }
                    }
                }
            }
            
            let outputPipe = Pipe()
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let output = String(data: handle.availableData, encoding: .utf8) ?? ""
                DispatchQueue.main.async {
                    self.logger?.appendLog(output, from: .stdout)
                }
            }
            
            downloadProcess.terminationHandler = { _ in
                progressPipe.fileHandleForReading.readabilityHandler = nil
                outputPipe.fileHandleForReading.readabilityHandler = nil
                Task { @MainActor in
                    if !self.downloadIsCancelled {
                        self.resetDownloadState()
                        self.appState = .finished
                    }
                }
            }
            downloadProcess.standardError = progressPipe
            downloadProcess.standardOutput = outputPipe
            downloadProcess.executableURL = URL(fileURLWithPath: pathToYleDl)
            downloadProcess.arguments = ["--ffmpeg", pathToFfmpeg, "--ffprobe", pathToFfprobe, "--destdir", downloadLocation, sourceUrl]
            do {
                try downloadProcess.run()
            } catch { print(error) }
        }
    }
    
    func handleError(_ error: DownloadError) {
        appState = .error
        currentError = error
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
        simulationTimer?.invalidate()
        simulationTimer = nil
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
