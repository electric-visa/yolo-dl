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
    @Environment(RecordingInput.self) private var recordingInput

    // App mode selection
    @State private var appMode: AppMode = .download

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
        if downloader.isActive {
            if appMode == .record {
                downloader.stopRecording()
            } else {
                downloader.cancelDownload()
            }
        } else {
            if appMode == .record {
                let source: String = switch recordingInput.recordSource {
                case .tvChannel: recordingInput.selectedChannel.keyword
                case .streamURL: recordingInput.streamURL
                }
                downloader.startRecording(source: source, downloadLocation: downloadLocation, recordSource: recordingInput.recordSource, duration: recordingInput.totalMinutes > 0 ? recordingInput.totalMinutes * 60 : nil)
            } else {
                await downloader.downloadFiles(downloadLocation: downloadLocation, fileNamingPattern: namingPreset.rawValue, namingPreset: namingPreset, appMode: appMode)
            }
        }
    }

    var body: some View {
        @Bindable var downloader = downloader
        @Bindable var recordingInput = recordingInput
        VStack(alignment: .leading, spacing: 12) {

            Picker("Mode", selection: $appMode) {
                ForEach(AppMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(downloader.isActive)
            .frame(maxWidth: .infinity, alignment: .center)

            Group {
                switch appMode {
                case .download:
                    DownloadModeView()
                case .record:
                    RecordModeView()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .top)

            Text(downloadLocation.isEmpty ? "No folder selected" : "Download location: \(downloadLocation)")

            HStack {
                Button(downloader.isActive ? "Stop" : appMode == .download ? "Download" : "Record") {
                    Task {
                        await handleDownloadButton()
                    }
                }
                .buttonStyle(.borderedProminent)
                Button("Choose folder") {
                    chooseFolder()
                }
                .disabled(downloader.isActive)
            }

            ProgressBarView(
                progress: downloader.progress,
                isActive: downloader.isActive,
                isFinished: downloader.isFinished,
                isRecording: downloader.appState == .recording
            )

            if appMode == .record,
               !downloader.recordingElapsed.isEmpty || !downloader.recordingFileSize.isEmpty {
                let elapsed = downloader.recordingElapsed
                let fileSize = downloader.recordingFileSize
                let text: String = {
                    if let totalSeconds = downloader.recordingDurationSeconds {
                        let remaining = max(0, totalSeconds - downloader.recordingElapsedSeconds)
                        return "\(elapsed) · \(fileSize) — stops in \(DurationFormatter.formatCountdown(seconds: remaining))"
                    } else {
                        return "\(elapsed) · \(fileSize)"
                    }
                }()
                Text(text)
                    .foregroundStyle(.secondary)
            }

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

        .navigationTitle("YoloDL \(appVersion)")

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
                recordingInput.prefillStream(url: downloader.sourceURL)
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
        .frame(minWidth: 480, minHeight: 300)
        .padding()
    }
}

#Preview {
    @Previewable @State var downloadManager = DownloadManager(logger: LogManager())
    @Previewable @State var recordingInput = RecordingInput()
    ContentView()
        .environment(downloadManager)
        .environment(recordingInput)
}
