import XCTest
@testable import HabitsTracker

final class EngineTests: XCTestCase {
    func testCustomScheduleMatching() {
        let habit = Habit(
            name: "Deep Work",
            scheduleType: .customDays,
            scheduledDays: [.monday, .wednesday],
            mode: .required
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let monday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 12)) ?? .now
        XCTAssertTrue(TodayEngine.isScheduled(habit, on: monday, calendar: calendar))
    }

    func testOptionalExcludedFromRequiredCompletion() {
        let required = Habit(name: "Read", scheduleType: .daily, mode: .required)
        let optional = Habit(name: "Walk", scheduleType: .daily, mode: .optional)
        let entry = DailyEntry(dateKey: DateUtilities.startOfDay(.now))

        let optionalState = HabitState(isCompleted: true, dailyEntry: entry, habit: optional)
        entry.habitStates = [optionalState]

        let result = StatsEngine.requiredCompletion(requiredHabits: [required], dayEntry: entry)
        XCTAssertEqual(result.completed, 0)
        XCTAssertEqual(result.total, 1)
    }

    func testWeeklyGoalRemainingNeverNegative() {
        XCTAssertEqual(WeeklyGoalEngine.remainingSessions(target: 3, completed: 5), 0)
        XCTAssertTrue(WeeklyGoalEngine.isTargetMet(target: 3, completed: 3))
    }

    func testRequiredStreakStopsAtMiss() {
        let habit = Habit(name: "Read", scheduleType: .daily, mode: .required)

        let day1 = DailyEntry(dateKey: DateUtilities.startOfDay(.now))
        day1.habitStates = [HabitState(isCompleted: true, dailyEntry: day1, habit: habit)]

        let day2Date = Calendar.current.date(byAdding: .day, value: -1, to: DateUtilities.startOfDay(.now)) ?? .now
        let day2 = DailyEntry(dateKey: day2Date)
        day2.habitStates = [HabitState(isCompleted: false, dailyEntry: day2, habit: habit)]

        let streak = StreakEngine.currentRequiredStreak(habit: habit, entries: [day1, day2])
        XCTAssertEqual(streak, 1)
    }
}
