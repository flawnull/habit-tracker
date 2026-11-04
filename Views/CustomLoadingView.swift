//
//  CustomLoadingView.swift
//  habit-tracker
//

import SwiftUI

struct CustomLoadingView: View {
    var tintColor: Color = Theme.teal
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0.05, to: 0.75)
            .stroke(
                AngularGradient(colors: [tintColor.opacity(0), tintColor], center: .center),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: 22, height: 22)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear { isAnimating = true }
            .accessibilityLabel("Loading")
    }
}

#Preview {
    HStack(spacing: 30) {
        CustomLoadingView()
        CustomLoadingView(tintColor: .white)
            .padding()
            .background(Color.black)
    }
}
