---
phase: 02-rules-b
plan: 03
subsystem: ui
tags: [habits, rules, swiftui, fill-then-commit, backref, designkit, stem]

# Dependency graph
requires:
  - phase: 02-rules-b
    plan: 01
    provides: Rule @Model + Habit.originRule + Domain.rules inverse
  - phase: 02-rules-b
    plan: 02
    provides: RuleDetailView (Stem CTA disabled with TODO(02-03) marker)
provides:
  - HabitCreateSheet: shared source-agnostic fill-then-commit habit create sheet
  - RuleDetailView: Stem CTA wired — presents HabitCreateSheet(source: .rule(rule))
  - HabitManagerView: "Add Habit" migrated to HabitCreateSheet(source: .manual)
  - HabitEditorView: read-only "Stemmed from" backref row → RuleDetailView
affects: [phase-05-ideas, promote-to-habit-reuse]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "HabitSource enum drives prefill only; chrome is identical for all sources (D-07 — Phase 5 adds .idea without touching the sheet)"
    - "Fill-then-commit: single modelContext.insert in Save action; Cancel exits without inserting (D-04, T-0203-01)"
    - "Backref guarded with if-let; bound constant drives both label and NavigationLink destination — no TOCTOU force-unwrap risk (T-0203-03)"
    - "Stem sets originRule on Habit side only; Rule is never mutated during stemming (RULE-03, T-0203-02)"

key-files:
  created:
    - HabitsTracker/Features/Habits/HabitCreateSheet.swift
  modified:
    - HabitsTracker/Features/Rules/RuleDetailView.swift
    - HabitsTracker/Features/Settings/HabitManagerView.swift
    - HabitsTracker/Features/Settings/HabitEditorView.swift

key-decisions:
  - "fill-then-commit pattern (D-04): modelContext.insert lives only in the Save action — cancel is completely orphan-free"
  - "HabitSource enum is Phase-5-extensible (D-07): adding .idea(Idea) requires zero changes to the sheet"
  - "NavigationLink in HabitEditorView pushes RuleDetailView within HabitEditorView's own NavigationStack — no doubled nav chrome"
  - "Removed unused modelContext + categories @Query from HabitManagerView after retiring insert-then-edit path"

# Metrics
duration: ~8min
completed: 2026-07-05
---

# Phase 02 Plan 03: HabitCreateSheet + Stem wiring + backref Summary

**Shared fill-then-commit HabitCreateSheet wired to three call sites — Stem in RuleDetailView, Add Habit in HabitManagerView, plus a read-only "Stemmed from" backref in HabitEditorView — closing the bidirectional Rule↔Habit link.**

## Performance

- **Duration:** ~8 min
- **Tasks:** 3 of 3 executed
- **Files modified:** 4 (1 created, 3 edited)

## Accomplishments

- `HabitCreateSheet`: source-agnostic fill-then-commit sheet (221 lines). `HabitSource` enum (`.manual` / `.rule(Rule)`) seeds title + domain; both remain editable. Single `modelContext.insert` in the Save action — Cancel exits without inserting (orphan-free, D-04, T-0203-01). "Add Habit" CTA disabled on empty trimmed title with validation copy "Give this a name to continue." Rule-sourced creates set `originRule`; rule is never mutated (T-0203-02). Phase 5 extensible: `.idea(Idea)` requires zero sheet changes (D-07).
- `RuleDetailView`: `.disabled(true)` guard + `.opacity(0.5)` + `// TODO(02-03)` marker removed; Stem CTA now presents `HabitCreateSheet(source: .rule(rule))` via `stemming` @State. Clean accessibility label retained.
- `HabitManagerView`: insert-then-edit "New Habit" placeholder retired (D-06). `@State private var creatingHabit = false`; button sets `creatingHabit = true`; `.sheet(isPresented: $creatingHabit)` presents `HabitCreateSheet(source: .manual)`. Unused `modelContext` + `categories` @Query removed.
- `HabitEditorView`: read-only "Stemmed from" backref section added (25 lines). Guarded with `if let originRule = habit.originRule` — no force-unwrap; bound `originRule` constant drives both the label and the `NavigationLink { RuleDetailView(rule: originRule) }` destination. VoiceOver: "Stemmed from {rule title}, opens rule"; `minHeight: 44` (§9.15). No write path to `habit.originRule` from this view (T-0203-03).

