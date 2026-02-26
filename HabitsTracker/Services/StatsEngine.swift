import Foundation

struct DayCompletion: Identifiable {
    let date: Date
    let completedRequired: Int
    let totalRequired: Int

    var id: Date { date }
    var ratio: Double { totalRequired == 0 ? 0 : Double(completedRequired) / Double(totalRequired) }
}

enum StatsEngine {
    nonisolated static func requiredCompletion(
        requiredHabits: [Habit],
        dayEntry: DailyEntry?
    ) -> (completed: Int, total: Int, ratio: Double) {
        let total = requiredHabits.count
        guard total > 0, let dayEntry else { return (0, total, 0) }

        let completed = dayEntry.habitStates
            .filter { state in
                state.isCompleted && requiredHabits.contains(where: { $0.id == state.habit?.id })
            }
            .count

        return (completed, total, Double(completed) / Double(total))
    }

    nonisolated static func dayCompletion(
        date: Date,
        habits: [Habit],
        entries: [DailyEntry],
        calendar: Calendar = .current
    ) -> DayCompletion {
        let required = TodayEngine.requiredHabits(from: habits, on: date, calendar: calendar)
        let key = DateUtilities.startOfDay(date, calendar: calendar)
        let dayEntry = entries.first(where: { calendar.isDate($0.dateKey, inSameDayAs: key) })
        let completion = requiredCompletion(requiredHabits: required, dayEntry: dayEntry)
        return DayCompletion(date: key, completedRequired: completion.completed, totalRequired: completion.total)
    }

    nonisolated static func dailyTrend(
        habits: [Habit],
        entries: [DailyEntry],
        daysBack: Int,
        endDate: Date = .now,
        calendar: Calendar = .current
    ) -> [DayCompletion] {
        guard daysBack > 0 else { return [] }
        return (0..<daysBack).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: endDate) else { return nil }
            return dayCompletion(date: date, habits: habits, entries: entries, calendar: calendar)
        }.sorted { $0.date < $1.date }
    }
}
