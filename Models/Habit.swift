//
//  Habit.swift
//  habit-tracker
//
//  Created by Ivan Kharitonenko on 31/10/2025.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit {
    var id: UUID
    var name: String
    var iconName: String
    var color: String
    var frequency: String // "daily" or "weekly"
    var targetDays: [Int] // For weekly: 0-6 (Sun-Sat), for daily: empty
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]

    init(name: String, iconName: String, color: String, frequency: String = "daily", targetDays: [Int] = [], createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.color = color
        self.frequency = frequency
        self.targetDays = targetDays
        self.createdAt = createdAt
        self.completions = []
    }

    var colorValue: Color { HabitPalette.color(color) }

    /// Unique completed days, normalised to start of day.
    var completedDays: Set<Date> {
        let calendar = Calendar.current
        return Set(completions.map { calendar.startOfDay(for: $0.date) })
    }

    func isCompleted(on date: Date) -> Bool {
        let calendar = Calendar.current
        return completions.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func isCompletedToday() -> Bool {
        isCompleted(on: .now)
    }

    /// Consecutive days up to today. If today is still open, the streak counts from yesterday.
    func currentStreak() -> Int {
        let calendar = Calendar.current
        let days = completedDays
        var cursor = calendar.startOfDay(for: .now)
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    func bestStreak() -> Int {
        let calendar = Calendar.current
        let sorted = completedDays.sorted()
        guard var previous = sorted.first else { return 0 }
        var best = 1
        var run = 1
        for day in sorted.dropFirst() {
            let gap = calendar.dateComponents([.day], from: previous, to: day).day ?? 0
            run = gap == 1 ? run + 1 : 1
            best = max(best, run)
            previous = day
        }
        return best
    }

    /// Share of the last `days` days (or days since creation, if fewer) that were completed.
    func completionRate(days: Int = 30) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return 0 }
        let created = calendar.startOfDay(for: createdAt)
        let windowStart = max(start, created)
        let window = (calendar.dateComponents([.day], from: windowStart, to: today).day ?? 0) + 1
        let done = completedDays.filter { $0 >= windowStart && $0 <= today }.count
        return window > 0 ? min(Double(done) / Double(window), 1) : 0
    }

    func completionCount(lastDays days: Int) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return 0 }
        return completedDays.filter { $0 >= start }.count
    }
}

@Model
final class HabitCompletion {
    var id: UUID
    var date: Date
    var habit: Habit?

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
    }
}

// MARK: - Mutations

extension Habit {
    /// Adds or removes the completion for `date`. Returns true if the day is now completed.
    @discardableResult
    func toggleCompletion(on date: Date, in context: ModelContext) -> Bool {
        let calendar = Calendar.current
        let matches = completions.filter { calendar.isDate($0.date, inSameDayAs: date) }
        if matches.isEmpty {
            let completion = HabitCompletion(date: date)
            context.insert(completion)
            completions.append(completion)
            try? context.save()
            return true
        } else {
            let ids = Set(matches.map(\.id))
            completions.removeAll { ids.contains($0.id) }
            matches.forEach { context.delete($0) }
            try? context.save()
            return false
        }
    }
}
