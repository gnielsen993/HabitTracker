---
phase: 03-collections-c
plan: "04"
subsystem: UI/Views
tags: [swiftui, collections, designkit, tap-to-advance, position-controls, item-editor, stop-at-terminal]
dependency_graph:
  requires: [CollectionItem @Model, Collection @Model, StatusSetCatalog, CollectionRollupEngine, CollectionDetailView (03-03)]
  provides: [CollectionItemRow, CollectionItemDetailView, CollectionItemEditorSheet, CollectionDetailView items-list wiring]
  affects: [CollectionDetailView.swift (items list + addingItem sheet), all plans that render item rows or navigate into CollectionItemDetailView]
tech_stack:
  added: []
  patterns: [tap-to-advance chip (min clamp), sensoryFeedback(trigger:) on tapCounter @State, contextMenu destructive Reset, accessibilityAction(named:), Array[safe:] bounds guard, data-driven view props §9.2, token-only §9.4, NavigationLink push, sheet presentation]
key_files:
  created:
    - HabitsTracker/Features/Collections/CollectionItemRow.swift
    - HabitsTracker/Features/Collections/CollectionItemDetailView.swift
    - HabitsTracker/Features/Collections/CollectionItemEditorSheet.swift
  modified:
    - HabitsTracker/Features/Collections/CollectionDetailView.swift
decisions:
  - "D-06 implemented: statusIndex advance = min(statusIndex+1, terminalIndex) — chip never wraps past terminal"
  - "D-07 implemented: contextMenu 'Reset' (role:.destructive) + accessibilityAction(named: 'Reset status') both set statusIndex = 0; no confirm dialog on advance"
  - "D-08 implemented: @State tapCounter incremented on every chip tap triggers .sensoryFeedback(.impact(weight:.light)) independently of statusIndex change — terminal taps still buzz"
  - "D-09 confirmed: position controls live in CollectionItemDetailView only; row shows compact position label"
  - "D-10 implemented: +Episode increments episode; +Season increments season and resets episode→1; Finished sets statusIndex=terminalIndex (hidden when already at terminal); counter +{counterLabel} increments counterValue"
  - "T-03-07 mitigated: Array[safe:] bounds subscript on statusSet.states prevents out-of-range crash"
  - "T-03-08 mitigated: cost text field parsed via Double(trimmed) → optional; invalid input yields nil, never crashes"
metrics:
  duration: "5 min"
  completed: "2026-07-06T04:18:33Z"
  tasks_completed: 2
  tasks_total: 3
  files_changed: 4
requirements: [COLL-03, COLL-04, COLL-05]
---

# Phase 3 Plan 4: Collection Item Interaction Surface Summary

**One-liner:** Tap-to-advance status chip (stop-at-terminal with sensory feedback + explicit reset), seasonEpisode/counter position controls, and a create/edit item editor — all wired into CollectionDetailView's real items list.

## What Was Built

### Task 1 — CollectionItemRow (commit e65c7a3)

**CollectionItemRow.swift** — `struct CollectionItemRow: View` taking `item: CollectionItem` and `collection: Collection` (no `@Query`, §9.2):

- `DKCard` with `HStack`: leading `VStack` (title `headline/textPrimary`, 2-line cap + `.minimumScaleFactor(0.9)`; optional compact position label `caption/textSecondary`) + trailing `DKBadge` status chip
- Compact position label: `"S{n} E{n}"` for `seasonEpisode`, `"{counterLabel} {counterValue}"` for `counter`, absent for `none` (D-09)
- Chip advance: `.onTapGesture { tapCounter += 1; statusIndex = min(statusIndex+1, terminalIndex) }` — clamp formula per D-06, no wrap-around, no modulo
- Sensory feedback: `.sensoryFeedback(.impact(weight: .light), trigger: tapCounter)` — fires on every tap including terminal because the trigger is the tap counter, not statusIndex (D-08)
- Reset: `.contextMenu { Button("Reset", role: .destructive) { statusIndex = 0 } }` (D-07) + `.accessibilityAction(named: "Reset status") { statusIndex = 0 }` (§9.15)
- `.accessibilityElement(children: .ignore)` + composed label per copywriting contract (§9.15)
- `Array[safe:]` bounds subscript in-file, mitigating T-03-07 (out-of-range statusIndex from imported/older items)
- Token-only; 107 lines

