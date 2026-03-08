//
//  DebugWindow.swift
//  YoloDL
//
//  Created by Visa Uotila on 8.3.2026.
//
// TO BE PLACED INSIDE CONTENTVIEW:

import SwiftUI

struct DebugWindow: View {
    
    @EnvironmentObject var manager: DownloadManager
    
    var body: some View {
        Button("Simulate Download") {
            manager.simulateDownload()
        }
        Button("Simulate Metadata Failure") {
            manager.simulateMetadataFailure()
        }
    }
}

