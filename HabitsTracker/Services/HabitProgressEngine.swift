import Foundation

enum HabitProgressEngine {
    enum Range: Int, CaseIterable, Identifiable {
        case fourWeeks = 28
        case twelveWeeks = 84
        case oneYear = 365

        var id: Int { rawValue }
        var title: String {
            switch self {
            case .fourWeeks: "4 weeks"
            case .twelveWeeks: "12 weeks"
            case .oneYear: "1 year"
            }
        }
    }

    enum DayStatus: Equatable {
        case completed
        case missed
        case notScheduled
        case inProgress
    }

    struct Revision: Equatable {
        let effectiveDate: Date
        let scheduleType: HabitScheduleType
        let scheduledDays: Set<Weekday>
        let mode: HabitMode
        let weeklyTarget: Int?
    }

    struct HabitSnapshot: Identifiable {
        let id: UUID
        let name: String
        let areaName: String?
        let isArchived: Bool
        let createdAt: Date
        let revisions: [Revision]
        let completionDates: Set<Date>
    }

    struct OpportunitySummary: Equatable {
        let completed: Int
        let scheduled: Int
        var percentage: Double { scheduled == 0 ? 0 : Double(completed) / Double(scheduled) }
    }

    struct WeeklySummary: Equatable {
        let achievedTargets: Int
        let eligibleTargets: Int
        var percentage: Double { eligibleTargets == 0 ? 0 : Double(achievedTargets) / Double(eligibleTargets) }
    }

    struct WeekProgress: Equatable {
        let completed: Int
        let target: Int
        var achieved: Bool { completed >= target }
    }

    struct DayWorkload: Identifiable, Equatable {
        let date: Date
        let completed: Int
        let scheduled: Int
        var id: Date { date }
    }

    struct WeekdayInsight: Equatable {
        let weekday: Weekday
        let completed: Int
        let eligible: Int

        var text: String {
            "\(weekdayName) have been harder: \(completed) of \(eligible) completed."
        }

        private var weekdayName: String {
            switch weekday {
            case .monday: "Mondays"
            case .tuesday: "Tuesdays"
            case .wednesday: "Wednesdays"
            case .thursday: "Thursdays"
            case .friday: "Fridays"
            case .saturday: "Saturdays"
            case .sunday: "Sundays"
            }
        }
    }

    static func snapshot(from habit: Habit, calendar: Calendar = .current) -> HabitSnapshot {
        let revisions = habit.scheduleRevisions.map {
            Revision(
                effectiveDate: calendar.startOfDay(for: $0.effectiveDate),
                scheduleType: $0.scheduleType,
                scheduledDays: Set($0.scheduledDays),
                mode: $0.mode,
                weeklyTarget: $0.weeklyTargetCount
            )
        }
        let fallback = Revision(
            effectiveDate: calendar.startOfDay(for: habit.createdAt),
            scheduleType: habit.scheduleType,
            scheduledDays: Set(habit.scheduledDays),
            mode: habit.mode,
            weeklyTarget: habit.weeklyTargetCount
        )
        let completions = Set(habit.states.compactMap { state -> Date? in
            guard state.isCompleted, let date = state.dailyEntry?.dateKey else { return nil }
            return calendar.startOfDay(for: date)
        })
        return HabitSnapshot(
            id: habit.id,
            name: habit.name,
            areaName: habit.category?.name,
            isArchived: habit.isArchived,
            createdAt: calendar.startOfDay(for: habit.createdAt),
            revisions: revisions.isEmpty ? [fallback] : revisions,
            completionDates: completions
        )
    }

    static func revision(for habit: HabitSnapshot, on date: Date, calendar: Calendar = .current) -> Revision? {
        let day = calendar.startOfDay(for: date)
        guard day >= calendar.startOfDay(for: habit.createdAt) else { return nil }
        return habit.revisions.enumerated()
            .filter { calendar.startOfDay(for: $0.element.effectiveDate) <= day }
            .max {
                if $0.element.effectiveDate == $1.element.effectiveDate { return $0.offset < $1.offset }
                return $0.element.effectiveDate < $1.element.effectiveDate
            }?.element
    }

