//
//  RecordModeView.swift
//  YoloDL 0.1
//
//  Created on 13.3.2026.
//

import SwiftUI

struct RecordModeView: View {

    @Binding var recordSource: RecordSource
    @Binding var selectedChannel: TVChannel
    @Binding var streamURL: String
    @Binding var durationMinutes: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("Source")
                .font(.headline)

            Picker("Source", selection: $recordSource) {
                ForEach(RecordSource.allCases, id: \.self) { source in
                    Text(source.label).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch recordSource {
            case .tvChannel:
                Picker("Channel", selection: $selectedChannel) {
                    ForEach(TVChannel.allCases, id: \.self) { channel in
                        Text(channel.label).tag(channel)
                    }
                }

            case .streamURL:
                TextField("Enter live stream URL", text: $streamURL)
            }

            HStack {
                Text("Duration:")
                TextField("min", value: $durationMinutes, format: .number)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
                Stepper("", value: $durationMinutes, in: 0...480, step: 5)
                    .labelsHidden()
            }
            Text(DurationFormatter.format(minutes: durationMinutes))
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    @Previewable @State var recordSource: RecordSource = .tvChannel
    @Previewable @State var selectedChannel: TVChannel = .tv1
    @Previewable @State var streamURL: String = ""
    @Previewable @State var durationMinutes: Int = 0

    RecordModeView(
        recordSource: $recordSource,
        selectedChannel: $selectedChannel,
        streamURL: $streamURL,
        durationMinutes: $durationMinutes
    )
}
