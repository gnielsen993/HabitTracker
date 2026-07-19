import Foundation
import SwiftData
import os

final class BootstrapService {
    private let seedDataService = SeedDataService()
    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "gn.HabitsTracker", category: "Bootstrap")

    /// The persisted "what seed version did we last reconcile?" marker. Greenfield —
    /// nothing wrote it before this version, so it reads `0` for every existing install.
    private let lastSeededVersionKey = "lastSeededVersion"

    /// The seed version this bootstrap reconciles to. Pairs with `SeedDataService.seedVersion`.
    private let currentSeedVersion = 3

    /// Inject an isolated `UserDefaults` suite in tests so the `lastSeededVersion`
    /// idempotency marker never leaks into (or out of) the app's standard defaults.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func bootstrapIfNeeded(context: ModelContext) throws {
        // Fresh-install path: seeds the opinionated subset PRE-FOCUSED and the new hub
        // domains UNFOCUSED (D-09). Early-returns if any Domain already exists.
        try seedDataService.seedIfNeeded(context: context)

        // Version-gated, once-only seed reconciliation (Research Pattern 2).
        let previous = defaults.integer(forKey: lastSeededVersionKey)
        if previous < currentSeedVersion {
            // Capture the IDs that pre-date this reconciliation BEFORE merge-add, so the
            // focus backfill flips only genuine pre-existing rows — never the unfocused
            // hub domains we are about to merge-add (D-08 keeps those unfocused).
            let preexistingIDs = Set(try context.fetch(FetchDescriptor<Domain>()).map(\.id))

            // Merge-add new hub domains unfocused; name-keyed dedupe (D-08).
            try seedDataService.restoreMissingDefaults(context: context)

            // `previous > 0` ⇒ a genuine upgrade with pre-existing user rows. Flip those
            // rows (which inferred migration defaulted to `isFocused = false`) to focused
            // so the upgrader's Hub opens to their familiar set (D-07). On a fresh install
            // `previous == 0`, so this is skipped — the curated subset is already focused
            // and the new domains stay unfocused (Pitfall 3).
            if previous > 0 {
                try backfillFocusOnExistingDomains(preexistingIDs: preexistingIDs, context: context)
            }

            // Record the reconciliation so it never runs again — a domain the user later
            // unfocuses stays unfocused across launches (D-11 / idempotent).
            defaults.set(currentSeedVersion, forKey: lastSeededVersionKey)
            logger.info("Seed reconciliation complete: \(previous, privacy: .public) -> \(self.currentSeedVersion, privacy: .public)")
        }

        _ = try ensureDailyEntryExists(for: .now, context: context)
        try HabitScheduleRevisionService.synthesizeMissingInitialRevisions(context: context)
    }

    /// D-07: flip every pre-existing Domain to focused, exactly once. Gated by the caller's
    /// `previous > 0` check and the marker write, so manual unfocusing is never reverted.
    /// Only rows captured before the merge-add are flipped — newly merge-added hub domains
    /// stay unfocused (D-08).
    private func backfillFocusOnExistingDomains(preexistingIDs: Set<UUID>, context: ModelContext) throws {
        let domains = try context.fetch(FetchDescriptor<Domain>())
        for domain in domains where preexistingIDs.contains(domain.id) {
            domain.isFocused = true
        }
        try context.save()
    }

    @discardableResult
    func ensureDailyEntryExists(for date: Date, context: ModelContext) throws -> DailyEntry {
        let key = DateUtilities.startOfDay(date)
        var descriptor = FetchDescriptor<DailyEntry>(predicate: #Predicate { $0.dateKey == key })
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let entry = DailyEntry(dateKey: key)
        context.insert(entry)
        try context.save()
        return entry
    }
}
