import XCTest
import SwiftData
@testable import HabitsTracker

/// Round-trip tests for Export/Import.
///
/// NOTE: the service always stamps the current `schemaVersion` (6), so every
/// test here exercises a v6 round-trip. The per-version names reflect *which
/// version's fields* they assert survive that round-trip, not a cross-version
/// backward-import (IN-05). Phase 6 (POL-03) added the all-types-in-one-bundle
/// round-trip and the malformed/unsupported-import safety test below.
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

    /// POL-03: a single bundle containing one of EVERY persisted type (Domain, Habit,
    /// DailyEntry, Rule, Collection, CollectionItem, Clip, Idea) survives export ->
    /// importReplace together, with fields AND cross-type relationships intact at
    /// schemaVersion 6 (D-14). The per-version tests above isolate one type's fields
    /// at a time; this proves they all round-trip together in one real backup shape.
    /// StatusSet is asserted via the stored `statusSetID` identifier (code catalog,
    /// not a DTO — D-14). Build-verify only per §9.7; device execution is 06-04.
    @MainActor
    func testAllTypesSurviveRoundTripV6() throws {
        let service = ExportImportService()

        let domain = Domain(name: "Home", iconName: "house", colorToken: "forest", sortIndex: 0, isFocused: true)

        let rule = Rule(
            title: "Keep counters clear",
            body: "Wipe down nightly",
            sourceURL: "https://example.com/kitchen",
            domain: domain,
            isArchived: false
        )

        let habit = Habit(name: "Wipe counters", category: domain, scheduleType: .daily, mode: .required)
        let entry = DailyEntry(dateKey: DateUtilities.startOfDay(.now), note: "All done")
        let habitState = HabitState(isCompleted: true, completedAt: .now, dailyEntry: entry, habit: habit)
        entry.habitStates = [habitState]
        habit.states = [habitState]

        let collection = Collection(
            title: "Watchlist",
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
            statusIndex: 1,
            sortIndex: 0,
            note: "Started season 2",
            sourceURL: "https://tv.apple.com/show/severance",
            cost: nil,
            season: 2,
            episode: 1,
            counterValue: 0,
            counterLabel: nil,
            isSeeded: false,
            seedVersion: 0,
            collection: collection
        )
        collection.items = [item]

        let clip = Clip(
            title: "Sourdough starter guide",
            url: "https://example.com/sourdough",
            note: "read this weekend",
            tag: "recipe",
            status: .saved,
            domain: domain
        )

        // Filed under domain AND promoted (consumed) — exercises both the
        // domain forward-link and the promotedToKind(raw)/promotedToID pair
        // in the same bundle (D-14).
        let ideaTargetID = UUID()
        let idea = Idea(
            title: "Weekly kitchen reset ritual",
            note: "grew out of the counters rule",
            url: "https://example.com/ritual",
            isArchived: true,
            promotedToKindRaw: Idea.PromotedKind.rule.rawValue,
            promotedToID: ideaTargetID,
            domain: domain
        )

        let data = try service.exportData(
            categories: [domain],
            habits: [habit],
            entries: [entry],
            rules: [rule],
            collections: [collection],
            collectionItems: [item],
            clips: [clip],
            ideas: [idea]
        )

        let context = try makeInMemoryContext()
        try service.importReplace(data: data, context: context)

        let domains = try context.fetch(FetchDescriptor<Domain>())
        let habits = try context.fetch(FetchDescriptor<Habit>())
        let entries = try context.fetch(FetchDescriptor<DailyEntry>())
        let rules = try context.fetch(FetchDescriptor<Rule>())
        let collections = try context.fetch(FetchDescriptor<Collection>())
        let items = try context.fetch(FetchDescriptor<CollectionItem>())
        let clips = try context.fetch(FetchDescriptor<Clip>())
        let ideas = try context.fetch(FetchDescriptor<Idea>())

        XCTAssertEqual(domains.count, 1, "Domain must survive round-trip")
        XCTAssertEqual(habits.count, 1, "Habit must survive round-trip")
        XCTAssertEqual(entries.count, 1, "DailyEntry must survive round-trip")
        XCTAssertEqual(rules.count, 1, "Rule must survive round-trip")
        XCTAssertEqual(collections.count, 1, "Collection must survive round-trip")
        XCTAssertEqual(items.count, 1, "CollectionItem must survive round-trip")
        XCTAssertEqual(clips.count, 1, "Clip must survive round-trip")
        XCTAssertEqual(ideas.count, 1, "Idea must survive round-trip")

        let fetchedDomain = try XCTUnwrap(domains.first)
        let fetchedHabit = try XCTUnwrap(habits.first)
        let fetchedEntry = try XCTUnwrap(entries.first)
        let fetchedRule = try XCTUnwrap(rules.first)
        let fetchedCollection = try XCTUnwrap(collections.first)
        let fetchedItem = try XCTUnwrap(items.first)
        let fetchedClip = try XCTUnwrap(clips.first)
        let fetchedIdea = try XCTUnwrap(ideas.first)

        // Rule.domain relationship + fields.
        XCTAssertEqual(fetchedRule.domain?.id, fetchedDomain.id, "Rule.domain must be re-linked after import")
        XCTAssertEqual(fetchedRule.body, "Wipe down nightly", "Rule.body must survive")
        XCTAssertEqual(fetchedRule.sourceURL, "https://example.com/kitchen", "Rule.sourceURL must survive")

        // Habit <-> DailyEntry relationship, via the shared HabitState.
        XCTAssertEqual(fetchedEntry.habitStates.count, 1, "HabitState must survive round-trip")
        XCTAssertEqual(fetchedEntry.habitStates.first?.habit?.id, fetchedHabit.id, "HabitState.habit must be re-linked after import")

        // Collection + CollectionItem: statusSetID (StatusSet-by-id, D-14), note, position fields.
        XCTAssertEqual(fetchedCollection.statusSetID, "shows", "Collection.statusSetID must survive as the stored identifier (StatusSet-by-id, D-14)")
        XCTAssertEqual(fetchedItem.collection?.id, fetchedCollection.id, "CollectionItem.collection must be re-linked after import")
        XCTAssertEqual(fetchedItem.note, "Started season 2", "CollectionItem.note must survive")
        XCTAssertEqual(fetchedItem.sortIndex, 0, "CollectionItem.sortIndex (position) must survive")
        XCTAssertEqual(fetchedItem.statusIndex, 1, "CollectionItem.statusIndex (position within StatusSet) must survive")

        // Clip.domain relationship + status.
        XCTAssertEqual(fetchedClip.domain?.id, fetchedDomain.id, "Clip.domain must be re-linked after import")
        XCTAssertEqual(fetchedClip.status, .saved, "Clip.status must survive")

        // Idea.domain relationship + promoted forward-link.
        XCTAssertEqual(fetchedIdea.domain?.id, fetchedDomain.id, "Idea.domain must be re-linked after import")
        XCTAssertEqual(fetchedIdea.promotedTo, .rule, "Idea.promotedTo facade must survive")
        XCTAssertEqual(fetchedIdea.promotedToID, ideaTargetID, "Idea.promotedToID forward-link must survive")
        XCTAssertEqual(fetchedIdea.isArchived, true, "Idea.isArchived (consumed) must survive")
    }

    /// POL-03 safety net (T-06-03-T): a malformed (non-JSON) import and an import
    /// from a newer, unsupported `schemaVersion` (7 > current 6) must both throw
    /// AND leave the existing store untouched. `importReplace` decodes + guards
    /// `schemaVersion <= currentSchemaVersion` BEFORE `deleteAll` (service lines
    /// 157-165), so a decode/guard failure never reaches the destructive delete —
    /// a bad backup file must never destroy the local store.
    @MainActor
    func testMalformedAndUnsupportedImportPreservesStore() throws {
        let service = ExportImportService()
        let context = try makeInMemoryContext()

        // Seed a non-empty store directly (not via import) so there is a clear
        // baseline to prove untouched after each throwing import attempt.
        let domain = Domain(name: "Health", iconName: "heart", colorToken: "maroon", sortIndex: 0, isFocused: true)
        let habit = Habit(name: "Stretch", category: domain, scheduleType: .daily, mode: .required)
        context.insert(domain)
        context.insert(habit)
        try context.save()

        let baselineDomains = try context.fetch(FetchDescriptor<Domain>()).count
        let baselineHabits = try context.fetch(FetchDescriptor<Habit>()).count
        XCTAssertEqual(baselineDomains, 1)
        XCTAssertEqual(baselineHabits, 1)

        // b1: syntactically invalid JSON must throw at decode, before any delete.
        let garbageData = Data("{ this is not valid json".utf8)
        XCTAssertThrowsError(try service.importReplace(data: garbageData, context: context)) { error in
            XCTAssertTrue(error is DecodingError, "malformed JSON must fail at decode, before any delete")
        }
        XCTAssertEqual(try context.fetch(FetchDescriptor<Domain>()).count, baselineDomains, "malformed import must not touch existing domains")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Habit>()).count, baselineHabits, "malformed import must not touch existing habits")

        // b2: a syntactically valid bundle whose schemaVersion (7) is newer than
        // this build's currentSchemaVersion (6) must also throw at the guard,
        // before any delete.
        let futureEncoder = JSONEncoder()
        futureEncoder.dateEncodingStrategy = .iso8601
        let futureBundle = HabitExportBundle(
            schemaVersion: ExportImportService.currentSchemaVersion + 1,
            exportedAt: .now,
            categories: [],
            habits: [],
            dailyEntries: [],
            rules: [],
            collections: [],
            collectionItems: [],
            clips: [],
            ideas: []
        )
        let futureData = try futureEncoder.encode(futureBundle)

        XCTAssertThrowsError(try service.importReplace(data: futureData, context: context)) { error in
            guard case ImportError.unsupportedSchema(let version) = error else {
                XCTFail("expected ImportError.unsupportedSchema, got \(error)")
                return
            }
            XCTAssertEqual(version, ExportImportService.currentSchemaVersion + 1)
        }
        XCTAssertEqual(try context.fetch(FetchDescriptor<Domain>()).count, baselineDomains, "unsupported-schema import must not touch existing domains")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Habit>()).count, baselineHabits, "unsupported-schema import must not touch existing habits")
    }
}
