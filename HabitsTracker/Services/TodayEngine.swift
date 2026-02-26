import Foundation

enum TodayEngine {
    nonisolated static func isScheduled(_ habit: Habit, on date: Date, calendar: Calendar = .current) -> Bool {
        switch habit.scheduleType {
        case .daily:
            return true
        case .customDays:
            return habit.scheduledDays.contains(DateUtilities.isoWeekday(for: date, calendar: calendar))
        }
    }

    nonisolated static func requiredHabits(from habits: [Habit], on date: Date, calendar: Calendar = .current) -> [Habit] {
        habits
            .filter { !$0.isArchived }
            .filter { $0.mode == .required && isScheduled($0, on: date, calendar: calendar) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    nonisolated static func optionalHabits(from habits: [Habit]) -> [Habit] {
        habits
            .filter { !$0.isArchived }
            .filter { $0.mode == .optional }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
