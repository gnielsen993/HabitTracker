import Foundation

enum WeeklyGoalEngine {
    nonisolated static func completedCountThisWeek(
        habit: Habit,
        entries: [DailyEntry],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let weekStart = DateUtilities.startOfWeek(for: referenceDate, calendar: calendar)
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart

        return entries
            .filter { $0.dateKey >= weekStart && $0.dateKey < weekEnd }
            .compactMap { entry in
                entry.habitStates.first(where: { $0.habit?.id == habit.id })
            }
            .filter(\.isCompleted)
            .count
    }

    nonisolated static func remainingSessions(target: Int, completed: Int) -> Int {
        max(target - completed, 0)
    }

    nonisolated static func isTargetMet(target: Int, completed: Int) -> Bool {
        completed >= target
    }
}
