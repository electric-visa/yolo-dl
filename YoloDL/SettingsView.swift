//
//  SettingsView.swift
//  YoloDL
//
//  Created by Visa Uotila on 15.3.2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(StorageKeys.fileFormat) private var fileFormat: FileFormat = .mp4
    @AppStorage(StorageKeys.subtitleLanguage) private var subtitleLanguage: SubtitleLanguage = .finnish
    @AppStorage(StorageKeys.maxBitrate) private var qualityPreset: QualityPreset = .best
    @AppStorage(StorageKeys.updateCheckFrequency) private var updateCheckFrequency: UpdateCheckFrequency = .daily
    @AppStorage(StorageKeys.customNamingTemplate) private var customNamingTemplate: String = ""
    @AppStorage(StorageKeys.rateLimit) private var rateLimit: String = ""
    @AppStorage(StorageKeys.customFlags) private var customFlags: String = ""
    @AppStorage(StorageKeys.hasAcceptedAdvancedDisclaimer) private var hasAcceptedDisclaimer: Bool = false
    @State private var showAdvancedSection: Bool = false
    @State private var showDisclaimerAlert: Bool = false

    var body: some View {
        Form {
            Picker("Format", selection: $fileFormat) {
                ForEach(FileFormat.allCases, id: \.self) { format in
                    Text(format.label)
                }
            }

            Picker("Subtitles", selection: $subtitleLanguage) {
                ForEach(SubtitleLanguage.allCases, id: \.self) { lang in
                    Text(lang.label)
                }
            }

            Picker("Check for updates", selection: $updateCheckFrequency) {
                ForEach(UpdateCheckFrequency.allCases, id: \.self) { freq in
                    Text(freq.label)
                }
            }

            if showAdvancedSection {
                Picker("Quality", selection: $qualityPreset) {
                    ForEach(QualityPreset.allCases, id: \.self) { preset in
                        Text(preset.label)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Custom naming template", text: $customNamingTemplate)
                    Text("Template passed to yle-dl's --output-template. Tokens: ${title}, ${series_separator}, ${episode_or_date}")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextField("Bandwidth limit (kB/s)", text: $rateLimit)

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Custom yle-dl flags", text: $customFlags)
                    Text("Space-separated flags passed directly to yle-dl. Paths or values containing spaces are not supported.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("Reset Advanced Disclaimer") {
                    hasAcceptedDisclaimer = false
                    showAdvancedSection = false
                }
                .foregroundStyle(.secondary)

                Button("Reset Indefinite Recording Warning") {
                    UserDefaults.standard.set(false, forKey: StorageKeys.hasAcceptedIndefiniteRecording)
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
