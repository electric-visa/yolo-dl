//
//  SettingsView.swift
//  YoloDL
//
//  Created by Visa Uotila on 15.3.2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("fileFormat") private var fileFormat: FileFormat = .mp4
    @AppStorage("subtitleLanguage") private var subtitleLanguage: SubtitleLanguage = .finnish
    @AppStorage("resumeDownloads") private var resumeDownloads: Bool = false

    var body: some View {
        Form {
            Picker("Format", selection: $fileFormat) {
                ForEach(FileFormat.allCases, id: \.self) { format in
                    Text(format.label).tag(format)
                }
            }

            Picker("Subtitles", selection: $subtitleLanguage) {
                ForEach(SubtitleLanguage.allCases, id: \.self) { lang in
                    Text(lang.label).tag(lang)
                }
            }

            Toggle("Resume incomplete downloads", isOn: $resumeDownloads)
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .padding()
    }
}
