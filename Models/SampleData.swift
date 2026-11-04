//
//  SampleData.swift
//  habit-tracker
//
//  Demo habits with ~10 weeks of realistic history. Used by previews and
//  Settings → Developer → Load demo data (handy for screenshots).
//

import Foundation
import SwiftData

enum SampleData {
    private struct Template {
        let name: String
        let icon: String
        let color: String
        /// Probability of completing on any given day.
        let consistency: Double
    }

    private static let templates: [Template] = [
        Template(name: "Morning run", icon: "figure.run", color: "mint", consistency: 0.78),
        Template(name: "Read 20 pages", icon: "book.fill", color: "indigo", consistency: 0.86),
        Template(name: "Drink 2L water", icon: "drop.fill", color: "cyan", consistency: 0.93),
        Template(name: "Meditate", icon: "figure.mind.and.body", color: "purple", consistency: 0.64),
        Template(name: "Ship one commit", icon: "laptopcomputer", color: "orange", consistency: 0.72),
        Template(name: "Sleep by 23:30", icon: "moon.stars.fill", color: "blue", consistency: 0.55)
    ]

    static func seed(into context: ModelContext, days: Int = 70) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var generator = SeededGenerator(seed: 42)

        for (index, template) in templates.enumerated() {
            let created = calendar.date(byAdding: .day, value: -(days + index), to: today) ?? today
            let habit = Habit(name: template.name, iconName: template.icon, color: template.color, createdAt: created)
            context.insert(habit)

            // Recent days lean more consistent, so streaks look alive.
            for offset in 1..<days {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
                let boost = offset < 12 ? 0.12 : 0
                if Double.random(in: 0...1, using: &generator) < template.consistency + boost {
                    let completion = HabitCompletion(date: day.addingTimeInterval(Double.random(in: 25_000...75_000, using: &generator)))
                    context.insert(completion)
                    habit.completions.append(completion)
                }
            }
            // Leave a couple of habits open today so the Today screen has something to do.
            if index % 2 == 0 {
                let completion = HabitCompletion(date: .now)
                context.insert(completion)
                habit.completions.append(completion)
            }
        }
        try? context.save()
    }

    static func eraseAll(in context: ModelContext) {
        try? context.delete(model: HabitCompletion.self)
        try? context.delete(model: Habit.self)
        try? context.save()
    }

    static var previewContainer: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Habit.self, HabitCompletion.self, configurations: config)
        seed(into: container.mainContext)
        return container
    }
}

/// Deterministic RNG so demo data looks the same on every device.
nonisolated struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
