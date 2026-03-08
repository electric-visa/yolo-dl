//
//  DebugWindow.swift
//  YoloDL
//
//  Created by Visa Uotila on 8.3.2026.
//

import SwiftUI

struct DebugWindow: View {
    
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var logManager: LogManager
    
    var body: some View {
        VStack (alignment: .center, spacing: 12) {
            
            Button("Simulate Download") {
                downloadManager.simulateDownload()
            }
            
            Button("Simulate Metadata Failure") {
                downloadManager.simulateMetadataFailure()
            }
            
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(logManager.logEntries.map { $0.text }.joined(separator: "\n"))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .id("logText")
                    }
                    .frame(minHeight: 300, maxHeight: 400)
                    .onChange(of: logManager.logEntries.count) {
                        proxy.scrollTo("logText", anchor: .bottom)
                    }
                }
            HStack() {
                Text("Log output")
                Divider()
                    .frame(height: 16)
                Text("\(logManager.logEntries.count) entries in log")
                Divider()
                    .frame(height: 16)
                Button("Copy Log") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(logManager.logEntries.map(\.text).joined(separator: "\n"), forType: .string)
                }
            }
            .padding()
        }
        .padding()
    }
}
