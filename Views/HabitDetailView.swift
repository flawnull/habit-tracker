//
//  HabitDetailView.swift
//  habit-tracker
//
//  Created by Ivan Kharitonenko on 31/10/2025.
//

import SwiftUI
import SwiftData
import Charts

struct HabitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var habit: Habit
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero
                statGrid
                ContributionHeatmap(habits: [habit], weeks: 16, color: habit.colorValue, title: "Tap a day to log or undo") { day in
                    Haptics.select()
                    habit.toggleCompletion(on: day, in: modelContext)
                }
                .padding(18)
                .glassCard(cornerRadius: 26)
                weeklyTrend
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .brandScreen()
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .alert("Delete habit?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteHabit() }
        } message: {
            Text("This permanently deletes \"\(habit.name)\" and all its history.")
        }
        .sheet(isPresented: $showingEditSheet) {
            AddHabitView(editing: habit)
        }
    }

    // MARK: Sections

    private var hero: some View {
        let done = habit.isCompletedToday()
        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(habit.colorValue.gradient)
                    .frame(width: 140, height: 140)
                    .blur(radius: 50)
                    .opacity(0.6)
                HabitIconBadge(icon: habit.iconName, color: habit.colorValue, size: 96)
            }

            VStack(spacing: 6) {
                Text(habit.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Theme.flame)
                        .symbolEffect(.bounce, value: habit.currentStreak())
                    Text("\(habit.currentStreak())-day streak")
                        .font(.subheadline.weight(.semibold))
                        .contentTransition(.numericText())
                }
                Text("Since \(habit.createdAt.formatted(.dateTime.day().month(.wide).year()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                Haptics.tap()
                habit.toggleCompletion(on: .now, in: modelContext)
            } label: {
                Label(done ? "Done today" : "Mark done today", systemImage: done ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(BrandButtonStyle())
            .padding(.horizontal, 32)
        }
        .padding(.top, 12)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: done)
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            StatTile(title: "Total check-ins", value: "\(habit.completedDays.count)", icon: "checkmark.seal.fill", color: habit.colorValue)
            StatTile(title: "Best streak", value: "\(habit.bestStreak())d", icon: "trophy.fill", color: Theme.flame)
            StatTile(title: "Last 7 days", value: "\(habit.completionCount(lastDays: 7))/7", icon: "calendar", color: Theme.teal)
            StatTile(title: "30-day rate", value: "\(Int((habit.completionRate(days: 30) * 100).rounded()))%", icon: "target", color: Theme.indigo)
        }
    }

    private struct WeekPoint: Identifiable {
        let start: Date
        let count: Int
        var id: Date { start }
    }

    private var weekPoints: [WeekPoint] {
        let calendar = Calendar.current
        let days = habit.completedDays
        let today = calendar.startOfDay(for: .now)
        return (0..<12).reversed().compactMap { back in
            guard let end = calendar.date(byAdding: .day, value: -7 * back, to: today),
                  let start = calendar.date(byAdding: .day, value: -6, to: end) else { return nil }
            let count = days.filter { $0 >= start && $0 <= end }.count
            return WeekPoint(start: start, count: count)
        }
    }

    private var weeklyTrend: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "Days per week, last 12 weeks")
            Chart(weekPoints) { point in
                AreaMark(x: .value("Week", point.start), y: .value("Days", point.count))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(colors: [habit.colorValue.opacity(0.45), habit.colorValue.opacity(0.02)], startPoint: .top, endPoint: .bottom)
                    )
                LineMark(x: .value("Week", point.start), y: .value("Days", point.count))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(habit.colorValue)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                PointMark(x: .value("Week", point.start), y: .value("Days", point.count))
                    .foregroundStyle(habit.colorValue)
                    .symbolSize(30)
            }
            .chartYScale(domain: 0...7)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 3)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 170)
        }
        .padding(18)
        .glassCard(cornerRadius: 26)
    }

    private func deleteHabit() {
        // Pop first so the view never renders a deleted model.
        let context = modelContext
        let target = habit
        dismiss()
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            context.delete(target)
            try? context.save()
            Haptics.success()
        }
    }
}

#Preview {
    let container = SampleData.previewContainer
    let habit = try! container.mainContext.fetch(FetchDescriptor<Habit>()).first!
    return NavigationStack {
        HabitDetailView(habit: habit)
    }
    .modelContainer(container)
}
