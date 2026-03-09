//
//  LogWindow.swift
//  YoloDL
//
//  Created by Visa Uotila on 9.3.2026.
//

import SwiftUI

struct LogWindow: View {
    
    @EnvironmentObject var logManager: LogManager

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            
            ScrollViewReader { proxy in
                ScrollView {
                    Text(logManager.logEntries.map { $0.text }.joined(separator: "\n"))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .id("logText")
                }
                .frame(minHeight: 300, maxHeight: .infinity)
                .onChange(of: logManager.logEntries.count) {
                    proxy.scrollTo("logText", anchor: .bottom)
                }
            }
            HStack {
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
                
                Divider()
                    .frame(height: 16)
                
                Button("Clear Log") {
                    logManager.clearLog()
                }
            }
            .padding()
        }
        .padding()
    }
    
}
