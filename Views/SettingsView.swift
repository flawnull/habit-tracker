//
//  SettingsView.swift
//  habit-tracker
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @AppStorage("appearance") private var appearance: AppearanceMode = .system
    @AppStorage("reminders.enabled") private var remindersEnabled = false
    @AppStorage("reminders.time") private var reminderTimestamp: Double = SettingsView.defaultReminder
    @State private var permissionDenied = false
    @State private var confirmErase = false

    private static let defaultReminder: Double = {
        let date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now) ?? .now
        return date.timeIntervalSince1970
    }()

    private var reminderTime: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: reminderTimestamp) },
            set: { reminderTimestamp = $0.timeIntervalSince1970 }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: $appearance) {
                        ForEach(AppearanceMode.allCases) { Text($0.title).tag($0) }
                    } label: {
                        SettingsLabel(title: "Theme", icon: "circle.lefthalf.filled", color: Theme.indigo)
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Appearance")
                }

                Section {
                    Toggle(isOn: $remindersEnabled) {
                        SettingsLabel(title: "Daily reminder", icon: "bell.badge.fill", color: Theme.flame)
                    }
                    if remindersEnabled {
                        DatePicker(selection: reminderTime, displayedComponents: .hourAndMinute) {
                            SettingsLabel(title: "Time", icon: "clock.fill", color: Theme.teal)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text(permissionDenied
                         ? "Notifications are blocked. Enable them for HabitTracker in the Settings app."
                         : "One gentle nudge a day, scheduled locally on your device.")
                }

                Section {
                    Button {
                        SampleData.seed(into: modelContext)
                        Haptics.success()
                    } label: {
                        SettingsLabel(title: "Load demo data", icon: "wand.and.stars", color: .purple)
                    }
                    Button(role: .destructive) {
                        confirmErase = true
                    } label: {
                        SettingsLabel(title: "Erase all habits", icon: "trash.fill", color: .red)
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Demo data adds six habits with ten weeks of history. Useful for exploring Insights or taking screenshots.")
                }

                Section {
                    Button {
                        openURL(AppConfig.repositoryURL)
                    } label: {
                        HStack {
                            SettingsLabel(title: "Source code", icon: "chevron.left.forwardslash.chevron.right", color: .gray)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    LabeledContent {
                        Text(AppConfig.version).monospacedDigit()
                    } label: {
                        SettingsLabel(title: "Version", icon: "number", color: Theme.teal)
                    }
                    LabeledContent {
                        Text(AppConfig.isFirebaseReady ? "Firebase" : "Local only")
                    } label: {
                        SettingsLabel(title: "Backend", icon: "server.rack", color: Theme.indigo)
                    }
                } header: {
                    Text("About")
                }
            }
            .foregroundStyle(.primary)
            .brandScreen()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: remindersEnabled) { _, enabled in
                Task { await updateReminder(enabled: enabled) }
            }
            .onChange(of: reminderTimestamp) { _, _ in
                Task { await updateReminder(enabled: remindersEnabled) }
            }
            .confirmationDialog("Erase every habit and check-in?", isPresented: $confirmErase, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) {
                    SampleData.eraseAll(in: modelContext)
                    Haptics.success()
                }
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    private func updateReminder(enabled: Bool) async {
        guard enabled else {
            ReminderScheduler.cancel()
            return
        }
        let granted = await ReminderScheduler.requestAuthorization()
        permissionDenied = !granted
        if granted {
            await ReminderScheduler.scheduleDaily(at: reminderTime.wrappedValue)
        } else {
            remindersEnabled = false
        }
    }
}

struct SettingsLabel: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(SampleData.previewContainer)
}
