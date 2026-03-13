//
//  DownloadMode.swift
//  YoloDL
//
//  Created on 13.3.2026.
//

import SwiftUI

struct DownloadMode: View {
    
    @Environment(DownloadManager.self) private var downloader
    
    @AppStorage("namingTemplate") private var namingPreset: NamingPreset = .seriesDateTitle
    
    var body: some View {
        @Bindable var downloader = downloader
        
        VStack(spacing: 8) {
            Text("File naming")
                .font(.headline)

            Picker("File naming", selection: $namingPreset) {
                ForEach(NamingPreset.allCases, id: \.self) { preset in
                    Text(preset.label).tag(preset)
                }
            }
            .labelsHidden()

            TextField("Enter source URL", text: $downloader.sourceUrl)
                .disabled(downloader.downloadIsActive)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    @Previewable @State var downloadManager = DownloadManager(logger: LogManager())
    DownloadMode()
        .environment(downloadManager)
}
