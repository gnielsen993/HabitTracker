import XCTest
@testable import HabitsTracker

final class HabitProgressEngineTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func habit(
        id: UUID = UUID(),
        name: String = "Habit",
        archived: Bool = false,
        created: Date,
        revisions: [HabitProgressEngine.Revision],
        completions: Set<Date>
    ) -> HabitProgressEngine.HabitSnapshot {
        .init(id: id, name: name, areaName: "Personal", isArchived: archived, createdAt: created, revisions: revisions, completionDates: completions)
    }

    private func revision(
        _ effective: Date,
        mode: HabitMode = .required,
        type: HabitScheduleType = .daily,
        days: Set<Weekday> = [],
        target: Int? = nil
    ) -> HabitProgressEngine.Revision {
        .init(effectiveDate: effective, scheduleType: type, scheduledDays: days, mode: mode, weeklyTarget: target)
    }

    func testOpportunityWeightingSumsCountsInsteadOfAveragingPercentages() {
        let start = date(2026, 1, 1)
        let today = date(2026, 1, 12)
        let oneOfOne = habit(
            created: date(2026, 1, 10),
            revisions: [revision(date(2026, 1, 10))],
            completions: [date(2026, 1, 10)]
        )
        let eightOfTen = habit(
            created: start,
            revisions: [revision(start)],
            completions: Set((1...8).map { date(2026, 1, $0) })
        )

        let result = HabitProgressEngine.opportunitySummary(
            habits: [oneOfOne, eightOfTen], from: start, through: date(2026, 1, 10), today: today, calendar: calendar
        )
        XCTAssertEqual(result.completed, 9)
        XCTAssertEqual(result.scheduled, 11)
        XCTAssertEqual(result.percentage, 9.0 / 11.0, accuracy: 0.0001)
    }

    func testEmptyPeriodAndZeroOpportunities() {
        let result = HabitProgressEngine.opportunitySummary(
            habits: [], from: date(2026, 2, 1), through: date(2026, 2, 10), today: date(2026, 2, 11), calendar: calendar
        )
        XCTAssertEqual(result, .init(completed: 0, scheduled: 0))
        XCTAssertEqual(result.percentage, 0)
    }

    func testCurrentDayIsInProgressAndExcludedFromHistoricalFailureRate() {
        let today = date(2026, 3, 10)
        let snapshot = habit(created: date(2026, 3, 9), revisions: [revision(date(2026, 3, 9))], completions: [date(2026, 3, 9)])
        XCTAssertEqual(HabitProgressEngine.status(for: snapshot, on: today, today: today, calendar: calendar), .inProgress)
        let result = HabitProgressEngine.opportunitySummary(habits: [snapshot], from: date(2026, 3, 9), through: today, today: today, calendar: calendar)
        XCTAssertEqual(result, .init(completed: 1, scheduled: 1))
    }

    func testScheduleRevisionBoundaryAndSameDayLatestRevision() {
        let monday = date(2026, 3, 2)
        let thursday = date(2026, 3, 5)
        let snapshot = habit(
            created: monday,
            revisions: [
                revision(monday),
                revision(thursday, type: .customDays, days: [.friday]),
                revision(thursday, type: .customDays, days: [.thursday])
            ],
            completions: []
        )
        XCTAssertEqual(HabitProgressEngine.status(for: snapshot, on: date(2026, 3, 4), today: date(2026, 3, 10), calendar: calendar), .missed)
        XCTAssertEqual(HabitProgressEngine.status(for: snapshot, on: thursday, today: date(2026, 3, 10), calendar: calendar), .missed)
        XCTAssertEqual(HabitProgressEngine.status(for: snapshot, on: date(2026, 3, 6), today: date(2026, 3, 10), calendar: calendar), .notScheduled)
    }

    func testDatesBeforeCreationAreNotScheduled() {
        let created = date(2026, 4, 3)
        let snapshot = habit(created: created, revisions: [revision(created)], completions: [])
        XCTAssertEqual(HabitProgressEngine.status(for: snapshot, on: date(2026, 4, 2), today: date(2026, 4, 10), calendar: calendar), .notScheduled)
    }

    func testTodayAndThisWeekUseDifferentAssessmentLevels() {
        let monday = date(2026, 5, 4)
        let todayHabit = habit(created: monday, revisions: [revision(monday)], completions: [monday])
        let weeklyHabit = habit(created: monday, revisions: [revision(monday, mode: .optional, target: 2)], completions: [monday, date(2026, 5, 6)])
        let summary = HabitProgressEngine.opportunitySummary(habits: [todayHabit, weeklyHabit], from: monday, through: monday, today: date(2026, 5, 11), calendar: calendar)
        XCTAssertEqual(summary, .init(completed: 1, scheduled: 1))
        XCTAssertEqual(HabitProgressEngine.weekProgress(for: weeklyHabit, weekStarting: monday, calendar: calendar), .init(completed: 2, target: 2))
        XCTAssertEqual(HabitProgressEngine.status(for: weeklyHabit, on: date(2026, 5, 5), today: date(2026, 5, 11), calendar: calendar), .notScheduled)
    }

    func testCurrentWeekIsExcludedFromCompletedWeekRate() {
        let priorMonday = date(2026, 5, 4)
        let currentMonday = date(2026, 5, 11)
        let weekly = habit(
            created: priorMonday,
            revisions: [revision(priorMonday, mode: .optional, target: 2)],
            completions: [date(2026, 5, 4), date(2026, 5, 5)]
        )
        let summary = HabitProgressEngine.weeklySummary(
            habits: [weekly], from: priorMonday, through: currentMonday,
            today: currentMonday, calendar: calendar
        )
        XCTAssertEqual(summary.achievedTargets, 1)
        XCTAssertEqual(summary.eligibleTargets, 1)
    }

    func testArchivedHabitsAreHiddenUnlessIncluded() {
        let day = date(2026, 6, 1)
        let archived = habit(archived: true, created: day, revisions: [revision(day)], completions: [day])
        let hidden = HabitProgressEngine.opportunitySummary(habits: [archived], from: day, through: day, today: date(2026, 6, 2), calendar: calendar)
        let shown = HabitProgressEngine.opportunitySummary(habits: [archived], from: day, through: day, today: date(2026, 6, 2), includeArchived: true, calendar: calendar)
        XCTAssertEqual(hidden.scheduled, 0)
        XCTAssertEqual(shown.scheduled, 1)
    }

    func testHardestDayRequiresFourSamplesAndFifteenPointGap() {
        let start = date(2026, 1, 5)
        let revision = revision(start, type: .customDays, days: [.monday, .friday])
        let completions: Set<Date> = [
            date(2026, 1, 5), date(2026, 1, 12), date(2026, 1, 19), date(2026, 1, 26),
            date(2026, 1, 9), date(2026, 1, 16)
        ]
        let snapshot = habit(created: start, revisions: [revision], completions: completions)
        let insight = HabitProgressEngine.hardestWeekdayInsight(
            for: snapshot, from: start, through: date(2026, 1, 30), today: date(2026, 2, 1), calendar: calendar
        )
        XCTAssertEqual(insight?.weekday, .friday)
        XCTAssertEqual(insight?.completed, 2)
        XCTAssertEqual(insight?.eligible, 4)

        let tooLittleData = habit(created: start, revisions: [revision], completions: [date(2026, 1, 5)])
        XCTAssertNil(HabitProgressEngine.hardestWeekdayInsight(
            for: tooLittleData, from: start, through: date(2026, 1, 16), today: date(2026, 2, 1), calendar: calendar
        ))
    }
}
