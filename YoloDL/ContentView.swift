//
//  ContentView.swift
//  YoloDL
//
//  Created on 5.3.2026.
//

import AppKit
import SwiftUI

struct ContentView: View {

    // MARK: - Environment
    // Open debug window on startup.
    @Environment(\.openWindow) var openWindow

    @Environment(DownloadManager.self) private var downloader
    @Environment(RecordingInput.self) private var recordingInput

    // MARK: - User preferences
    // App mode selection
    @AppStorage(StorageKeys.appMode) private var appMode: AppMode = .download

    // AppStorage properties for storing user selections
    @AppStorage(StorageKeys.lastFolder) private var downloadLocation: String = ""
    @AppStorage(StorageKeys.namingTemplate) private var namingPreset: NamingPreset = .seriesDateTitle
    @AppStorage(StorageKeys.customNamingTemplate) private var customNamingTemplate: String = ""
    @AppStorage(StorageKeys.hasSeenWelcome) private var hasSeenWelcome: Bool = false

    // MARK: - Local state
    @State private var updateResult: UpdateResult?
    @State private var showUpdateAvailable = false


    // Function to choose the download location.
    func chooseFolder() {
        if let path = FolderPicker.chooseFolder() {
            downloadLocation = path
        }
    }

    func handleDownloadButton() async {
        if downloader.isActive {
            downloader.stop(for: appMode)
        } else {
            if appMode == .record {
                if !recordingInput.useTimeLimit {
                    guard IndefiniteRecordingAlert.confirm() else { return }
                }
                if recordingInput.totalMinutes >= 360 {
                    downloader.showLongRecordingAlert = true
                    return
                }
                await downloader.startRecordingFrom(recordingInput, downloadLocation: downloadLocation)
            } else {
                await downloader.downloadFiles(downloadLocation: downloadLocation, fileNamingPattern: namingPreset.resolvedPattern(custom: customNamingTemplate), namingPreset: namingPreset, appMode: appMode)
                if !FileManager.default.fileExists(atPath: downloadLocation) {
                    downloadLocation = ""
                }
            }
        }
    }

    // MARK: - Computed properties

    var actionButtonLabel: String {
        downloader.isActive ? "Stop" : appMode == .download ? "Download" : "Record"
    }

    var body: some View {
        @Bindable var downloader = downloader
        @Bindable var recordingInput = recordingInput
        VStack(alignment: .leading, spacing: 12) {
            ModeControlsView()

            Text(downloadLocation.isEmpty ? "No folder selected" : "Download folder: \(downloadLocation)")
                .lineLimit(1)
                .truncationMode(.middle)

            HStack {
                Button {
                    Task {
                        await handleDownloadButton()
                    }
                } label: {
                    ZStack {
                        // Hidden baselines to reserve width for the longest possible label
                        Text("Download").hidden()
                        Text("Record").hidden()
                        Text("Stop").hidden()

                        // Visible label
                        Text(actionButtonLabel)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(appMode == .record && !downloader.isActive && (recordingInput.hasInvalidDuration || (recordingInput.useTimeLimit && recordingInput.totalMinutes == 0)))
                .help(appMode == .record && recordingInput.hasInvalidDuration ? "Duration can't be negative" : appMode == .record && recordingInput.useTimeLimit && recordingInput.totalMinutes == 0 ? "Minimum recording duration is 1 minute" : "")
                Button("Choose Folder") {
                    chooseFolder()
                }
                .disabled(downloader.isActive)
            }

            ProgressBarView(
                progress: downloader.progress,
                isActive: downloader.isActive,
                isFinished: downloader.isFinished,
                showsIndeterminateProgress: downloader.appState.showsIndeterminateProgress,
                appState: downloader.appState
            )

            StatusStripView()

            Spacer()
        }

        // Show debug window on startup.
        .onAppear {
#if DEBUG
            openWindow(id:"debug")
#endif
        }
#if DEBUG
        .onChange(of: downloader.showDebugUpdateAlert) {
            if downloader.showDebugUpdateAlert {
                updateResult = downloader.debugUpdateResult
                showUpdateAvailable = true
                downloader.showDebugUpdateAlert = false
            }
        }
#endif
        .task {
            let frequency = UpdateCheckFrequency(
                rawValue: UserDefaults.standard.string(forKey: StorageKeys.updateCheckFrequency) ?? "daily"
            ) ?? .daily
            guard let interval = frequency.intervalSeconds else { return }
            let lastCheck = UserDefaults.standard.double(forKey: StorageKeys.lastUpdateCheck)
            let now = Date.timeIntervalSinceReferenceDate
            guard now - lastCheck >= interval else { return }

            if case .available(let result) = await UpdateChecker.checkForUpdate() {
                updateResult = result
                showUpdateAvailable = true
            }
            UserDefaults.standard.set(now, forKey: StorageKeys.lastUpdateCheck)
        }

        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Mode", selection: $appMode) {
                    Image(systemName: "arrow.down.circle")
                        .tag(AppMode.download)
                        .help("Download")
                    Image(systemName: "record.circle")
                        .tag(AppMode.record)
                        .help("Record")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .disabled(downloader.isActive)
                .frame(width: 100)
            }
        }

        .alert(
            downloader.alertToShow?.title ?? "Error",
            isPresented: $downloader.isShowingAlert,
            presenting: downloader.alertToShow
        ) { _ in
            // default OK button
        } message: { alert in
            Text(alert.text)
        }
        .onChange(of: downloader.alertToShow) {
            if downloader.alertToShow == nil && downloader.appState == .error {
                downloader.appState = .ready
            }
        }
        .alert("Update available", isPresented: $showUpdateAvailable) {
            Button("Download") {
                if let url = updateResult?.url {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Later", role: .cancel) {}
        } message: {
            let current = Bundle.main.appVersion
            Text("A new YOLO-DL version \(updateResult?.version ?? "") is available. You are currently running \(current).")
        }

        .confirmationDialog(
            "Live stream detected",
            isPresented: $downloader.showLiveContentAlert,
            titleVisibility: .visible
        ) {
            Button("Record") {
                appMode = .record
                recordingInput.prefillStream(url: downloader.sourceURL)
                downloader.appState = .ready
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
                downloader.appState = .ready
                downloader.clearPendingState()
            }
        } message: {
            Text("A file with this name already exists. If you continue, it will be overwritten.")
        }
        .confirmationDialog(
            "Long recording",
            isPresented: $downloader.showLongRecordingAlert,
            titleVisibility: .visible
        ) {
            Button("Record") {
                Task {
                    await downloader.startRecordingFrom(recordingInput, downloadLocation: downloadLocation)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Recording for \(DurationFormatter.format(minutes: recordingInput.totalMinutes)) could produce a large file. Make sure you have enough free disk space.")
        }
        .sheet(isPresented: .constant(!hasSeenWelcome), onDismiss: {
            hasSeenWelcome = true
        }) {
            WelcomeView()
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
