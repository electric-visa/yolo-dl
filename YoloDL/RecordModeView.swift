//
//  RecordModeView.swift
//  YoloDL
//
// Subview rendered when the app is in Record mode.
// Assembles source selection, timing controls, and input field.

import SwiftUI

struct LabelWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct RecordModeView: View {
    
    @State private var labelWidth: CGFloat = 0
    @Environment(RecordingInput.self) private var recordingInput
    
    var body: some View {
        @Bindable var recordingInput = recordingInput
        VStack(spacing: 8) {
            Text("Duration:")
                .hidden()
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: LabelWidthKey.self, value: proxy.size.width)
                    }
                )
                .frame(height: 0)
            RecordSourceView(labelWidth: labelWidth)
            RecordTimingView(labelWidth: labelWidth)

            switch recordingInput.recordSource {
            case .tvChannel:
                HStack {
                    Color.clear
                        .frame(width: labelWidth > 0 ? labelWidth : 0, height: 1)
                    Picker("Channel", selection: $recordingInput.selectedChannel) {
                        ForEach(TVChannel.allCases, id: \.self) { channel in
                            Text(channel.label)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .accessibilityLabel("Channel")
                }
                .frame(maxWidth: .infinity)
                
            case .streamURL:
                    TextField("Enter live stream URL", text: $recordingInput.streamURL)
                        .accessibilityLabel("Live stream URL")
            }
        }
        .onPreferenceChange(LabelWidthKey.self) { width in
            labelWidth = width
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    RecordModeView()
        .environment(RecordingInput())
}
