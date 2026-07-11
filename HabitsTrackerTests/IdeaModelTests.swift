import XCTest
import SwiftData
@testable import HabitsTracker

/// Tests for the `Idea` @Model, the nested `Idea.PromotedKind` facade, and the
/// Domain<->Idea `.nullify` inverse (IDEA-01).
///
/// These are SwiftData `@Model` persistence tests: per CLAUDE.md §9.7 they crash
/// the XCTest host at 0.000s on the iOS 26 simulator. They are BUILD-VERIFY ONLY
/// here (compiled by `build-for-testing`); execution happens on a physical device
/// or a different runtime, and migration safety is proven separately by the
/// mandatory upgrade test in plan 05-04.
final class IdeaModelTests: XCTestCase {

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        // Include every model Domain relates to so the in-memory schema is complete
        // (Domain has rules/collections/clips/ideas relationships) — IN-04.
        let schema = Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self,
                             Rule.self, Collection.self, CollectionItem.self, Clip.self, Idea.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    /// A freshly constructed `Idea(title:)` has every optional/defaulted field at its default.
    @MainActor
    func testDefaultValues() throws {
        let context = try makeInMemoryContext()

        let idea = Idea(title: "Read that article")
        context.insert(idea)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Idea>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.isArchived, false)
        XCTAssertNil(fetched.first?.note)
        XCTAssertNil(fetched.first?.url)
        XCTAssertNil(fetched.first?.domain)
        XCTAssertNil(fetched.first?.promotedToKindRaw)
    }

    /// The `promotedTo` facade round-trips through `promotedToKindRaw` (Idea.PromotedKind).
    @MainActor
    func testPromotedToFacadeRoundTrips() throws {
        let context = try makeInMemoryContext()

        let idea = Idea(title: "Read that article")
        context.insert(idea)
        try context.save()

        idea.promotedTo = .rule
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Idea>())
        XCTAssertEqual(fetched.first?.promotedToKindRaw, "rule")
        XCTAssertEqual(fetched.first?.promotedTo, Idea.PromotedKind.rule)
    }

    /// Domain.ideas inverse — assigning idea.domain wires domain.ideas.
    @MainActor
    func testDomainIdeasInverse() throws {
        let context = try makeInMemoryContext()

        let domain = Domain(name: "Health", iconName: "heart", colorToken: "maroon", sortIndex: 0)
        let idea = Idea(title: "Read that article", domain: domain)
        context.insert(domain)
        context.insert(idea)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Domain>())
        XCTAssertEqual(fetched.first?.ideas.count, 1)
        XCTAssertTrue(fetched.first?.ideas.contains(where: { $0.id == idea.id }) ?? false)
    }

    /// Deleting a Domain nullifies its ideas — never cascades (D-11).
    @MainActor
    func testDeleteDomainNullifiesIdeas() throws {
        let context = try makeInMemoryContext()

        let domain = Domain(name: "Health", iconName: "heart", colorToken: "maroon", sortIndex: 0)
        let idea = Idea(title: "Read that article", domain: domain)
        context.insert(domain)
        context.insert(idea)
        try context.save()

        context.delete(domain)
        try context.save()

        let ideas = try context.fetch(FetchDescriptor<Idea>())
        XCTAssertEqual(ideas.count, 1, "Idea must survive domain deletion (no cascade)")
        XCTAssertNil(ideas.first?.domain, "domain must be nullified")

        let domains = try context.fetch(FetchDescriptor<Domain>())
        XCTAssertEqual(domains.count, 0)
    }
}
