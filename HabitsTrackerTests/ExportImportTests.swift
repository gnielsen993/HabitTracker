import XCTest
import SwiftData
@testable import HabitsTracker

/// Round-trip tests for Export/Import.
///
/// testExportImportRoundTripV2: legacy schemaVersion-2 test (DOM-01/02).
/// testExportImportRoundTripV3: schemaVersion-3 test (RULE-01, RULE-04, RULE-05) — RED by design
///   until plan 02-01 bumps schemaVersion to 3, adds RuleDTO, adds originRuleID to HabitDTO,
///   and updates SettingsView call site. Do NOT weaken the schema-version guard or stub types.
final class ExportImportTests: XCTestCase {

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self, Rule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    /// Legacy round-trip at schemaVersion 2 (kept as regression guard until schema bumped).
    /// NOTE: This test will fail when schemaVersion is bumped to 3 — at that point it should be
    /// updated to use the v3 export path (rules: []).
    @MainActor
    func testExportImportRoundTripV3() throws {
        let service = ExportImportService()

        let domain = Domain(name: "Learning", iconName: "book", colorToken: "navy", sortIndex: 0, isFocused: true)
        let rule = Rule(title: "Read broadly", body: "Aim for variety", sourceURL: "https://example.com", domain: domain, isArchived: false)
        let habit = Habit(name: "Read 30 min", category: domain, scheduleType: .daily, mode: .required, originRule: rule)
        let entry = DailyEntry(dateKey: DateUtilities.startOfDay(.now), note: "Good day")
        entry.habitStates = [HabitState(isCompleted: true, completedAt: .now, dailyEntry: entry, habit: habit)]

        let data = try service.exportData(categories: [domain], habits: [habit], entries: [entry], rules: [rule])

        let context = try makeInMemoryContext()
        try service.importReplace(data: data, context: context)

        let domains = try context.fetch(FetchDescriptor<Domain>())
        let habits = try context.fetch(FetchDescriptor<Habit>())
        let entries = try context.fetch(FetchDescriptor<DailyEntry>())
        let rules = try context.fetch(FetchDescriptor<Rule>())

        XCTAssertEqual(domains.count, 1, "Domain must survive round-trip")
        XCTAssertEqual(habits.count, 1, "Habit must survive round-trip")
        XCTAssertEqual(entries.count, 1, "Entry must survive round-trip")
        XCTAssertEqual(entries.first?.habitStates.count, 1, "HabitState must survive round-trip")
        XCTAssertEqual(rules.count, 1, "Rule must survive round-trip")

        // isFocused must survive.
        XCTAssertEqual(domains.first?.isFocused, true)

        // isArchived must survive.
        XCTAssertEqual(rules.first?.isArchived, false)

        // Stem link must survive: fetched habit.originRule.id must equal fetched rule.id.
        let fetchedHabit = habits.first
        let fetchedRule = rules.first
        XCTAssertNotNil(fetchedHabit?.originRule, "originRule must be re-linked after import")
        XCTAssertEqual(fetchedHabit?.originRule?.id, fetchedRule?.id, "stem link (originRule.id) must survive round-trip")
    }
}
