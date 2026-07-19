import Foundation
import SwiftData

enum HabitCompletionError: LocalizedError {
    case futureDate

    var errorDescription: String? {
        switch self {
        case .futureDate: "Future days are read-only."
        }
    }
}

final class HabitCompletionService {
    @discardableResult
    func setCompletion(
        _ isCompleted: Bool,
        for habit: Habit,
        on date: Date,
        context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws -> HabitState {
        let day = DateUtilities.startOfDay(date, calendar: calendar)
        guard day <= DateUtilities.startOfDay(now, calendar: calendar) else {
            throw HabitCompletionError.futureDate
        }

        let entry = try entry(on: day, context: context)
        let state: HabitState
        if let existing = entry.habitStates.first(where: { $0.habit?.id == habit.id }) {
            state = existing
        } else {
            state = HabitState(isCompleted: false, dailyEntry: entry, habit: habit)
            context.insert(state)
            entry.habitStates.append(state)
            habit.states.append(state)
        }

        state.isCompleted = isCompleted
        state.completedAt = isCompleted ? (calendar.isDateInToday(day) ? now : day) : nil
        try context.save()
        return state
    }

    @discardableResult
    func toggle(
        _ habit: Habit,
        on date: Date,
        context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws -> HabitState {
        let day = DateUtilities.startOfDay(date, calendar: calendar)
        let existing = habit.states.first { state in
            guard let stateDate = state.dailyEntry?.dateKey else { return false }
            return calendar.isDate(stateDate, inSameDayAs: day)
        }
        return try setCompletion(!(existing?.isCompleted ?? false), for: habit, on: day, context: context, now: now, calendar: calendar)
    }

    @discardableResult
    func updateNote(
        _ note: String,
        on date: Date,
        context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws -> DailyEntry {
        let day = DateUtilities.startOfDay(date, calendar: calendar)
        guard day <= DateUtilities.startOfDay(now, calendar: calendar) else {
            throw HabitCompletionError.futureDate
        }
        let entry = try entry(on: day, context: context)
        entry.note = note
        try context.save()
        return entry
    }

    private func entry(on day: Date, context: ModelContext) throws -> DailyEntry {
        var descriptor = FetchDescriptor<DailyEntry>(predicate: #Predicate { $0.dateKey == day })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first { return existing }
        let entry = DailyEntry(dateKey: day)
        context.insert(entry)
        return entry
    }
}
