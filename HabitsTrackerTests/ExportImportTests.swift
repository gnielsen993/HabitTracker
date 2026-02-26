import XCTest
import SwiftData
@testable import HabitsTracker

final class ExportImportTests: XCTestCase {
    @MainActor
    func testExportImportRoundTrip() throws {
        let service = ExportImportService()

        let category = Category(name: "Learning", iconName: "book", colorToken: "navy", sortIndex: 0)
        let habit = Habit(name: "Read", category: category, scheduleType: .daily, mode: .required)
        let entry = DailyEntry(dateKey: DateUtilities.startOfDay(.now), note: "Good day")
        entry.habitStates = [HabitState(isCompleted: true, completedAt: .now, dailyEntry: entry, habit: habit)]

        let data = try service.exportData(categories: [category], habits: [habit], entries: [entry])

        let schema = Schema([Category.self, Habit.self, DailyEntry.self, HabitState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        try service.importReplace(data: data, context: context)

        let categories = try context.fetch(FetchDescriptor<HabitsTracker.Category>())
        let habits = try context.fetch(FetchDescriptor<Habit>())
        let entries = try context.fetch(FetchDescriptor<DailyEntry>())

        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(habits.count, 1)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.habitStates.count, 1)
    }
}
