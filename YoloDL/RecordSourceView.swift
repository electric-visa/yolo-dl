//
//  RecordSourceView.swift
//  YoloDL
//
// Source picker row for Record mode.
// Displays "Source" label and Stream URL / TV Channel menu picker.

import SwiftUI

struct RecordSourceView: View {

    @AppStorage(StorageKeys.appMode) private var appMode: AppMode = .download
    @Environment(RecordingInput.self) private var recordingInput

    private var isActive: Bool { appMode == .record }

    var body: some View {
        @Bindable var recordingInput = recordingInput
        HStack {
            Spacer()
            Text("Source")
            Picker("Source", selection: $recordingInput.recordSource) {
                ForEach(RecordSource.allCases, id: \.self) { source in
                    Text(source.label).tag(source)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .accessibilityLabel("Source")
            Spacer()
        }
        .opacity(isActive ? 1 : 0)
        .offset(y: isActive ? 0 : -8)
        .animation(.easeOut(duration: 0.25), value: isActive)
        .padding(.top, 8)
    }
}

#Preview {
    RecordSourceView()
        .environment(RecordingInput())
}
