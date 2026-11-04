//
//  TodayView.swift
//  habit-tracker
//
//  Created by Ivan Kharitonenko on 31/10/2025.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var showingAddHabit = false
    @State private var confettiTrigger = 0
    @State private var coach = HabitCoach()

    private var completedCount: Int {
        habits.filter { $0.isCompletedToday() }.count
    }

    private var progress: Double {
        habits.isEmpty ? 0 : Double(completedCount) / Double(habits.count)
    }

    private var bestActiveStreak: Int {
        habits.map { $0.currentStreak() }.max() ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if habits.isEmpty {
                    BrandEmptyState(
                        icon: "sparkles",
                        title: "Build your first loop",
                        message: "Add a habit, check it off daily and watch the streak grow.",
                        actionTitle: "Add a habit"
                    ) { showingAddHabit = true }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            greeting
                            heroCard
                            WeekStrip(habits: habits)
                            CoachCard(coach: coach, habits: habits, firstName: authManager.firstName)
                            habitsSection
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }

                ConfettiView(trigger: confettiTrigger)
            }
            .brandScreen()
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add habit")
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sensoryFeedback(.success, trigger: confettiTrigger)
        }
    }

    // MARK: Sections

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            Text(greetingText)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let part = hour < 5 ? "Up late" : hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening"
        let name = authManager.firstName
        return name.isEmpty || authManager.isGuest ? part : "\(part), \(name)"
    }

    private var heroCard: some View {
        HStack(spacing: 24) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 16)
                VStack(spacing: 0) {
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .contentTransition(.numericText(value: progress))
                    Text("done")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 132, height: 132)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Eyebrow(text: "Today")
                    Text("\(completedCount) of \(habits.count)")
                        .font(.title2.weight(.bold))
                        .contentTransition(.numericText())
                    Text(motivationalMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Theme.flame)
                        .symbolEffect(.bounce, value: bestActiveStreak)
                    Text("\(bestActiveStreak)-day best streak")
                        .font(.footnote.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.flame.opacity(0.14), in: Capsule())
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .glassCard(cornerRadius: 30)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: completedCount)
    }

    private var motivationalMessage: String {
        switch progress {
        case 1: return "Perfect day. Every loop closed."
        case 0.75...: return "Almost there, finish strong."
        case 0.5...: return "Past halfway. Keep rolling."
        case 0.0001...: return "Good start. Momentum is real."
        default: return "Fresh day. Pick the easiest one first."
        }
    }

    private var habitsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Your habits", subtitle: "Tap to check in", systemImage: "square.stack.3d.up.fill")
                .padding(.top, 4)

            ForEach(habits) { habit in
                HabitCardView(habit: habit) { toggle(habit) }
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: habits.count)
    }

    private func toggle(_ habit: Habit) {
        Haptics.tap()
        let nowDone = habit.toggleCompletion(on: .now, in: modelContext)
        if nowDone && habits.allSatisfy({ $0.isCompletedToday() }) {
            confettiTrigger += 1
        }
    }
}

// MARK: - Habit card

struct HabitCardView: View {
    let habit: Habit
    let onToggle: () -> Void

    var body: some View {
        let done = habit.isCompletedToday()
        Button(action: onToggle) {
            HStack(spacing: 14) {
                HabitIconBadge(icon: habit.iconName, color: habit.colorValue, size: 50)

                VStack(alignment: .leading, spacing: 5) {
                    Text(habit.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .strikethrough(done, color: .secondary)
                        .opacity(done ? 0.7 : 1)

                    HStack(spacing: 10) {
                        Label("\(habit.currentStreak())d", systemImage: "flame.fill")
                            .foregroundStyle(Theme.flame)
                        Label("\(Int((habit.completionRate(days: 30) * 100).rounded()))%", systemImage: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption.weight(.semibold))
                    .labelStyle(CompactLabelStyle())
                }

                Spacer()

                CheckOrb(isOn: done, color: habit.colorValue)
            }
            .padding(14)
            .contentShape(Rectangle())
            .glassCard(cornerRadius: 22, tint: done ? habit.colorValue : nil, interactive: true)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("\(habit.name), \(done ? "done" : "not done") today")
    }
}

struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
            configuration.title
        }
    }
}

