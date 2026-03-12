//
//  DebugWindow.swift
//  YoloDL
//
//  Created by Visa Uotila on 8.3.2026.
//

import SwiftUI

struct DebugWindow: View {
    
    @Environment(DownloadManager.self) var downloadManager

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            
            Button("Simulate Download") {
                downloadManager.simulateDownload()
            }
            
            Button("Simulate Metadata Failure") {
                downloadManager.simulateMetadataFailure()
            }
            
            Button("Simulate Overwrite Confirmation") {
                downloadManager.simulateOverwriteConfirmation()
            }
        }
        .padding()
    }
}

