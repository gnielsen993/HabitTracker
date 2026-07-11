---
phase: 05-ideas-promotion-e
plan: 03
subsystem: services
tags: [swiftdata, promote, engine-tests, idea]

# Dependency graph
requires:
  - phase: 05-ideas-promotion-e
    provides: "Idea @Model with promotedTo/promotedToID/domain fields and nested Idea.PromotedKind (05-01)"
provides:
  - "PromoteService.archiveAndForwardLink(idea:as:targetID:) — the single consume/archive/forward-link core all three promote editors call on Save"
  - "PromoteService.requiresDomainBeforePromote(idea:) — unfiled-idea-needs-domain predicate (IDEA-05)"
  - "PromoteServiceTests — runnable engine-tier suite (4/4 green) covering happy path, already-archived skip, unfiled-requires-domain, promote-to-collection needs-list"
affects: [05-06, 05-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "nonisolated(unsafe) file-scoped Logger constant when a Logger must be called from nonisolated static functions under default-actor-isolation build settings (first precedent in this repo — CollectionRollupEngine has no logger; ClipEditorView's logger is only ever called from MainActor view code)"

key-files:
  created:
    - HabitsTracker/Services/PromoteService.swift
    - HabitsTrackerTests/PromoteServiceTests.swift
  modified: []

key-decisions:
  - "PromoteService mirrors CollectionRollupEngine's pure-enum/nonisolated-static idiom but legitimately mutates the passed-in Idea (no ModelContext.save() inside the core) so the caller retains save ownership and the test suite stays ModelContainer-free (§9.7)"
  - "No separate 'collection needs a list' predicate was added — per the pattern map, choosing the target collection resolves the idea's domain gap, so the shared requiresDomainBeforePromote gate covers the collection-promote precondition too; testCollectionPromoteNeedsList exercises this indirectly (blocked unfiled -> domain assigned via chosen collection -> gate clears -> archive succeeds)"

patterns-established:
  - "Shared consume-core service pattern: one small pure/save-free helper (archiveAndForwardLink) that every target editor calls on Save, rather than each editor re-implementing the consume logic (§9.5, D-07)"

requirements-completed: [IDEA-04]

# Metrics
duration: 4min
completed: 2026-07-11
---

# Phase 05 Plan 03: PromoteService Consume/Archive/Forward-Link Core Summary

**PromoteService — a pure, save-free enum namespace centralizing the promote-is-consume logic (archive + scalar forward-link + domain-required predicate), proven by a 4/4 green runnable-tier test suite with zero ModelContainer.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-10T20:52:18-05:00 (approx., prior plan completion)
- **Completed:** 2026-07-11T01:55:57Z
- **Tasks:** 2
- **Files modified:** 2 (both new)

## Accomplishments
- Added `PromoteService` as an `enum` namespace mirroring `CollectionRollupEngine`'s pure/`nonisolated static` idiom: `archiveAndForwardLink(idea:as:targetID:)` sets `isArchived`/`promotedTo`/`promotedToID`, guarded against double-archive (T-05-04) with a logged skip via `os.Logger`
- Added `requiresDomainBeforePromote(idea:)` — the unfiled-idea-needs-domain predicate (IDEA-05) the three target editors' Save-gates will consult in 05-06
- Added `PromoteServiceTests` with the four required cases (happy path, already-archived skip, unfiled-requires-domain, collection-promote-needs-list), constructing bare in-memory `Idea`/`Domain` instances with no `ModelContainer` — inherits the runnable engine tier that actually executes on the iOS 26 simulator (§9.7)
- Fixed a Swift concurrency warning (`nonisolated(unsafe)` on the file-scoped `Logger` constant) so the `nonisolated static` functions can call it cleanly with zero build warnings

## Task Commits

Each task was committed atomically:

1. **Task 1: PromoteService consume/archive/forward-link core** - `087122d` (feat)
2. **Task 2: PromoteServiceTests (runnable engine tier)** - `32a7c87` (test)

## Files Created/Modified
- `HabitsTracker/Services/PromoteService.swift` - New pure `enum PromoteService` namespace: `archiveAndForwardLink(idea:as:targetID:)` + `requiresDomainBeforePromote(idea:)`, `os.Logger` diagnostic on the already-archived skip, no `print(`, no DesignKit/SwiftUI import, no `.save()` call
- `HabitsTrackerTests/PromoteServiceTests.swift` - New `final class PromoteServiceTests: XCTestCase` with 4 tests, all passing on `-only-testing:HabitsTrackerTests/PromoteServiceTests`

## Decisions Made
- Followed the plan's locked scope: this service performs only the idea-side consume + preconditions, and does NOT construct the target Rule/Habit/CollectionItem (that stays with the three editors in 05-06)
- `nonisolated(unsafe)` applied to the file-scoped `Logger` constant — required because this repo's build settings implicitly actor-isolate top-level `let` declarations, and `archiveAndForwardLink`/`requiresDomainBeforePromote` must stay `nonisolated static` to match the `CollectionRollupEngine` pure-engine idiom and to keep `PromoteServiceTests` callable from a plain `XCTestCase` with no actor hops. `Logger` is a thread-safe value type over `os_log`, so this is a correctness-neutral annotation, not a data-race risk.

## Deviations from Plan

None - plan executed exactly as written. (One minor build-warning fix — `nonisolated(unsafe)` on the logger constant — applied inline as part of Task 1 per Rule 1, not tracked as a separate deviation since it was fixed before the Task 1 commit landed.)

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`PromoteService.archiveAndForwardLink` and `requiresDomainBeforePromote` are in place, build clean, and pass their full test suite (4/4). This unblocks:
- 05-06 (the three target editors: RuleEditorView, HabitCreateSheet's `.idea` case, CollectionItemEditorSheet) — each calls `PromoteService.archiveAndForwardLink` right after its own `try? modelContext.save()`, per the pattern map's per-editor hook notes
- 05-07 (IdeaRow's Promote affordance) — will invoke `requiresDomainBeforePromote` to gate the Promote-to-Rule/Habit action when the idea is unfiled

No blockers.

---
*Phase: 05-ideas-promotion-e*
*Completed: 2026-07-11*

## Self-Check: PASSED

- FOUND: HabitsTracker/Services/PromoteService.swift
- FOUND: HabitsTrackerTests/PromoteServiceTests.swift
- FOUND commit: 087122d (feat)
- FOUND commit: 32a7c87 (test)
- FOUND commit: bfc8c6d (docs: summary)
