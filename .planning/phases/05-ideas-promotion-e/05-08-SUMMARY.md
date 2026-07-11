---
phase: 05-ideas-promotion-e
plan: 08
subsystem: ui
tags: [swiftui, swiftdata, ideas, hub, designkit]

# Dependency graph
requires:
  - phase: 05-ideas-promotion-e (05-07)
    provides: "IdeaRow — the reusable, data-driven idea row this plan renders inside InboxView"
provides:
  - "InboxView — data-driven list of unfiled ideas (owns its own @Query, D-05), the Hub inbox screen"
  - "HubView inbox card — count-gated 'N to file' DKCard pinned above the domain grid, opens InboxView"
affects: [05-09, 05-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Outer VStack(alignment:.leading, spacing: theme.spacing.l) wrapping grid(theme:)'s ScrollView content, with the inbox card conditionally prepended above the unchanged LazyVGrid — additive card without restructuring the grid itself"

key-files:
  created:
    - HabitsTracker/Features/Ideas/InboxView.swift
  modified:
    - HabitsTracker/Features/Hub/HubView.swift

key-decisions:
  - "InboxView's minimal D-04 empty state uses a single centered Text, not the two-line heading+body DomainDetailView.emptyState shape it was scaffolded from — kept deliberately lighter per S4's literal instruction"
  - "HubView.grid(theme:) wraps its ScrollView content in a new outer VStack to prepend the inbox card above the LazyVGrid; the LazyVGrid's own columns/spacing/ForEach body is untouched, only its container changed"

patterns-established: []

requirements-completed: [IDEA-03]

# Metrics
duration: 4min
completed: 2026-07-11
---

# Phase 05 Plan 08: Hub Inbox Surface (InboxView + HubView Card) Summary

**A count-gated "N to file" DKCard pinned above HubView's domain grid opens InboxView, a self-querying list of unfiled ideas rendered as IdeaRows — the surface where captured ideas land until filed or promoted.**

## Performance

- **Duration:** ~4 min
- **Completed:** 2026-07-11T08:10:00-05:00
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 edited)

## Accomplishments
- `InboxView` — data-driven (§9.2, D-05): owns `@Query(filter: domain == nil && !isArchived, sort: createdAt desc)`, renders `ForEach(unfiledIdeas) { IdeaRow(idea: $0) }` in a `ScrollView`/`VStack`, `navigationTitle("Inbox")`, no nested `NavigationStack` (nests under HubView's stack, matching `DomainDetailView`'s precedent)
- D-04 minimal empty state: single centered "Nothing to file right now." (body/textSecondary, `spacing.xxl` top), no heading/CTA — a code comment flags POL-02 as the future replacement
- `HubView` gained a second `@Query` (`unfiledIdeas`, same predicate) alongside the existing `focusedDomains` query
- Inbox card: `DKCard` with leading `tray.full` icon (accentPrimary), "Ideas to file" (headline/textPrimary), `Spacer()`, `DKBadge("{N} to file")`, trailing chevron; the whole card is one `NavigationLink { InboxView() }`, `.buttonStyle(.plain)`, `.frame(minHeight: 44)`, `accessibilityLabel("{N} ideas to file, opens inbox")`
- Card is gated `if !unfiledIdeas.isEmpty` and pinned above `grid(theme:)`'s `LazyVGrid` inside the same `ScrollView`, entirely absent at zero count (no ghost state) — the domain grid's own `LazyVGrid` body (columns, ForEach, `DomainTile` rendering) is untouched, only wrapped in a new outer `VStack` to host the card

## Task Commits

Each task was committed atomically:

1. **Task 1: InboxView (data-driven list of unfiled ideas)** - `34cd5b0` (feat)
2. **Task 2: Hub inbox card (pinned above the grid, count-gated)** - `c2727ed` (feat)

**Plan metadata:** (this commit, following)

## Files Created/Modified
- `HabitsTracker/Features/Ideas/InboxView.swift` - New: self-querying unfiled-ideas list, renders IdeaRow, D-04 minimal empty state, no owned NavigationStack
- `HabitsTracker/Features/Hub/HubView.swift` - Added `unfiledIdeas` @Query + count-gated `inboxCard(theme:)` pinned above the domain grid via a new wrapping VStack

## Decisions Made
- Simplified `InboxView`'s empty state to a single centered line rather than porting `DomainDetailView.emptyState`'s two-line heading+body shape — S4 explicitly calls for something lighter than the domain empty state.
- To prepend the inbox card "inside the same ScrollView/VStack" per the plan's must_haves, `grid(theme:)` now wraps its content in an outer `VStack(alignment: .leading, spacing: theme.spacing.l)` holding the conditional card + the LazyVGrid; the LazyVGrid's internals (columns, ForEach, DomainTile) are byte-for-byte the same as before, only re-parented.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `InboxView` and the Hub inbox card are both live and build-verified; filing or promoting an idea from an `IdeaRow` inside the inbox flips `idea.isArchived`/`idea.domain`, which drops it out of both the card's count query and the list's own query live (no manual list mutation needed, per IdeaRow's 05-07 wiring).
- 05-09 can now build the Ideas section inside `DomainDetailView` using the same `IdeaRow` component, with the File pill naturally absent there since filed ideas have `domain != nil`.
- Owner on-device visual confirmation (card layout, tap-to-open, live emptying as ideas are filed/promoted) rides the phase-end owner check per this plan's success criteria — not yet exercised on a simulator/device.
- No blockers.

---
*Phase: 05-ideas-promotion-e*
*Completed: 2026-07-11*
