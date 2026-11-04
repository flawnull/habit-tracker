//
//  DesignSystem.swift
//  habit-tracker
//
//  Brand tokens, Liquid Glass surfaces and shared components.
//

import SwiftUI

// MARK: - Brand

enum Theme {
    /// Pulled from the app icon: mint at the top of the loop, indigo at the bottom.
    static let mint = Color(red: 0.06, green: 0.96, blue: 0.52)
    static let teal = Color(red: 0.16, green: 0.70, blue: 0.68)
    static let indigo = Color(red: 0.36, green: 0.37, blue: 0.90)
    static let ink = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let flame = Color(red: 1.00, green: 0.55, blue: 0.20)

    static let brandGradient = LinearGradient(
        colors: [mint, teal, indigo],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Lower-contrast end trimmed so white labels stay readable.
    static let buttonGradient = LinearGradient(
        colors: [teal, indigo],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let ringGradient = AngularGradient(
        colors: [indigo, teal, mint],
        center: .center,
        startAngle: .degrees(0),
        endAngle: .degrees(360)
    )

    static let chartGradient = LinearGradient(
        colors: [indigo, teal, mint],
        startPoint: .bottom,
        endPoint: .top
    )
}

// MARK: - Habit palette

enum HabitPalette {
    static let colorNames = [
        "mint", "teal", "cyan", "blue", "indigo", "purple",
        "pink", "red", "orange", "yellow", "green", "brown"
    ]

    static let icons = [
        "figure.run", "figure.walk", "dumbbell.fill", "figure.mind.and.body",
        "drop.fill", "fork.knife", "bed.double.fill", "cup.and.saucer.fill",
        "book.fill", "brain.head.profile", "pencil.and.scribble", "laptopcomputer",
        "music.note", "camera.fill", "leaf.fill", "sun.max.fill",
        "moon.stars.fill", "heart.fill", "flame.fill", "bolt.fill",
        "sparkles", "star.fill", "globe.europe.africa.fill", "phone.down.fill"
    ]

    static func color(_ name: String) -> Color {
        switch name {
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "brown": return .brown
        default: return .teal
        }
    }
}

// MARK: - Appearance

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func select() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Animated background

/// Slow-moving mesh gradient that sits behind every screen.
struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0, paused: reduceMotion)) { timeline in
            let t = Float(timeline.date.timeIntervalSinceReferenceDate * 0.12)
            MeshGradient(width: 3, height: 3, points: points(t), colors: colors)
        }
        .ignoresSafeArea()
    }

    private func points(_ t: Float) -> [SIMD2<Float>] {
        let wobbleA = 0.10 * sin(t)
        let wobbleB = 0.12 * cos(t * 0.8)
        let wobbleC = 0.10 * sin(t * 1.3)
        return [
            SIMD2<Float>(0, 0), SIMD2<Float>(0.5, 0), SIMD2<Float>(1, 0),
            SIMD2<Float>(0, 0.5 + wobbleA), SIMD2<Float>(0.5 + wobbleB, 0.5 + wobbleC), SIMD2<Float>(1, 0.5 - wobbleA),
            SIMD2<Float>(0, 1), SIMD2<Float>(0.5, 1), SIMD2<Float>(1, 1)
        ]
    }

    private var colors: [Color] {
        let dark = scheme == .dark
        let base = dark ? Theme.ink : Color(red: 0.96, green: 0.97, blue: 0.99)
        let indigo = Theme.indigo.opacity(dark ? 0.55 : 0.22)
        let teal = Theme.teal.opacity(dark ? 0.35 : 0.16)
        let mint = Theme.mint.opacity(dark ? 0.30 : 0.18)
        return [
            indigo, base, base,
            base, teal, base,
            base, base, mint
        ]
    }
}

// MARK: - Glass surfaces

extension View {
    /// Liquid Glass card used for every grouped surface in the app.
    func glassCard(cornerRadius: CGFloat = 24, tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, tint: tint, interactive: interactive))
    }

    /// Screen chrome shared by every tab: animated mesh behind, clear scroll background.
    func brandScreen() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background { AppBackground() }
    }
}

private struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if let tint {
            content.glassEffect(.regular.tint(tint.opacity(0.18)).interactive(interactive), in: shape)
        } else {
            content.glassEffect(.regular.interactive(interactive), in: shape)
        }
    }
}

// MARK: - Buttons

struct BrandButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.buttonGradient, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: Theme.indigo.opacity(isEnabled ? 0.45 : 0), radius: 18, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.5)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Components

struct BrandMark: View {
    var size: CGFloat = 96
    var glow: Bool = true

    var body: some View {
        Image("BrandMark")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: glow ? Theme.mint.opacity(0.35) : .clear, radius: size * 0.25, y: size * 0.08)
    }
}

struct HabitIconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 52

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
        shape
            .fill(LinearGradient(colors: [color, color.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .overlay(shape.strokeBorder(.white.opacity(0.3), lineWidth: 1))
            .shadow(color: color.opacity(0.35), radius: size * 0.15, y: size * 0.08)
    }
}

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 14
    var gradient: AngularGradient = Theme.ringGradient

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(min(progress, 1), 0.0001))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.mint.opacity(0.55 * progress), radius: lineWidth)
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.75), value: progress)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brandGradient)
            }
            Text(title)
                .font(.title3.weight(.bold))
            Spacer()
            if let subtitle {
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Small all-caps label, used for card eyebrows ("TODAY", "ON-DEVICE AI").
struct Eyebrow: View {
    let text: String
    var color: Color = .secondary

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(color)
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.15), in: Circle())

            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard(cornerRadius: 22)
    }
}

struct BrandEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @State private var float = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.brandGradient)
                    .frame(width: 120, height: 120)
                    .blur(radius: 40)
                    .opacity(0.6)
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(Theme.brandGradient)
                    .symbolEffect(.breathe, options: .repeating)
            }
            .offset(y: float ? -6 : 6)
            .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: float)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.weight(.bold))
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus")
                }
                .buttonStyle(BrandButtonStyle())
                .padding(.horizontal, 48)
                .padding(.top, 4)
            }
        }
        .onAppear { float = true }
    }
}

// MARK: - Dates

extension Calendar {
    /// Days from `days - 1` ago up to today, oldest first, normalised to start of day.
    func lastDays(_ days: Int, from date: Date = .now) -> [Date] {
        let today = startOfDay(for: date)
        return (0..<days).reversed().compactMap { self.date(byAdding: .day, value: -$0, to: today) }
    }
}
