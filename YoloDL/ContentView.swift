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

    // App mode selection
    @State private var appMode: AppMode = .download
    
    // Record mode settings (persisted across mode switches)
    @State private var recordSource: RecordSource = .streamURL
    @State private var selectedChannel: TVChannel = .tv1
    @State private var streamURL: String = ""
    
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
            if appMode == .record {
                let source: String = switch recordSource {
                case .tvChannel: selectedChannel.keyword
                case .streamURL: streamURL
                }
                downloader.startRecording(source: source, downloadLocation: downloadLocation)
            } else {
                await downloader.downloadFiles(downloadLocation: downloadLocation, fileNamingPattern: namingPreset.rawValue, namingPreset: namingPreset, appMode: appMode)
            }
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
                    DownloadModeView()
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
                isRecording: downloader.appState == .recording
            )

            Text(downloadLocation.isEmpty ? "No folder selected" : "Download location: \(downloadLocation)")

            Button(downloader.downloadIsActive ? "Stop" : appMode == .download ? "Download" : "Record") {
                Task {
                    await handleDownloadButton()
                }
            }
            .buttonStyle(.borderedProminent)
            Button("Choose folder") {
                chooseFolder()
            }
            .disabled(downloader.downloadIsActive)

            Text(downloader.appState.statusText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.secondary)
        }
        
        // Show debug window on startup.
        .onAppear {
#if DEBUG
            openWindow(id:"debug")
#endif
        }
        
        .alert(
            downloader.alertToShow?.title ?? "Error",
            isPresented: $downloader.isShowingAlert
        ) {
            
        } message: {
            Text(downloader.alertToShow?.text ?? "")
        }
        
        .confirmationDialog(
            "Live stream detected",
            isPresented: $downloader.showLiveContentAlert,
            titleVisibility: .visible
        ) {
            Button("Record") {
                appMode = .record
                recordSource = .streamURL
                streamURL = downloader.sourceURL
            }

            Button("Cancel", role: .cancel) {
                downloader.appState = .ready
            }
        } message: {
            Text("This content is a live stream. Would you like to switch to Record mode?")
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
        .frame(minWidth: 561, minHeight: 358)
    }
}

#Preview {
    @Previewable @State var downloadManager = DownloadManager(logger: LogManager())
    ContentView()
        .environment(downloadManager)
}
