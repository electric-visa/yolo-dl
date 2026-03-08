//
//  LogManager.swift
//  YoloDL
//
//  Created by Visa Uotila on 8.3.2026.
//

import Foundation
import Combine

// Struct to handle log parsing.

struct LogEntry {
    
    enum LogSource {
        case stdout
        case stderr
    }

    var text: String
    var timestamp: Date = .now
    var source: LogSource
}

// LogManager class

class LogManager: ObservableObject {
    
    @Published var logEntries: [LogEntry] = []
    private var currentBufferSize: Int = 0
    
    // Constant for maximum log size to be stored in memory.
    private let maxBufferSize: Int = 1_048_576
    
    // Function to append a log entry to the buffer 
    // and remove oldest entries if buffer goes over the size limit.
    func appendLog(_ rawText: String, from pipe: LogEntry.LogSource) {
        let entry = LogEntry(text: rawText, source: pipe)
        let entrySize = rawText.utf8.count
        logEntries.append(entry)
        currentBufferSize = currentBufferSize + entrySize
        while currentBufferSize > maxBufferSize {
            let removed = logEntries.removeFirst()
            currentBufferSize = currentBufferSize - removed.text.utf8.count
        }
    }
    
    // Function to clear the log array.
    func clearLog() {
        logEntries.removeAll()
        currentBufferSize = 0
    }
}



