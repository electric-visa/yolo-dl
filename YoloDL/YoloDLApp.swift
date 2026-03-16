//
//  YoloDLApp.swift
//  YoloDL
//
//  Created by Visa Uotila on 5.3.2026.
//

import SwiftUI

@main
struct YoloDLApp: App {
    @State private var downloadManager: DownloadManager
    @State private var logManager: LogManager
    @State private var recordingInput: RecordingInput = RecordingInput()

    @AppStorage("appMode") private var appMode: AppMode = .download
    @AppStorage("lastFolder") private var downloadLocation: String = ""
    @AppStorage("namingTemplate") private var namingPreset: NamingPreset = .seriesDateTitle

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
        }
        .defaultSize(width: 520, height: 340)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Download") {
                    Task {
                        await downloadManager.downloadFiles(
                            downloadLocation: downloadLocation,
                            fileNamingPattern: namingPreset.rawValue,
                            namingPreset: namingPreset,
                            appMode: appMode
                        )
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
