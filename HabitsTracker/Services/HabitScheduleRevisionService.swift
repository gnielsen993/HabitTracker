import Foundation
import SwiftData

enum HabitScheduleRevisionService {
    static func recordCurrentConfiguration(
        for habit: Habit,
        effectiveDate: Date = .now,
        context: ModelContext
    ) {
        let day = DateUtilities.startOfDay(effectiveDate)
        let revision: HabitScheduleRevision
        if let existing = habit.scheduleRevisions.first(where: { Calendar.current.isDate($0.effectiveDate, inSameDayAs: day) }) {
            revision = existing
        } else {
            revision = HabitScheduleRevision(
                habit: habit,
                effectiveDate: day,
                scheduleType: habit.scheduleType,
                scheduledDays: habit.scheduledDays,
                mode: habit.mode,
                weeklyTargetCount: habit.weeklyTargetCount
            )
            context.insert(revision)
            habit.scheduleRevisions.append(revision)
        }

        revision.scheduleType = habit.scheduleType
        revision.scheduledDays = habit.scheduledDays
        revision.mode = habit.mode
        revision.weeklyTargetCount = habit.mode == .optional ? habit.weeklyTargetCount : nil
    }

    static func synthesizeMissingInitialRevisions(context: ModelContext) throws {
        let habits = try context.fetch(FetchDescriptor<Habit>())
        var inserted = false
        for habit in habits where habit.scheduleRevisions.isEmpty {
            recordCurrentConfiguration(for: habit, effectiveDate: habit.createdAt, context: context)
            inserted = true
        }
        if inserted { try context.save() }
    }
}
