//
//  DownloadModeView.swift
//  YoloDL
//
// Subview rendered when the app is in Download mode.

import SwiftUI

struct DownloadModeView: View {
    
    @Environment(DownloadManager.self) private var downloader
    
    @AppStorage(StorageKeys.namingTemplate) private var namingPreset: NamingPreset = .seriesDateTitle
    
    var body: some View {
        @Bindable var downloader = downloader
        
        VStack(spacing: 8) {
            Spacer()

            Picker("File naming", selection: $namingPreset) {
                ForEach(NamingPreset.allCases, id: \.self) { preset in
                    Text(preset.label)
                }
            }
            Spacer()
            TextField("Enter source URL", text: $downloader.sourceURL)
                .disabled(downloader.isActive)
                .accessibilityLabel("Source URL")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    @Previewable @State var downloadManager = DownloadManager(logger: LogManager())
    DownloadModeView()
        .environment(downloadManager)
}
