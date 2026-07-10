import XCTest
import SwiftData
@testable import HabitsTracker

/// Tests for the `Clip` @Model, `ClipStatus` facade, and the Domain<->Clip
/// `.nullify` inverse (CLIP-02, CLIP-03, CLIP-04).
///
/// These are SwiftData `@Model` persistence tests: per CLAUDE.md §9.7 they crash
/// the XCTest host at 0.000s on the iOS 26 simulator. They are BUILD-VERIFY ONLY
/// here (compiled by `build-for-testing`); execution happens on a physical device
/// or a different runtime, and is exercised via the Task 3 upgrade gate + the
/// 04-05 visual checkpoint.
final class ClipModelTests: XCTestCase {

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        // Include every model Domain relates to so the in-memory schema is complete
        // (Domain has rules/collections/clips relationships) — IN-04.
        let schema = Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self,
                             Rule.self, Collection.self, CollectionItem.self, Clip.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    /// CLIP-04: a Clip built without passing `status` defaults to `.saved` / statusRaw "saved".
    @MainActor
    func testStatusDefaultsSaved() throws {
        let context = try makeInMemoryContext()

        let clip = Clip(title: "Great article", url: "https://example.com/article")
        context.insert(clip)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Clip>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.status, .saved)
        XCTAssertEqual(fetched.first?.statusRaw, "saved")
    }

    /// CLIP-02: a Clip built without passing `isArchived` must default to false.
    @MainActor
    func testIsArchivedDefaultsFalse() throws {
        let context = try makeInMemoryContext()

        let clip = Clip(title: "Great article", url: "https://example.com/article")
        context.insert(clip)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Clip>())
        XCTAssertEqual(fetched.first?.isArchived, false)
    }

    /// CLIP-04: setting `clip.status = .acted` writes statusRaw == "acted".
    @MainActor
    func testStatusToggleWritesRaw() throws {
        let context = try makeInMemoryContext()

        let clip = Clip(title: "Great article", url: "https://example.com/article")
        context.insert(clip)
        try context.save()

        clip.status = .acted
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Clip>())
        XCTAssertEqual(fetched.first?.statusRaw, "acted")
        XCTAssertEqual(fetched.first?.status, .acted)
    }

    /// CLIP-03: Domain.clips inverse — assigning clip.domain wires domain.clips.
    @MainActor
    func testDomainClipsInverse() throws {
        let context = try makeInMemoryContext()

        let domain = Domain(name: "Health", iconName: "heart", colorToken: "maroon", sortIndex: 0)
        let clip = Clip(title: "Great article", url: "https://example.com/article", domain: domain)
        context.insert(domain)
        context.insert(clip)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Domain>())
        XCTAssertEqual(fetched.first?.clips.count, 1)
        XCTAssertTrue(fetched.first?.clips.contains(where: { $0.id == clip.id }) ?? false)
    }

    /// CLIP-03/D-12: deleting a Domain nullifies its clips — never cascades.
    @MainActor
    func testDeleteDomainNullifiesClips() throws {
        let context = try makeInMemoryContext()

        let domain = Domain(name: "Health", iconName: "heart", colorToken: "maroon", sortIndex: 0)
        let clip = Clip(title: "Great article", url: "https://example.com/article", domain: domain)
        context.insert(domain)
        context.insert(clip)
        try context.save()

        context.delete(domain)
        try context.save()

        let clips = try context.fetch(FetchDescriptor<Clip>())
        XCTAssertEqual(clips.count, 1, "Clip must survive domain deletion (no cascade)")
        XCTAssertNil(clips.first?.domain, "domain must be nullified")

        let domains = try context.fetch(FetchDescriptor<Domain>())
        XCTAssertEqual(domains.count, 0)
    }
}
