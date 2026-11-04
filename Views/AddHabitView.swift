//
//  AddHabitView.swift
//  habit-tracker
//
//  Created by Ivan Kharitonenko on 31/10/2025.
//
//  Shared create/edit sheet. Pass `editing:` to edit an existing habit.
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let editing: Habit?

    @State private var habitName: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @FocusState private var nameFocused: Bool

    private let suggestions: [(String, String, String)] = [
        ("Morning run", "figure.run", "mint"),
        ("Read 20 pages", "book.fill", "indigo"),
        ("Drink water", "drop.fill", "cyan"),
        ("Meditate", "figure.mind.and.body", "purple"),
        ("No phone in bed", "phone.down.fill", "orange")
    ]

    init(editing: Habit? = nil) {
        self.editing = editing
        _habitName = State(initialValue: editing?.name ?? "")
        _selectedIcon = State(initialValue: editing?.iconName ?? "sparkles")
        _selectedColor = State(initialValue: editing?.color ?? "teal")
    }

    private var trimmedName: String {
        habitName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var color: Color { HabitPalette.color(selectedColor) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    preview
                    nameField
                    if editing == nil && trimmedName.isEmpty {
                        suggestionChips
                    }
                    colorPicker
                    iconPicker
                }
                .padding()
            }
            .brandScreen()
            .navigationTitle(editing == nil ? "New habit" : "Edit habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "Add" : "Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear { if editing == nil { nameFocused = true } }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: Sections

    private var preview: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.gradient)
                    .frame(width: 120, height: 120)
                    .blur(radius: 40)
                    .opacity(0.55)
                HabitIconBadge(icon: selectedIcon, color: color, size: 84)
                    .contentTransition(.symbolEffect(.replace))
            }
            Text(trimmedName.isEmpty ? "Your new habit" : trimmedName)
                .font(.title2.weight(.bold))
                .foregroundStyle(trimmedName.isEmpty ? .secondary : .primary)
                .lineLimit(1)
        }
        .padding(.top, 8)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedColor)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedIcon)
    }

    private var nameField: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil")
                .foregroundStyle(.secondary)
            TextField("Name it, e.g. Morning run", text: $habitName)
                .font(.body.weight(.medium))
                .focused($nameFocused)
                .submitLabel(.done)
                .onSubmit { if !trimmedName.isEmpty { save() } }
        }
        .padding(16)
        .glassCard(cornerRadius: 18)
    }

    private var suggestionChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Quick start")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.0) { name, icon, colorName in
                        Button {
                            Haptics.select()
                            habitName = name
                            selectedIcon = icon
                            selectedColor = colorName
                        } label: {
                            Label(name, systemImage: icon)
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
            .scrollClipDisabled()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Color")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 12) {
                ForEach(HabitPalette.colorNames, id: \.self) { name in
                    ColorButton(color: HabitPalette.color(name), isSelected: selectedColor == name) {
                        Haptics.select()
                        selectedColor = name
                    }
                }
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 24)
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Icon")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 12) {
                ForEach(HabitPalette.icons, id: \.self) { icon in
                    IconButton(icon: icon, color: color, isSelected: selectedIcon == icon) {
                        Haptics.select()
                        selectedIcon = icon
                    }
                }
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 24)
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        if let editing {
            editing.name = trimmedName
            editing.iconName = selectedIcon
            editing.color = selectedColor
        } else {
            modelContext.insert(Habit(name: trimmedName, iconName: selectedIcon, color: selectedColor))
        }
        try? modelContext.save()
        Haptics.success()
        dismiss()
    }
}

#Preview {
    AddHabitView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
