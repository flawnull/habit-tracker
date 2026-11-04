//
//  SupportView.swift
//  habit-tracker
//

import SwiftUI

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var expanded: FAQItem.ID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.brandGradient)
                                .frame(width: 100, height: 100)
                                .blur(radius: 36)
                                .opacity(0.55)
                            Image(systemName: "questionmark.bubble.fill")
                                .font(.system(size: 52, weight: .semibold))
                                .foregroundStyle(Theme.brandGradient)
                        }
                        Text("How can we help?")
                            .font(.title2.weight(.bold))
                        Text("Quick answers to the common questions.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 10) {
                        ForEach(FAQItem.all) { item in
                            FAQRow(item: item, isExpanded: expanded == item.id) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    expanded = expanded == item.id ? nil : item.id
                                }
                                Haptics.select()
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: "Still stuck?")
                        ContactButton(icon: "ladybug.fill", title: "Report a bug", subtitle: "Open an issue on GitHub", color: .red) {
                            openURL(AppConfig.repositoryURL.appending(path: "issues/new"))
                        }
                        ContactButton(icon: "lightbulb.fill", title: "Suggest a feature", subtitle: "Start a discussion", color: .yellow) {
                            openURL(AppConfig.repositoryURL.appending(path: "issues"))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .brandScreen()
            .navigationTitle("Help & support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}

struct FAQItem: Identifiable {
    let id: Int
    let question: String
    let answer: String

    static let all: [FAQItem] = [
        FAQItem(id: 0, question: "How do I add a habit?", answer: "Tap + on the Today or Habits tab. Pick a name, a color and an icon, or start from one of the quick-start suggestions."),
        FAQItem(id: 1, question: "How are streaks counted?", answer: "A streak is the number of consecutive days you checked in. If today is still open, the streak counts up to yesterday, so you don't lose it before the day ends."),
        FAQItem(id: 2, question: "I forgot to log yesterday. Can I fix it?", answer: "Yes. Open the habit from the Habits tab and tap any past day in the heatmap to add or remove a check-in."),
        FAQItem(id: 3, question: "How does the AI coach work?", answer: "On devices with Apple Intelligence, the coach runs Apple's on-device language model through the Foundation Models framework. Your habit data never leaves the phone. Other devices get a rule-based coach instead."),
        FAQItem(id: 4, question: "Where is my data stored?", answer: "Habits and check-ins live on your device in SwiftData. If you create an account, only your name and email are stored in Firebase."),
        FAQItem(id: 5, question: "How do I reset my password?", answer: "On the sign-in screen tap Forgot password and enter your email. A reset link arrives within a minute.")
    ]
}

struct FAQRow: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(item.question)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                if isExpanded {
                    Text(item.answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .glassCard(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}

struct ContactButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .contentShape(Rectangle())
            .glassCard(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SupportView()
}
