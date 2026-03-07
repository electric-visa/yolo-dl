//
//  DownloadManager.swift
//  YoloDL
//
//  Created by Visa Uotila on 7.3.2026.
//

import Foundation 
import Combine

struct EpisodeMetadata: Codable {
    let duration_seconds: Int
}

enum DownloadError: Identifiable {
    case emptyURL
    case noFolderSelected
    case totalDurationIsZero
    
    var id: String { String(describing: self) }
}

class DownloadManager: ObservableObject {

    // Paths to binaries
    let pathToYleDl: String = "/opt/homebrew/bin/yle-dl"
    let pathToFfmpeg: String = "/opt/homebrew/bin/ffmpeg"
    let pathToFfprobe: String = "/opt/homebrew/bin/ffprobe"
    
    // Variables to be passed to yle-dl
    @Published var sourceUrl: String = ""
    @Published var downloadLocation: String = ""
    
    // Variables and constants related to download & progress bar logic
    @Published private(set) var downloadIsActive: Bool = false
    @Published private(set) var downloadIsFinished: Bool = false
    @Published private(set) var totalDuration: Int = 0
    @Published private(set) var downloadProgress: Double = 0
    let progressBarFinishedSpeed: Double = 2.5
    
    // Default error state
    @Published var currentError: DownloadError? = nil
    
    // Function to check for valid user inputs.
    // Currently guards for empty URL and destination folder.
    
    func validateInputs() -> Bool {
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
    
    // Function to download files.
    // TO BE SPLIT INTO DIFFERENT FUNCTIONS.
    func downloadFiles() {
        Task {

            guard validateInputs() else { return }
            
            // Reset downloadIsFinished state to false.
            downloadIsFinished = false
            
            // Call metadata parsing with guard for total duration of 0.
            totalDuration = await fetchMetadata()
            print(totalDuration)
            guard totalDuration != 0 else { handleError(.totalDurationIsZero); return }
            downloadIsActive = true
            
            let downloadProcess = Process()
            let progressPipe = Pipe()
            
            progressPipe.fileHandleForReading.readabilityHandler = { handle in
                let output = String(data: handle.availableData, encoding: .utf8) ?? ""
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
            
            downloadProcess.terminationHandler = { _ in
                progressPipe.fileHandleForReading.readabilityHandler = nil
                Task { @MainActor in self.resetDownloadState()
                }
            }
            downloadProcess.standardError = progressPipe
            downloadProcess.executableURL = URL(fileURLWithPath: pathToYleDl)
            downloadProcess.arguments = ["--ffmpeg", pathToFfmpeg, "--ffprobe", pathToFfprobe, "--destdir", downloadLocation, sourceUrl]
            do {
                try downloadProcess.run()
            } catch { print(error) }
        }
    }
    
    func handleError(_ error: DownloadError) {
        currentError = error
    }
    
    // Function for a simulated download to test and/or debug the progress bar.
    func simulateDownload() {
        downloadProgress = 0.0
        downloadIsActive = true
        downloadIsFinished = false
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            DispatchQueue.main.async {
                if self.downloadProgress < 1.0 {
                    self.downloadProgress += 0.01
                } else {
                    self.downloadProgress = 1.0
                    self.downloadIsActive = false
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.progressBarFinishedSpeed) {
                        self.downloadIsFinished = true
                    }
                }
            }
        }
    }
    
    // Function to simulate metadata failure
    func simulateMetadataFailure() {
        totalDuration = 0
        guard totalDuration != 0 else { handleError(.totalDurationIsZero); return }
    }
}
