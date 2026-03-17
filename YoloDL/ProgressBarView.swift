//
//  ProgressBarView.swift
//  YoloDL 0.1
//
//  Created on 13.3.2026.
//

import SwiftUI

private enum Style {
    static let barHeight: CGFloat = 30
    static let shimmerOpacity: Double = 0.42
    static let stripeOpacity: Double = 0.40
    static let animationSpeed: Double = 0.5
    static let downloadActive: [Color] = [.blue, .cyan]
    static let downloadFinished: [Color] = [.green, .mint]
    static let indeterminateActive: [Color] = [.blue, Color(red: 0.52, green: 0.72, blue: 0.92)]
}

struct ProgressBarView: View {

    let progress: Double
    let isActive: Bool
    let isFinished: Bool
    let showsIndeterminateProgress: Bool

    @State private var shimmerOffset: CGFloat = -1.0

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
            .frame(height: Style.barHeight)
            .blendMode(blendMode)
            .opacity(visible ? 1.0 : 0.0)
    }

    var body: some View {
        Rectangle()
            .frame(height: Style.barHeight)
            .frame(maxWidth: .infinity)
            .opacity(0.2)
            .overlay(alignment: .leading) {
                gradientBar(
                    colors: Style.downloadActive,
                    trackProgress: true,
                    visible: progress > 0 && !isFinished
                )
            }
            .overlay(alignment: .leading) {
                gradientBar(
                    colors: Style.downloadFinished,
                    trackProgress: true,
                    visible: isFinished
                )
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(Style.shimmerOpacity), .clear],
                            startPoint: UnitPoint(x: shimmerOffset - 0.5, y: 0),
                            endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 0)
                        )
                    )
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * progress
                    }
                    .frame(height: Style.barHeight)
                    .blendMode(.screen)
                    .opacity(isActive && !showsIndeterminateProgress ? 1.0 : 0.0)
            }
            .overlay {
                gradientBar(
                    colors: Style.indeterminateActive,
                    trackProgress: false,
                    visible: showsIndeterminateProgress
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
                            context.fill(path, with: .color(.white.opacity(Style.stripeOpacity)))
                            x += step
                        }
                    }
                }
                .frame(height: Style.barHeight)
                .blendMode(.screen)
                .opacity(showsIndeterminateProgress ? 1.0 : 0.0)
            }
            .clipped()
            .animation(.easeInOut(duration: Style.animationSpeed), value: progress)
            .animation(.easeInOut(duration: Style.animationSpeed), value: isFinished)
            .animation(.easeInOut(duration: Style.animationSpeed), value: showsIndeterminateProgress)
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
            showsIndeterminateProgress: false
        )

        ProgressBarView(
            progress: 0.65,
            isActive: true,
            isFinished: false,
            showsIndeterminateProgress: false
        )

        ProgressBarView(
            progress: 1.0,
            isActive: false,
            isFinished: true,
            showsIndeterminateProgress: false
        )

        ProgressBarView(
            progress: 0,
            isActive: false,
            isFinished: false,
            showsIndeterminateProgress: true
        )
    }
    .padding()
}
