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
    @AppStorage("maxBitrate") private var qualityPreset: QualityPreset = .best
    @AppStorage("rateLimit") private var rateLimit: String = ""
    @AppStorage("customFlags") private var customFlags: String = ""
    @AppStorage("hasAcceptedAdvancedDisclaimer") private var hasAcceptedDisclaimer: Bool = false
    @State private var showAdvancedSection: Bool = false
    @State private var showDisclaimerAlert: Bool = false

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

            if showAdvancedSection {
                Picker("Quality", selection: $qualityPreset) {
                    ForEach(QualityPreset.allCases, id: \.self) { preset in
                        Text(preset.label).tag(preset)
                    }
                }

                TextField("Bandwidth limit (kB/s)", text: $rateLimit)

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Custom yle-dl flags", text: $customFlags)
                    Text("Space-separated flags passed directly to yle-dl")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("Reset Advanced Disclaimer") {
                    hasAcceptedDisclaimer = false
                    showAdvancedSection = false
                }
                .foregroundStyle(.secondary)
            }

            Button(showAdvancedSection ? "Hide Advanced Options" : "Advanced Options") {
                if hasAcceptedDisclaimer {
                    showAdvancedSection.toggle()
                } else {
                    showDisclaimerAlert = true
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .padding()
        .onAppear {
            showAdvancedSection = hasAcceptedDisclaimer
        }
        .alert("Advanced Options", isPresented: $showDisclaimerAlert) {
            Button("I Understand") {
                hasAcceptedDisclaimer = true
                showAdvancedSection = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("These settings are for experienced users. Incorrect values may cause downloads to fail. YOLO-DL cannot validate custom flags.")
        }
    }
}
