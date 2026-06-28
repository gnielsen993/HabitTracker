import XCTest
import SwiftData
@testable import HabitsTracker

/// Wave-0 RED test for custom-domain creation persistence (DOM-05). Asserts a user-created
/// Domain — name + a curated SF Symbol + a colorToken drawn from the closed 5-token accent
/// set — round-trips through SwiftData and that `colorToken` is valid-by-construction (one
/// of the DesignKit accent tokens, never an off-brand raw color).
///
/// References the not-yet-existing `Domain` type, so it is EXPECTED RED until plan 01-02
/// lands the rename. Do NOT stub `Domain` to make this green.
final class DomainCreateTests: XCTestCase {

    /// The closed accent-token set custom domains may pick from (DesignKit Balanced Luxury).
    private let accentTokens = ["forest", "navy", "maroon", "walnut", "stone"]

    @MainActor
    func testCustomDomainPersistsWithValidToken() throws {
        let schema = Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // A user-created domain: name + curated SF Symbol + token from the closed set.
        let chosenToken = "maroon"
        XCTAssertTrue(accentTokens.contains(chosenToken), "Test must pick from the curated token set")

        let custom = Domain(
            name: "Travel",
            iconName: "airplane",
            colorToken: chosenToken,
            sortIndex: 12
        )
        context.insert(custom)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Domain>())
        XCTAssertEqual(fetched.count, 1)

        let domain = try XCTUnwrap(fetched.first)
        XCTAssertEqual(domain.name, "Travel")
        XCTAssertEqual(domain.iconName, "airplane")
        XCTAssertEqual(domain.colorToken, chosenToken)
        XCTAssertTrue(
            ["forest", "navy", "maroon", "walnut", "stone"].contains(domain.colorToken),
            "Custom domain colorToken must be one of the 5 DesignKit accent tokens"
        )
    }
}
