//
//  ContentView.swift
//  YoloDL 0.02
//
//  Created on 5.3.2026.
//

import SwiftUI

struct EpisodeMetadata: Codable {
    let duration_seconds: Int
}

enum DownloadError: Identifiable {
    case emptyURL
    case noFolderSelected
    
    var id: String { String(describing: self) }
}

struct ContentView: View {
    
    let appVersion = "0.02"
    
    @State private var sourceUrl: String = ""
    @State private var downloadLocation: String = ""
    
    @State private var totalDuration: Int = 0
    @State private var downloadProgress: Double = 0
    
    @State private var currentError: DownloadError? = nil
    
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
    
    func fetchMetadata() -> Int {
        let metadataParsing = Process()
        metadataParsing.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/yle-dl")
        metadataParsing.arguments = ["--ffmpeg", "/opt/homebrew/bin/ffmpeg", "--ffprobe", "/opt/homebrew/bin/ffprobe", "--showmetadata", sourceUrl]
        
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
    
    func downloadFiles(){
        guard !sourceUrl.isEmpty else { handleError(.emptyURL); return }
        guard !downloadLocation.isEmpty else { handleError(.noFolderSelected); return }
        
        totalDuration = fetchMetadata()
        print(totalDuration)
        
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
        
        downloadProcess.standardError = progressPipe
        downloadProcess.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/yle-dl")
        downloadProcess.arguments = ["--ffmpeg", "/opt/homebrew/bin/ffmpeg", "--ffprobe", "/opt/homebrew/bin/ffprobe", "--destdir", downloadLocation, sourceUrl]
       do {
            try downloadProcess.run()
        } catch {print(error)}
    }
    
    func handleError(_ error: DownloadError) {
        currentError = error
    }
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("YoloDL \(appVersion)")
            
            TextField("Enter source URL", text: $sourceUrl)
            
            Text(downloadLocation.isEmpty ? "No folder selected" : "Download location: \(downloadLocation)")
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(height: 30)
                    .opacity(0.2)
                Rectangle()
                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 100, height: 30)
            }
            
            Button("Download"){
                downloadFiles()
            }
            Button("Choose folder") {
                chooseFolder()
                }
            }
    
        .alert(item: $currentError) { error in
            switch error {
            case .emptyURL:
                return Alert(title: Text("No download URL"), message: Text("Please input a valid download URL."))
            case .noFolderSelected:
                return Alert(title: Text("No destination folder"), message: Text("Please choose a destination folder."))
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
