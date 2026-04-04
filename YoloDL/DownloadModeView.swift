//
//  DownloadModeView.swift
//  YoloDL
//
// Subview rendered when the app is in Download mode.
// Contains only the file naming picker. The URL field is
// shared across modes and lives in ModeControlsView.

import SwiftUI

struct DownloadModeView: View {

    @AppStorage(StorageKeys.namingTemplate) private var namingPreset: NamingPreset = .seriesDateTitle

    var body: some View {
        VStack(spacing: 8) {
            Picker("File naming", selection: $namingPreset) {
                ForEach(NamingPreset.allCases, id: \.self) { preset in
                    Text(preset.label)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    DownloadModeView()
}
