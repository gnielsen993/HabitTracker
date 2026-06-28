import XCTest
import SwiftData
@testable import HabitsTracker

/// Wave-0 RED tests for the `Category` → `Domain` rename (DOM-01) and the additive
/// `isFocused` field (DOM-02). These reference the not-yet-existing `Domain` type and
/// `isFocused` field, so they are EXPECTED to fail to compile until plan 01-02 lands the
/// rename + the additive defaulted field. Do NOT stub `Domain` to make these green.
final class DomainMigrationTests: XCTestCase {

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    /// DOM-02: a Domain constructed via the designated initializer WITHOUT passing
    /// `isFocused` must default to `false` (additive, defaulted field). This default is
    /// what inferred lightweight migration writes onto existing rows on upgrade.
    @MainActor
    func testIsFocusedDefaultsFalse() throws {
        let context = try makeInMemoryContext()

        // Construct without passing isFocused — relies on the default in the initializer.
        let domain = Domain(name: "Learning", iconName: "book", colorToken: "navy", sortIndex: 0)
        context.insert(domain)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Domain>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.isFocused, false)
    }

    /// DOM-01 compile-level shape lock: Domain must carry every prior Category field
    /// (name, iconName, colorToken, sortIndex, isSeeded, seedVersion), the new `isFocused`
    /// flag, and the `habits` inverse relationship. Reading each property keeps the shape
    /// asserted at compile time so a future field drop is caught here.
    @MainActor
    func testDomainCarriesAllPriorFields() throws {
        let domain = Domain(
            name: "Fitness",
            iconName: "figure.run",
            colorToken: "forest",
            sortIndex: 4,
            isSeeded: true,
            seedVersion: 2,
            isFocused: true
        )

        XCTAssertEqual(domain.name, "Fitness")
        XCTAssertEqual(domain.iconName, "figure.run")
        XCTAssertEqual(domain.colorToken, "forest")
        XCTAssertEqual(domain.sortIndex, 4)
        XCTAssertTrue(domain.isSeeded)
        XCTAssertEqual(domain.seedVersion, 2)
        XCTAssertTrue(domain.isFocused)

        // Compile-level shape lock: `habits` must exist as an array on Domain.
        let habits: [Habit] = domain.habits
        XCTAssertTrue(habits.isEmpty)
    }
}
