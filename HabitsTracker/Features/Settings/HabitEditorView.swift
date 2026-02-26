import SwiftUI
import SwiftData
import DesignKit

struct HabitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Category.sortIndex) private var categories: [Category]

    let habit: Habit

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Habit name", text: Binding(
                        get: { habit.name },
                        set: { habit.name = $0 }
                    ))
                }

                Section("Category") {
                    Picker("Category", selection: Binding(
                        get: { habit.category?.id },
                        set: { id in habit.category = categories.first(where: { $0.id == id }) }
                    )) {
                        Text("None").tag(UUID?.none)
                        ForEach(categories, id: \.id) { category in
                            Text(category.name).tag(UUID?.some(category.id))
                        }
                    }
                }

                Section("Mode") {
                    Picker("Mode", selection: Binding(
                        get: { habit.mode },
                        set: { habit.mode = $0 }
                    )) {
                        ForEach(HabitMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }

                    if habit.mode == .optional {
                        Stepper(value: Binding(
                            get: { habit.weeklyTargetCount ?? 1 },
                            set: { habit.weeklyTargetCount = $0 }
                        ), in: 1...14) {
                            Text("Weekly target: \(habit.weeklyTargetCount ?? 1)")
                        }
                    }
                }

                Section("Schedule") {
                    Picker("Type", selection: Binding(
                        get: { habit.scheduleType },
                        set: { habit.scheduleType = $0 }
                    )) {
                        Text("Daily").tag(HabitScheduleType.daily)
                        Text("Custom Days").tag(HabitScheduleType.customDays)
                    }

                    if habit.scheduleType == .customDays {
                        ForEach(Weekday.allCases, id: \.id) { day in
                            Toggle(day.shortLabel, isOn: Binding(
                                get: { habit.scheduledDays.contains(day) },
                                set: { enabled in
                                    var updated = Set(habit.scheduledDays)
                                    if enabled { updated.insert(day) } else { updated.remove(day) }
                                    habit.scheduledDays = Array(updated).sorted { $0.rawValue < $1.rawValue }
                                }
                            ))
                        }
                    }
                }

                Section("Flags") {
                    Toggle("Pinned", isOn: Binding(get: { habit.isPinned }, set: { habit.isPinned = $0 }))
                    Toggle("Archived", isOn: Binding(get: { habit.isArchived }, set: { habit.isArchived = $0 }))
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.colors.background)
            .navigationTitle("Edit Habit")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
