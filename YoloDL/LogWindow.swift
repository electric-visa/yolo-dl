//
//  LogWindow.swift
//  YoloDL
//
//  Created by Visa Uotila on 9.3.2026.
//

import SwiftUI

struct LogWindow: View {
    
    @Environment(LogManager.self) var logManager
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            
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
                    proxy.scrollTo(logManager.logEntries.last?.id, anchor: .bottom)
                }
                .frame(minHeight: 300, maxHeight: .infinity)
                
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
                .padding(.horizontal)
            }
            .padding(.vertical, 2)
        }
        
    }
}