## Task Commits

1. **Task 1: Build HabitCreateSheet** — `be1b2e8`
2. **Task 2: Wire Stem + migrate HabitManager** — `f956260`
3. **Task 3: Stemmed-from backref in HabitEditorView** — `097d63a`

## Files Created/Modified

- `HabitsTracker/Features/Habits/HabitCreateSheet.swift` — new shared fill-then-commit sheet (221 lines)
- `HabitsTracker/Features/Rules/RuleDetailView.swift` — Stem CTA unlocked + HabitCreateSheet sheet wired (208 lines)
- `HabitsTracker/Features/Settings/HabitManagerView.swift` — Add Habit migrated; insert-then-edit retired (74 lines)
- `HabitsTracker/Features/Settings/HabitEditorView.swift` — "Stemmed from" backref section added (125 lines)

## Decisions Made

- Fill-then-commit pattern (D-04): `modelContext.insert` is called exactly once, inside the "Add Habit" save closure. This closes T-0203-01 by construction — there is no orphan risk on cancel.
- `HabitSource` enum kept extensible (D-07): Phase 5 promote-to-habit adds `.idea(Idea)` and reuses the sheet verbatim.
- Backref uses `if let` guard (not force-unwrap) so a SwiftData fault-to-nil after rule deletion is handled gracefully (T-0203-03).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `originRule!` appeared in a comment (not code), failing the grep guard**
- **Found during:** Task 3 verify
- **Issue:** Comment text read `— no re-read of habit.originRule!` — the plan's acceptance grep for `! grep -q "originRule!" HabitEditorView.swift` would have failed on this comment literal.
- **Fix:** Rewrote the comment to `— no force-unwrap of originRule`.
- **Files modified:** `HabitsTracker/Features/Settings/HabitEditorView.swift`
- **Commit:** `097d63a` (same task commit)

**2. [Rule 1 - Cleanup] Removed now-unused modelContext + categories @Query from HabitManagerView**
- **Found during:** Task 2 post-edit review
- **Issue:** After retiring the insert-then-edit path, `@Environment(\.modelContext)` and `@Query(sort: \Domain.sortIndex) private var categories` were no longer referenced anywhere in `HabitManagerView`. Leaving them would be dead code and a potential Swift warning.
- **Fix:** Removed both declarations.
- **Files modified:** `HabitsTracker/Features/Settings/HabitManagerView.swift`
- **Commit:** `f956260` (same task commit)

## Known Stubs

None — all three requirements (RULE-02, RULE-03, RULE-04) are fully wired. The "Stemmed from" backref section is live (not mocked); the Stem CTA is enabled and presents the real sheet.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes. All threat register dispositions (T-0203-01 through T-0203-SC) satisfied:
- T-0203-01 (orphan on cancel): mitigated by fill-then-commit.
- T-0203-02 (stem mutating rule): mitigated — `originRule` set only on Habit side.
- T-0203-03 (backref writing originRule): mitigated — read-only NavigationLink, no write path.
- T-0203-SC (supply chain): N/A — zero new dependencies.

## Self-Check: PASSED

- `HabitsTracker/Features/Habits/HabitCreateSheet.swift` — FOUND
- `HabitsTracker/Features/Settings/HabitEditorView.swift` contains "Stemmed from" — FOUND
- Commits `be1b2e8`, `f956260`, `097d63a` — all present on main

---
*Phase: 02-rules-b*
*Completed: 2026-07-05*
