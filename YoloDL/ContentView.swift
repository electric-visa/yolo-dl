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
    
    // Progress bar animation speed
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
    
    func handleDownloadButton() async {
        if downloader.downloadIsActive {
            downloader.cancelDownload()
        } else {
           await downloader.downloadFiles(downloadLocation: downloadLocation, fileNamingPattern: namingPreset.rawValue, namingPreset: namingPreset)
        }
    }
    
    var body: some View {
        @Bindable var downloader = downloader
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(alignment: .center, spacing: 12) {
                Text("YoloDL \(appVersion)")
                Text("\(downloader.appState.statusText)")
            }
            
            TextField("Enter source URL", text: $downloader.sourceUrl)
                .disabled(downloader.downloadIsActive)

            ProgressBarView(
                downloadProgress: downloader.downloadProgress,
                downloadIsActive: downloader.downloadIsActive,
                downloadIsFinished: downloader.downloadIsFinished,
                progressBarAnimationSpeed: progressBarAnimationSpeed
            )
            
            Text(downloadLocation.isEmpty ? "No folder selected" : "Download location: \(downloadLocation)")
            
            Picker("File naming", selection: $namingPreset) {
                ForEach(NamingPreset.allCases, id: \.self) { preset in
                    Text(preset.label).tag(preset)
                }
            }
            
            Button(downloader.downloadIsActive ? "Stop" : "Download") {
                Task {
                    await handleDownloadButton()
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
    @Previewable @State var downloadManager = DownloadManager(logger: LogManager())
    ContentView()
        .environment(downloadManager)
}
