//
//  RecordModeView.swift
//  YoloDL
//
// Subview rendered when the app is in Record mode.
// Assembles source selection, timing controls, and input field.

import SwiftUI

struct RecordModeView: View {

    @Environment(RecordingInput.self) private var recordingInput

    var body: some View {
        @Bindable var recordingInput = recordingInput
        VStack(spacing: 8) {
            RecordSourceView()
            RecordTimingView()

            switch recordingInput.recordSource {
            case .tvChannel:
                Picker("Channel", selection: $recordingInput.selectedChannel) {
                    ForEach(TVChannel.allCases, id: \.self) { channel in
                        Text(channel.label)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityLabel("Channel")

            case .streamURL:
                TextField("Enter live stream URL", text: $recordingInput.streamURL)
                    .accessibilityLabel("Live stream URL")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    RecordModeView()
        .environment(RecordingInput())
}
