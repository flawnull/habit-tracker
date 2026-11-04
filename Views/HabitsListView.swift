//
//  HabitsListView.swift
//  habit-tracker
//
//  Created by Ivan Kharitonenko on 31/10/2025.
//

import SwiftUI
import SwiftData

struct HabitsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @State private var showingAddHabit = false
    @State private var searchText = ""
    @State private var pendingDelete: Habit?

    private var filtered: [Habit] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return habits }
        return habits.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    BrandEmptyState(
                        icon: "square.stack.3d.up.fill",
                        title: "No habits yet",
                        message: "Create a habit with an icon and color that make you want to tap it.",
                        actionTitle: "Create habit"
                    ) { showingAddHabit = true }
                } else {
                    List {
                        ForEach(filtered) { habit in
                            NavigationLink(value: habit) {
                                HabitListRow(habit: habit)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    pendingDelete = habit
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search habits")
                }
            }
            .brandScreen()
            .navigationTitle("Habits")
            .navigationDestination(for: Habit.self) { habit in
                HabitDetailView(habit: habit)
            }
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
            .confirmationDialog(
                "Delete \(pendingDelete?.name ?? "habit")?",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete habit and history", role: .destructive) {
                    if let habit = pendingDelete {
                        withAnimation {
                            modelContext.delete(habit)
                            try? modelContext.save()
                        }
                        Haptics.success()
                    }
                    pendingDelete = nil
                }
            } message: {
                Text("This removes every check-in for this habit.")
            }
        }
    }
}

struct HabitListRow: View {
    let habit: Habit

    var body: some View {
        HStack(spacing: 14) {
            HabitIconBadge(icon: habit.iconName, color: habit.colorValue, size: 48)

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.name)
                    .font(.headline)

                HStack(spacing: 12) {
                    Label("\(habit.currentStreak())d streak", systemImage: "flame.fill")
                        .foregroundStyle(Theme.flame)
                    Label("\(habit.completions.count) total", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.secondary)
                }
                .font(.caption.weight(.semibold))
                .labelStyle(CompactLabelStyle())
            }

            Spacer()

            MiniWeek(habit: habit)
        }
        .padding(14)
        .glassCard(cornerRadius: 22)
    }
}

/// Seven dots for the last week.
struct MiniWeek: View {
    let habit: Habit

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Calendar.current.lastDays(7), id: \.self) { day in
                Circle()
                    .fill(habit.isCompleted(on: day) ? AnyShapeStyle(habit.colorValue.gradient) : AnyShapeStyle(Color.primary.opacity(0.1)))
                    .frame(width: 7, height: 7)
            }
        }
    }
}

#Preview {
    HabitsListView()
        .modelContainer(SampleData.previewContainer)
}
