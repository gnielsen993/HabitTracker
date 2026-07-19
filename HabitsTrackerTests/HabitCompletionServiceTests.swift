import XCTest
import SwiftData
@testable import HabitsTracker

final class HabitCompletionServiceTests: XCTestCase {
    @MainActor
    private func context() throws -> ModelContext {
        let schema = Schema([Domain.self, Habit.self, HabitScheduleRevision.self, DailyEntry.self, HabitState.self, Rule.self])
        return try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]).mainContext
    }

    @MainActor
    func testHistoricalCompletionCanBeCreatedAndCorrected() throws {
        let context = try context()
        let habit = Habit(name: "Read", scheduleType: .daily, mode: .required)
        context.insert(habit)
        let service = HabitCompletionService()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!

        let completed = try service.setCompletion(true, for: habit, on: yesterday, context: context)
        XCTAssertTrue(completed.isCompleted)
        XCTAssertNotNil(completed.completedAt)

        let corrected = try service.toggle(habit, on: yesterday, context: context)
        XCTAssertFalse(corrected.isCompleted)
        XCTAssertNil(corrected.completedAt)
        XCTAssertEqual(try context.fetch(FetchDescriptor<HabitState>()).count, 1)
    }

    @MainActor
    func testFutureCompletionIsRejectedWithoutCreatingState() throws {
        let context = try context()
        let habit = Habit(name: "Read", scheduleType: .daily, mode: .required)
        context.insert(habit)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!
        XCTAssertThrowsError(try HabitCompletionService().setCompletion(true, for: habit, on: tomorrow, context: context))
        XCTAssertTrue(try context.fetch(FetchDescriptor<HabitState>()).isEmpty)
    }

    @MainActor
    func testSameDayScheduleEditUpdatesOneRevision() throws {
        let context = try context()
        let habit = Habit(name: "Read", scheduleType: .daily, mode: .required)
        context.insert(habit)
        HabitScheduleRevisionService.recordCurrentConfiguration(for: habit, context: context)
        habit.scheduleType = .customDays
        habit.scheduledDays = [.monday]
        HabitScheduleRevisionService.recordCurrentConfiguration(for: habit, context: context)
        try context.save()

        XCTAssertEqual(habit.scheduleRevisions.count, 1)
        XCTAssertEqual(habit.scheduleRevisions.first?.scheduleType, .customDays)
        XCTAssertEqual(habit.scheduleRevisions.first?.scheduledDays, [.monday])
    }
}
