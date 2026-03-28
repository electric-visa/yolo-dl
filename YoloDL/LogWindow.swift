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
            ScrollView {
                LazyVStack(spacing: 1) {
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
            .safeAreaInset(edge: .bottom) {
                Text("\(logManager.logEntries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(.bar)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Toggle(isOn: $autoScroll) {
                    Label("Follow", systemImage: "arrow.down.to.line")
                }
                .toggleStyle(.button)
                .help("Auto-scroll to latest entry")

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(
                        logManager.logEntries.map(\.text).joined(separator: "\n"),
                        forType: .string
                    )
                } label: {
                    Label("Copy Log", systemImage: "doc.on.doc")
                }
                .help("Copy log to clipboard")

                Button {
                    logManager.clearLog()
                } label: {
                    Label("Clear Log", systemImage: "trash")
                }
                .help("Clear all log entries")
            }
        }
    }
}
