//
//  LogManager.swift
//  YoloDL
//
// @Observable @MainActor log buffer capped at 1 MB of LogEntry objects.
// Receives lines from both stdout and stderr of child processes, enforces
// the size cap by dropping the oldest entries, and exposes clearLog().
// Consumed by LogWindow for display.

import Foundation

// Struct to handle log parsing.

struct LogEntry: Identifiable {

    enum LogSource {
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

// LogManager class

@MainActor
@Observable class LogManager {

    var logEntries: [LogEntry] = []
    private var currentBufferSize: Int = 0
    
    // Constant for maximum log size to be stored in memory.
    private let maxBufferSize: Int = 1_048_576
    
    // Function to append a log entry to the buffer 
    // and remove oldest entries if buffer goes over the size limit.
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



