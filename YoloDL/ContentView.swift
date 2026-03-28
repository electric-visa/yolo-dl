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
                downloader.startRecordingFrom(recordingInput, downloadLocation: downloadLocation)
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

    private var downloadInfoVisible: Bool {
        appMode == .download && downloader.appState == .downloading
    }

    var downloadInfoText: String {
        guard downloadInfoVisible else { return " " }
        let parts: [String] = [
            downloader.currentFileSize.isEmpty ? nil : downloader.currentFileSize,
            downloader.timeRemaining.map {
                let estimate = DurationFormatter.formatEstimate(seconds: $0)
                return estimate == "Almost done" ? estimate : estimate + " remaining"
            }
        ].compactMap { $0 }
        return parts.isEmpty ? " " : parts.joined(separator: " · ")
    }

    private var recordingInfoVisible: Bool {
        appMode == .record &&
            (!downloader.recordingElapsed.isEmpty || !downloader.currentFileSize.isEmpty)
    }

    var recordingInfoText: String {
        guard recordingInfoVisible else { return " " }
        let elapsed = downloader.recordingElapsed
        let fileSize = downloader.currentFileSize
        if let totalSeconds = downloader.recordingDurationSeconds {
            let remaining = max(0, totalSeconds - downloader.recordingElapsedSeconds)
            return "\(elapsed) · \(fileSize) — stops in \(DurationFormatter.formatCountdown(seconds: remaining))"
        } else {
            return "\(elapsed) · \(fileSize)"
        }
    }

    var body: some View {
        @Bindable var downloader = downloader
        @Bindable var recordingInput = recordingInput
        VStack(alignment: .leading, spacing: 12) {
            Spacer()
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
                .lineLimit(1)
                .truncationMode(.middle)

            HStack {
                Button(actionButtonLabel) {
                    Task {
                        await handleDownloadButton()
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

            Text(downloadInfoText)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .opacity(downloadInfoVisible ? 1 : 0)

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

        .navigationTitle("YOLO-DL \(Bundle.main.appVersion)")

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
                downloader.startRecordingFrom(recordingInput, downloadLocation: downloadLocation)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Recording for \(DurationFormatter.format(minutes: recordingInput.totalMinutes)) could produce a large file. Make sure you have enough free disk space.")
        }
        .sheet(isPresented: Binding(
            get: { !hasSeenWelcome },
            set: { hasSeenWelcome = !$0 }
        )) {
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
