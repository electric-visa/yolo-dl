//
//  ContentView.swift
//  YoloDL 0.08
//
//  Created on 5.3.2026.
//  Last updated on 8.3.2026.
//

import SwiftUI

struct ContentView: View {
    
    let appVersion = "0.08"
    
    // Open debug window on startup.
    @Environment(\.openWindow) var openWindow
    
    @EnvironmentObject private var downloader: DownloadManager
    
    // Variables related to the download process and the progress bar logic & animations.
    @State private var shimmerOffset: CGFloat = -1.0
    let progressBarAnimationSpeed: Double = 0.5
    let progressBarFinishedSpeed: Double = 2.5
    
    // Default error state
    @State private var currentError: InputValidationError? = nil
    
    // Storing previous downloadLocation in AppStorage
    @AppStorage("lastFolder") private var downloadLocation: String = ""
    
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
    
    var downloadActiveColors: [Color] { [.blue, .cyan] }
    var downloadFinishedColors: [Color] { [.green, .mint] }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(alignment: .center, spacing: 12) {
                Text("YoloDL \(appVersion)")
                Text("\(downloader.appState.statusText)")
            }
            
            TextField("Enter source URL", text: $downloader.sourceUrl)
                .disabled(downloader.downloadIsActive)
            
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
                        .frame(width: geometry.size.width * downloader.downloadProgress, height: 30)
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: downloadFinishedColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * downloader.downloadProgress, height: 30)
                        .opacity(downloader.downloadIsFinished ? 1.0 : 0.0)
                    Rectangle()
                        .fill (
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.7), .clear],
                                startPoint: UnitPoint(x: shimmerOffset - 0.5, y: 0),
                                endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 0)
                            )
                        )
                        .frame(width: geometry.size.width * downloader.downloadProgress, height: 30)
                        .blendMode(.screen)
                        .opacity(downloader.downloadIsActive ? 1.0 : 0.0)
                }
                .animation(.easeInOut(duration: progressBarAnimationSpeed), value: downloader.downloadProgress)
                .animation(nil, value: downloader.downloadIsFinished)
                .clipped()
            }
            .frame(height: 30)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 2.0
                }
            }
            
            
            Text(downloadLocation.isEmpty ? "No folder selected" : "Download location: \(downloadLocation)")
            
            Button(downloader.downloadIsActive ? "Stop" : "Download") {
                if downloader.downloadIsActive {
                    downloader.cancelDownload()
                } else {
                    downloader.downloadFiles(downloadLocation: downloadLocation)
                }
            }
            
            Button("Choose folder") {
                chooseFolder()
            }
            .disabled(downloader.downloadIsActive)
        }
        
        // Show debug window on startup.
        .onAppear {
            #if DEBUG
            openWindow(id:"debug")
            #endif
        }
        
        .alert(item: $downloader.inputValidationError) { error in
            switch error {
            case .emptyURL:
                return Alert(title: Text("No download URL"), message: Text("Please input a valid download URL."))
            case .noFolderSelected:
                return Alert(title: Text("No destination folder"), message: Text("Please choose a destination folder."))
            case .totalDurationIsZero:
                return Alert(title: Text("Error while fetching metadata"),message: Text("Metadata shows the total video duration as 0 seconds. Try again or with a different URL."))
            }
        }
        .alert(item: $downloader.downloadToolError) { error in
            Alert(title: Text("Download Error"), message: Text(error.text))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