struct CheckOrb: View {
    let isOn: Bool
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(color.opacity(0.35), lineWidth: 2.5)
            Circle()
                .fill(color.gradient)
                .scaleEffect(isOn ? 1 : 0.2)
                .opacity(isOn ? 1 : 0)
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white)
                .scaleEffect(isOn ? 1 : 0.4)
                .opacity(isOn ? 1 : 0)
        }
        .frame(width: 34, height: 34)
        .shadow(color: isOn ? color.opacity(0.6) : .clear, radius: 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isOn)
    }
}

// MARK: - Week strip

struct WeekStrip: View {
    let habits: [Habit]

    var body: some View {
        let calendar = Calendar.current
        let days = calendar.lastDays(7)
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                let ratio = ratio(for: day)
                let isToday = calendar.isDateInToday(day)
                VStack(spacing: 8) {
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isToday ? .primary : .secondary)
                    ZStack {
                        ProgressRing(progress: ratio, lineWidth: 4)
                        Text(day.formatted(.dateTime.day()))
                            .font(.caption.weight(isToday ? .heavy : .medium))
                    }
                    .frame(width: 34, height: 34)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background {
                    if isToday {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    }
                }
            }
        }
        .padding(10)
        .glassCard(cornerRadius: 24)
    }

    private func ratio(for day: Date) -> Double {
        guard !habits.isEmpty else { return 0 }
        let done = habits.filter { $0.isCompleted(on: day) }.count
        return Double(done) / Double(habits.count)
    }
}

// MARK: - AI coach

struct CoachCard: View {
    let coach: HabitCoach
    let habits: [Habit]
    let firstName: String

    @State private var shimmer = false

    private var signature: String {
        habits.map { "\($0.id)\($0.isCompletedToday())" }.joined()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.brandGradient)
                    .symbolEffect(.pulse, isActive: coach.phase == .thinking)
                Eyebrow(text: "AI coach", color: .primary)
                Spacer()
                engineBadge
                Button {
                    Task { await coach.generate(for: CoachSnapshot(habits: habits, firstName: firstName)) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.footnote.weight(.bold))
                }
                .buttonStyle(.glass)
                .disabled(coach.phase == .thinking)
                .accessibilityLabel("Refresh coaching tip")
            }

            switch coach.phase {
            case .idle, .thinking:
                VStack(alignment: .leading, spacing: 10) {
                    ForEach([0.55, 0.95, 0.75], id: \.self) { width in
                        Capsule()
                            .fill(Color.primary.opacity(shimmer ? 0.14 : 0.06))
                            .frame(height: 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .scaleEffect(x: width, anchor: .leading)
                    }
                }
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: shimmer)
                .onAppear { shimmer = true }
            case .ready(let note):
                VStack(alignment: .leading, spacing: 8) {
                    Text(note.headline)
                        .font(.title3.weight(.bold))
                    Text(note.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.max.fill")
                            .foregroundStyle(.yellow)
                        Text(note.tip)
                            .font(.footnote.weight(.medium))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 26, tint: Theme.indigo)
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Theme.brandGradient.opacity(0.5), lineWidth: 1)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: coach.phase)
        .task(id: signature) {
            // Debounce rapid check-ins so the model runs once per burst.
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            await coach.generate(for: CoachSnapshot(habits: habits, firstName: firstName))
        }
    }

    @ViewBuilder
    private var engineBadge: some View {
        switch coach.engine {
        case .appleIntelligence:
            Label("On-device", systemImage: "apple.intelligence")
                .font(.caption2.weight(.semibold))
                .labelStyle(CompactLabelStyle())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.brandGradient.opacity(0.25), in: Capsule())
        case .offline(let reason):
            Text(reason)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06), in: Capsule())
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(AuthenticationManager())
        .modelContainer(SampleData.previewContainer)
}
