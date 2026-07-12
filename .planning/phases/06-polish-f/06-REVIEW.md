---
phase: 06-polish-f
reviewed: 2026-07-12T04:28:33Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - HabitsTracker/Features/Hub/SearchResultsView.swift
  - HabitsTracker/Features/Hub/HubView.swift
  - HabitsTracker/Features/Ideas/InboxView.swift
  - HabitsTracker/Features/Collections/CollectionItemRow.swift
  - HabitsTracker/Features/Settings/SettingsView.swift
  - HabitsTracker/Services/ExportImportService.swift
  - HabitsTrackerTests/ExportImportTests.swift
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues_found
---

# Phase 6: Code Review Report

**Reviewed:** 2026-07-12T04:28:33Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Reviewed all 7 files changed in Phase 6 (cross-domain search, Collections VoiceOver fix, Settings About row, and export/import round-trip tests) against CLAUDE.md §1 (design tokens), §4 (coding standards), §9.1–§9.16 (session-derived rules), and the plan summaries' stated decisions (D-01..D-15).

**No critical/blocker issues found.** The implementation is careful and defensively coded: no force-unwraps, no `print()`, no hardcoded colors/tokens in the new code, safe subscripting on `StatusSet.states`, and the export/import safety property (decode + schema guard strictly before `deleteAll`) is real and correctly verified by the new tests. `ExportImportService.schemaVersion` → `static let currentSchemaVersion` is confirmed cosmetic (value unchanged at 6, both internal call sites updated) — no accidental behavior change.

One real (if minor) accessibility-correctness regression was found in `CollectionItemRow`'s new VoiceOver hint (WARNING), plus two doc-comment/doc-drift accuracy issues (INFO). Cross-checked against sibling patterns (`ClipRow`, `RuleRow`, `CollectionRow`) to confirm findings are genuinely introduced by this phase's diff and not pre-existing conventions.

## Warnings

### WR-01: CollectionItemRow's advance-chip accessibilityHint is misleading at the terminal status

**File:** `HabitsTracker/Features/Collections/CollectionItemRow.swift:89`
**Issue:** The new `.accessibilityHint("Advances to the next status")` (added in this phase, commit `dd77e59`, to close the VoiceOver-reachability gap) is a static string that does not account for the terminal-clamp behavior already implemented two lines above it:
```swift
let newIndex = min(item.statusIndex + 1, terminalIndex)
if item.statusIndex != newIndex {
    item.statusIndex = newIndex
}
```
When `item.statusIndex == terminalIndex`, activating the Button is a no-op (no state change), yet VoiceOver still announces "Advances to the next status" every time, and `sensoryFeedback` still fires (haptic confirms "something happened" — D-08's documented behavior). A VoiceOver user at the terminal status has no way to know from the hint or from feedback that the item is already at its final state; they'll keep tapping believing it's still advancing. Contrast with `ClipRow.statusChip` (`Features/Clips/ClipRow.swift:68`), whose hint ("Toggles between saved and acted") is accurate on every tap because that chip is a true two-state toggle with no terminal state — so this is not an existing app-wide convention being mirrored, it's a new inaccuracy specific to the terminal-clamped chip.
**Fix:** Make the hint state-aware, e.g.:
```swift
.accessibilityHint(item.statusIndex >= terminalIndex
    ? "Already at the final status"
    : "Advances to the next status")
```
(`statusIndex` and `terminalIndex` are already in scope in `statusChip(theme:statusLabel:terminalIndex:)`.)

## Info

### IN-01: ExportImportTests.swift top-of-file doc comment is stale after this phase's additions

**File:** `HabitsTrackerTests/ExportImportTests.swift:7`
**Issue:** The file-level doc comment says "so all four tests exercise a v6 round-trip" and only documents `testV3FieldsSurviveRoundTrip` / `testV4FieldsSurviveRoundTrip` / `testV5FieldsSurviveRoundTrip` / `testV6IdeaFieldsSurviveRoundTrip`. This phase (06-03) added two more tests (`testAllTypesSurviveRoundTripV6`, `testMalformedAndUnsupportedImportPreservesStore`) that are not mentioned in that summary line, so the "four tests" count and the enumerated list are now inaccurate — a maintainer skimming the header will miss that two more tests exist.
**Fix:** Update the header comment's count/enumeration to reflect all 6 tests, or move the count claim out entirely and let each test's own doc comment (already present and accurate for the two new tests) stand alone.

### IN-02: SearchResultsView's file doc comment overclaims uniform archived/consumed filtering across all six queries

**File:** `HabitsTracker/Features/Hub/SearchResultsView.swift:9`
**Issue:** The doc comment states the six `@Query`s "each already exclud[e] archived/consumed items (D-06) at the `#Predicate` level." In practice only 4 of the 6 do (`habits`, `rules`, `clips`, `ideas`); the `collections` (line 29) and `collectionItems` (line 32) queries carry no predicate at all. This is functionally correct — `Collection`/`CollectionItem` have no `isArchived`/consumed concept in their model — but the comment's "each" is misleading and could cause a future maintainer to assume archived-collection filtering exists when it doesn't (e.g., if an archival concept is later added to `Collection`, this comment gives false confidence that search already handles it).
**Fix:** Reword to something like: "the four queries for types that carry an archived/consumed concept (Habit, Rule, Clip, Idea) exclude those at the `#Predicate` level; Collection/CollectionItem have no such concept and are unfiltered."

---

_Reviewed: 2026-07-12T04:28:33Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
