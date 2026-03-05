//
//  ContentView.swift
//  YoloDL 0.02
//
//  Created by Visa Uotila on 5.3.2026.
//

import SwiftUI

struct ContentView: View {
    
    let appVersion = "0.02"
    @State private var sourceUrl: String = ""
    @State private var downloadLocation: String = ""
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YoloDL \(appVersion)")
            TextField("Enter source URL", text: $sourceUrl)
            Text(downloadLocation.isEmpty ? "No folder selected" : "Download location: \(downloadLocation)")
            Button("Download"){
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/yle-dl")
                process.arguments = ["--ffmpeg", "/opt/homebrew/bin/ffmpeg", "--ffprobe", "/opt/homebrew/bin/ffprobe", "--destdir", downloadLocation, sourceUrl]
                do {
                    try process.run()
                } catch {print(error)}
            }
            Button("Choose folder"){
            let folderSelector = NSOpenPanel()
                folderSelector.canChooseFiles = false
                folderSelector.canChooseDirectories = true
                folderSelector.allowsMultipleSelection = false
                if folderSelector.runModal() == .OK {
                    downloadLocation = folderSelector.url!.path
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
