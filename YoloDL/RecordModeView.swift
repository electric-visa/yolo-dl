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
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    @Previewable @State var recordSource: RecordSource = .tvChannel
    @Previewable @State var selectedChannel: TVChannel = .tv1
    @Previewable @State var streamURL: String = ""
    
    RecordModeView(
        recordSource: $recordSource,
        selectedChannel: $selectedChannel,
        streamURL: $streamURL
    )
}
