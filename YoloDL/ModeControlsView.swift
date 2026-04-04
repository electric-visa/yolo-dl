//
//  ModeControlsView.swift
//  YoloDL
//
// ZStack container that keeps both mode views in the layout
// simultaneously. The tallest child (RecordModeView) determines
// the height, eliminating layout shift when switching modes.

import SwiftUI

struct ModeControlsView: View {
    @AppStorage(StorageKeys.appMode) private var appMode: AppMode = .download

    var body: some View {
        ZStack(alignment: .top) {
            RecordModeView()
                .opacity(appMode == .record ? 1 : 0)
                .disabled(appMode != .record)
                .accessibilityHidden(appMode != .record)

            DownloadModeView()
                .opacity(appMode == .download ? 1 : 0)
                .disabled(appMode != .download)
                .accessibilityHidden(appMode != .download)
        }
    }
}
