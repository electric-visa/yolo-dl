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
    
    // App mode selection
    @State private var appMode: AppMode = .download
    
    // Record mode settings (persisted across mode switches)
    @State private var recordSource: RecordSource = .tvChannel
    @State private var selectedChannel: TVChannel = .tv1
    @State private var streamURL: String = ""
    
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

            Text("YoloDL \(appVersion)")
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 8) {
                Text("Mode")
                    .font(.headline)

                Picker("Mode", selection: $appMode) {
                    ForEach(AppMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Group {
                switch appMode {
                case .download:
                    DownloadMode()
                case .record:
                    RecordModeView(
                        recordSource: $recordSource,
                        selectedChannel: $selectedChannel,
                        streamURL: $streamURL
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            ProgressBarView(
                downloadProgress: downloader.downloadProgress,
                downloadIsActive: downloader.downloadIsActive,
                downloadIsFinished: downloader.downloadIsFinished,
                progressBarAnimationSpeed: progressBarAnimationSpeed
            )

            Text(downloadLocation.isEmpty ? "No folder selected" : "Download location: \(downloadLocation)")

            Button(downloader.downloadIsActive ? "Stop" : appMode == .download ? "Download" : "Record") {
                Task {
                    await handleDownloadButton()
                }
            }

            Button("Choose folder") {
                chooseFolder()
            }
            .disabled(downloader.downloadIsActive)

            Text("\(downloader.appState.statusText)")
                .frame(maxWidth: .infinity, alignment: .leading)
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
