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

    @AppStorage(StorageKeys.appMode) private var appMode: AppMode = .download
    @AppStorage(StorageKeys.lastFolder) private var downloadLocation: String = ""
    @AppStorage(StorageKeys.namingTemplate) private var namingPreset: NamingPreset = .seriesDateTitle
    @AppStorage(StorageKeys.customNamingTemplate) private var customNamingTemplate: String = ""

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
                    let current = Bundle.main.appVersion
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
        .windowToolbarStyle(.unified)
        .windowResizability(.contentSize)
        .defaultSize(width: 561, height: 315)
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
                            fileNamingPattern: namingPreset.resolvedPattern(custom: customNamingTemplate),
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
                    if !recordingInput.useTimeLimit {
                        guard IndefiniteRecordingAlert.confirm() else { return }
                    }
                    if recordingInput.totalMinutes >= 360 {
                        downloadManager.showLongRecordingAlert = true
                        return
                    }
                    Task {
                        await downloadManager.startRecordingFrom(recordingInput, downloadLocation: downloadLocation)
                    }
                }
                .keyboardShortcut("r")
                .disabled(downloadManager.isActive || appMode != .record)

                Button("Stop") {
                    downloadManager.stop(for: appMode)
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

            CommandGroup(replacing: .appTermination) {
                Button("Quit YOLO-DL") {
                    if downloadManager.isActive {
                        let alert = NSAlert()
                        alert.alertStyle = .critical

                        if downloadManager.appState == .recording {
                            alert.messageText = "Recording in Progress"
                            alert.informativeText = "Quitting now will lose your current recording."
                        } else {
                            alert.messageText = "Download in Progress"
                            alert.informativeText = "Quitting now will lose your current download progress."
                        }

                        alert.addButton(withTitle: "Quit")
                        alert.addButton(withTitle: "Cancel")
                        alert.buttons[0].hasDestructiveAction = true

                        if alert.runModal() == .alertFirstButtonReturn {
                            NSApplication.shared.terminate(nil)
                        }
                    } else {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .keyboardShortcut("q")
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