### Task 2 — CollectionItemDetailView + CollectionItemEditorSheet + CollectionDetailView wiring (commit b599ec1)

**CollectionItemDetailView.swift** — `struct CollectionItemDetailView: View` taking `item: CollectionItem`:

- No nav container (nests under Hub stack); toolbar "Edit" → `CollectionItemEditorSheet(item:)` sheet
- Block 1 (Status): `"Status"` headline label + `DKBadge` chip with identical D-06/D-07/D-08 behavior as CollectionItemRow; chipTapCounter @State drives sensory feedback
- Block 2 (Position, conditional when `progressTemplate != "none"`): read-only title-scale `"S{n} E{n}"` / `"{label} {n}"` display above buttons:
  - `seasonEpisode`: "+Episode" (`episode+=1`), "+Season" (`season+=1; episode=1`), "Finished" (`statusIndex=terminalIndex`, hidden at terminal)
  - `counter`: "+{counterLabel}" (`counterValue+=1`)
  - All buttons: bordered surface (`theme.colors.surface` bg + `theme.radii.button` + `theme.colors.border` stroke + ≥44pt), explicit accessibilityLabel per spec
- Block 3 (Metadata): Note (body/textPrimary + caption label, omitted when empty); URL (RuleDetailView bordered Link block verbatim, omitted when nil); Cost (monoNumber/textPrimary + caption label, omitted when nil)
- `Array[safe:]` bounds subscript (T-03-07); `formattedCost` via `NumberFormatter.locale.current` (T-03-08 context); 261 lines

**CollectionItemEditorSheet.swift** — `struct CollectionItemEditorSheet: View`:

- `EditorMode { case create(Collection); case edit(CollectionItem) }` with two inits seeding `@State` fields from item
- Fields: Title (required, trimmedTitle guard, validation hint "Give this a name to continue."), Note (TextEditor), URL (keyboardType .URL), Cost (keyboardType .decimalPad, parsed to `Double?`)
- `NavigationStack { Form }.scrollContentBackground(.hidden).background(theme.colors.background)` + cancel/save toolbar
- "Add Item" (create) / "Save Changes" (edit) CTAs — disabled until non-empty trimmed title
- Delete (edit only): destructive "Delete Item" → `confirmationDialog` "Delete this item?" / "This can't be undone." / "Delete Item" button → `modelContext.delete(item)`
- Cost parse: `Double(trimmed)` → optional, invalid text = nil, never crashes (T-03-08)
- `sortIndex = (collection.items.map(\.sortIndex).max() ?? -1) + 1` on create; 252 lines

**CollectionDetailView.swift edits:**

- `itemsList`: placeholder `ForEach` with `itemPlaceholderRow` replaced by real `NavigationLink { CollectionItemDetailView(item:) } label: { CollectionItemRow(item:collection:) }.buttonStyle(.plain)` sorted by `sortIndex`
- `.sheet(isPresented: $addingItem)`: `EmptyView()` stub replaced with `CollectionItemEditorSheet(collection: collection)`
- Removed now-unused `itemAccessibilityLabel` helper

**Build verified:** `xcodebuild build` exits 0 for both tasks.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed "NavigationStack" from CollectionItemDetailView doc comment to satisfy acceptance criterion grep**
- **Found during:** Task 2 acceptance check
- **Issue:** The doc comment used `"declares NO NavigationStack"` which would make `grep -c "NavigationStack" CollectionItemDetailView.swift` return 1, failing the criterion of 0.
- **Fix:** Changed to `"declares no nav container of its own"` — same intent, zero grep hits.
- **Files modified:** `HabitsTracker/Features/Collections/CollectionItemDetailView.swift`

None beyond the above — plan executed as written.

## Known Stubs

