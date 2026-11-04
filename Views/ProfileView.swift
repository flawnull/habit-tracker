//
//  ProfileView.swift
//  habit-tracker
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var showSignOutAlert = false
    @State private var showSettings = false
    @State private var showSupport = false
    @State private var showAbout = false

    private var totalCompletions: Int {
        habits.reduce(0) { $0 + $1.completions.count }
    }

    private var bestStreak: Int {
        habits.map { $0.bestStreak() }.max() ?? 0
    }

    private var daysActive: Int {
        Set(habits.flatMap { $0.completedDays }).count
    }

    private var level: PlayerLevel { PlayerLevel(xp: totalCompletions * 10 + bestStreak * 25) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    levelCard
                    statsRow
                    badges
                    menu
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .brandScreen()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert(authManager.isGuest ? "Leave guest mode?" : "Sign out?", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button(authManager.isGuest ? "Leave" : "Sign out", role: .destructive) { signOut() }
            } message: {
                Text("Your habits stay on this device.")
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showSupport) { SupportView() }
            .sheet(isPresented: $showAbout) { AboutView() }
            .onAppear { authManager.refreshProfile() }
        }
    }

    // MARK: Header

    private var displayName: String {
        authManager.displayName.isEmpty ? "Habit builder" : authManager.displayName
    }

    private var initials: String {
        let parts = displayName.split(separator: " ").prefix(2).compactMap(\.first)
        return parts.isEmpty ? "H" : String(parts).uppercased()
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Theme.ringGradient, lineWidth: 4)
                    .frame(width: 112, height: 112)
                    .shadow(color: Theme.mint.opacity(0.5), radius: 12)
                Circle()
                    .fill(Theme.brandGradient)
                    .frame(width: 96, height: 96)
                Text(initials)
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .overlay(alignment: .bottomTrailing) {
                Text("LV \(level.level)")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.indigo.gradient, in: Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.6), lineWidth: 1.5))
                    .offset(x: 6, y: 2)
            }

            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title2.weight(.bold))
                Text(authManager.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if authManager.isGuest {
                    Label("Guest mode", systemImage: "person.crop.circle.dashed")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.07), in: Capsule())
                        .padding(.top, 4)
                }
            }
        }
        .padding(.top, 12)
    }

    // MARK: Level

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Eyebrow(text: "Level \(level.level)")
                    Text(level.title)
                        .font(.title3.weight(.bold))
                }
                Spacer()
                Text("\(level.xp) XP")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.brandGradient)
                    .contentTransition(.numericText())
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(Theme.buttonGradient)
                        .frame(width: max(proxy.size.width * level.progress, 10))
                        .shadow(color: Theme.mint.opacity(0.5), radius: 6)
                }
            }
            .frame(height: 10)
            Text("\(level.xpToNext) XP to level \(level.level + 1). Check-ins give 10 XP, streak records give 25 XP per day.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .glassCard(cornerRadius: 26, tint: Theme.indigo)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            miniStat(value: "\(habits.count)", label: "Habits", icon: "square.stack.3d.up.fill", color: Theme.teal)
            miniStat(value: "\(totalCompletions)", label: "Check-ins", icon: "checkmark.seal.fill", color: Theme.indigo)
            miniStat(value: "\(daysActive)", label: "Days active", icon: "calendar", color: Theme.flame)
        }
    }

    private func miniStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard(cornerRadius: 20)
    }

    // MARK: Badges

    private var badges: some View {
        let list = Achievement.all(habits: habits, totalCompletions: totalCompletions, bestStreak: bestStreak)
        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Achievements", subtitle: "\(list.filter(\.unlocked).count)/\(list.count)", systemImage: "rosette")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 14) {
                ForEach(list) { badge in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(badge.unlocked ? AnyShapeStyle(badge.color.gradient) : AnyShapeStyle(Color.primary.opacity(0.06)))
                                .frame(width: 58, height: 58)
                                .shadow(color: badge.unlocked ? badge.color.opacity(0.5) : .clear, radius: 10, y: 4)
                            Image(systemName: badge.unlocked ? badge.icon : "lock.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(badge.unlocked ? AnyShapeStyle(Color.white) : AnyShapeStyle(HierarchicalShapeStyle.tertiary))
                        }
                        Text(badge.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Text(badge.detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .opacity(badge.unlocked ? 1 : 0.7)
                }
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 26)
    }

    // MARK: Menu

    private var menu: some View {
        VStack(spacing: 0) {
            menuRow(icon: "gearshape.fill", title: "Settings", color: .gray) { showSettings = true }
            Divider().padding(.leading, 62)
            menuRow(icon: "questionmark.bubble.fill", title: "Help & support", color: Theme.teal) { showSupport = true }
            Divider().padding(.leading, 62)
            menuRow(icon: "info.circle.fill", title: "About", color: Theme.indigo) { showAbout = true }
            Divider().padding(.leading, 62)
            menuRow(
                icon: "rectangle.portrait.and.arrow.right.fill",
                title: authManager.isGuest ? "Leave guest mode" : "Sign out",
                color: .red,
                showChevron: false
            ) { showSignOutAlert = true }
        }
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 24)
    }

    private func menuRow(icon: String, title: String, color: Color, showChevron: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(color == .red ? .red : .primary)
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func signOut() {
        do {
            try authManager.signOut()
            Haptics.success()
        } catch {
            Haptics.error()
        }
    }
}

// MARK: - Gamification

struct PlayerLevel {
    let xp: Int

    /// Quadratic curve: level n starts at 50 * (n-1)^2 XP.
    var level: Int { Int((Double(xp) / 50).squareRoot()) + 1 }
    private var floorXP: Int { 50 * (level - 1) * (level - 1) }
    private var nextXP: Int { 50 * level * level }
    var progress: Double { Double(xp - floorXP) / Double(max(nextXP - floorXP, 1)) }
    var xpToNext: Int { nextXP - xp }

    var title: String {
        switch level {
        case 1: return "Spark"
        case 2...3: return "Starter"
        case 4...6: return "Regular"
        case 7...9: return "Committed"
        case 10...14: return "Relentless"
        default: return "Legend"
        }
    }
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let color: Color
    let unlocked: Bool

    static func all(habits: [Habit], totalCompletions: Int, bestStreak: Int) -> [Achievement] {
        [
            Achievement(id: "first", title: "First step", detail: "1 check-in", icon: "shoeprints.fill", color: Theme.teal, unlocked: totalCompletions >= 1),
            Achievement(id: "week", title: "On fire", detail: "7-day streak", icon: "flame.fill", color: Theme.flame, unlocked: bestStreak >= 7),
            Achievement(id: "month", title: "Unstoppable", detail: "30-day streak", icon: "bolt.fill", color: .yellow, unlocked: bestStreak >= 30),
            Achievement(id: "century", title: "Centurion", detail: "100 check-ins", icon: "laurel.leading", color: Theme.indigo, unlocked: totalCompletions >= 100),
            Achievement(id: "collector", title: "Collector", detail: "5 habits", icon: "square.stack.3d.up.fill", color: .purple, unlocked: habits.count >= 5),
            Achievement(id: "perfect", title: "Perfect day", detail: "All done today", icon: "crown.fill", color: Theme.mint, unlocked: !habits.isEmpty && habits.allSatisfy { $0.isCompletedToday() })
        ]
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
        .modelContainer(SampleData.previewContainer)
}
