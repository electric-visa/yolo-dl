//
//  RecordSourceView.swift
//  YoloDL
//
// Source picker row for Record mode.
// Displays "Source" label and Stream URL / TV Channel menu picker.

import SwiftUI

struct RecordSourceView: View {

    var labelWidth: CGFloat = 0
    @Environment(RecordingInput.self) private var recordingInput

    var body: some View {
        @Bindable var recordingInput = recordingInput
        HStack {
            Text("Source")
                .frame(width: labelWidth > 0 ? labelWidth : nil, alignment: .trailing)
            Picker("Source", selection: $recordingInput.recordSource) {
                ForEach(RecordSource.allCases, id: \.self) { source in
                    Text(source.label).tag(source)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .accessibilityLabel("Source")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

#Preview {
    RecordSourceView(labelWidth: 0)
        .environment(RecordingInput())
}
