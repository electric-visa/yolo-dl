//
//  LogWindow.swift
//  YoloDL
//
// Separate Window scene showing the live yle-dl / ffmpeg log output.

import SwiftUI

struct LogWindow: View {
    
    @Environment(LogManager.self) var logManager
    @State private var autoScroll: Bool = true
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView { LazyVStack(spacing: 1) {
                ForEach(logManager.logEntries) { entry in
                    Text(entry.text)
                        .id(entry.id)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .textSelection(.enabled)
            .padding()
            }
            .onChange(of: logManager.logEntries.count) {
                if autoScroll {
                    proxy.scrollTo(logManager.logEntries.last?.id, anchor: .bottom)
                }
            }
            .frame(minHeight: 300, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Text("\(logManager.logEntries.count) entries")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Toggle("Follow", isOn: $autoScroll)
                    .toggleStyle(.switch)

                Button("Copy Log") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(logManager.logEntries.map(\.text).joined(separator: "\n"), forType: .string)
                }

                Button("Clear Log") {
                    logManager.clearLog()
                }
            }
        }
    }
}
