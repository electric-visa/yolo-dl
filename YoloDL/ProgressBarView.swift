//
//  ProgressBarView.swift
//  YoloDL 0.1
//
//  Created on 13.3.2026.
//

import SwiftUI

struct ProgressBarView: View {
    
    let downloadProgress: Double
    let downloadIsActive: Bool
    let downloadIsFinished: Bool
    let isRecording: Bool
    let progressBarAnimationSpeed: Double

    @State private var shimmerOffset: CGFloat = -1.0
    
    // Main colors for the progress bar states.
    
    let downloadActiveColors: [Color] = [.blue, .cyan]
    let downloadFinishedColors: [Color] = [.green, .mint]
    let recordingActiveColors: [Color] = [.blue, Color(red: 0.52, green: 0.72, blue: 0.92)]
    
    // UI animation constant for the finished state delay
    static let progressBarFinishedSpeed: Double = 2.5
    
    var body: some View {
        Rectangle()
            .frame(height: 30)
            .frame(maxWidth: .infinity)
            .opacity(0.2)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: downloadActiveColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * downloadProgress
                    }
                    .frame(height: 30)
                    .opacity(downloadProgress > 0 ? 1.0 : 0.0)
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: downloadFinishedColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * downloadProgress
                    }
                    .frame(height: 30)
                    .opacity(downloadIsFinished ? 1.0 : 0.0)
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.42), .clear],
                            startPoint: UnitPoint(x: shimmerOffset - 0.5, y: 0),
                            endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 0)
                        )
                    )
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * downloadProgress
                    }
                    .frame(height: 30)
                    .blendMode(.screen)
                    .opacity(downloadIsActive && !isRecording ? 1.0 : 0.0)
            }
            .overlay {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: recordingActiveColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 30)
                    .opacity(isRecording ? 1.0 : 0.0)
            }
            .overlay {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let stripeWidth: CGFloat = 10
                        let spacing: CGFloat = 10
                        let step = stripeWidth + spacing
                        let cycleLength: CGFloat = 20.0
                        let elapsed = timeline.date.timeIntervalSinceReferenceDate
                        let offset = CGFloat(elapsed.truncatingRemainder(dividingBy: 0.7)) / 0.7 * cycleLength

                        let diagonal = size.width + size.height
                        var x = -diagonal + offset
                        while x < diagonal {
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: size.height))
                            path.addLine(to: CGPoint(x: x + stripeWidth, y: size.height))
                            path.addLine(to: CGPoint(x: x + size.height + stripeWidth, y: 0))
                            path.addLine(to: CGPoint(x: x + size.height, y: 0))
                            path.closeSubpath()
                            context.fill(path, with: .color(.white.opacity(0.40)))
                            x += step
                        }
                    }
                }
                .frame(height: 30)
                .blendMode(.screen)
                .opacity(isRecording ? 1.0 : 0.0)
            }
            .clipped()
            .animation(.easeInOut(duration: progressBarAnimationSpeed), value: downloadProgress)
            .animation(nil, value: downloadIsFinished)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 2.0
                }
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBarView(
            downloadProgress: 0.0,
            downloadIsActive: false,
            downloadIsFinished: false,
            isRecording: false,
            progressBarAnimationSpeed: 0.5
        )

        ProgressBarView(
            downloadProgress: 0.65,
            downloadIsActive: true,
            downloadIsFinished: false,
            isRecording: false,
            progressBarAnimationSpeed: 0.5
        )

        ProgressBarView(
            downloadProgress: 1.0,
            downloadIsActive: false,
            downloadIsFinished: true,
            isRecording: false,
            progressBarAnimationSpeed: 0.5
        )

        ProgressBarView(
            downloadProgress: 0,
            downloadIsActive: false,
            downloadIsFinished: false,
            isRecording: true,
            progressBarAnimationSpeed: 0.5
        )
    }
    .padding()
}
