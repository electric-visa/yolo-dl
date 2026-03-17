//
//  WelcomeView.swift
//  YoloDL
//
//  Created by Visa Uotila on 17.3.2026.
//

import SwiftUI

struct WelcomeView: View {
    
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to YOLO-DL!")
                .font(.largeTitle)
                .padding()
            Text("YOLO-DL allows you to download content from Yle Areena by utilizing yle-dl without touching the terminal.")
            Label("Paste in an Areena URL", systemImage: "doc.on.clipboard")
            Label("Choose a destination folder", systemImage: "folder.badge.plus")
            Label("Press download", systemImage: "arrow.down.circle")
            Button("Get started") {
                isPresented = false
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
    }
}
