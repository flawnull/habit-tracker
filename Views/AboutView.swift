//
//  AboutView.swift
//  habit-tracker
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let features: [(String, String, String, Color)] = [
        ("apple.intelligence", "On-device AI coach", "Apple Foundation Models write a note from your real streaks. Nothing leaves the phone.", Theme.indigo),
        ("square.grid.3x3.fill", "Activity heatmap", "Eighteen weeks of check-ins at a glance, with tap-to-backfill per habit.", Theme.teal),
        ("chart.xyaxis.line", "Swift Charts insights", "Daily trend, best weekday and a consistency leaderboard.", Theme.mint),
        ("flame.fill", "Streaks, XP and badges", "Levels and achievements that reward showing up.", Theme.flame),
        ("bell.badge.fill", "Daily reminders", "One local notification at the time you pick.", .pink),
        ("lock.shield.fill", "Private by default", "SwiftData on device. Firebase is optional, for accounts only.", .green)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 12) {
                        BrandMark(size: 96)
                        Text("HabitTracker")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                        Text("Version \(AppConfig.version)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)

                    Text("A habit tracker that stays out of your way. Check in with one tap, keep the loop closed, and let the numbers tell you what's working.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: feature.0)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 34, height: 34)
                                    .background(feature.3.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(feature.1).font(.subheadline.weight(.semibold))
                                    Text(feature.2)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 12)
                            if index < features.count - 1 { Divider().padding(.leading, 48) }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .glassCard(cornerRadius: 26)

                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: "Built with")
                        FlowTags(tags: ["SwiftUI", "Liquid Glass", "SwiftData", "Swift Charts", "Foundation Models", "Firebase Auth", "Firestore"])
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .glassCard(cornerRadius: 26)

                    Button {
                        openURL(AppConfig.repositoryURL)
                    } label: {
                        Label("View on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    .buttonStyle(BrandButtonStyle())

                    Text("Made by Ivan Kharitonenko")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .brandScreen()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}

/// Grid of capsule tags.
struct FlowTags: View {
    let tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Color.primary.opacity(0.07), in: Capsule())
            }
        }
    }
}

#Preview {
    AboutView()
}
