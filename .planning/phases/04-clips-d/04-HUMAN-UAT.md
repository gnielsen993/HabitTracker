---
status: resolved
phase: 04-clips-d
source: [04-VERIFICATION.md]
started: 2026-07-09T23:57:48Z
updated: 2026-07-10T00:00:00Z
---

## Current Test

[all tests complete — owner approved 2026-07-10]

## Tests

### 1. 04-01 Task 3 — Schema upgrade test (Phase-3 store → Phase-4 build)
expected: Old Phase-3 app builds data (domains/habits/rules/collections/history); new build (with Clip @Model) installs OVER that store; app launches without crashing; all prior data intact; Clip type present but empty. `xcrun simctl spawn booted launchctl list | grep -i habits` shows a PID > 0.
result: PASSED (automated, 2026-07-09) — verified via the simctl real-app migration procedure with a sentinel control. Built pre-Clip app from f8d6cf6, seeded 16 domains/10 habits/2 collections, injected a domain renamed `SENTINEL_MIGRATION_9Z7Q` (unreproducible by seed), installed the with-Clip build OVER the store, launched (PID alive, no crash). The sentinel + all 16 domains survived; `ZCLIP` table added, 0 rows. Evidence: `04-UPGRADE-TEST-EVIDENCE.md`. Owner may re-confirm on a physical device if desired, but this is no longer a blocking gap.

### 2. 04-05 Task 2 — Full Clips flow + offline gate + export/import round-trip (device)
expected: |
  (1) A focused domain with 0 clips shows NO Clips section.
  (2) The section-header "+" opens ClipEditorView pre-scoped to the domain; pasting a URL auto-suggests a Title (D-02); typing a Title by hand stops further URL-driven overwrites; Save disabled until Title + URL are both non-empty.
  (3) After save, a Clips section appears with the new row: title, tag caption, "Saved" status chip.
  (4) Tapping the row's status chip flips Saved↔Acted WITH haptic feedback and WITHOUT navigating into the detail view (confirms the WR-01 NavigationLink-gesture-priority fix works with real touch).
  (5) Tapping the row pushes ClipDetailView: full-width "Open Link" CTA opens Safari (never fetches), tap-toggle status chip, tag pill, note block, Edit → ClipEditorView prefilled, Delete Clip → "Delete this clip?" confirm dialog.
  (6) OFFLINE GATE (SC1/D-01): Airplane Mode ON — create a clip and open its link; confirm it works fully offline with NO spinner/preview/thumbnail ever appearing.
  (7) EXPORT/IMPORT (D-13, RC smoke §6): Settings → export a backup; delete the clip(s) or erase+reinstall; import the backup → clip returns with title/url/note/tag/status intact, still filed under the right domain.
  (8) ACCESSIBILITY (§9.15): VoiceOver reads the composed row label and the status chip is reachable as a distinct Button (confirms WR-04); Dynamic Type at large sizes does not clip the 2-line row title. Today tab unchanged; 4-tab structure holds.
result: PASSED (owner device verification, 2026-07-10) — full Clips flow confirmed on iPhone 17: create with title-suggestion, in-row status chip toggles saved↔acted without navigating, detail Open Link opens Safari (no fetch), edit/delete-confirm, offline gate holds under Airplane Mode (no spinner/preview), export→wipe→import round-trip restores clips intact, section hides when empty, Today unchanged.

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
