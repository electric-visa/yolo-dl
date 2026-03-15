//
//  ProgressBarView.swift
//  YoloDL 0.1
//
//  Created on 13.3.2026.
//

import SwiftUI

struct ProgressBarView: View {

    let progress: Double
    let isActive: Bool
    let isFinished: Bool
    let isRecording: Bool

    static let progressBarAnimationSpeed: Double = 0.5

    @State private var shimmerOffset: CGFloat = -1.0

    // Main colors for the progress bar states.

    let downloadActiveColors: [Color] = [.blue, .cyan]
    let downloadFinishedColors: [Color] = [.green, .mint]
    let recordingActiveColors: [Color] = [.blue, Color(red: 0.52, green: 0.72, blue: 0.92)]

    // UI animation constant for the finished state delay
    static let progressBarFinishedSpeed: Double = 2.5

    @ViewBuilder
    private func gradientBar(
        colors: [Color],
        trackProgress: Bool,
        visible: Bool,
        blendMode: BlendMode = .normal
    ) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .modifier(ProgressWidthModifier(trackProgress: trackProgress, progress: progress))
            .frame(height: 30)
            .blendMode(blendMode)
            .opacity(visible ? 1.0 : 0.0)
    }

    var body: some View {
        Rectangle()
            .frame(height: 30)
            .frame(maxWidth: .infinity)
            .opacity(0.2)
            .overlay(alignment: .leading) {
                gradientBar(
                    colors: downloadActiveColors,
                    trackProgress: true,
                    visible: progress > 0
                )
            }
            .overlay(alignment: .leading) {
                gradientBar(
                    colors: downloadFinishedColors,
                    trackProgress: true,
                    visible: isFinished
                )
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
                        length * progress
                    }
                    .frame(height: 30)
                    .blendMode(.screen)
                    .opacity(isActive && !isRecording ? 1.0 : 0.0)
            }
            .overlay {
                gradientBar(
                    colors: recordingActiveColors,
                    trackProgress: false,
                    visible: isRecording
                )
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
            .animation(.easeInOut(duration: Self.progressBarAnimationSpeed), value: progress)
            .animation(nil, value: isFinished)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 2.0
                }
            }
    }
}

private struct ProgressWidthModifier: ViewModifier {
    let trackProgress: Bool
    let progress: Double

    func body(content: Content) -> some View {
        if trackProgress {
            content.containerRelativeFrame(.horizontal) { length, _ in
                length * progress
            }
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBarView(
            progress: 0.0,
            isActive: false,
            isFinished: false,
            isRecording: false
        )

        ProgressBarView(
            progress: 0.65,
            isActive: true,
            isFinished: false,
            isRecording: false
        )

        ProgressBarView(
            progress: 1.0,
            isActive: false,
            isFinished: true,
            isRecording: false
        )

        ProgressBarView(
            progress: 0,
            isActive: false,
            isFinished: false,
            isRecording: true
        )
    }
    .padding()
}
