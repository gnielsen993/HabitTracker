---
phase: 06-polish-f
plan: 01
subsystem: ui
tags: [swiftui, swiftdata, searchable, search, accessibility]

# Dependency graph
requires:
  - phase: 05-ideas-promotion-e
    provides: Idea @Model, IdeaRow, InboxView, PromoteService (search reuses IdeaRow's tap-to-edit sheet)
  - phase: 04-clips-d
    provides: Clip @Model, ClipRow, ClipDetailView
  - phase: 03-collections-c
    provides: Collection/CollectionItem @Models, CollectionRow, CollectionDetailView
  - phase: 02-rules-b
    provides: Rule @Model, RuleRow, RuleDetailView
provides:
  - Cross-domain search (SearchResultsView) reachable from the Hub tab via .searchable
  - Type-grouped in-memory search across Habit/Rule/Collection/CollectionItem/Clip/Idea
  - Search no-results state via ContentUnavailableView.search(text:)
  - Verified/confirmed pre-existing empty states satisfy §9.3 (POL-02 groundwork)
affects: [06-polish-f (remaining waves: POL-03 export/import verification, POL-04 accessibility pass)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cross-model search as N per-type @Query fetches, in-memory .localizedStandardContains filter, no FTS engine/dependency"
    - "Search results reuse each type's existing row + detail/editor destination — no new detail UI"

key-files:
  created:
    - HabitsTracker/Features/Hub/SearchResultsView.swift
  modified:
    - HabitsTracker/Features/Hub/HubView.swift
    - HabitsTracker/Features/Ideas/InboxView.swift

key-decisions:
  - "Search lives on Hub's existing NavigationStack via .searchable + .searchToolbarBehavior(.minimize) — no second stack, no new tab (D-01/D-02)"
  - "CollectionItem title/note hits are folded up into their parent Collection's search result (no separate CollectionItem row/section)"
  - "InboxView's minimal single-line empty state is confirmed as the accepted D-11 designed treatment; stale POL-02 placeholder comment removed, rendered copy unchanged"

patterns-established:
  - "SearchResultsView.swift: type-grouped read-only search lens over existing rows — future search additions (if any) extend the match-array + section pattern here"

requirements-completed: [POL-01, POL-02]

# Metrics
duration: ~10min
completed: 2026-07-12
---

# Phase 6 Plan 1: Cross-Domain Search + Empty-State Verification Summary

**Cross-domain search on the Hub tab (`.searchable` + iOS 26 `.searchToolbarBehavior(.minimize)`) with type-grouped results (Habits/Rules/Collections/Clips/Ideas) that reuse each item's existing detail/editor surface, plus confirmation that all pre-existing empty states satisfy §9.3.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-07-12T02:42:01Z
- **Completed:** 2026-07-12T02:44:07Z
- **Tasks:** 2 completed
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- Delivered `SearchResultsView` — six per-type `@Query`s (Habit/Rule/Collection/CollectionItem/Clip/Idea), each excluding archived/consumed items at the predicate level, matched in memory via `.localizedStandardContains` over title + free-text fields, grouped into one section per non-empty type.
- Wired `.searchable(text:)` + `.searchToolbarBehavior(.minimize)` onto HubView's existing single `NavigationStack`; non-empty query swaps in `SearchResultsView` while the pre-existing empty-state/grid branch is untouched.
- Verified every pre-existing empty state (HubView "Your Hub is empty", DomainDetailView "Nothing here yet", InboxView "Nothing to file right now.", PromoteToCollectionPicker) still renders and satisfies §9.3; removed the stale InboxView doc-comment that mischaracterized its empty state as a placeholder — D-11 confirms it is the accepted designed treatment.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create SearchResultsView — type-grouped cross-domain results + no-results state** - `36359bf` (feat)
2. **Task 2: Wire .searchable into HubView + verify existing empty states + close inbox POL-02 flag** - `5f43b68` (feat)

**Plan metadata:** (final commit follows this summary)

## Files Created/Modified
- `HabitsTracker/Features/Hub/SearchResultsView.swift` - New type-grouped cross-domain search results view + no-results state
- `HabitsTracker/Features/Hub/HubView.swift` - Added `.searchable` + `.searchToolbarBehavior(.minimize)`, swaps in `SearchResultsView` on non-empty query
- `HabitsTracker/Features/Ideas/InboxView.swift` - Removed stale placeholder doc-comment on `emptyState(theme:)`; rendered copy unchanged

## Decisions Made
- CollectionItem hits are folded into their parent Collection's result row rather than surfaced as a standalone item row/section — matches the plan's "surface under Collections" instruction and avoids inventing new UI for CollectionItem.
- Habit search results present `HabitEditorView` via a local `.sheet(item:)` owned by `SearchResultsView` (not a `NavigationLink`), matching D-08's explicit "editor sheet, never a jump to Today."

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- POL-01 and POL-02 are functionally complete and build-verified (`xcodebuild ... build` exits 0 on iPhone 17 simulator).
- Full device/VoiceOver confirmation of the search flow and empty states is explicitly deferred to the Wave-2 owner-verification plan (06-04), per this plan's `<verification>` section — not a blocker for closing 06-01.
- POL-03 (export/import round-trip verification) and POL-04 (accessibility pass, incl. the CollectionItemRow status-chip fix) remain open in subsequent 06-xx plans; no schema change was introduced here (D-15 — search/empty-state work is read-side only).

---
*Phase: 06-polish-f*
*Completed: 2026-07-12*
