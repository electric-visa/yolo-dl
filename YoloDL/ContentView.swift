//
//  ContentView.swift
//  YoloDL 0.1
//
//  Created on 5.3.2026.
//

import SwiftUI

struct ContentView: View {
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    
    // Open debug window on startup.
    @Environment(\.openWindow) var openWindow
    
    @Environment(DownloadManager.self) private var downloader
    
    // Variables related to the download process and the progress bar logic & animations.
    @State private var shimmerOffset: CGFloat = -1.0
    let progressBarAnimationSpeed: Double = 0.5
    
    // Error state handling
    @State private var currentError: InputValidationError? = nil
    
    private var showAlert: Binding<Bool> {
        Binding(
            get: { downloader.alertToShow != nil },
            set: { if !$0 { downloader.alertToShow = nil } }
        )
    }
    
    // AppStorage properties for storing user selections
    @AppStorage("lastFolder") private var downloadLocation: String = ""
    @AppStorage("namingTemplate") private var namingPreset: NamingPreset = .seriesDateTitle

    
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
    
    func handleDownloadButton() {
        if downloader.downloadIsActive {
            downloader.cancelDownload()
        } else {
            downloader.downloadFiles(downloadLocation: downloadLocation, fileNamingPattern: namingPreset.rawValue, namingPreset: namingPreset)
        }
    }
    
    let downloadActiveColors: [Color] = [.blue, .cyan]
    let downloadFinishedColors:  [Color] = [.green, .mint]
    
    var body: some View {
        @Bindable var downloader = downloader
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(alignment: .center, spacing: 12) {
                Text("YoloDL \(appVersion)")
                Text("\(downloader.appState.statusText)")
            }
            
            TextField("Enter source URL", text: $downloader.sourceUrl)
                .disabled(downloader.downloadIsActive)

            Rectangle()
                .frame(height: 30)
                .frame(maxWidth: .infinity)
                .opacity(0.2)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: downloadActiveColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .containerRelativeFrame(.horizontal) { length, _ in
                            length * downloader.downloadProgress
                        }
                        .frame(height: 30)
                        .opacity(downloader.downloadProgress > 0 ? 1.0 : 0.0)
                }
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: downloadFinishedColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .containerRelativeFrame(.horizontal) { length, _ in
                            length * downloader.downloadProgress
                        }
                        .frame(height: 30)
                        .opacity(downloader.downloadIsFinished ? 1.0 : 0.0)
                }
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.7), .clear],
                                startPoint: UnitPoint(x: shimmerOffset - 0.5, y: 0),
                                endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 0)
                            )
                        )
                        .containerRelativeFrame(.horizontal) { length, _ in
                            length * downloader.downloadProgress
                        }
                        .frame(height: 30)
                        .blendMode(.screen)
                        .opacity(downloader.downloadIsActive ? 1.0 : 0.0)
                }
                .clipped()
                .animation(.easeInOut(duration: progressBarAnimationSpeed), value: downloader.downloadProgress)
                .animation(nil, value: downloader.downloadIsFinished)
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        shimmerOffset = 2.0
                    }
                }
            
            
            Text(downloadLocation.isEmpty ? "No folder selected" : "Download location: \(downloadLocation)")
            
            Picker("File naming", selection: $namingPreset) {
                ForEach(NamingPreset.allCases, id: \.self) { preset in
                    Text(preset.label).tag(preset)
                }
            }
            
            Button(downloader.downloadIsActive ? "Stop" : "Download") {
                handleDownloadButton()
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
        
        .alert(
            downloader.alertToShow?.title ?? "Error",
            isPresented: showAlert
        ) {
            
        } message: {
            Text(downloader.alertToShow?.text ?? "")
        }
        
        .confirmationDialog(
            "File already exists",
            isPresented: $downloader.showDuplicateConfirmation,
            titleVisibility: .visible
        ) {
            Button("Overwrite", role: .destructive) {
                downloader.startDownloadProcess()
            }
            Button("Cancel", role: .cancel) {
                downloader.appState = .ready
                downloader.clearPendingState()
            }
        } message: {
            Text("A file with this name already exists. Do you want to overwrite it?")
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var downloadManager = DownloadManager()
    ContentView()
        .environment(downloadManager)
}
