import SwiftUI
import SwiftData
import DesignKit

struct DayDetailSheet: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.name) private var habits: [Habit]
    @Query(sort: \DailyEntry.dateKey, order: .reverse) private var entries: [DailyEntry]

    let date: Date
    @State private var note = ""
    @State private var errorMessage: String?
    private let completionService = HabitCompletionService()

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        let todayHabits = applicableHabits(mode: .required)
        let weekHabits = applicableHabits(mode: .optional)

        NavigationStack {
            List {
                habitSection("Today", habits: todayHabits, empty: "No Today habits were scheduled.", theme: theme)
                habitSection("This Week", habits: weekHabits, empty: "No This Week goals were active.", theme: theme)

                Section("Daily note") {
                    TextField("A note about this day", text: $note, axis: .vertical)
                        .disabled(isFuture)
                        .foregroundStyle(isFuture ? theme.colors.textTertiary : theme.colors.textPrimary)
                        .onSubmit { saveNote() }
                        .accessibilityLabel("Daily note")
                    if isFuture {
                        Label("Future days are read-only", systemImage: "lock")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    } else {
                        Button("Save Note") { saveNote() }
                            .disabled(note == (entry?.note ?? ""))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.colors.background)
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { note = entry?.note ?? "" }
            .alert("Unable to update day", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private func habitSection(
        _ title: String,
        habits: [Habit],
        empty: String,
        theme: Theme
    ) -> some View {
        Section(title) {
            if habits.isEmpty {
                Text(empty).font(theme.typography.body).foregroundStyle(theme.colors.textSecondary)
            } else {
                ForEach(habits) { habit in
                    Button { toggle(habit) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                Text(habit.name).foregroundStyle(theme.colors.textPrimary)
                                Text(habit.category?.name ?? "No area")
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: isCompleted(habit) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isCompleted(habit) ? theme.colors.success : theme.colors.textTertiary)
                        }
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .disabled(isFuture)
                    .accessibilityLabel("\(habit.name), \(isCompleted(habit) ? "completed" : "not completed")")
                    .accessibilityHint(isFuture ? "Future day, read-only" : "Double tap to correct this day")
                }
            }
        }
    }

    private var entry: DailyEntry? {
        entries.first { Calendar.current.isDate($0.dateKey, inSameDayAs: date) }
    }

    private var isFuture: Bool {
        DateUtilities.startOfDay(date) > DateUtilities.startOfDay(.now)
    }

    private func applicableHabits(mode: HabitMode) -> [Habit] {
        habits.filter { habit in
            guard !habit.isArchived else { return false }
            let snapshot = HabitProgressEngine.snapshot(from: habit)
            guard let revision = HabitProgressEngine.revision(for: snapshot, on: date), revision.mode == mode else { return false }
            if mode == .optional { return true }
            if revision.scheduleType == .daily { return true }
            return revision.scheduledDays.contains(DateUtilities.isoWeekday(for: date))
        }
    }

    private func isCompleted(_ habit: Habit) -> Bool {
        entry?.habitStates.first(where: { $0.habit?.id == habit.id })?.isCompleted == true
    }

    private func toggle(_ habit: Habit) {
        do {
            try completionService.toggle(habit, on: date, context: modelContext)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveNote() {
        do {
            try completionService.updateNote(note, on: date, context: modelContext)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
