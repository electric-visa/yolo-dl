//
//  ContentView.swift
//  YoloDL 0.05
//
//  Created on 5.3.2026.
//  Last updated on 7.3.2026.
//

import SwiftUI

struct EpisodeMetadata: Codable {
    let duration_seconds: Int
}

enum DownloadError: Identifiable {
    case emptyURL
    case noFolderSelected
    case totalDurationIsZero
    
    var id: String { String(describing: self) }
}

struct ContentView: View {
    
    let appVersion = "0.05"
    
    // Constants to binaries.
    let pathToYleDl: String = "/opt/homebrew/bin/yle-dl"
    let pathToFfmpeg: String = "/opt/homebrew/bin/ffmpeg"
    let pathToFfprobe: String = "/opt/homebrew/bin/ffprobe"
    
    // Variables to be passed to yle-dl
    @State private var sourceUrl: String = ""
    @State private var downloadLocation: String = ""
    
    // Variables related to the download process and the progress bar logic & animations.
    @State private var downloadIsActive: Bool = false
    @State private var downloadIsFinished: Bool = false
    @State private var totalDuration: Int = 0
    @State private var downloadProgress: Double = 0
    @State private var shimmerOffset: CGFloat = -1.0
    let progressBarAnimationSpeed: Double = 0.5
    let progressBarFinishedSpeed: Double = 2.5
    
    // Default error state
    @State private var currentError: DownloadError? = nil
    
    // Function to choose the download location.
    func chooseFolder(){
        let folderSelector = NSOpenPanel()
        folderSelector.canChooseFiles = false
        folderSelector.canChooseDirectories = true
        folderSelector.allowsMultipleSelection = false
        if folderSelector.runModal() == .OK {
            if let url = folderSelector.url {
                downloadLocation = url.path
            }
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
            // Guards for empty URL and destination folder.
            // Reset downloadIsFinished state to false.
            guard !sourceUrl.isEmpty else { handleError(.emptyURL); return }
            guard !downloadLocation.isEmpty else { handleError(.noFolderSelected); return }
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
                DispatchQueue.main.async {
                    self.downloadProgress = 1.0
                    self.downloadIsActive = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + progressBarFinishedSpeed) {
                    self.downloadIsFinished = true
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
    
    
    var downloadActiveColors: [Color] { [.blue, .cyan] }
    var downloadFinishedColors: [Color] { [.green, .mint] }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("YoloDL \(appVersion)")
            
            TextField("Enter source URL", text: $sourceUrl)
                .disabled(downloadIsActive)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(height: 30)
                        .opacity(0.2)
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: downloadActiveColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * downloadProgress, height: 30)
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: downloadFinishedColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * downloadProgress, height: 30)
                        .opacity(downloadIsFinished ? 1.0 : 0.0)
                    Rectangle()
                        .fill (
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.7), .clear],
                                startPoint: UnitPoint(x: shimmerOffset - 0.5, y: 0),
                                endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 0)
                            )
                        )
                        .frame(width: geometry.size.width * downloadProgress, height: 30)
                        .blendMode(.screen)
                        .opacity(downloadIsActive ? 1.0 : 0.0)
                }
                .animation(.easeInOut(duration: progressBarAnimationSpeed), value: downloadProgress)
                .animation(nil, value: downloadIsFinished)
                .clipped()
            }
            .frame(height: 30)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 2.0
                }
            }
            
            
            Text(downloadLocation.isEmpty ? "No folder selected" : "Download location: \(downloadLocation)")
            
            #if DEBUG
            Button("Simulate Download") {
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + progressBarFinishedSpeed) {
                                self.downloadIsFinished = true
                            }
                        }
                    }
                }
            }
            #endif
            
            Button("Download") {
                downloadFiles()
            }
            .disabled(downloadIsActive)
            
            Button("Choose folder") {
                chooseFolder()
            }
            .disabled(downloadIsActive)
        }
        
        .alert(item: $currentError) { error in
            switch error {
            case .emptyURL:
                return Alert(title: Text("No download URL"), message: Text("Please input a valid download URL."))
            case .noFolderSelected:
                return Alert(title: Text("No destination folder"), message: Text("Please choose a destination folder."))
            case .totalDurationIsZero:
                return Alert(title: Text("Error while fetching metadata"),message: Text("Metadata shows the total video duration as 0 seconds. Try again or with a different URL."))
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
