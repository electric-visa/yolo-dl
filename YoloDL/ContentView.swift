//
//  ContentView.swift
//  YoloDL
//
//  Created by Visa Uotila on 5.3.2026.
//

import SwiftUI

struct ContentView: View {
    
    @State private var sourceUrl: String = ""
    @State private var downloadLocation: String = ""
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YoloDL 0.01")
            TextField("Enter source URL", text: $sourceUrl)
            Text(downloadLocation.isEmpty ? "No folder selected" : "Download location: \(downloadLocation)")
            Button("Download"){ print(sourceUrl)
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