    static func status(
        for habit: HabitSnapshot,
        on date: Date,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> DayStatus {
        let day = calendar.startOfDay(for: date)
        let currentDay = calendar.startOfDay(for: today)
        guard day <= currentDay, let revision = revision(for: habit, on: day, calendar: calendar) else {
            return .notScheduled
        }
        if habit.completionDates.contains(day) { return .completed }
        if revision.mode == .optional { return day == currentDay ? .inProgress : .notScheduled }
        guard isScheduled(revision, on: day, calendar: calendar) else { return .notScheduled }
        return day == currentDay ? .inProgress : .missed
    }

    static func opportunitySummary(
        habits: [HabitSnapshot],
        from startDate: Date,
        through endDate: Date,
        today: Date = .now,
        includeArchived: Bool = false,
        calendar: Calendar = .current
    ) -> OpportunitySummary {
        let historicalEnd = min(calendar.startOfDay(for: endDate), calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: today)) ?? endDate)
        guard calendar.startOfDay(for: startDate) <= historicalEnd else { return OpportunitySummary(completed: 0, scheduled: 0) }
        var completed = 0
        var scheduled = 0
        for habit in habits where includeArchived || !habit.isArchived {
            for day in dates(from: startDate, through: historicalEnd, calendar: calendar) {
                guard let revision = revision(for: habit, on: day, calendar: calendar),
                      revision.mode == .required,
                      isScheduled(revision, on: day, calendar: calendar) else { continue }
                scheduled += 1
                if habit.completionDates.contains(calendar.startOfDay(for: day)) { completed += 1 }
            }
        }
        return OpportunitySummary(completed: completed, scheduled: scheduled)
    }

    static func dailyWorkload(
        habits: [HabitSnapshot],
        from startDate: Date,
        through endDate: Date,
        today: Date = .now,
        includeArchived: Bool = false,
        calendar: Calendar = .current
    ) -> [DayWorkload] {
        dates(from: startDate, through: min(endDate, today), calendar: calendar).map { day in
            var completed = 0
            var scheduled = 0
            for habit in habits where includeArchived || !habit.isArchived {
                guard let revision = revision(for: habit, on: day, calendar: calendar),
                      revision.mode == .required,
                      isScheduled(revision, on: day, calendar: calendar) else { continue }
                scheduled += 1
                if habit.completionDates.contains(calendar.startOfDay(for: day)) { completed += 1 }
            }
            return DayWorkload(date: calendar.startOfDay(for: day), completed: completed, scheduled: scheduled)
        }
    }

    static func weeklySummary(
        habits: [HabitSnapshot],
        from startDate: Date,
        through endDate: Date,
        today: Date = .now,
        includeArchived: Bool = false,
        calendar: Calendar = .current
    ) -> WeeklySummary {
        let currentWeek = DateUtilities.startOfWeek(for: today, calendar: calendar)
        var achieved = 0
        var eligible = 0
        var week = DateUtilities.startOfWeek(for: startDate, calendar: calendar)
        let end = calendar.startOfDay(for: endDate)
        while week < currentWeek && week <= end {
            for habit in habits where includeArchived || !habit.isArchived {
                guard let progress = weekProgress(for: habit, weekStarting: week, calendar: calendar) else { continue }
                eligible += 1
                if progress.achieved { achieved += 1 }
            }
            week = calendar.date(byAdding: .day, value: 7, to: week) ?? end.addingTimeInterval(1)
        }
        return WeeklySummary(achievedTargets: achieved, eligibleTargets: eligible)
    }

    static func weekProgress(
        for habit: HabitSnapshot,
        weekStarting: Date,
        calendar: Calendar = .current
    ) -> WeekProgress? {
        let week = DateUtilities.startOfWeek(for: weekStarting, calendar: calendar)
        let days = dates(from: week, through: calendar.date(byAdding: .day, value: 6, to: week) ?? week, calendar: calendar)
        let optionalRevisions = days.compactMap { revision(for: habit, on: $0, calendar: calendar) }.filter { $0.mode == .optional }
        guard let activeRevision = optionalRevisions.last else { return nil }
        let completed = days.filter { habit.completionDates.contains(calendar.startOfDay(for: $0)) }.count
        return WeekProgress(completed: completed, target: max(1, activeRevision.weeklyTarget ?? 1))
    }

    static func currentStreak(
        for habit: HabitSnapshot,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        var streak = 0
        var day = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: today)) ?? today
        while day >= habit.createdAt {
            guard let revision = revision(for: habit, on: day, calendar: calendar) else { break }
            if revision.mode != .required || !isScheduled(revision, on: day, calendar: calendar) {
                day = calendar.date(byAdding: .day, value: -1, to: day) ?? habit.createdAt.addingTimeInterval(-1)
                continue
            }
            guard habit.completionDates.contains(calendar.startOfDay(for: day)) else { break }
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? habit.createdAt.addingTimeInterval(-1)
        }
        return streak
    }

    static func bestStreak(for habit: HabitSnapshot, through endDate: Date, calendar: Calendar = .current) -> Int {
        var best = 0
        var current = 0
        for day in dates(from: habit.createdAt, through: endDate, calendar: calendar) {
            guard let revision = revision(for: habit, on: day, calendar: calendar), revision.mode == .required,
                  isScheduled(revision, on: day, calendar: calendar) else { continue }
            if habit.completionDates.contains(calendar.startOfDay(for: day)) {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    static func hardestWeekdayInsight(
        for habit: HabitSnapshot,
        from startDate: Date,
        through endDate: Date,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> WeekdayInsight? {
        var counts: [Weekday: (completed: Int, eligible: Int)] = [:]
        let historicalEnd = min(endDate, calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: today)) ?? endDate)
        for day in dates(from: startDate, through: historicalEnd, calendar: calendar) {
            guard let revision = revision(for: habit, on: day, calendar: calendar), revision.mode == .required,
                  isScheduled(revision, on: day, calendar: calendar) else { continue }
            let weekday = DateUtilities.isoWeekday(for: day, calendar: calendar)
            var count = counts[weekday] ?? (0, 0)
            count.eligible += 1
            if habit.completionDates.contains(calendar.startOfDay(for: day)) { count.completed += 1 }
            counts[weekday] = count
        }
        let compared = counts.filter { $0.value.eligible >= 4 }
        guard compared.count >= 2,
              let weakest = compared.min(by: { rate($0.value) < rate($1.value) }),
              let strongest = compared.max(by: { rate($0.value) < rate($1.value) }),
              rate(strongest.value) - rate(weakest.value) >= 0.15 else { return nil }
        return WeekdayInsight(weekday: weakest.key, completed: weakest.value.completed, eligible: weakest.value.eligible)
    }

    private static func rate(_ count: (completed: Int, eligible: Int)) -> Double {
        count.eligible == 0 ? 0 : Double(count.completed) / Double(count.eligible)
    }

    private static func isScheduled(_ revision: Revision, on date: Date, calendar: Calendar) -> Bool {
        revision.scheduleType == .daily || revision.scheduledDays.contains(DateUtilities.isoWeekday(for: date, calendar: calendar))
    }

    private static func dates(from startDate: Date, through endDate: Date, calendar: Calendar) -> [Date] {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        guard start <= end else { return [] }
        var result: [Date] = []
        var day = start
        while day <= end {
            result.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }
}
