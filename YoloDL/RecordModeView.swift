//
//  RecordModeView.swift
//  YoloDL
//
// Subview rendered when the app is in Record mode.

import SwiftUI

struct RecordModeView: View {

    @Environment(RecordingInput.self) private var recordingInput

    var body: some View {
        @Bindable var recordingInput = recordingInput
        VStack(spacing: 8) {
            Picker("Source", selection: $recordingInput.recordSource) {
                ForEach(RecordSource.allCases, id: \.self) { source in
                    Text(source.label).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch recordingInput.recordSource {
            case .tvChannel:
                Picker("Channel", selection: $recordingInput.selectedChannel) {
                    ForEach(TVChannel.allCases, id: \.self) { channel in
                        Text(channel.label).tag(channel)
                    }
                }

            case .streamURL:
                TextField("Enter live stream URL", text: $recordingInput.streamURL)
            }

            HStack {
                Text("Duration:")
                TextField("h", value: $recordingInput.durationHours, format: .number)
                    .frame(width: 40)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Hours")
                    .onSubmit { recordingInput.normalize() }
                Stepper("Hours", value: $recordingInput.durationHours, in: 0...8, step: 1)
                    .labelsHidden()
                Text("h")
                TextField("min", value: $recordingInput.durationMinutes, format: .number)
                    .frame(width: 40)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Minutes")
                    .onSubmit { recordingInput.normalize() }
                Stepper("Minutes", value: $recordingInput.durationMinutes, in: 0...55, step: 5)
                    .labelsHidden()
                Text("min")
            }
            if recordingInput.totalMinutes < 0 {
                Text("Duration can't be negative")
                    .foregroundStyle(.red)
                    .font(.caption)
            } else {
                Text(DurationFormatter.format(minutes: recordingInput.totalMinutes))
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    RecordModeView()
        .environment(RecordingInput())
}
