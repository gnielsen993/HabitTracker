import XCTest
import SwiftData
@testable import HabitsTracker

/// Wave-0 RED tests for the version-gated, one-time focus backfill (DOM-04) that plan 01-03
/// will implement in `BootstrapService`. They assert the Pattern-2 semantics from
/// 01-RESEARCH.md: a `previous < 2` gate, a `previous > 0` "is a genuine upgrade" guard,
/// two-run idempotency, and the name-keyed merge-add of new domains as unfocused.
///
/// These reference the not-yet-existing `Domain` type and the not-yet-existing
/// version-gated backfill wiring in `BootstrapService.bootstrapIfNeeded`, so they are
/// EXPECTED RED until 01-02 (rename) and 01-03 (backfill) land. Do NOT stub production
/// types to make these green.
///
/// Each test uses an isolated `UserDefaults` suite so the persisted `lastSeededVersion`
/// marker never leaks between tests or into the app's standard defaults.
final class BootstrapBackfillTests: XCTestCase {

    private var suiteName: String = ""
    private var defaults: UserDefaults!

    private let lastSeededVersionKey = "lastSeededVersion"

    override func setUp() {
        super.setUp()
        suiteName = "BootstrapBackfillTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    @MainActor
    private func insertDomain(
        named name: String,
        isFocused: Bool,
        into context: ModelContext
    ) -> Domain {
        let domain = Domain(
            name: name,
            iconName: "circle",
            colorToken: "stone",
            sortIndex: 0,
            isSeeded: true,
            seedVersion: 1,
            isFocused: isFocused
        )
        context.insert(domain)
        return domain
    }

    /// DOM-04 / D-07: an upgrader (marker `> 0` and `< 2`) with pre-existing unfocused
    /// domains must have every pre-existing Domain flipped to `isFocused == true` so the
    /// Hub opens to their familiar set — no empty screen.
    @MainActor
    func testBackfillFlipsPreexistingDomainsWhenUpgrading() throws {
        let context = try makeInMemoryContext()
        _ = insertDomain(named: "Productivity", isFocused: false, into: context)
        _ = insertDomain(named: "Learning", isFocused: false, into: context)
        try context.save()

        // Simulate an existing v1 install: a prior marker that is > 0 and < 2.
        defaults.set(1, forKey: lastSeededVersionKey)

        let service = BootstrapService(defaults: defaults)
        try service.bootstrapIfNeeded(context: context)

        let domains = try context.fetch(FetchDescriptor<Domain>())
        let preexisting = domains.filter { $0.name == "Productivity" || $0.name == "Learning" }
        XCTAssertEqual(preexisting.count, 2)
        XCTAssertTrue(preexisting.allSatisfy { $0.isFocused }, "Every pre-existing Domain should be focused after the upgrade backfill")
    }

    /// DOM-04 / D-11: the backfill is gated by the persisted `lastSeededVersion` marker and
    /// must run at most once. After run 1 flips and records the marker, manually unfocusing
    /// a Domain and running run 2 must NOT re-focus it.
    @MainActor
    func testBackfillRunsOnce() throws {
        let context = try makeInMemoryContext()
        let productivity = insertDomain(named: "Productivity", isFocused: false, into: context)
        try context.save()

        defaults.set(1, forKey: lastSeededVersionKey)

        let service = BootstrapService(defaults: defaults)

        // Run 1: should flip Productivity to focused and record the marker.
        try service.bootstrapIfNeeded(context: context)
        XCTAssertTrue(productivity.isFocused, "Run 1 should focus the pre-existing Domain")

        // User unfocuses it after the upgrade.
        productivity.isFocused = false
        try context.save()

        // Run 2: the gate (marker now == 2) must make this a no-op for the backfill.
        try service.bootstrapIfNeeded(context: context)
        XCTAssertFalse(productivity.isFocused, "Run 2 must NOT re-focus a Domain the user unfocused")
    }

    /// DOM-04 / D-09 + Pitfall 3: on a fresh install (marker `== 0`) the existing-row flip
    /// must NOT fire. The merge-added new hub domains (Style/Diet/Money/Media) must remain
    /// `isFocused == false` — the `previous > 0` guard skips the existing-row backfill.
    @MainActor
    func testFreshInstallDoesNotBackfillExistingRows() throws {
        let context = try makeInMemoryContext()

        // Fresh install: no marker yet (defaults integer(forKey:) == 0).
        XCTAssertEqual(defaults.integer(forKey: lastSeededVersionKey), 0)

        let service = BootstrapService(defaults: defaults)
        try service.bootstrapIfNeeded(context: context)

        let domains = try context.fetch(FetchDescriptor<Domain>())
        let newHubNames: Set<String> = ["Style", "Diet", "Money", "Media"]
        let newHubDomains = domains.filter { newHubNames.contains($0.name) }

        XCTAssertFalse(newHubDomains.isEmpty, "Fresh install should merge-add the new hub domains")
        XCTAssertTrue(newHubDomains.allSatisfy { !$0.isFocused }, "Merge-added hub domains must be unfocused on fresh install (no existing-row flip)")
    }

    /// DOM-04 / D-08: the merge-add path is name-keyed and additive. A pre-seeded "Social"
    /// must not be duplicated, and newly merge-added domains must arrive `isFocused == false`.
    @MainActor
    func testMergeAddIsUnfocusedAndDedupesByName() throws {
        let context = try makeInMemoryContext()

        // Pre-seed an existing "Social" domain to prove name-keyed dedupe.
        _ = insertDomain(named: "Social", isFocused: true, into: context)
        try context.save()

        // Existing install with a prior marker so merge-add runs.
        defaults.set(1, forKey: lastSeededVersionKey)

        let service = BootstrapService(defaults: defaults)
        try service.bootstrapIfNeeded(context: context)

        let domains = try context.fetch(FetchDescriptor<Domain>())
        let socials = domains.filter { $0.name == "Social" }
        XCTAssertEqual(socials.count, 1, "Merge-add must dedupe by name — exactly one 'Social'")

        let newHubNames: Set<String> = ["Style", "Diet", "Money", "Media"]
        let newlyAdded = domains.filter { newHubNames.contains($0.name) }
        XCTAssertFalse(newlyAdded.isEmpty, "New hub domains should be merge-added")
        XCTAssertTrue(newlyAdded.allSatisfy { !$0.isFocused }, "Newly merge-added domains must be unfocused")
    }
}
