//
//  WelcomeView.swift
//  YoloDL
//
//  Created by Visa Uotila on 17.3.2026.
//

import SwiftUI

struct WelcomeView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to YOLO-DL!")
                .font(.largeTitle)
            HStack (spacing: 8) {
                Text("Licensed under [GPLv3](https://www.gnu.org/licenses/gpl-3.0.html).")
                Text("Source code on [GitHub](https://github.com/electric-visa/yolo-dl).")
            }
            .foregroundStyle(.secondary)
            Text("YOLO-DL allows you to download content from Yle Areena by utilizing yle-dl without touching the terminal.")
            Label("Paste in an Areena URL", systemImage: "doc.on.clipboard")
            Label("Choose a destination folder", systemImage: "folder.badge.plus")
            Label("Press download", systemImage: "arrow.down.circle")
            Button("Get Started") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
    }
}
