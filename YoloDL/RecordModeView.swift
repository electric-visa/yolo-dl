//
//  RecordModeView.swift
//  YoloDL
//
// Subview rendered when the app is in Record mode.
// Assembles source selection and timing controls.

import SwiftUI

struct RecordModeView: View {

    var body: some View {
        VStack(spacing: 8) {
            RecordSourceView()
            RecordTimingView()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    RecordModeView()
        .environment(RecordingInput())
}
