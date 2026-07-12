---
phase: 06-polish-f
plan: 02
subsystem: ui
tags: [accessibility, voiceover, swiftui, dynamic-type, settings, schema-visibility]

# Dependency graph
requires:
  - phase: 06-polish-f (06-01)
    provides: Cross-domain search + HubView/SearchResultsView, DomainDetailView empty-state confirmation
provides:
  - VoiceOver-reachable Collections tap-to-advance chip (Button + label + hint, matching ClipRow)
  - Settings "About" section surfacing app version + data schema version from a single source of truth
  - Tokens/Dynamic-Type verify sweep across chips/buttons/Hub grid (D-09 fix-as-found, clean)
affects: [06-03, 06-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "VoiceOver-reachable status chip: Button (not .onTapGesture) + .accessibilityLabel(current status) + .accessibilityHint(advance outcome) + named .accessibilityAction for secondary actions, keyed sensoryFeedback via a tapCounter @State"
    - "Readable service constants: static let over private let when a view needs to read a service's source-of-truth value without duplicating a literal"

key-files:
  created: []
  modified:
    - HabitsTracker/Features/Collections/CollectionItemRow.swift
    - HabitsTracker/Features/Settings/SettingsView.swift
    - HabitsTracker/Services/ExportImportService.swift

key-decisions:
  - "CollectionItemRow's advance chip converted from .onTapGesture-on-DKBadge to a Button, matching ClipRow's reachable-chip template exactly (D-10) — card-level accessibilityElement(children: .ignore) removed in favor of a combined text-block element + separately reachable chip Button, so VoiceOver users can both hear and activate the advance"
  - "Reset stays reachable two ways: the existing long-press contextMenu, plus a named .accessibilityAction('Reset status') now attached to the chip Button itself (previously it was a card-level action, which no longer exists as a single element)"
  - "ExportImportService.schemaVersion became a static let currentSchemaVersion (readable, unchanged value 6) rather than adding a duplicate Settings-side literal or a bump — schema stays 6 per D-15 (read-only display change only)"
  - "Settings About section placed after Backup, LabeledContent rows for Version (CFBundleShortVersionString) and Data schema (vN), no new screen or DesignKit component per D-13"

patterns-established:
  - "Reachable-chip pattern is now applied consistently across both status-chip surfaces in the app (ClipRow, CollectionItemRow) — future status-chip work should follow the same Button + label + hint shape"

requirements-completed: [POL-04]

# Metrics
duration: 4min
completed: 2026-07-12
---

# Phase 06 Plan 02: Collections VoiceOver fix + Settings schema/version visibility Summary

**Fixed the silent-VoiceOver Collections tap-to-advance chip (converted to a reachable Button with label+hint, mirroring ClipRow) and added a read-only Settings "About" section surfacing app version + data schema version from a single source of truth.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-12T02:49:27Z
- **Completed:** 2026-07-12T02:52:23Z
- **Tasks:** 2 completed
- **Files modified:** 3

## Accomplishments
- Collections status chip is now a VoiceOver-reachable `Button` (not a bare `.onTapGesture`), exposing current status via `.accessibilityLabel` and the advance outcome via `.accessibilityHint` — closes a real correctness bug (D-10), not cosmetic polish
- Reset stays reachable both via the long-press context menu and a named VoiceOver `.accessibilityAction`
- Settings gained a read-only "About" section showing `Version` (from `CFBundleShortVersionString`) and `Data schema` (from `ExportImportService.currentSchemaVersion`) — closes the pre-existing "Next 3" schema/version visibility debt (D-13)
- Tokens/Dynamic-Type verify sweep across CollectionItemRow, ClipRow, IdeaRow, HubView found zero hardcoded colors (D-09 fix-as-found, scope held to the enumerated set)

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix CollectionItemRow tap-to-advance chip for VoiceOver (D-10 priority)** - `dd77e59` (fix)
2. **Task 2: Settings About row (schema + version) + tokens/Dynamic-Type verify sweep** - `889f060` (feat)

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified
- `HabitsTracker/Features/Collections/CollectionItemRow.swift` - Advance chip is now a `Button` with `.accessibilityLabel`/`.accessibilityHint`/named `.accessibilityAction`; title block is its own `.accessibilityElement(children: .combine)`; card-level `.accessibilityElement(children: .ignore)` removed
- `HabitsTracker/Features/Settings/SettingsView.swift` - New `Section("About")` with `Version` and `Data schema` `LabeledContent` rows
- `HabitsTracker/Services/ExportImportService.swift` - `schemaVersion` (private `let`) became `static let currentSchemaVersion` (readable, value unchanged at 6); both internal use sites (`exportData`, `importReplace`) updated to `Self.currentSchemaVersion`

## Decisions Made
- Reachable-chip conversion followed ClipRow's existing template exactly rather than inventing a new shape (§4 reuse-existing-patterns) — the only material choice was where the "Reset status" `.accessibilityAction` moves once the card-level `.accessibilityElement(children: .ignore)` disappears; it now lives on the chip Button alongside the label/hint, keeping it reachable in the same VoiceOver rotor gesture as before.
- `ExportImportService.schemaVersion` exposed as `static let` rather than instance `var`/computed property — no instantiation needed for `SettingsView` to read it, and it is genuinely a compile-time constant, not per-instance state.

## Deviations from Plan

None - plan executed exactly as written. The tokens/Dynamic-Type verify sweep (Task 2, D-09) found no hardcoded colors, so no fix was needed there.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- POL-04 requirement satisfied for this plan's scope (chip a11y fix + About row + tokens sweep). Full VoiceOver-on-device confirmation of chip reachability is deferred to the Wave-2 owner plan (06-04) per this plan's `<verification>` section.
- No blockers for 06-03/06-04.

---
*Phase: 06-polish-f*
*Completed: 2026-07-12*

## Self-Check: PASSED

All created/modified files verified present on disk; all task commits (dd77e59, 889f060) and the summary commit (090a46f) verified present in git log.
