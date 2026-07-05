---
phase: 02-rules-b
plan: 02
subsystem: ui
tags: [rules, swiftui, crud, archive, delete, domaindetailview, designkit]

# Dependency graph
requires:
  - phase: 02-rules-b
    plan: 01
    provides: Rule @Model + Habit.originRule + Domain.rules inverse
provides:
  - RuleRow.swift: data-driven card row for rule list entries
  - RuleDetailView.swift: reference-first read surface with body/source/stem/stemmed blocks
  - RuleEditorView.swift: create/edit form + archive + delete-with-stems confirmation
  - DomainDetailView: Rules section appended to nonEmptySections (S1 + "+" create entry)
affects: [02-03, rules-ui, habit-create-sheet]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Rules section appended to nonEmptySections(theme:) — the template Phases C–E mirror for Collections/Clips/Ideas"
    - "Stem CTA shipped .disabled(true) with TODO(02-03) marker — prevents silently broken intermediate build"
    - "Stemmed habit rows open HabitEditorView as sheet (not NavigationLink) because HabitEditorView owns its own NavigationStack"
    - "RuleEditorView @State body renamed to bodyText to avoid SwiftUI body computed property redeclaration"

key-files:
  created:
    - HabitsTracker/Features/Rules/RuleRow.swift
    - HabitsTracker/Features/Rules/RuleDetailView.swift
    - HabitsTracker/Features/Rules/RuleEditorView.swift
  modified:
    - HabitsTracker/Features/Hub/DomainDetailView.swift

key-decisions:
  - "Stem CTA carries .disabled(true) + .opacity(0.5) in 02-02; 02-03 removes the guard and wires HabitCreateSheet"
  - "Stemmed habit navigation uses .sheet(item:) not NavigationLink because HabitEditorView wraps its own NavigationStack"
  - "@State var body renamed bodyText — Swift @State named body conflicts with the View.body computed property"

# Metrics
duration: ~6 min
completed: 2026-07-05
---

# Phase 02 Plan 02: Rules UI Surfaces Summary

**RuleRow, RuleDetailView, RuleEditorView, and the Rules section in DomainDetailView — full CRUD + archive + delete-with-stems, all token-only with VoiceOver labels and explicit empty states.**

## Performance

- **Duration:** ~6 min
- **Tasks:** 3 of 3 executed
- **Files modified:** 4

## Accomplishments

- `RuleRow`: data-driven DKCard row (no @Query) showing headline title + optional caption "Stemmed: {N}" / "· has link"; ≥44pt tap target; VoiceOver label "{title}, rule[, stemmed N habits][, has link]".
- `DomainDetailView`: `nonEmptySections` now appends a Rules section when the domain has ≥1 non-archived rule; section header is an HStack of "Rules" title + accentPrimary "+" button (≥44pt, VoiceOver "Add rule to {domain}") that presents `RuleEditorView`; each `RuleRow` wraps in a `NavigationLink` → `RuleDetailView`; DOM-03 empty state preserved when no sections exist.
- `RuleDetailView`: ScrollView of 5 conditional blocks (header, body, source, stem, stemmed) per 02-UI-SPEC S2; no NavigationStack of its own; toolbar "Edit" presents `RuleEditorView`; "Stem habit" CTA is present but `.disabled(true)` with a `// TODO(02-03)` wiring marker so the intermediate build ships no silently broken action; stemmed-habit rows open `HabitEditorView` as a sheet (not a push).
- `RuleEditorView`: dual-init create/edit; Form with Title (trim + validation copy) / Body / Source URL / Domain picker; "Add Rule"/"Save Changes" CTA disabled until trimmed title non-empty; archive toggle "Archive rule"/"Unarchive Rule"; `confirmationDialog` delete with stem-count-aware copy; `.nullify` inverse handles habit pointer nulling automatically (RULE-05).

## Task Commits

1. **Task 1 (S1): RuleRow + Rules section in DomainDetailView** — `1c3303e`
2. **Task 2 (S2): RuleDetailView — reference-first read surface** — `a39abc9`
3. **Task 3 (S3): RuleEditorView — create/edit/archive/delete** — `b37ba25`

## Files Created/Modified

- `HabitsTracker/Features/Rules/RuleRow.swift` — new data-driven card row (62 lines)
- `HabitsTracker/Features/Rules/RuleDetailView.swift` — new reference-first detail (211 lines)
- `HabitsTracker/Features/Rules/RuleEditorView.swift` — new create/edit form (281 lines)
- `HabitsTracker/Features/Hub/DomainDetailView.swift` — Rules section appended (158 lines)

## Decisions Made

- "Stem habit" button is present + labeled but `.disabled(true)` in 02-02; 02-03 removes the guard. This ensures the intermediate build never ships a silently broken affordance (a tap is visibly inert, not a silent no-op).
- Stemmed habit rows use `.sheet(item:)` rather than `NavigationLink` because `HabitEditorView` owns its own `NavigationStack`. Pushing it under Hub's stack would produce nested nav. Sheet presentation matches the existing `HabitManagerView` pattern.
- `@State private var body: String` renamed to `bodyText` to avoid a Swift compiler error: a stored property named `body` in a `View` conflicts with the required `var body: some View` computed property.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `@State var body` conflicts with `View.body`**
- **Found during:** Task 3 build
- **Issue:** Swift compiler error "invalid redeclaration of 'body'" — `@State private var body: String` in a SwiftUI `View` shadows the required `body: some View` computed property.
- **Fix:** Renamed the state property to `bodyText` throughout `RuleEditorView.swift`.
- **Files modified:** `HabitsTracker/Features/Rules/RuleEditorView.swift`
- **Commit:** `b37ba25`

**2. [Rule 1 - Bug] Spurious nil-coalescing on `domain.rules`**
- **Found during:** Task 1 build (compiler warning)
- **Issue:** `(domain.rules ?? [])` — `Domain.rules` is non-optional, so `??` is always dead.
- **Fix:** Changed to `domain.rules.filter(...)` directly.
- **Files modified:** `HabitsTracker/Features/Hub/DomainDetailView.swift`
- **Commit:** `1c3303e`

**3. [Rule 2 - Design] Stemmed habit navigation pattern**
- **Found during:** Task 2 implementation review
- **Issue:** Plan spec says "navigate to that habit", but `HabitEditorView` owns its own `NavigationStack`. Using `NavigationLink` inside Hub's stack would produce doubled nav chrome (known ecosystem anti-pattern).
- **Fix:** Used `.sheet(item: $editingHabit)` instead of `NavigationLink`, matching the existing `HabitManagerView` pattern. The UX intent (open the habit) is preserved.
- **Files modified:** `HabitsTracker/Features/Rules/RuleDetailView.swift`
- **Commit:** `a39abc9`

## Known Stubs

- `RuleDetailView.swift` line ~117: `// TODO(02-03): present HabitCreateSheet(source: .rule(rule))` — "Stem habit" button is present but `.disabled(true)`. 02-03 removes the disable and attaches the real `HabitCreateSheet` sheet.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes. The `sourceURL` → `openURL` path was already modeled in the threat register (T-0202-02, disposition: accept — user's own stored URL handed to the system browser on explicit tap only).

---
*Phase: 02-rules-b*
*Completed: 2026-07-05*
