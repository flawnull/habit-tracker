//
//  StatisticsView.swift
//  habit-tracker
//
//  Created by Ivan Kharitonenko on 31/10/2025.
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var range: ChartRange = .month

    enum ChartRange: Int, CaseIterable, Identifiable {
        case week = 7, month = 30, quarter = 90
        var id: Int { rawValue }
        var title: String {
            switch self {
            case .week: return "7D"
            case .month: return "30D"
            case .quarter: return "90D"
            }
        }
    }

    private var totalCompletions: Int {
        habits.reduce(0) { $0 + $1.completions.count }
    }

    private var averageRate: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.reduce(0.0) { $0 + $1.completionRate(days: range.rawValue) } / Double(habits.count)
    }

    private var bestStreak: Int {
        habits.map { $0.bestStreak() }.max() ?? 0
    }

    private var activeStreaks: Int {
        habits.filter { $0.currentStreak() > 0 }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    BrandEmptyState(
                        icon: "chart.xyaxis.line",
                        title: "No insights yet",
                        message: "Check in on a few habits and your trends show up here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            statTiles
                            trendCard
                            ContributionHeatmap(habits: habits, weeks: 18)
                                .padding(18)
                                .glassCard(cornerRadius: 26)
                            weekdayCard
                            leaderboard
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .brandScreen()
            .navigationTitle("Insights")
        }
    }

    // MARK: Tiles

    private var statTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            StatTile(title: "Total check-ins", value: "\(totalCompletions)", icon: "checkmark.seal.fill", color: Theme.teal)
            StatTile(title: "Best streak", value: "\(bestStreak)d", icon: "flame.fill", color: Theme.flame)
            StatTile(title: "Active streaks", value: "\(activeStreaks)/\(habits.count)", icon: "bolt.fill", color: .yellow)
            StatTile(title: "Consistency \(range.title)", value: "\(Int((averageRate * 100).rounded()))%", icon: "target", color: Theme.indigo)
        }
    }

    // MARK: Trend chart

    private struct DayPoint: Identifiable {
        let date: Date
        let count: Int
        var id: Date { date }
    }

    private var points: [DayPoint] {
        let calendar = Calendar.current
        return calendar.lastDays(range.rawValue).map { day in
            DayPoint(date: day, count: habits.filter { $0.isCompleted(on: day) }.count)
        }
    }

    private var trendCard: some View {
        let data = points
        let average = data.isEmpty ? 0 : Double(data.map(\.count).reduce(0, +)) / Double(data.count)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Eyebrow(text: "Check-ins per day")
                    Text(String(format: "%.1f avg", average))
                        .font(.title2.weight(.bold))
                        .contentTransition(.numericText())
                }
                Spacer()
                Picker("Range", selection: $range.animation(.spring)) {
                    ForEach(ChartRange.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            Chart {
                ForEach(data) { point in
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Check-ins", point.count)
                    )
                    .foregroundStyle(Theme.chartGradient)
                    .cornerRadius(4)
                }
                RuleMark(y: .value("Average", average))
                    .foregroundStyle(Color.primary.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartYScale(domain: 0...max(habits.count, 1))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: range == .week ? 1 : (range == .month ? 7 : 21))) { _ in
                    AxisValueLabel(format: range == .week ? Date.FormatStyle.dateTime.weekday(.abbreviated) : Date.FormatStyle.dateTime.day().month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Color.primary.opacity(0.08))
                    AxisValueLabel()
                }
            }
            .frame(height: 190)
        }
        .padding(18)
        .glassCard(cornerRadius: 26)
    }

    // MARK: Weekday breakdown

    private struct WeekdayPoint: Identifiable {
        let weekday: Int
        let label: String
        let rate: Double
        var id: Int { weekday }
    }

    private var weekdayPoints: [WeekdayPoint] {
        let calendar = Calendar.current
        let days = calendar.lastDays(84)
        let symbols = calendar.shortWeekdaySymbols
        let ordered = (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
        return ordered.map { weekday in
            let matching = days.filter { calendar.component(.weekday, from: $0) == weekday }
            let possible = matching.count * max(habits.count, 1)
            let done = matching.reduce(0) { total, day in total + habits.filter { $0.isCompleted(on: day) }.count }
            return WeekdayPoint(weekday: weekday, label: symbols[weekday - 1], rate: possible > 0 ? Double(done) / Double(possible) : 0)
        }
    }

    private var weekdayCard: some View {
        let data = weekdayPoints
        let best = data.max { $0.rate < $1.rate }
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow(text: "Best day, last 12 weeks")
                Text(best.map { "\($0.label), \(Int(($0.rate * 100).rounded()))%" } ?? "-")
                    .font(.title2.weight(.bold))
            }
            Chart(data) { point in
                BarMark(
                    x: .value("Weekday", point.label),
                    y: .value("Rate", point.rate)
                )
                .foregroundStyle(point.weekday == best?.weekday ? AnyShapeStyle(Theme.chartGradient) : AnyShapeStyle(Color.primary.opacity(0.15)))
                .cornerRadius(6)
            }
            .chartYScale(domain: 0...1)
            .chartYAxis(.hidden)
            .frame(height: 120)
        }
        .padding(18)
        .glassCard(cornerRadius: 26)
    }

    // MARK: Leaderboard

    private var leaderboard: some View {
        let ranked = habits.sorted { $0.completionRate(days: range.rawValue) > $1.completionRate(days: range.rawValue) }
        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Leaderboard", subtitle: range.title, systemImage: "trophy.fill")
            ForEach(Array(ranked.enumerated()), id: \.element.id) { index, habit in
                HabitRateRow(rank: index + 1, habit: habit, rate: habit.completionRate(days: range.rawValue))
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 26)
    }
}

