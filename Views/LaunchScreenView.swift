//
//  LaunchScreenView.swift
//  habit-tracker
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0
    @State private var spin = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Theme.ringGradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 168, height: 168)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .opacity(0.8)
                    BrandMark(size: 120)
                }
                .scaleEffect(scale)

                VStack(spacing: 6) {
                    Text("HabitTracker")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.brandGradient)
                    Text("Close the loop, every day")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.65)) {
                scale = 1
                opacity = 1
            }
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                spin = true
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
