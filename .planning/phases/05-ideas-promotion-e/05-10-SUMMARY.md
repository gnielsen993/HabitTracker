---
phase: 05-ideas-promotion-e
plan: 10
subsystem: verification
tags: [owner-checkpoint, ideas, promote, phase-close]
dependency-graph:
  requires: [05-04, 05-05, 05-07, 05-08, 05-09]
  provides: [phase-05-close-gate]
  affects: [Ideas capture/inbox/File/Promote spine]
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - .planning/phases/05-ideas-promotion-e/05-10-SUMMARY.md
  modified:
    - HabitsTrackerTests/ExportImportTests.swift
decisions:
  - "Fixed a blocking test-target compile error (missing `ideas:` argument in 3 ExportImportTests calls, caused by 05-02's exportData signature change) so PromoteServiceTests could run at all — Rule 3 (auto-fix blocking issue)."
metrics:
  duration: "~15 min"
  completed: "2026-07-11"
---

# Phase 05 Plan 10: Owner Device Verification — Pre-checkpoint Automated Gates Summary

Pre-checkpoint automated gates for the Phase 5 owner device walkthrough: build, PromoteServiceTests, and tokens/print grep sweeps on the Ideas surfaces — all green, clearing the way for the blocking human-verify checkpoint (Task 2).

## What Was Done

### Task 1: Pre-checkpoint automated gates (type=auto)

**Gate 1 — Build.**
```
xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build
```
Result: **exit 0**, clean build. Only warning emitted is the harmless `xcodebuild[...] [MT] IDERunDestination: Supported platforms for the buildables in the current scheme is empty.` (build-tooling noise, not a compile diagnostic).

**Gate 2 — PromoteServiceTests (runnable engine tier, §9.7).**
```
xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:HabitsTrackerTests/PromoteServiceTests -parallel-testing-enabled NO test
```
First attempt failed with `** TEST FAILED **` — not a `PromoteServiceTests` regression, but a whole-test-target **compile error** in `ExportImportTests.swift`: 3 call sites of `ExportImportService.exportData(...)` were missing the `ideas:` argument added when 05-02 bumped the signature to `schemaVersion 6` (`ideas: [Idea]`). Since Xcode must compile the entire `HabitsTrackerTests` target before running any subset of tests, this blocked `PromoteServiceTests` from running even though `PromoteServiceTests.swift` itself was untouched and correct.

Fixed per deviation Rule 3 (auto-fix blocking issue — missing referenced parameter): added `ideas: []` to all three `exportData(...)` calls in `testV3FieldsSurviveRoundTrip`, `testV4FieldsSurviveRoundTrip`, and `testV5FieldsSurviveRoundTrip`. These three tests assert pre-Idea schema fields only, so an empty ideas array is correct and does not change their assertions. (A dedicated schemaVersion-6 Idea round-trip test does not yet exist — out of scope for this gate task; the schemaVersion-6 round-trip is exercised instead as part of the Task 2 owner walkthrough's Baseline DoD step, per the plan's own threat model T-05-01.)

Re-ran after the fix: **`** TEST SUCCEEDED **`**, 4/4 `PromoteServiceTests` green:
- `testAlreadyArchived_isSkipped` — passed (0.003s)
- `testCollectionPromoteNeedsList` — passed (0.002s)
- `testHappyPath_archivesAndForwardLinks` — passed (0.001s)
- `testUnfiledRequiresDomain` — passed (0.001s)

**Gate 3 — Tokens-only + zero-`print(` grep sweeps on the new Ideas surfaces.**

Files swept: `HabitsTracker/Features/Ideas/*.swift` (`IdeaCaptureSheet.swift`, `IdeaRow.swift`, `InboxView.swift`, `PromoteToCollectionPicker.swift`), `HabitsTracker/Services/PromoteService.swift`, `HabitsTracker/Models/Idea.swift`, plus the edited surfaces `TodayView.swift`, `HubView.swift`, `DomainDetailView.swift`, `RuleEditorView.swift`, `HabitCreateSheet.swift`.

- `Color(` sweep: **zero hits** in the new Ideas files. One pre-existing qualified call remains in `DomainDetailView.swift` (`HabitsTracker.accentColor(forToken:scheme:)`, the app-level semantic resolver, not a raw `Color(...)` literal — same pattern used by Rules/Collections/Clips headers, unrelated to this phase's new code).
- `print(` sweep: **zero hits** anywhere in `HabitsTracker/` non-test source (repo-wide, not just the new files) — confirms §9.13 holds.
- Literal-dimension sweep (`.frame(`, `.padding(`, `cornerRadius(`, `.font(.system(size:`) on the new Ideas files: every `.padding(`/spacing value is a `theme.spacing.*` token (`.l`, `.xl`, `.xxl`, `.s`); every literal numeric `.frame(minHeight: 44)` is the documented ≥44pt accessibility tap-target floor, the one allowed non-token dimension per the UI-SPEC's Spacing Scale exception. No stray literal radii or spacing found.
- `.font(.system(size: 18, weight: .semibold))` sweep: the Ideas section-header "+" (`DomainDetailView.swift`) and the new Today toolbar "+" (`TodayView.swift`) both reuse the exact pre-existing house exception already used for Rules/Collections/Clips section headers — matches the UI-SPEC's explicit "reuses this exact pattern, not a new one" instruction, not a new deviation.

All three gates green. Only the owner device walkthrough (Task 2) remains before Phase 5 can close.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Fixed test-target compile error blocking PromoteServiceTests from running**
- **Found during:** Task 1, Gate 2 (first PromoteServiceTests run attempt)
- **Issue:** `HabitsTrackerTests/ExportImportTests.swift`'s 3 `exportData(...)` calls didn't pass the `ideas:` parameter added by 05-02's schemaVersion-6 signature change, failing the whole `HabitsTrackerTests` target's compile step and blocking every test in the target, including the untouched `PromoteServiceTests`.
- **Fix:** Added `ideas: []` to the 3 call sites (`testV3FieldsSurviveRoundTrip`, `testV4FieldsSurviveRoundTrip`, `testV5FieldsSurviveRoundTrip`) — correct since none of those three tests assert Idea-specific fields.
- **Files modified:** `HabitsTrackerTests/ExportImportTests.swift`
- **Commit:** (this plan's Task 1 commit, see below)

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file-access patterns, or schema changes introduced by this plan. This plan is verification-only.

## Self-Check: PASSED

- FOUND: `.planning/phases/05-ideas-promotion-e/05-10-SUMMARY.md`
- FOUND: commit `17abfd8` (`fix(05-10): pre-checkpoint automated gates green ...`)
- No unexpected file deletions in the commit (`git diff --diff-filter=D` empty).

## Task 2 Status

**NOT self-answered.** Task 2 (`checkpoint:human-verify`, `gate="blocking"`) requires the owner's
physical iPhone 17 per §9.7 (the iOS 26 simulator cannot launch this UI/@Model host for a live
walkthrough). Returning the structured checkpoint state to the orchestrator so SC1–SC4 + the
baseline DoD device walkthrough can be handed to the owner (Gabe).
