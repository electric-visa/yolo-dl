//
//  RecordModeView.swift
//  YoloDL 0.1
//
//  Created on 13.3.2026.
//

import SwiftUI

struct RecordModeView: View {

    @Environment(RecordingInput.self) private var recordingInput

    var body: some View {
        @Bindable var recordingInput = recordingInput
        VStack(spacing: 8) {
            Text("Source")
                .font(.headline)

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
                TextField("min", value: $recordingInput.durationMinutes, format: .number)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
                Stepper("", value: $recordingInput.durationMinutes, in: 0...480, step: 5)
                    .labelsHidden()
            }
            Text(DurationFormatter.format(minutes: recordingInput.durationMinutes))
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    RecordModeView()
        .environment(RecordingInput())
}
