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
    let progressBarAnimationSpeed: Double
    
    @State private var shimmerOffset: CGFloat = -1.0
    
    let downloadActiveColors: [Color] = [.blue, .cyan]
    let downloadFinishedColors: [Color] = [.green, .mint]
    
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
                            colors: [.clear, .white.opacity(0.7), .clear],
                            startPoint: UnitPoint(x: shimmerOffset - 0.5, y: 0),
                            endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 0)
                        )
                    )
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * downloadProgress
                    }
                    .frame(height: 30)
                    .blendMode(.screen)
                    .opacity(downloadIsActive ? 1.0 : 0.0)
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
            progressBarAnimationSpeed: 0.5
        )
        
        ProgressBarView(
            downloadProgress: 0.65,
            downloadIsActive: true,
            downloadIsFinished: false,
            progressBarAnimationSpeed: 0.5
        )
        
        ProgressBarView(
            downloadProgress: 1.0,
            downloadIsActive: false,
            downloadIsFinished: true,
            progressBarAnimationSpeed: 0.5
        )
    }
    .padding()
}
