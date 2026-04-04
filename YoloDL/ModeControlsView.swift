//
//  ModeControlsView.swift
//  YoloDL
//
// ZStack container that keeps both mode views in the layout
// simultaneously. The tallest child (RecordModeView) determines
// the height, eliminating layout shift when switching modes.
// The shared input slot below the ZStack ensures the URL field
// or channel picker always occupies the same vertical position.

import SwiftUI

struct ModeControlsView: View {
    @AppStorage(StorageKeys.appMode) private var appMode: AppMode = .download
    @Environment(DownloadManager.self) private var downloader
    @Environment(RecordingInput.self) private var recordingInput
    @State private var zStackHeight: CGFloat = 350

    private struct HeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

    private var urlFieldLabel: String {
        appMode == .download ? "Enter source URL" : "Enter live stream URL"
    }

    var body: some View {
        @Bindable var downloader = downloader
        @Bindable var recordingInput = recordingInput

        VStack(spacing: 8) {
            ZStack(alignment: .top) {
                DownloadModeView()
                    .opacity(appMode == .download ? 1 : 0)
                    .disabled(appMode != .download)
                    .accessibilityHidden(appMode != .download)

                RecordModeView()
                    .background(Color(nsColor: .windowBackgroundColor))
                    .offset(y: appMode == .record ? 0 : -zStackHeight)
                    .animation(.easeOut(duration: 0.3), value: appMode)
                    .disabled(appMode != .record)
                    .accessibilityHidden(appMode != .record)
            }
            .clipped()
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: HeightKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(HeightKey.self) { height in
                zStackHeight = height
            }

            if appMode == .record && recordingInput.recordSource == .tvChannel {
                Picker("Channel", selection: $recordingInput.selectedChannel) {
                    ForEach(TVChannel.allCases, id: \.self) { channel in
                        Text(channel.label)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Channel")
            } else {
                TextField(urlFieldLabel, text: appMode == .download ? $downloader.sourceURL : $recordingInput.streamURL)
                    .disabled(downloader.isActive)
                    .accessibilityLabel(appMode == .download ? "Source URL" : "Live stream URL")
            }
        }
    }
}
