//
//  HabitCoach.swift
//  habit-tracker
//
//  On-device AI coach built on Apple's Foundation Models framework (iOS 26).
//  Runs the Apple Intelligence language model locally: no API key, no network,
//  habit data never leaves the phone. Falls back to a rule-based coach on
//  devices without Apple Intelligence.
//

import Foundation
import FoundationModels
import Observation

/// Structured output the model fills in via guided generation.
@Generable
nonisolated struct CoachInsight {
    @Guide(description: "A punchy headline of at most six words. No emoji.")
    var headline: String

    @Guide(description: "One or two sentences that reference the user's actual habits and streaks by name.")
    var message: String

    @Guide(description: "One concrete, small action for the next 24 hours.")
    var tip: String
}

/// What the UI renders, regardless of which engine produced it.
struct CoachNote: Equatable {
    var headline: String
    var message: String
    var tip: String
}

/// Plain-value snapshot of the user's habits, safe to hand to the model.
struct CoachSnapshot {
    struct Item {
        let name: String
        let doneToday: Bool
        let streak: Int
        let bestStreak: Int
        let rate30: Int
    }

    let items: [Item]
    let firstName: String

    @MainActor
    init(habits: [Habit], firstName: String) {
        self.firstName = firstName
        self.items = habits.map {
            Item(
                name: $0.name,
                doneToday: $0.isCompletedToday(),
                streak: $0.currentStreak(),
                bestStreak: $0.bestStreak(),
                rate30: Int(($0.completionRate(days: 30) * 100).rounded())
            )
        }
    }

    var prompt: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let partOfDay = hour < 12 ? "morning" : (hour < 18 ? "afternoon" : "evening")
        let lines = items.map {
            "- \($0.name): \($0.doneToday ? "done today" : "not done yet today"), current streak \($0.streak) days, best \($0.bestStreak) days, \($0.rate30)% over 30 days"
        }
        return """
        It is \(partOfDay). The user\(firstName.isEmpty ? "" : " is called \(firstName) and") tracks these habits:
        \(lines.joined(separator: "\n"))
        Write a short coaching note for right now.
        """
    }

    /// Deterministic coach used when the on-device model is unavailable.
    var fallbackNote: CoachNote {
        guard !items.isEmpty else {
            return CoachNote(headline: "Start with one", message: "Pick the smallest habit you can do daily and add it.", tip: "Make it so easy it feels silly to skip.")
        }
        let open = items.filter { !$0.doneToday }
        let atRisk = open.filter { $0.streak >= 3 }.max { $0.streak < $1.streak }
        let strongest = items.max { $0.streak < $1.streak }
        let weakest = items.min { $0.rate30 < $1.rate30 }

        if open.isEmpty {
            return CoachNote(
                headline: "Perfect day locked in",
                message: "Every habit is done. \(strongest.map { "\($0.name) is on a \($0.streak)-day run." } ?? "")",
                tip: "Set out tomorrow's first habit tonight so the morning starts on autopilot."
            )
        }
        if let atRisk {
            return CoachNote(
                headline: "Protect the \(atRisk.streak)-day streak",
                message: "\(atRisk.name) is still open today. Missing now would reset a \(atRisk.streak)-day run.",
                tip: "Do a two-minute version of \(atRisk.name.lowercased()) right now. It still counts."
            )
        }
        if let weakest, weakest.rate30 < 50 {
            return CoachNote(
                headline: "One habit needs a reset",
                message: "\(weakest.name) sits at \(weakest.rate30)% this month. The others are carrying you.",
                tip: "Attach \(weakest.name.lowercased()) to something you already do daily, like coffee."
            )
        }
        return CoachNote(
            headline: "\(open.count) left for today",
            message: "You are on track. \(strongest.map { "\($0.name) leads with \($0.streak) days." } ?? "")",
            tip: "Knock out the quickest one first to build momentum."
        )
    }
}

@MainActor
@Observable
final class HabitCoach {
    enum Engine: Equatable {
        case appleIntelligence
        case offline(reason: String)
    }

    enum Phase: Equatable {
        case idle
        case thinking
        case ready(CoachNote)
    }

    private(set) var phase: Phase = .idle
    private(set) var engine: Engine = .offline(reason: "Checking model")

    private static let instructions = """
    You are a warm, concise habit coach inside an iOS habit tracker.
    Speak directly to the user in second person. Be specific: mention habits by name and use the numbers given.
    Never invent habits or numbers. Never moralise. Keep the whole note under 60 words.
    """

    init() {
        refreshEngine()
    }

    func refreshEngine() {
        switch SystemLanguageModel.default.availability {
        case .available:
            engine = .appleIntelligence
        case .unavailable(let reason):
            engine = .offline(reason: Self.describe(reason))
        @unknown default:
            engine = .offline(reason: "Unavailable")
        }
    }

    func generate(for snapshot: CoachSnapshot) async {
        phase = .thinking
        refreshEngine()

        guard engine == .appleIntelligence, !snapshot.items.isEmpty else {
            try? await Task.sleep(for: .milliseconds(450))
            phase = .ready(snapshot.fallbackNote)
            return
        }

        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let response = try await session.respond(to: snapshot.prompt, generating: CoachInsight.self)
            let insight = response.content
            phase = .ready(CoachNote(headline: insight.headline, message: insight.message, tip: insight.tip))
        } catch {
            phase = .ready(snapshot.fallbackNote)
        }
    }

    private static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible: return "Device not eligible"
        case .appleIntelligenceNotEnabled: return "Apple Intelligence off"
        case .modelNotReady: return "Model downloading"
        @unknown default: return "Unavailable"
        }
    }
}
