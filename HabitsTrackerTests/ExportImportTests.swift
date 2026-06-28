import XCTest
import SwiftData
@testable import HabitsTracker

/// Round-trip test for Export/Import at schemaVersion 2 (DOM-01/02). Targets the post-rename
/// `Domain` shape and asserts `isFocused` survives the export → import round-trip.
///
/// RED by design until plan 01-02 renames `Category` → `Domain`, adds `isFocused`, bumps
/// `ExportImportService.schemaVersion` 1 → 2, and updates the DTO/import to carry `isFocused`.
/// Do NOT weaken the schema-version guard or stub production types to make this green.
final class ExportImportTests: XCTestCase {
    @MainActor
    func testExportImportRoundTrip() throws {
        let service = ExportImportService()

        let domain = Domain(name: "Learning", iconName: "book", colorToken: "navy", sortIndex: 0, isFocused: true)
        let habit = Habit(name: "Read", category: domain, scheduleType: .daily, mode: .required)
        let entry = DailyEntry(dateKey: DateUtilities.startOfDay(.now), note: "Good day")
        entry.habitStates = [HabitState(isCompleted: true, completedAt: .now, dailyEntry: entry, habit: habit)]

        let data = try service.exportData(categories: [domain], habits: [habit], entries: [entry])

        let schema = Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        try service.importReplace(data: data, context: context)

        let domains = try context.fetch(FetchDescriptor<Domain>())
        let habits = try context.fetch(FetchDescriptor<Habit>())
        let entries = try context.fetch(FetchDescriptor<DailyEntry>())

        XCTAssertEqual(domains.count, 1)
        XCTAssertEqual(habits.count, 1)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.habitStates.count, 1)

        // isFocused must survive the schemaVersion-2 round-trip.
        XCTAssertEqual(domains.first?.isFocused, true)
    }
}
