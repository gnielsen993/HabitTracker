import SwiftUI
import SwiftData
import DesignKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Domain.sortIndex) private var categories: [Domain]
    @Query(sort: \Habit.name) private var habits: [Habit]
    @Query(sort: \DailyEntry.dateKey, order: .reverse) private var entries: [DailyEntry]

    @State private var saveError: String?

    private let bootstrapService = BootstrapService()

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        let required = TodayEngine.requiredHabits(from: habits, on: .now)
        let optional = TodayEngine.optionalHabits(from: habits)
        let completion = StatsEngine.requiredCompletion(requiredHabits: required, dayEntry: todayEntry)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.l) {
                    DKCard(theme: theme) {
                        HStack(spacing: theme.spacing.l) {
                            DKProgressRing(progress: completion.ratio, label: "Required", theme: theme)
                                .frame(width: 140, height: 140)

                            VStack(alignment: .leading, spacing: theme.spacing.s) {
                                Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                                    .font(theme.typography.title)
                                    .foregroundStyle(theme.colors.textPrimary)
                                Text("\(completion.completed) of \(completion.total) required complete")
                                    .font(theme.typography.body)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                            Spacer()
                        }
                    }

                    DKSectionHeader("Required", subtitle: "Scheduled today", theme: theme)
                    ForEach(grouped(required: required), id: \.category.id) { group in
                        DKCard(theme: theme) {
                            VStack(alignment: .leading, spacing: theme.spacing.s) {
                                Text(group.category.name)
                                    .font(theme.typography.headline)
                                    .foregroundStyle(theme.colors.textPrimary)

                                ForEach(group.habits, id: \.id) { habit in
                                    HabitToggleRow(
                                        habit: habit,
                                        isCompleted: state(for: habit)?.isCompleted ?? false,
                                        theme: theme,
                                        detail: nil
                                    ) {
                                        toggle(habit)
                                    }
                                }
                            }
                        }
                    }

                    DKSectionHeader("Optional", subtitle: "Tracked weekly", theme: theme)
                    DKCard(theme: theme) {
                        VStack(spacing: theme.spacing.s) {
                            ForEach(optional, id: \.id) { habit in
                                HabitToggleRow(
                                    habit: habit,
                                    isCompleted: state(for: habit)?.isCompleted ?? false,
                                    theme: theme,
                                    detail: weeklyProgressText(for: habit)
                                ) {
                                    toggle(habit)
                                }
                            }
                        }
                    }

                    DKSectionHeader("Daily Note", theme: theme)
                    DKCard(theme: theme) {
                        TextField("Reflect on today", text: Binding(
                            get: { todayEntry?.note ?? "" },
                            set: { updateDailyNote($0) }
                        ), axis: .vertical)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textPrimary)
                    }
                }
                .padding(theme.spacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(theme.colors.background.ignoresSafeArea())
            .navigationTitle("Today")
            .alert("Save Error", isPresented: Binding(get: { saveError != nil }, set: { _ in saveError = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "Unknown error")
            }
            .task {
                do {
                    _ = try bootstrapService.ensureDailyEntryExists(for: .now, context: modelContext)
                } catch {
                    saveError = error.localizedDescription
                }
            }
        }
    }

    private var todayEntry: DailyEntry? {
        entries.first(where: { Calendar.current.isDateInToday($0.dateKey) })
    }

    private func grouped(required: [Habit]) -> [(category: Domain, habits: [Habit])] {
        categories.compactMap { category in
            let matching = required.filter { $0.category?.id == category.id }
            return matching.isEmpty ? nil : (category, matching)
        }
    }

    private func state(for habit: Habit) -> HabitState? {
        todayEntry?.habitStates.first(where: { $0.habit?.id == habit.id })
    }

    private func toggle(_ habit: Habit) {
        guard let entry = todayEntry else { return }
        if let state = state(for: habit) {
            state.isCompleted.toggle()
            state.completedAt = state.isCompleted ? .now : nil
        } else {
            let newState = HabitState(isCompleted: true, completedAt: .now, dailyEntry: entry, habit: habit)
            modelContext.insert(newState)
            entry.habitStates.append(newState)
            habit.states.append(newState)
        }

        do {
            try modelContext.save()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func weeklyProgressText(for habit: Habit) -> String? {
        guard let target = habit.weeklyTargetCount else { return nil }
        let completed = WeeklyGoalEngine.completedCountThisWeek(habit: habit, entries: entries)
        return "\(completed)/\(target) this week"
    }

    private func updateDailyNote(_ note: String) {
        guard let entry = todayEntry else { return }
        entry.note = note
        try? modelContext.save()
    }
}

private struct HabitToggleRow: View {
    let habit: Habit
    let isCompleted: Bool
    let theme: Theme
    let detail: String?
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: theme.spacing.s) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? theme.colors.success : theme.colors.textTertiary)
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(habit.name)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textPrimary)
                    if let detail {
                        Text(detail)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
