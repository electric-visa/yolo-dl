//
//  ProgressBarView.swift
//  YoloDL 0.1
//
// Custom animated progress bar built with Canvas and TimelineView.

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
    let appState: AppState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
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

    private var shimmerShouldAnimate: Bool {
        isActive && !showsIndeterminateProgress && !reduceMotion
    }

    private var accessibilityProgressValue: String {
        if isFinished { return "Complete" }
        if showsIndeterminateProgress && appState == .recording { return "Recording" }
        if showsIndeterminateProgress { return "In progress" }
        if isActive { return "\(Int(progress * 100)) percent" }
        return "Idle"
    }

    private var stateLabel: String? {
        if isFinished { return "Done" }
        if appState == .downloading { return "Downloading" }
        if appState == .recording { return "Recording" }
        return nil
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
                    .opacity(isActive && !showsIndeterminateProgress && !reduceMotion ? 1.0 : 0.0)
            }
            .overlay {
                gradientBar(
                    colors: Style.indeterminateActive,
                    trackProgress: false,
                    visible: showsIndeterminateProgress
                )
            }
            .overlay {
                if showsIndeterminateProgress {
                    TimelineView(.animation) { timeline in
                        Canvas { context, size in
                            let stripeWidth: CGFloat = 10
                            let spacing: CGFloat = 10
                            let step = stripeWidth + spacing
                            let cycleLength: CGFloat = 20.0
                            let elapsed = timeline.date.timeIntervalSinceReferenceDate
                            let offset: CGFloat = reduceMotion ? 0 : CGFloat(elapsed.truncatingRemainder(dividingBy: 0.7)) / 0.7 * cycleLength

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
                }
            }
            .overlay(alignment: .trailing) {
                Group {
                    if isFinished {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .transition(reduceMotion ? .identity : .opacity)
                    } else if appState == .downloading {
                        Image(systemName: "arrow.down.circle")
                            .foregroundStyle(.primary)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    } else if appState == .recording {
                        Image(systemName: "record.circle.fill")
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .padding(.trailing, 8)
            }
            .overlay(alignment: .center) {
                if differentiateWithoutColor, let label = stateLabel {
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Progress")
            .accessibilityValue(accessibilityProgressValue)
            .animation(reduceMotion ? nil : .easeInOut(duration: Style.animationSpeed), value: progress)
            .animation(reduceMotion ? nil : .easeInOut(duration: Style.animationSpeed), value: isFinished)
            .animation(reduceMotion ? nil : .easeInOut(duration: Style.animationSpeed), value: showsIndeterminateProgress)
            .onChange(of: shimmerShouldAnimate, initial: true) { _, shouldAnimate in
                if shouldAnimate {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        shimmerOffset = 2.0
                    }
                } else {
                    withAnimation(nil) {
                        shimmerOffset = -1.0
                    }
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
            showsIndeterminateProgress: false,
            appState: .ready
        )

        ProgressBarView(
            progress: 0.65,
            isActive: true,
            isFinished: false,
            showsIndeterminateProgress: false,
            appState: .downloading
        )

        ProgressBarView(
            progress: 1.0,
            isActive: false,
            isFinished: true,
            showsIndeterminateProgress: false,
            appState: .finished
        )

        ProgressBarView(
            progress: 0,
            isActive: false,
            isFinished: false,
            showsIndeterminateProgress: true,
            appState: .recording
        )
    }
    .padding()
}
