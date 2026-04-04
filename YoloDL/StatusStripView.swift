//
//  StatusStripView.swift
//  YoloDL
//
//  Created on 4.4.2026.
//

import Foundation
import SwiftUI
import AppKit

struct StatusStripView: View {
    @Environment(DownloadManager.self) private var downloader
    @AppStorage(StorageKeys.lastFolder) private var downloadLocation: String = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack {
            statusContent
            Spacer()
            if downloader.appState == .finished {
                Button("Reveal in Finder") {
                    let url = URL(fileURLWithPath: downloadLocation)
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.link)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(downloader.appState == .error ? .red : .secondary)
        .monospacedDigit()
        .animation(.easeInOut(duration: 0.3), value: downloader.appState)
    }

    @ViewBuilder
    private var statusContent: some View {
        switch downloader.appState {
        case .ready:
            Text("Ready")
        case .preparing:
            animatedDotsText(label: "Preparing")
        case .fetchingMetadata:
            animatedDotsText(label: "Fetching metadata")
        case .downloading:
            Text(downloadStatusText)
                .contentTransition(.numericText())
        case .recording:
            Text(recordingStatusText)
                .contentTransition(.numericText())
        case .finished:
            Text("Finished")
        case .cancelled:
            Text("Cancelled")
        case .error:
            Text("An error occurred")
        }
    }

    @ViewBuilder
    private func animatedDotsText(label: String) -> some View {
        if reduceMotion {
            Text("\(label)...")
        } else {
            TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                let dotCount = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 4
                let dots = String(repeating: ".", count: dotCount)
                Text("\(label)\(dots)")
            }
        }
    }

    private var downloadStatusText: String {
        var parts: [String] = []

        if !downloader.currentFileSize.isEmpty {
            parts.append(downloader.currentFileSize)
        }

        if let timeRemaining = downloader.timeRemaining {
            let estimate = DurationFormatter.formatEstimate(seconds: timeRemaining)
            if estimate == "Almost done" {
                parts.append("Almost done")
            } else {
                parts.append("\(estimate) remaining")
            }
        }

        return parts.isEmpty ? " " : parts.joined(separator: " · ")
    }

    private var recordingStatusText: String {
        var parts: [String] = []
        let elapsed = downloader.recordingElapsed
        let fileSize = downloader.currentFileSize
        if !elapsed.isEmpty { parts.append(elapsed) }
        if !fileSize.isEmpty { parts.append(fileSize) }

        let base = parts.isEmpty ? " " : parts.joined(separator: " · ")

        if let totalSeconds = downloader.recordingDurationSeconds {
            let remaining = max(0, totalSeconds - downloader.recordingElapsedSeconds)
            let countdown = DurationFormatter.formatCountdown(seconds: remaining)
            return base == " " ? "stops in \(countdown)" : "\(base) — stops in \(countdown)"
        }
        return base
    }
}

#Preview {
    @Previewable @State var downloadManager = DownloadManager(logger: LogManager())
    StatusStripView()
        .environment(downloadManager)
}
