import XCTest
@testable import HabitsTracker

/// Unit tests for `PromoteService` — the consume/archive/forward-link core (§9.5, IDEA-04).
/// `Idea`/`Domain` instances are constructed in-memory and passed directly to the
/// pure/save-free static functions; no SwiftData `ModelContainer` is required, so this
/// suite inherits the runnable engine tier that actually executes on the iOS 26
/// simulator (§9.7), like `EngineTests`/`CollectionRollupEngineTests`.
final class PromoteServiceTests: XCTestCase {

    // MARK: - Happy path: archive + forward-link set

    /// Promoting an unarchived idea to a Rule sets isArchived/promotedTo/promotedToID (D-07).
    func testHappyPath_archivesAndForwardLinks() {
        let idea = Idea(title: "Read more sci-fi")
        let ruleID = UUID()

        PromoteService.archiveAndForwardLink(idea: idea, as: .rule, targetID: ruleID)

        XCTAssertTrue(idea.isArchived)
        XCTAssertEqual(idea.promotedTo, .rule)
        XCTAssertEqual(idea.promotedToID, ruleID)
    }

    // MARK: - Already-archived idea is a safe no-op skip

    /// A second promote attempt on an already-archived idea must not double-archive
    /// or overwrite the existing forward-link (T-05-04).
    func testAlreadyArchived_isSkipped() {
        let originalTargetID = UUID()
        let idea = Idea(
            title: "Learn pottery",
            isArchived: true,
            promotedToKindRaw: Idea.PromotedKind.habit.rawValue,
            promotedToID: originalTargetID
        )

        let newTargetID = UUID()
        PromoteService.archiveAndForwardLink(idea: idea, as: .collectionItem, targetID: newTargetID)

        XCTAssertTrue(idea.isArchived)
        XCTAssertEqual(idea.promotedTo, .habit, "forward-link kind must not change on an already-archived skip")
        XCTAssertEqual(idea.promotedToID, originalTargetID, "forward-link id must not change on an already-archived skip")
    }

    // MARK: - Unfiled idea requires a domain before promote (IDEA-05)

    func testUnfiledRequiresDomain() {
        let unfiledIdea = Idea(title: "Try a new recipe")
        XCTAssertTrue(PromoteService.requiresDomainBeforePromote(idea: unfiledIdea))

        let domain = Domain(name: "Food", iconName: "fork.knife", colorToken: "forest", sortIndex: 0)
        let filedIdea = Idea(title: "Try a new recipe", domain: domain)
        XCTAssertFalse(PromoteService.requiresDomainBeforePromote(idea: filedIdea))
    }

    // MARK: - Promote-to-collection needs a list (domain resolved via the chosen collection)

    /// Promoting to a Collection has no separate "needs a list" predicate on the
    /// service — picking the target collection resolves the domain requirement
    /// (the collection's own domain fills the idea's domain gap). Before a
    /// collection/domain is chosen the shared requiresDomainBeforePromote gate still
    /// blocks; once the idea is filed (as picking a collection implies), the gate
    /// clears and the promote/archive call succeeds.
    func testCollectionPromoteNeedsList() {
        let unfiledIdea = Idea(title: "Watch this show")
        XCTAssertTrue(
            PromoteService.requiresDomainBeforePromote(idea: unfiledIdea),
            "promote-to-collection is blocked until a target collection (and thus a domain) is chosen"
        )

        let showsDomain = Domain(name: "Media", iconName: "tv", colorToken: "navy", sortIndex: 0)
        unfiledIdea.domain = showsDomain
        XCTAssertFalse(
            PromoteService.requiresDomainBeforePromote(idea: unfiledIdea),
            "once filed via the chosen collection's domain, the gate clears"
        )

        let itemID = UUID()
        PromoteService.archiveAndForwardLink(idea: unfiledIdea, as: .collectionItem, targetID: itemID)
        XCTAssertTrue(unfiledIdea.isArchived)
        XCTAssertEqual(unfiledIdea.promotedTo, .collectionItem)
        XCTAssertEqual(unfiledIdea.promotedToID, itemID)
    }
}
