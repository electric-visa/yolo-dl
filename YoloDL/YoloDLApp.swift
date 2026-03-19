//
//  YoloDLApp.swift
//  YoloDL

import AppKit
import SwiftUI

@main
struct YoloDLApp: App {
    @State private var downloadManager: DownloadManager
    @State private var logManager: LogManager
    @State private var recordingInput: RecordingInput = RecordingInput()
    @State private var manualUpdateResult: UpdateResult?
    @State private var showManualUpdateAvailable = false
    @State private var showNoUpdate = false
    @State private var showUpdateCheckFailed = false

    @AppStorage("appMode") private var appMode: AppMode = .download
    @AppStorage("lastFolder") private var downloadLocation: String = ""
    @AppStorage("namingTemplate") private var namingPreset: NamingPreset = .seriesDateTitle
    @AppStorage("customNamingTemplate") private var customNamingTemplate: String = ""

    @Environment(\.openWindow) private var openWindow

    init() {
        let lm = LogManager()
        _logManager = State(initialValue: lm)
        _downloadManager = State(initialValue: DownloadManager(logger: lm))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(downloadManager)
                .environment(logManager)
                .environment(recordingInput)
                .alert("Update Available", isPresented: $showManualUpdateAvailable) {
                    Button("Download") {
                        if let url = manualUpdateResult?.url {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    Button("Later", role: .cancel) {}
                } message: {
                    let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
                    Text("YOLO-DL \(manualUpdateResult?.version ?? "") is available. You are currently running \(current).")
                }
                .alert("No Update Available", isPresented: $showNoUpdate) {
                    Button("OK") {}
                } message: {
                    Text("You're running the latest version of YOLO-DL.")
                }
                .alert("Update Check Failed", isPresented: $showUpdateCheckFailed) {
                    Button("OK") {}
                } message: {
                    Text("Couldn't check for updates. Verify your internet connection and try again.")
                }
        }
        .defaultSize(width: 520, height: 340)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    Task {
                        let result = await UpdateChecker.checkForUpdate()
                        switch result {
                        case .available(let update):
                            manualUpdateResult = update
                            showManualUpdateAvailable = true
                        case .upToDate:
                            showNoUpdate = true
                        case .failed:
                            showUpdateCheckFailed = true
                        }
                    }
                }
            }

            CommandGroup(after: .newItem) {
                Button("Download") {
                    Task {
                        await downloadManager.downloadFiles(
                            downloadLocation: downloadLocation,
                            fileNamingPattern: namingPreset == .custom ? customNamingTemplate : namingPreset.rawValue,
                            namingPreset: namingPreset,
                            appMode: appMode
                        )
                        if !FileManager.default.fileExists(atPath: downloadLocation) {
                            downloadLocation = ""
                        }
                    }
                }
                .keyboardShortcut("d")
                .disabled(downloadManager.isActive || appMode != .download)

                Button("Record") {
                    let input = recordingInput
                    let source: String = switch input.recordSource {
                    case .tvChannel: input.selectedChannel.keyword
                    case .streamURL: input.streamURL
                    }
                    downloadManager.startRecording(
                        source: source,
                        downloadLocation: downloadLocation,
                        recordSource: input.recordSource,
                        duration: input.totalMinutes > 0 ? input.totalMinutes * 60 : nil
                    )
                }
                .keyboardShortcut("r")
                .disabled(downloadManager.isActive || appMode != .record)

                Button("Stop") {
                    if appMode == .record {
                        downloadManager.stopRecording()
                    } else {
                        downloadManager.cancelDownload()
                    }
                }
                .keyboardShortcut(".")
                .disabled(!downloadManager.isActive)

                Divider()

                Button("Choose Folder…") {
                    if let path = FolderPicker.chooseFolder() {
                        downloadLocation = path
                    }
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                .disabled(downloadManager.isActive)
            }

            CommandGroup(after: .windowList) {
                Button("Show Log") {
                    openWindow(id: "logWindow")
                }
            }
        }

        Window("Log Window", id: "logWindow") {
            LogWindow()
                .environment(logManager)
        }
        Settings {
            SettingsView()
        }
        #if DEBUG
        Window("Debug Window", id: "debug") {
            DebugWindow()
                .environment(downloadManager)
                .environment(recordingInput)
        }
        #endif
    }
}
