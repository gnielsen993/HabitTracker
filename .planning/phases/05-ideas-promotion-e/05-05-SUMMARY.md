---
phase: 05-ideas-promotion-e
plan: 05
subsystem: ui
tags: [swiftui, swiftdata, ideas, capture-first, designkit]

# Dependency graph
requires:
  - phase: 05-ideas-promotion-e (05-01)
    provides: Idea @Model + Domain.ideas nullify inverse + container registration
provides:
  - IdeaCaptureSheet — shared title-only create/edit sheet for Idea (dual init)
  - Today's top-trailing capture "+" toolbar item, wired to IdeaCaptureSheet()
affects: [05-06, 05-07, 05-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-mode private enum Mode { case create(domain: Domain?); case edit(idea: Idea) } + dual-init sheet (RuleEditorView/ClipEditorView shape), extended to an optional-domain create case"
    - "Plain VStack (not Form) for a genuinely single-field capture sheet — deliberately lighter than the multi-section editors"
    - "Net-new toolbar chrome added to an existing NavigationStack without touching any pre-existing body content"

key-files:
  created:
    - HabitsTracker/Features/Ideas/IdeaCaptureSheet.swift
  modified:
    - HabitsTracker/Features/Today/TodayView.swift

key-decisions:
  - "IdeaCaptureSheet uses a plain VStack, not a Form — matches UI-SPEC S2's explicit 'deliberately lighter than RuleEditorView/ClipEditorView' instruction for a single-field sheet"
  - "presentationDetents([.medium]) only (not [.medium, .large] like HabitCreateSheet) — keeps the capture flow visually light per the plan's explicit 'planner's call — keep it light'"
  - "No os.Logger added — no error path exists in this sheet (only try? modelContext.save(), same as RuleEditorView/HabitCreateSheet, which also skip logging)"

patterns-established:
  - "Optional-domain create init (Domain? = nil) on the two-mode enum — a variation on the RuleEditorView dual-init pattern where create previously always required a non-optional Domain"

requirements-completed: [IDEA-02]

# Metrics
duration: 5min
completed: 2026-07-10
---

# Phase 05 Plan 05: Ideas Capture Spine (IdeaCaptureSheet + Today "+") Summary

**Title-only IdeaCaptureSheet (dual create/edit init, orphan-free save, hard-delete escape hatch) wired to a net-new top-trailing "+" on Today that captures unfiled ideas straight into the Hub inbox without touching Today's existing content.**

## Performance

- **Duration:** ~5 min
- **Completed:** 2026-07-10T21:09:15-05:00
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 edited)

## Accomplishments
- `IdeaCaptureSheet` — one shared component for create (`domain: Domain? = nil`) and edit (`idea: Idea`), single `TextField("What's the idea?")`, autofocus via `@FocusState`, verbatim validation-hint/copy reuse from `RuleEditorView`
- Fill-then-commit save discipline: `Idea` is constructed and `modelContext.insert`-ed only inside the Save action; Cancel changes nothing
- Edit-mode destructive "Delete Idea" row with a `confirmationDialog` (hard delete — the mis-capture escape hatch)
- Today's `NavigationStack` gained a top-trailing "+" toolbar item (net-new chrome only) presenting `IdeaCaptureSheet()` via `.sheet` — the ScrollView/VStack row content and `.task` bootstrap are byte-for-byte untouched

## Task Commits

Each task was committed atomically:

1. **Task 1: IdeaCaptureSheet (title-only create/edit)** - `8342274` (feat)
2. **Task 2: Today capture '+' toolbar item** - `d3c3ecd` (feat)

**Plan metadata:** (this commit, following)

_Note: tasks were flagged `tdd="true"` in the plan frontmatter, but see "TDD Gate Compliance" below._

## Files Created/Modified
- `HabitsTracker/Features/Ideas/IdeaCaptureSheet.swift` - New shared title-only create/edit sheet for `Idea`
- `HabitsTracker/Features/Today/TodayView.swift` - Added `showingCapture` state + top-trailing "+" toolbar item + `.sheet(isPresented:) { IdeaCaptureSheet() }`

## TDD Gate Compliance

Task 1 was marked `tdd="true"` in the plan frontmatter with a `<behavior>` block, but the behavior describes a SwiftUI view surface (sheet composition: dual-init, save/cancel/delete wiring) with no pure-function unit under test — not an isolated engine. This is consistent with how Phase 4's Plan 04-03 (`04-03-SUMMARY.md`) scoped TDD to pure-function helpers only (e.g. `ClipTitleSuggestion`) and treated view-composition tasks as a single GREEN-equivalent implementation commit, verified by the plan's grep-based acceptance criteria plus a clean build. No separate RED/GREEN commits were applicable here for the same reason; Task 1's single `feat` commit is that GREEN-equivalent.

## Decisions Made
- Plain `VStack` (not `Form`) for `IdeaCaptureSheet` body — matches the UI-SPEC's explicit instruction that this sheet is "deliberately lighter" than `RuleEditorView`/`ClipEditorView`.
- `.presentationDetents([.medium])` only, per the plan's "keep it light" instruction (contrast with `HabitCreateSheet`'s `[.medium, .large]`).
- No `os.Logger` added — no error path exists in this sheet.

## Deviations from Plan

None — plan executed exactly as written. Both tasks matched their acceptance criteria on the first pass; no auto-fixes were needed.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `IdeaCaptureSheet` is the shared component that 05-06/05-07/05-09 (in-domain Ideas "+", row tap-to-edit) will reuse without modification, per its dual-init design.
- Today's capture entry point (S1, IDEA-02) is live: a global "+" reaches `IdeaCaptureSheet()` without leaving Today, and Today's list is unchanged.
- No blockers. The captured (unfiled) idea does not yet surface anywhere visible (Hub inbox card/`InboxView` land in later plans in this phase) — this is expected sequencing, not a gap in this plan's scope.

---
*Phase: 05-ideas-promotion-e*
*Completed: 2026-07-10*

## Self-Check: PASSED

- FOUND: HabitsTracker/Features/Ideas/IdeaCaptureSheet.swift
- FOUND: HabitsTracker/Features/Today/TodayView.swift
- FOUND: .planning/phases/05-ideas-promotion-e/05-05-SUMMARY.md
- FOUND commit: 8342274 (Task 1)
- FOUND commit: d3c3ecd (Task 2)
- FOUND commit: 3ecf235 (docs: plan summary)
