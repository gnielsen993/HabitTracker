import Foundation

enum StreakEngine {
    nonisolated static func currentRequiredStreak(
        habit: Habit,
        entries: [DailyEntry],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        guard habit.mode == .required else { return 0 }

        let indexed: [Date: Bool] = Dictionary(uniqueKeysWithValues: entries.map { entry in
            let completed = entry.habitStates.first(where: { $0.habit?.id == habit.id })?.isCompleted ?? false
            return (DateUtilities.startOfDay(entry.dateKey, calendar: calendar), completed)
        })

        var streak = 0
        var cursor = DateUtilities.startOfDay(referenceDate, calendar: calendar)

        while true {
            if TodayEngine.isScheduled(habit, on: cursor, calendar: calendar) {
                let done = indexed[cursor] ?? false
                if !done { break }
                streak += 1
            }

            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous

            if cursor < (entries.map { $0.dateKey }.min() ?? cursor) { break }
        }

        return streak
    }
}
