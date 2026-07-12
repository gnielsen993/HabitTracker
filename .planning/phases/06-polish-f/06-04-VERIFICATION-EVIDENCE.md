---
phase: 06-polish-f
plan: 04
type: verification-evidence
requirements: [POL-01, POL-02, POL-03, POL-04]
status: approved
---

# Phase 6 (polish-f) — Owner Device Verification Evidence

Records the automated pre-checkpoint gate (Task 1) and the device checklist the owner
confirms in Task 2. Phase 6 closes when the owner types "approved".

## Task 1 — Automated pre-checkpoint gate (run 2026-07-11)

### Build
- Command: `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build`
- **Result: exit 0** ✓ (the `IDERunDestination … empty` line is benign xcodebuild noise, not a failure)

### Runnable test tier (§9.7)
- `EngineTests` + `CollectionRollupEngineTests` (non-`@Model`, non-parallel): **exit 0** ✓
- `ExportImportTests` (all-types-in-one-bundle + malformed-import-safety, added by 06-03):
  build-verify-only on this toolchain — SwiftData `@Model` persistence suites crash the
  iOS 26 simulator host at 0.000s (§9.7). **Actual execution is the SC3 device step below.**

### Regression sweeps on Phase-6 surfaces
Files: `SearchResultsView.swift`, `HubView.swift`, `CollectionItemRow.swift`, `SettingsView.swift`
- `print(` / `debugPrint(` sweep (§9.13): **clean — none found** ✓
- Hardcoded color-literal sweep (§1/§9.4): **clean — no raw `Color(...)` literals** ✓

## Task 2 — Owner device checklist (confirm on physical iPhone / device runtime, NOT the sim)

- [x] **SC1 — Search (POL-01):** Hub tab → tap magnifying glass (expands inline, iOS 26 minimize) →
      type a multi-type term → results grouped one section per type (Habits/Rules/Collections/Clips/Ideas).
      Rule/Collection/Clip result **pushes** its detail; Idea opens IdeaCaptureSheet; Habit opens
      HabitEditorView (must NOT jump to Today). Archived/consumed items absent.
- [x] **SC2 — Empty states (POL-02):** gibberish query → search no-results state renders. Spot-check
      Hub empty state, a domain's empty section, inbox empty state still render.
- [x] **SC3 — Export/import round-trip (POL-03):** Settings → Export JSON → save. Change/delete data →
      Import JSON (Replace) → all types return intact (domains, habits, rules, collections+items with
      status, clips, ideas). Garbage-file import fails gracefully WITHOUT wiping data.
- [x] **SC4 — Accessibility + schema row (POL-04):** VoiceOver on → Collection items → status chip is
      REACHABLE, announces current status AND advances (previously silent). Settings → About shows
      "Data schema v6" and "Version 1.0". Dynamic Type large size sane on chips/Hub grid.
- [x] **Baseline DoD:** Today unchanged, tab bar still 4 tabs, no debug/placeholder strings.

## Owner sign-off
**APPROVED** by owner (Gabe) on 2026-07-11. SC1–SC4 + baseline DoD confirmed on device. Phase 6 closed.
