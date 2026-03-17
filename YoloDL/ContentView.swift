//
//  ContentView.swift
//  YoloDL
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
    @AppStorage("appMode") private var appMode: AppMode = .download

    // AppStorage properties for storing user selections
    @AppStorage("lastFolder") private var downloadLocation: String = ""
    @AppStorage("namingTemplate") private var namingPreset: NamingPreset = .seriesDateTitle
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @State private var showWelcome: Bool = true


    // Function to choose the download location.
    func chooseFolder() {
        if let path = FolderPicker.chooseFolder() {
            downloadLocation = path
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

            Text(downloadLocation.isEmpty ? "No folder selected" : "Download folder: \(downloadLocation)")

            HStack {
                Button(downloader.isActive ? "Stop" : appMode == .download ? "Download" : "Record") {
                    Task {
                        await handleDownloadButton()
                    }
                }
                .buttonStyle(.borderedProminent)
                Button("Choose Folder") {
                    chooseFolder()
                }
                .disabled(downloader.isActive)
            }

            ProgressBarView(
                progress: downloader.progress,
                isActive: downloader.isActive,
                isFinished: downloader.isFinished,
                showsIndeterminateProgress: downloader.appState.showsIndeterminateProgress
            )

            let downloadInfoParts: [String] = appMode == .download && downloader.appState == .downloading ? [
                downloader.recordingFileSize.isEmpty ? nil : downloader.recordingFileSize,
                downloader.timeRemaining.map {
                    let estimate = DurationFormatter.formatEstimate(seconds: $0)
                    return estimate == "Almost done" ? estimate : estimate + " remaining"
                }
            ].compactMap { $0 } : []
            Text(downloadInfoParts.isEmpty ? " " : downloadInfoParts.joined(separator: " · "))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .opacity(downloadInfoParts.isEmpty ? 0 : 1)

            let recordingInfoVisible = appMode == .record &&
                (!downloader.recordingElapsed.isEmpty || !downloader.recordingFileSize.isEmpty)
            let recordingInfoText: String = {
                guard recordingInfoVisible else { return " " }
                let elapsed = downloader.recordingElapsed
                let fileSize = downloader.recordingFileSize
                if let totalSeconds = downloader.recordingDurationSeconds {
                    let remaining = max(0, totalSeconds - downloader.recordingElapsedSeconds)
                    return "\(elapsed) · \(fileSize) — stops in \(DurationFormatter.formatCountdown(seconds: remaining))"
                } else {
                    return "\(elapsed) · \(fileSize)"
                }
            }()
            Text(recordingInfoText)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .opacity(recordingInfoVisible ? 1 : 0)

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

        .navigationTitle("YOLO-DL \(appVersion)")

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
            isPresented: $downloader.showFileExistsDialog,
            titleVisibility: .visible
        ) {
            Button("Overwrite", role: .destructive) {
                downloader.startDownloadProcess()
            }
            Button("Cancel", role: .cancel) {
                downloader.clearPendingState()
            }
        } message: {
            Text("A file with this name already exists. If you continue, it will be overwritten.")
        }
        .sheet(isPresented: $showWelcome, onDismiss: {
            hasSeenWelcome = true
        }) {
            WelcomeView(isPresented: $showWelcome)
        }
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 28, trailing: 20))
        .frame(minWidth: 561, minHeight: 358)
    }
}

#Preview {
    @Previewable @State var downloadManager = DownloadManager(logger: LogManager())
    @Previewable @State var recordingInput = RecordingInput()
    ContentView()
        .environment(downloadManager)
        .environment(recordingInput)
}
