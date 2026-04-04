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
            DownloadModeView()
                .disabled(appMode != .download)
                .accessibilityHidden(appMode != .download)

            RecordModeView()
                .background(Color(nsColor: .windowBackgroundColor))
                .offset(y: appMode == .record ? 0 : -300)
                .animation(.easeOut(duration: 0.3), value: appMode)
                .disabled(appMode != .record)
                .accessibilityHidden(appMode != .record)
        }
        .clipped()
    }
}
