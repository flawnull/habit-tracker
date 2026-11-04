//
//  ConfettiView.swift
//  habit-tracker
//
//  Created by Ivan Kharitonenko on 31/10/2025.
//

import SwiftUI

/// Burst of tumbling confetti, fired whenever `trigger` changes.
struct ConfettiView: View {
    let trigger: Int

    @State private var pieces: [ConfettiPiece] = []
    @State private var launched = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(pieces) { piece in
                    piece.shape
                        .fill(piece.color)
                        .frame(width: piece.size.width, height: piece.size.height)
                        .rotation3DEffect(.degrees(launched ? piece.spin : 0), axis: (x: 1, y: 0.4, z: 0.2))
                        .rotationEffect(.degrees(launched ? piece.spin / 2 : 0))
                        .position(
                            x: launched ? piece.endX * proxy.size.width : proxy.size.width / 2,
                            y: launched ? proxy.size.height + 40 : proxy.size.height * 0.35
                        )
                        .opacity(launched ? 0 : 1)
                        .animation(.timingCurve(0.2, 0.7, 0.4, 1, duration: piece.duration).delay(piece.delay), value: launched)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onChange(of: trigger) { _, _ in fire() }
    }

    private func fire() {
        launched = false
        pieces = (0..<90).map { _ in ConfettiPiece() }
        Task {
            try? await Task.sleep(for: .milliseconds(30))
            launched = true
            try? await Task.sleep(for: .seconds(3))
            pieces = []
            launched = false
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color = [Theme.mint, Theme.teal, Theme.indigo, .pink, .yellow, .orange, .white].randomElement()!
    let size = CGSize(width: .random(in: 6...11), height: .random(in: 10...18))
    let isCircle = Bool.random()
    let endX = CGFloat.random(in: -0.1...1.1)
    let spin = Double.random(in: 360...1080) * (Bool.random() ? 1 : -1)
    let duration = Double.random(in: 1.6...2.6)
    let delay = Double.random(in: 0...0.25)

    var shape: AnyShape {
        isCircle ? AnyShape(Capsule()) : AnyShape(Rectangle())
    }
}

#Preview {
    ConfettiView(trigger: 0)
}