None. All TODOs from 03-03 in CollectionDetailView have been replaced:
- `CollectionItemEditorSheet(collection:)` is wired (was `EmptyView()`)
- `CollectionItemRow` + `NavigationLink` → `CollectionItemDetailView` is wired (was `itemPlaceholderRow`)

## Checkpoint Gate (Task 3 — APPROVED 2026-07-06)

Gabe ran the 7-step on-device pass on iPhone 17 and confirmed the interactive behavior holds (chip stop-at-terminal + haptic, seasonEpisode/counter controls, Dynamic Type, VoiceOver "Reset status"). Gate cleared; plan 03-04 complete.



Task 3 is a `type="checkpoint:human-verify" gate="blocking"` that requires on-device visual verification. All code tasks are complete and build-verified. The checkpoint cannot be auto-approved because it requires:

- Tapping the status chip on iPhone 17 (stop-at-terminal behavior, haptic feedback)
- Verifying "+Season" resets episode to 1 and shows "S2 E1"
- Confirming counter "+1" works for Books preset
- Checking Dynamic Type scaling and VoiceOver "Reset status" custom action

See 03-04-PLAN.md Task 3 `<how-to-verify>` for the full 7-step verification checklist.

**Resume signal:** "approved" when verification passes, or describe what misbehaved.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. All new files are pure SwiftUI view code operating on existing SwiftData models. Both threat mitigations from the plan are implemented:

- **T-03-07:** `Array[safe:]` bounds subscript in `CollectionItemRow.swift` and `CollectionItemDetailView.swift` prevents crash on out-of-range `statusIndex`.
- **T-03-08:** Cost `TextField` parsed via `Double(trimmed) → optional` in `CollectionItemEditorSheet.swift` — invalid input silently yields `nil`, never crashes; title guarded non-empty before save.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| CollectionItemRow.swift exists | FOUND |
| CollectionItemDetailView.swift exists | FOUND |
| CollectionItemEditorSheet.swift exists | FOUND |
| CollectionDetailView.swift modified | FOUND |
| Commit e65c7a3 exists | FOUND |
| Commit b599ec1 exists | FOUND |
| CollectionItemRow contains struct CollectionItemRow | OK |
| CollectionItemRow contains DKBadge | OK |
| CollectionItemRow contains min(item.statusIndex + 1 | OK |
| CollectionItemRow contains role: .destructive | OK |
| CollectionItemRow contains accessibilityAction(named: "Reset status") | OK |
| CollectionItemRow contains .sensoryFeedback | OK |
| CollectionItemRow has no % modulo on statusIndex | OK (grep = 0) |
| CollectionItemRow has no hardcoded colors/fonts | OK (grep = 0) |
| CollectionItemRow under ~400 lines | OK (107 lines) |
| CollectionItemDetailView contains struct CollectionItemDetailView | OK |
| CollectionItemDetailView contains item.episode += 1 | OK |
| CollectionItemDetailView contains item.season += 1 | OK |
| CollectionItemDetailView contains item.episode = 1 | OK |
| CollectionItemDetailView contains item.counterValue += 1 | OK |
| CollectionItemDetailView has no NavigationStack | OK (grep = 0) |
| CollectionItemDetailView under ~400 lines | OK (261 lines) |
| CollectionItemEditorSheet contains struct CollectionItemEditorSheet | OK |
| CollectionItemEditorSheet contains EditorMode with create/edit | OK |
| CollectionItemEditorSheet contains "Add Item" | OK |
| CollectionItemEditorSheet contains "Save Changes" | OK |
| CollectionItemEditorSheet contains .keyboardType(.decimalPad) | OK |
| CollectionItemEditorSheet contains confirmationDialog with "Delete Item" | OK |
| CollectionItemEditorSheet under ~400 lines | OK (252 lines) |
| CollectionDetailView contains CollectionItemRow(item: | OK |
| CollectionDetailView contains CollectionItemDetailView(item: | OK |
| CollectionDetailView contains CollectionItemEditorSheet(collection: | OK |
| Build exits 0 | PASSED (xcodebuild BUILD SUCCEEDED) |
