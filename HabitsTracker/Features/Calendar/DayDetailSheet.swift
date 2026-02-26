import SwiftUI
import SwiftData
import DesignKit

struct DayDetailSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Habit.name) private var habits: [Habit]
    @Query(sort: \DailyEntry.dateKey, order: .reverse) private var entries: [DailyEntry]

    let date: Date

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        let required = TodayEngine.requiredHabits(from: habits, on: date)
        let optional = TodayEngine.optionalHabits(from: habits)
        let entry = entries.first(where: { Calendar.current.isDate($0.dateKey, inSameDayAs: date) })

        NavigationStack {
            List {
                Section("Required") {
                    ForEach(required, id: \.id) { habit in
                        row(habit: habit, entry: entry, theme: theme)
                    }
                }

                Section("Optional") {
                    ForEach(optional, id: \.id) { habit in
                        row(habit: habit, entry: entry, theme: theme)
                    }
                }

                if let note = entry?.note, !note.isEmpty {
                    Section("Note") {
                        Text(note)
                            .foregroundStyle(theme.colors.textPrimary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.colors.background)
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
        }
    }

    @ViewBuilder
    private func row(habit: Habit, entry: DailyEntry?, theme: Theme) -> some View {
        let completed = entry?.habitStates.first(where: { $0.habit?.id == habit.id })?.isCompleted ?? false
        HStack {
            Text(habit.name)
                .foregroundStyle(theme.colors.textPrimary)
            Spacer()
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(completed ? theme.colors.success : theme.colors.textTertiary)
        }
    }
}
