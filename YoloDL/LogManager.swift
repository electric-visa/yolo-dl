//
//  LogManager.swift
//  YoloDL
//
// @Observable @MainActor log buffer capped at 1 MB of LogEntry objects.
// Receives lines from both stdout and stderr of child processes, enforces
// the size cap by dropping the oldest entries, and exposes clearLog().
// Consumed by LogWindow for display.

import Foundation

struct LogEntry: Identifiable, Sendable {

    enum LogSource: Sendable {
        case stdout
        case stderr
    }

    let text: String
    let timestamp: Date
    let source: LogSource
    let id = UUID()

    init(text: String, source: LogSource, timestamp: Date = .now) {
        self.text = text
        self.source = source
        self.timestamp = timestamp
    }
}

@MainActor
@Observable class LogManager {

    var logEntries: [LogEntry] = []
    private var currentBufferSize: Int = 0
    
    // 1 MB cap prevents unbounded memory growth during long series downloads
    // that can produce thousands of log lines.
    private let maxBufferSize: Int = 1_048_576

    func appendLog(_ rawText: String, from pipe: LogEntry.LogSource) {
        let entry = LogEntry(text: rawText, source: pipe)
        let entrySize = rawText.utf8.count
        logEntries.append(entry)
        currentBufferSize += entrySize
        while currentBufferSize > maxBufferSize {
            let removed = logEntries.removeFirst()
            currentBufferSize -= removed.text.utf8.count
        }
    }
    
    func clearLog() {
        logEntries.removeAll()
        currentBufferSize = 0
    }
}



