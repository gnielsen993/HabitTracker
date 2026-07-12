---
phase: 06-polish-f
plan: 03
subsystem: testing
tags: [swiftdata, export-import, round-trip, xctest]

# Dependency graph
requires:
  - phase: 06-polish-f
    provides: "06-02 exposed ExportImportService.currentSchemaVersion as a static let for the Settings About row (D-13), which this plan's Test B references directly"
provides:
  - "All-7-types-in-one-bundle export -> importReplace round-trip test (fields + cross-type relationships) at schemaVersion 6"
  - "Malformed-JSON and unsupported-newer-schema import safety test proving deleteAll is never reached on decode/guard failure"
affects: [06-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "All-types-in-one-bundle round-trip test: seed one of every persisted @Model type in a single HabitExportBundle, export, importReplace into a fresh in-memory ModelContainer, then assert both scalar fields AND cross-type relationship IDs (Rule.domain, Habit<->DailyEntry via HabitState, CollectionItem.collection, Clip.domain, Idea.domain) survived together — not just per-type in isolation."
    - "Import-safety test: seed a store directly via context.insert (not via import), snapshot counts, then XCTAssertThrowsError twice (invalid JSON Data; a hand-encoded HabitExportBundle with schemaVersion = currentSchemaVersion + 1), re-fetching counts after each throw to prove the existing store was never touched."

key-files:
  created: []
  modified:
    - HabitsTrackerTests/ExportImportTests.swift

key-decisions:
  - "Idea test fixture is filed (has domain) AND promoted (promotedToKindRaw/promotedToID set) simultaneously, matching the plan's 'filed + one promoted' wording as one Idea instance exercising both forward-links, not two separate Idea rows — keeps count assertions at exactly one-of-each-type per the plan's must_haves truth."
  - "b2 (unsupported-schema) safety case built its own HabitExportBundle with a local JSONEncoder (iso8601 date strategy) rather than mutating exportData's output, since ExportImportService's encoder/decoder are private — HabitExportBundle and all *DTO structs are internal, so @testable import HabitsTracker gives direct access to construct a schemaVersion=7 payload without touching production code."

requirements-completed: [POL-03]

# Metrics
duration: 8min
completed: 2026-07-12
---

# Phase 6 Plan 03: Export/Import Round-Trip Verification Summary

**Added `testAllTypesSurviveRoundTripV6` (all 7 persisted types + cross-type relationships in one bundle) and `testMalformedAndUnsupportedImportPreservesStore` (invalid JSON + schemaVersion-7 both throw and never destroy the existing store) to `ExportImportTests.swift`; `ExportImportService.swift` and `schemaVersion` (6) are unchanged.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-12T02:58:57Z
- **Completed:** 2026-07-12T03:02:02Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- `testAllTypesSurviveRoundTripV6`: single bundle seeding Domain, Habit+DailyEntry+HabitState, Rule, Collection+CollectionItem, Clip, and a filed+promoted Idea; asserts every type's count == 1 and cross-type relationships (Rule.domain, HabitState.habit, CollectionItem.collection, Clip.domain, Idea.domain) re-link correctly after `importReplace`, plus `Collection.statusSetID` ("shows") survives as the stored StatusSet identifier (D-14, not a DTO).
- `testMalformedAndUnsupportedImportPreservesStore`: seeds a store directly, then proves both a syntactically invalid JSON `Data` blob and a well-formed bundle stamped `schemaVersion = 7` throw (`DecodingError` / `ImportError.unsupportedSchema`) and leave the seeded Domain/Habit counts unchanged — the replace-safety property (decode + guard happen before `deleteAll`, service lines 157–165).
- Confirmed `git diff --stat` on `ExportImportService.swift` is empty (verify-only, no schema bump — D-15) and the build exits 0.

## Task Commits

1. **Task 1: Add all-types-in-one-bundle round-trip + malformed-import-safety tests** - `359809a` (test)

**Plan metadata:** (this commit, docs)

## Files Created/Modified
- `HabitsTrackerTests/ExportImportTests.swift` - Added `testAllTypesSurviveRoundTripV6` and `testMalformedAndUnsupportedImportPreservesStore`, extending the existing per-version round-trip test family without modifying prior tests.

## Decisions Made
- Idea fixture combines "filed" (domain set) and "promoted" (promotedToKindRaw/promotedToID set) in one instance rather than two Ideas — matches the must_haves truth of "one of every type" while still exercising both forward-links in the same bundle.
- b2's schemaVersion-7 payload is built by directly constructing `HabitExportBundle` with a local `JSONEncoder` (internal-visibility DTOs accessible via `@testable import`) rather than mutating `exportData`'s output — avoids any production code change while still exercising the exact `bundle.schemaVersion <= currentSchemaVersion` guard path.

## Deviations from Plan

None - plan executed exactly as written. `ExportImportService.swift` was not touched; `schemaVersion` remains 6.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Both new tests compile and are included in the build (build exits 0; `EngineTests` 4/4 confirmed runnable in the same build to validate the test target as a whole). Per CLAUDE.md §9.7, `ExportImportTests` is a SwiftData `@Model` persistence suite that crashes the iOS 26 simulator test host at 0.000s — actual pass/fail execution of `testAllTypesSurviveRoundTripV6` and `testMalformedAndUnsupportedImportPreservesStore` is deferred to the device-only verification in 06-04, alongside the rest of Phase 6's owner walkthrough. No blockers for 06-04.

---
*Phase: 06-polish-f*
*Completed: 2026-07-12*

## Self-Check: PASSED

- FOUND: HabitsTrackerTests/ExportImportTests.swift
- FOUND: .planning/phases/06-polish-f/06-03-SUMMARY.md
- FOUND commit: 359809a
- FOUND: func testAllTypesSurviveRoundTripV6
- FOUND: func testMalformedAndUnsupportedImportPreservesStore
