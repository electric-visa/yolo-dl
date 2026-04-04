//
//  RecordTimingView.swift
//  YoloDL
//
// Time limit toggle and duration controls for Record mode.

import SwiftUI

struct RecordTimingView: View {

    @Environment(RecordingInput.self) private var recordingInput

    var body: some View {
        @Bindable var recordingInput = recordingInput
        VStack(spacing: 8) {
            Toggle("Set time limit", isOn: $recordingInput.useTimeLimit)

            if recordingInput.useTimeLimit {
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
            } else {
                Text("Recording will continue until you press Stop")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    RecordTimingView()
        .environment(RecordingInput())
}