struct HabitRateRow: View {
    let rank: Int
    let habit: Habit
    let rate: Double

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(rank == 1 ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
                .frame(width: 20)
            HabitIconBadge(icon: habit.iconName, color: habit.colorValue, size: 36)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(habit.name)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(Int((rate * 100).rounded()))%")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.08))
                        Capsule()
                            .fill(habit.colorValue.gradient)
                            .frame(width: max(proxy.size.width * rate, 6))
                    }
                }
                .frame(height: 6)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: rate)
    }
}

/// GitHub-style contribution grid. Columns are weeks, rows are weekdays.
struct ContributionHeatmap: View {
    let habits: [Habit]
    var weeks: Int = 18
    var color: Color? = nil
    var title: String = "Activity"
    var onTap: ((Date) -> Void)? = nil

    private let spacing: CGFloat = 4

    var body: some View {
        let calendar = Calendar.current
        let columns = weekColumns(calendar)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: title)
                Spacer()
                legend
            }
            GeometryReader { proxy in
                let cell = (proxy.size.width - spacing * CGFloat(weeks - 1)) / CGFloat(weeks)
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(columns.indices, id: \.self) { column in
                        VStack(spacing: spacing) {
                            ForEach(columns[column], id: \.self) { day in
                                cellView(for: day, size: cell, calendar: calendar)
                            }
                        }
                    }
                }
            }
            .aspectRatio(CGFloat(weeks) / 7, contentMode: .fit)
        }
    }

    @ViewBuilder
    private func cellView(for day: Date, size: CGFloat, calendar: Calendar) -> some View {
        let isFuture = day > calendar.startOfDay(for: .now)
        let shape = RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
        let level = intensity(for: day)
        Group {
            if isFuture {
                shape.fill(Color.clear)
            } else if let color {
                shape.fill(level > 0 ? AnyShapeStyle(color.gradient) : AnyShapeStyle(Color.primary.opacity(0.07)))
            } else {
                shape.fill(level > 0 ? AnyShapeStyle(Theme.teal.mix(with: Theme.mint, by: level).opacity(0.3 + 0.7 * level)) : AnyShapeStyle(Color.primary.opacity(0.07)))
            }
        }
        .frame(width: size, height: size)
        .overlay {
            if calendar.isDateInToday(day) {
                shape.strokeBorder(Color.primary.opacity(0.6), lineWidth: 1.2)
            }
        }
        .contentShape(shape)
        .onTapGesture {
            guard !isFuture, let onTap else { return }
            onTap(day)
        }
    }

    private var legend: some View {
        HStack(spacing: 3) {
            Text("Less").font(.caption2).foregroundStyle(.secondary)
            ForEach([0.0, 0.33, 0.66, 1.0], id: \.self) { level in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(level == 0 ? AnyShapeStyle(Color.primary.opacity(0.07)) : AnyShapeStyle((color ?? Theme.teal.mix(with: Theme.mint, by: level)).opacity(0.3 + 0.7 * level)))
                    .frame(width: 10, height: 10)
            }
            Text("More").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func intensity(for day: Date) -> Double {
        guard !habits.isEmpty else { return 0 }
        let done = habits.filter { $0.isCompleted(on: day) }.count
        return Double(done) / Double(habits.count)
    }

    /// `weeks` columns of 7 days each, ending with the current week.
    private func weekColumns(_ calendar: Calendar) -> [[Date]] {
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let offsetIntoWeek = (weekday - calendar.firstWeekday + 7) % 7
        guard let thisWeekStart = calendar.date(byAdding: .day, value: -offsetIntoWeek, to: today),
              let firstStart = calendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: thisWeekStart)
        else { return [] }
        return (0..<weeks).map { week in
            (0..<7).compactMap { day in
                calendar.date(byAdding: .day, value: week * 7 + day, to: firstStart)
            }
        }
    }
}

#Preview {
    StatisticsView()
        .modelContainer(SampleData.previewContainer)
}
