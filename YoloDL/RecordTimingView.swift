//
//  RecordTimingView.swift
//  YoloDL
//
// Time limit toggle and duration controls for Record mode.

import SwiftUI

struct RecordTimingView: View {

    var labelWidth: CGFloat = 0
    @Environment(RecordingInput.self) private var recordingInput

    var body: some View {
        @Bindable var recordingInput = recordingInput
        VStack(spacing: 8) {
            Toggle("Set time limit", isOn: $recordingInput.useTimeLimit)

            ZStack(alignment: .top) {
                // Timed branch — taller, determines ZStack height
                VStack(spacing: 8) {
                    HStack {
                        Text("Duration:")
                            .frame(width: labelWidth > 0 ? labelWidth : nil, alignment: .trailing)
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
                .opacity(recordingInput.useTimeLimit ? 1 : 0)
                .disabled(!recordingInput.useTimeLimit)
                .accessibilityHidden(!recordingInput.useTimeLimit)

                // Indefinite branch
                Text("Recording will continue until you press Stop")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .opacity(recordingInput.useTimeLimit ? 0 : 1)
                    .accessibilityHidden(recordingInput.useTimeLimit)
            }
        }
    }
}

#Preview {
    RecordTimingView(labelWidth: 0)
        .environment(RecordingInput())
}
