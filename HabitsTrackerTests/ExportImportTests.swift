import XCTest
import SwiftData
@testable import HabitsTracker

/// Round-trip tests for Export/Import.
///
/// NOTE: the service always stamps the current `schemaVersion` (6), so all four
/// tests exercise a v6 round-trip. Their names reflect *which version's fields*
/// they assert survive that round-trip, not a cross-version backward-import (IN-05).
/// A real older-version fixture import is Phase F (Polish) work.
///
/// testV3FieldsSurviveRoundTrip: fields introduced at schemaVersion 3 (RULE-01,
///   RULE-04, RULE-05) — domains, habits, entries, rules.
/// testV4FieldsSurviveRoundTrip: fields introduced at schemaVersion 4 (COLL-02,
///   COLL-07) — Collection + CollectionItem scalar fields and index wiring (D-05, D-23).
/// testV5FieldsSurviveRoundTrip: fields introduced at schemaVersion 5 (CLIP-02, D-13)
///   — Clip scalar fields, raw status, and domain wiring.
/// testV6IdeaFieldsSurviveRoundTrip: fields introduced at schemaVersion 6 (IDEA-01, D-14)
///   — Idea title/note/url/isArchived, the promotedToKind(raw)/promotedToID forward-link,
///   and domain re-wiring through categoryIndex (WR-01, §9.5).
///
/// All are build-verify only per §9.7 — the XCTest host crashes at 0.000s for SwiftData
/// @Model persistence suites on this simulator; executed on device via the owner
/// full-flow checkpoints (04-05 for Clips, 05-10 for Ideas).
final class ExportImportTests: XCTestCase {

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self, Rule.self,
                             Collection.self, CollectionItem.self, Clip.self, Idea.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    /// Round-trip at schemaVersion 3 fields — verifies domains, habits, entries, rules, and
    /// originRule stem link survive. Updated to pass empty collections/collectionItems to the
    /// v4 exportData signature.
    @MainActor
    func testV3FieldsSurviveRoundTrip() throws {
        let service = ExportImportService()

        let domain = Domain(name: "Learning", iconName: "book", colorToken: "navy", sortIndex: 0, isFocused: true)
        let rule = Rule(title: "Read broadly", body: "Aim for variety", sourceURL: "https://example.com", domain: domain, isArchived: false)
        let habit = Habit(name: "Read 30 min", category: domain, scheduleType: .daily, mode: .required, originRule: rule)
        let entry = DailyEntry(dateKey: DateUtilities.startOfDay(.now), note: "Good day")
        entry.habitStates = [HabitState(isCompleted: true, completedAt: .now, dailyEntry: entry, habit: habit)]

        let data = try service.exportData(
            categories: [domain],
            habits: [habit],
            entries: [entry],
            rules: [rule],
            collections: [],
            collectionItems: [],
            clips: [],
            ideas: []
        )

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

    /// schemaVersion-4 round-trip: Collection + CollectionItem survive with
    /// status/position/cost/wiring intact (D-05, D-23).
    @MainActor
    func testV4FieldsSurviveRoundTrip() throws {
        let service = ExportImportService()

        let domain = Domain(name: "Entertainment", iconName: "play.rectangle", colorToken: "navy", sortIndex: 0, isFocused: true)

        let collection = Collection(
            title: "My Shows",
            statusSetID: "shows",
            progressTemplate: "seasonEpisode",
            showsAggregate: true,
            sortIndex: 0,
            isSeeded: false,
            seedVersion: 0,
            domain: domain
        )

        let item = CollectionItem(
            title: "Severance",
            statusIndex: 2,
            sortIndex: 0,
            note: "Great show",
            sourceURL: "https://tv.apple.com/show/severance",
            cost: 12.99,
            season: 2,
            episode: 4,
            counterValue: 0,
            counterLabel: nil,
            isSeeded: false,
            seedVersion: 0,
            collection: collection
        )
        collection.items = [item]

        let data = try service.exportData(
            categories: [domain],
            habits: [],
            entries: [],
            rules: [],
            collections: [collection],
            collectionItems: [item],
            clips: [],
            ideas: []
        )

        let context = try makeInMemoryContext()
        try service.importReplace(data: data, context: context)

        let collections = try context.fetch(FetchDescriptor<Collection>())
        let items = try context.fetch(FetchDescriptor<CollectionItem>())

        XCTAssertEqual(collections.count, 1, "Collection must survive round-trip")
        XCTAssertEqual(items.count, 1, "CollectionItem must survive round-trip")

        let fetchedItem = try XCTUnwrap(items.first)
        let fetchedCollection = try XCTUnwrap(collections.first)

        // Scalar field preservation (D-05).
        XCTAssertEqual(fetchedItem.statusIndex, 2, "statusIndex must survive")
        XCTAssertEqual(fetchedItem.season, 2, "season must survive")
        XCTAssertEqual(fetchedItem.episode, 4, "episode must survive")
        XCTAssertEqual(try XCTUnwrap(fetchedItem.cost), 12.99, accuracy: 0.001, "cost must survive")
        XCTAssertEqual(fetchedCollection.statusSetID, "shows", "statusSetID must survive")
        XCTAssertEqual(fetchedCollection.progressTemplate, "seasonEpisode", "progressTemplate must survive")
        XCTAssertEqual(fetchedCollection.showsAggregate, true, "showsAggregate must survive")

        // Index wiring survived (D-23): item is linked to the imported collection.
        XCTAssertNotNil(fetchedItem.collection, "CollectionItem.collection must be re-linked after import")
        XCTAssertEqual(fetchedItem.collection?.id, fetchedCollection.id, "collectionID wiring (index) must survive round-trip")
    }

    /// schemaVersion-5 round-trip: Clip survives with title/url/note/tag/status(raw)/
    /// domain wiring intact (CLIP-02, D-13). Build-verify only per §9.7 — authored and
    /// compiled here; executed on device via the 04-05 owner checkpoint.
    @MainActor
    func testV5FieldsSurviveRoundTrip() throws {
        let service = ExportImportService()

        let domain = Domain(name: "Cooking", iconName: "fork.knife", colorToken: "forest", sortIndex: 0, isFocused: true)

        let clip = Clip(
            title: "Sourdough",
            url: "https://example.com/sourdough",
            note: "read later",
            tag: "recipe",
            status: .acted,
            domain: domain
        )

        let data = try service.exportData(
            categories: [domain],
            habits: [],
            entries: [],
            rules: [],
            collections: [],
            collectionItems: [],
            clips: [clip],
            ideas: []
        )

        let context = try makeInMemoryContext()
        try service.importReplace(data: data, context: context)

        let clips = try context.fetch(FetchDescriptor<Clip>())
        let domains = try context.fetch(FetchDescriptor<Domain>())

        XCTAssertEqual(clips.count, 1, "Clip must survive round-trip")

        let fetchedClip = try XCTUnwrap(clips.first)
        let fetchedDomain = try XCTUnwrap(domains.first)

        XCTAssertEqual(fetchedClip.title, "Sourdough", "title must survive")
        XCTAssertEqual(fetchedClip.url, "https://example.com/sourdough", "url must survive")
        XCTAssertEqual(fetchedClip.note, "read later", "note must survive")
        XCTAssertEqual(fetchedClip.tag, "recipe", "tag must survive")
        XCTAssertEqual(fetchedClip.status, .acted, "status must survive as .acted (D-03)")
        XCTAssertEqual(fetchedClip.isArchived, false, "isArchived must survive")

        // Domain wiring survived: fetched clip.domain.id must equal fetched domain.id.
        XCTAssertNotNil(fetchedClip.domain, "Clip.domain must be re-linked after import")
        XCTAssertEqual(fetchedClip.domain?.id, fetchedDomain.id, "domainID wiring must survive round-trip")
    }

    /// schemaVersion-6 round-trip: a filed, promoted Idea survives with title/note/url/
    /// isArchived, the promotedToKind(raw)/promotedToID forward-link, and domain re-wiring
    /// intact (IDEA-01, D-14, WR-01). This exercises the `promotedToKindRaw`↔`promotedToKind`
    /// facade crossover and the domainID→categoryIndex re-link — the exact wiring that
    /// silently breaks. The forward-link is a lean scalar pair with no backref (D-07), so
    /// `promotedToID` is asserted as a bare UUID, not a relationship. Build-verify only per
    /// §9.7 — authored and compiled here; executed on device via the 05-10 owner checkpoint.
    @MainActor
    func testV6IdeaFieldsSurviveRoundTrip() throws {
        let service = ExportImportService()

        let domain = Domain(name: "Writing", iconName: "pencil", colorToken: "walnut", sortIndex: 0, isFocused: true)

        // A promoted idea: consumed (archived) with a scalar forward-link to a Rule.
        let targetID = UUID()
        let idea = Idea(
            title: "Draft a weekly review ritual",
            note: "kicked off from a shower thought",
            url: "https://example.com/ritual",
            isArchived: true,
            promotedToKindRaw: Idea.PromotedKind.rule.rawValue,
            promotedToID: targetID,
            domain: domain
        )

        let data = try service.exportData(
            categories: [domain],
            habits: [],
            entries: [],
            rules: [],
            collections: [],
            collectionItems: [],
            clips: [],
            ideas: [idea]
        )

        let context = try makeInMemoryContext()
        try service.importReplace(data: data, context: context)

        let ideas = try context.fetch(FetchDescriptor<Idea>())
        let domains = try context.fetch(FetchDescriptor<Domain>())

        XCTAssertEqual(ideas.count, 1, "Idea must survive round-trip")

        let fetchedIdea = try XCTUnwrap(ideas.first)
        let fetchedDomain = try XCTUnwrap(domains.first)

        XCTAssertEqual(fetchedIdea.title, "Draft a weekly review ritual", "title must survive")
        XCTAssertEqual(fetchedIdea.note, "kicked off from a shower thought", "note must survive")
        XCTAssertEqual(fetchedIdea.url, "https://example.com/ritual", "url must survive")
        XCTAssertEqual(fetchedIdea.isArchived, true, "isArchived (consumed) must survive")

        // Forward-link facade crossover: raw string round-trips back into the enum facade.
        XCTAssertEqual(fetchedIdea.promotedTo, .rule, "promotedToKind facade must survive as .rule")
        XCTAssertEqual(fetchedIdea.promotedToID, targetID, "promotedToID forward-link must survive")

        // Domain wiring survived: fetched idea.domain.id must equal fetched domain.id.
        XCTAssertNotNil(fetchedIdea.domain, "Idea.domain must be re-linked after import")
        XCTAssertEqual(fetchedIdea.domain?.id, fetchedDomain.id, "domainID wiring (categoryIndex) must survive round-trip")
    }
}
