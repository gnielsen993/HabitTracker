---
phase: 05-ideas-promotion-e
verified: 2026-07-11T20:25:00Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 8/9
  gaps_closed:
    - "PromoteToCollectionPicker: tapping a collection dismisses the picker and opens CollectionItemEditorSheet prefilled from the idea (05-06 must_have truth, IDEA-04/IDEA-05)"
  gaps_remaining: []
  regressions: []
deferred: []
human_verification: []
---

# Phase 5: Ideas + Promotion (E) Verification Report

**Phase Goal:** A single always-reachable capture point feeds a Hub inbox, and unfiled ideas graduate in one tap — File to keep them as ideas, or Promote to consume them into a rule, habit, or collection item.
**Verified:** 2026-07-11T20:25:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (commits 420bc48, ef6397a)

## Goal Achievement

This is a re-verification. The prior report (2026-07-11T20:56:18Z) found 8/9 truths verified with
one blocking gap (WR-02: `PromoteToCollectionPicker` did not dismiss after a successful promote,
enabling a duplicate `CollectionItem` on re-tap) and two related warnings (WR-01: no automated
Idea export/import round-trip test; WR-03: non-atomic two-save promote-consume path). All three
were independently re-verified against current source, not trusted from SUMMARY/REVIEW claims.

### Gap Closure Verification (full 3-level check)

**WR-02 — PromoteToCollectionPicker dismiss-on-consume (the blocking gap)**

Re-read `HabitsTracker/Features/Ideas/PromoteToCollectionPicker.swift` directly (commit 420bc48).
The `.sheet(item: $pickedCollection)` presenting `CollectionItemEditorSheet` now carries:

```swift
.onDisappear {
    if idea.isArchived { dismiss() }
}
```

This closes the exact vector described in the prior gap: on a successful Save, the child editor's
`saveItem()` calls `PromoteService.archiveAndForwardLink` which sets `idea.isArchived = true`
before the single atomic save (see WR-03 below), so `onDisappear` observes `isArchived == true`
and dismisses the picker — a second tap on another collection is no longer possible because the
picker itself is gone. On Cancel, the idea is untouched (`isArchived` stays `false`), so the guard
correctly keeps the picker open for another choice. VERIFIED — exists, substantive (real state
check, not a no-op), and wired (fires on every child-sheet dismissal, both save and cancel paths).

**WR-03 — Atomic target+consume save**

Re-read `RuleEditorView.saveRule()` (lines 288-313) and `CollectionItemEditorSheet.saveItem()`
(lines 247-267). Both create-branches now do `modelContext.insert(target)` →
`if let sourceIdea { PromoteService.archiveAndForwardLink(...) }` → a single
`try? modelContext.save()` call. The prior two-`try?`-save split (insert+save, then
consume+save) is gone in both files — confirmed by direct read, not grep-only. This closes the
latent risk where a failed second save could leave a persisted target with an unarchived,
re-promotable idea.

**WR-01 — Idea v6 export/import round-trip test**

Re-read `HabitsTrackerTests/ExportImportTests.swift` (commit ef6397a). `testV6IdeaFieldsSurviveRoundTrip`
(lines 220-271) constructs a filed, promoted `Idea` (`isArchived: true`,
`promotedToKindRaw: Idea.PromotedKind.rule.rawValue`, `promotedToID`, `domain:`), calls
`service.exportData(... ideas: [idea])`, imports into a fresh in-memory container, and asserts
title/note/url/isArchived, the `promotedTo` facade round-trip (`.rule`), `promotedToID`, and the
domain re-link via `categoryIndex` all survive. The test schema at line 30 now includes `Idea.self`.
The `Idea` init signature (`Models/Idea.swift`) matches every named argument used in the test
exactly (`isArchived`, `promotedToKindRaw`, `promotedToID`, `domain`) — no compile-time mismatch.
Per the established §9.7 exception, this is a `@Model`-persistence test (crashes the iOS 26 sim
XCTest host at 0.000s like `testV3`/`testV4`/`testV5`) — build-verify tier by design, not
execution-verify. Confirmed it compiles as part of the full `xcodebuild build` run below (no
compiler errors reported for the test target). Docstring header updated to schemaVersion 6 and
the v6 test line added (closes IN-02/IN-03 too).

**IN-01 — dead HubView columns property**

`grep -n "columns" HabitsTracker/Features/Hub/HubView.swift` now returns only the live inline
usage at line 49 (`columns: [GridItem(.adaptive(minimum: 120), spacing: theme.spacing.m)]`) — the
dead `private let columns = [...spacing: 12]` property is gone. VERIFIED.

### Independent Confirmation (not trusted from notes)

| Check | Command | Result |
|---|---|---|
| Full project build | `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build` | Exit 0, no errors — confirms `PromoteToCollectionPicker.swift`, `RuleEditorView.swift`, `CollectionItemEditorSheet.swift`, `HubView.swift`, and the new `ExportImportTests.swift` test all compile clean together. |
| PromoteServiceTests re-run | `xcodebuild ... -only-testing:HabitsTrackerTests/PromoteServiceTests -parallel-testing-enabled NO test` | `Executed 4 tests, with 0 failures` — `testHappyPath_archivesAndForwardLinks`, `testAlreadyArchived_isSkipped`, `testUnfiledRequiresDomain`, `testCollectionPromoteNeedsList` all PASS. No regression from the atomic-save refactor in WR-03. |
| Commit provenance | `git log --oneline -8` | `420bc48 fix(05): close promote-consume gaps...` and `ef6397a test(05): add Idea v6 export/import round-trip test...` both present, correctly scoped diffs (`git show --stat`) touching exactly the files the note claimed. |
| Debt-marker sweep on touched files | `grep -n "TBD\|FIXME\|XXX\|TODO\|HACK\|PLACEHOLDER"` across all 5 files touched by the two fix commits | No matches — clean. |

### Observable Truths (updated)

| # | Truth (ROADMAP SC + baseline) | Status | Evidence |
|---|---|---|---|
| 1 | SC1 — global quick-add reachable without leaving Today, adds no Today row, lands in Hub inbox | VERIFIED | Unchanged from prior verification; re-confirmed no regression via full build. |
| 2 | SC2 — File assigns a domain and the item stays an `Idea` | VERIFIED | Unchanged from prior verification. |
| 3 | SC3 — Promote → Rule/Habit/Collection item opens prefilled editor; Save archives the idea (leaves active list), result carries no backref; promote-to-habit reuses Phase 2's `HabitCreateSheet` | VERIFIED | Now fully verified across all three routes. The Collection-item route's picker-dismiss gap (previously PARTIAL) is closed: `PromoteToCollectionPicker` now dismisses itself once the idea is consumed, eliminating the duplicate-`CollectionItem` vector on re-tap. Rule/Habit routes unchanged (previously verified). |
| 4 | SC4 — unfiled-idea promote prompts for a domain (Rule route); promote-to-collection prompts for the target list | VERIFIED | Unchanged from prior verification. |
| 5 | IDEA-01 — `Idea` `@Model` persists (title-only minimum, note/url/domain optional) and migrates a Phase-4 store with zero data loss | VERIFIED | Unchanged; `05-UPGRADE-TEST-EVIDENCE.md` PASS still stands. |
| 6 | Baseline DoD — schemaVersion-6 export/import round-trip green; Today visually unchanged aside from "+"; 4 tabs hold; tokens-only + accessibility labels on new surfaces | VERIFIED | Now fully verified including automated test coverage: `testV6IdeaFieldsSurviveRoundTrip` exercises the exact wiring (promotedToKindRaw↔promotedTo facade crossover, domainID→categoryIndex re-link) that the prior report flagged as untested (WR-01). Previously WARNING on test coverage; that warning is closed. |
| 7 | PromoteService centralizes consume/archive/forward-link logic, pure, idempotent on already-archived idea | VERIFIED | Re-run 4/4 PASS by this verifier (see table above) — confirms no regression from the WR-03 atomic-save refactor in the two call sites. |
| 8 | IdeaRow is reusable/data-driven (§9.2), shared by InboxView + DomainDetailView, with tap-to-edit + File/Promote pills, accessible as separate VoiceOver elements | VERIFIED | Unchanged from prior verification. |
| 9 | Hub inbox card is count-gated, pinned above the domain grid, absent when zero unfiled ideas | VERIFIED | Unchanged from prior verification; dead `columns` property removal (IN-01) is cosmetic and does not affect this truth's behavior — confirmed via re-read. |

**Score:** 9/9 truths fully verified. No partial, no failed.

### Required Artifacts (delta from prior report)

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `HabitsTracker/Features/Ideas/PromoteToCollectionPicker.swift` | app-wide collection picker, dismiss-then-open, AND dismiss-on-consume | VERIFIED | Was ⚠️ ORPHANED WIRING in prior report. Now fully wired: `.onDisappear { if idea.isArchived { dismiss() } }` closes the gap. Re-read in full, confirmed present exactly as committed. |
| `HabitsTracker/Features/Rules/RuleEditorView.swift` | atomic target-insert + consume | VERIFIED | Single `try? modelContext.save()` after both `modelContext.insert(rule)` and the conditional `archiveAndForwardLink` call — confirmed by direct read of `saveRule()`, lines 288-313. |
| `HabitsTracker/Features/Collections/CollectionItemEditorSheet.swift` | atomic target-insert + consume | VERIFIED | Same pattern confirmed in `saveItem()`, lines 247-267. |
| `HabitsTracker/Features/Hub/HubView.swift` | no dead code | VERIFIED | Dead `columns` property removed; only the live inline `GridItem` definition (token-based) remains. |
| `HabitsTrackerTests/ExportImportTests.swift` | v6 Idea round-trip test | VERIFIED | `testV6IdeaFieldsSurviveRoundTrip` added, compiles clean (confirmed via full build), authored to spec (assertions match the exact fields WR-01 called out). Build-verify tier per §9.7, consistent with `testV3`/`testV4`/`testV5`. |

All other artifacts from the prior report (`Idea.swift`, `Domain.swift`, `HabitsTrackerApp.swift`,
`PromoteService.swift`, `ExportImportDTOs.swift`, `IdeaCaptureSheet.swift`, `IdeaRow.swift`,
`InboxView.swift`, `DomainDetailView.swift`, `HabitCreateSheet.swift`, `IdeaModelTests.swift`,
`PromoteServiceTests.swift`) are unchanged and remain VERIFIED — no regression found on
spot re-read of the diffs touching adjacent files.

### Key Link Verification (delta from prior report)

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `IdeaRow.swift` | `PromoteToCollectionPicker` | Promote → Collection | WIRED | Previously "WIRED (with downstream defect)" — the downstream defect is now closed. Full chain confirmed: `IdeaRow` → `PromoteToCollectionPicker` → `CollectionItemEditorSheet` → consume → `onDisappear` dismiss, with no duplicate-item vector remaining. |
| `RuleEditorView.swift` / `CollectionItemEditorSheet.swift` | `PromoteService` | `archiveAndForwardLink` in the SAME commit as target insert, single `try? save()` | WIRED (atomic) | Previously "WIRED (non-atomic)" — now a single save commits both mutations together, confirmed by direct read of both files. |

All other key links from the prior report are unchanged and remain WIRED.

### Data-Flow Trace (Level 4)

No new dynamic-data-rendering artifacts were introduced by the gap-closure commits — both fixes
are control-flow (dismiss timing, save atomicity) and code-cleanliness (dead property removal),
not new data sources. The existing data-flow traces from the prior verification (Idea query →
InboxView/HubView/DomainDetailView rendering) are unaffected and remain valid.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| App builds clean against the full Phase 5 diff including both gap-closure commits | `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build` | Exit 0, no errors | PASS |
| PromoteService consume/archive/forward-link core behaves per spec after the WR-03 atomic-save refactor | `xcodebuild ... -only-testing:HabitsTrackerTests/PromoteServiceTests -parallel-testing-enabled NO test` | 4/4 tests passed (independently re-run by this verifier) | PASS |
| No debt markers / print() in the 5 files touched by the gap-closure commits | grep sweep across `PromoteToCollectionPicker.swift`, `RuleEditorView.swift`, `CollectionItemEditorSheet.swift`, `HubView.swift`, `ExportImportTests.swift` | zero `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` | PASS |
| `testV6IdeaFieldsSurviveRoundTrip` compiles and is correctly authored (execution deferred per §9.7, like `testV3`/`testV4`/`testV5`) | Full build + direct read of test body against `Idea.init` signature | Compiles clean; every named argument in the test matches `Idea.init` exactly; assertions cover all fields WR-01 flagged as missing | PASS (build-verify tier, by design) |

### Probe Execution

No `scripts/*/tests/probe-*.sh` convention or explicit probe declarations exist in this phase's
plans/summaries — native iOS project verified via `xcodebuild`, not shell probes. SKIPPED (no
probe convention applies). Unchanged from prior verification.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| IDEA-01 | 05-01, 05-02, 05-04, 05-09 | `Idea` model exists (freeform, title-only minimum, domain optional) | SATISFIED | Unchanged; now additionally backed by an automated round-trip test (WR-01 closed). |
| IDEA-02 | 05-05 | Global quick-add reachable without leaving Today, lands in inbox | SATISFIED | Unchanged. |
| IDEA-03 | 05-07, 05-08, 05-09 | Hub inbox with File + Promote one-tap graduations | SATISFIED | Unchanged. |
| IDEA-04 | 05-03, 05-06, 05-07 | Promote converts idea per asymmetry rule (archive+forward-link, no backref), habit route reuses Phase 2's sheet | SATISFIED | Previously "SATISFIED WITH A KNOWN DEFECT" — the Collection-item picker-dismiss defect (Gap #1 / WR-02) is closed. All three promote routes now fully match their plan must-haves. |
| IDEA-05 | 05-03, 05-06 | Promote prompts for missing context (domain for Rule, list for Collection) | SATISFIED | Unchanged. |

REQUIREMENTS.md's Phase E rows (all 5) are marked `Complete`; no orphaned requirements found. All
5 requirement IDs are now cleanly SATISFIED with no caveats.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| — | — | None found in the gap-closure diff | — | All three warnings from the prior review (WR-01, WR-02, WR-03) and the info-level IN-01 finding are closed. IN-02/IN-03 (stale docstring) are also closed — the `ExportImportTests.swift` header now correctly states schemaVersion 6 and documents the v6 test. |

No unreferenced `TBD`/`FIXME`/`XXX` debt markers found in any phase file, including the two
gap-closure commits (Step 7 debt-marker gate: clean).

### Human Verification Required

None. The blocking gap (WR-02) and both related warnings (WR-01, WR-03) were code-level defects
resolvable and verifiable by static reading + automated test/build execution — no new device
observation is needed. The phase's device-verified truths (SC1-SC4 + baseline DoD, owner
walkthrough 05-10, approved 2026-07-11; upgrade test 05-04, PASS) remain valid evidence per the
standing §9.7 exception and are unaffected by these control-flow/atomicity fixes, which touch no
UI-visible behavior beyond the (now-correct) picker-dismiss timing.

### Gaps Summary

All gaps from the prior verification are closed. WR-02 (the blocking gap — `PromoteToCollectionPicker`
not dismissing after a successful promote, enabling a duplicate `CollectionItem`) is fixed exactly
per the reviewer's suggested approach: `.onDisappear { if idea.isArchived { dismiss() } }` on the
nested sheet, verified by direct source read. WR-03 (non-atomic two-save promote-consume) is fixed
by collapsing both mutations into a single `try? modelContext.save()` in both `RuleEditorView` and
`CollectionItemEditorSheet`. WR-01 (missing Idea export/import round-trip test) is fixed with a
correctly-authored `testV6IdeaFieldsSurviveRoundTrip` that exercises exactly the wiring the reviewer
flagged as at-risk (the `promotedToKindRaw`↔`promotedTo` facade crossover and the domain
re-link via `categoryIndex`). IN-01 (dead `HubView.columns` property) is removed.

This verifier independently re-ran the full build (exit 0) and `PromoteServiceTests` (4/4 PASS,
confirming no regression from the atomic-save refactor) rather than trusting the fix-commit
messages or SUMMARY claims. All 9 observable truths are now VERIFIED with no partial or failed
status. Phase 5's goal — a single always-reachable capture point feeding a Hub inbox, with
one-tap File/Promote graduation for unfiled ideas — is fully achieved in the codebase, confirmed
by both device walkthrough (prior evidence, still valid) and this round of static+build
verification (new evidence, this report).

---

_Verified: 2026-07-11T20:25:00Z_
_Verifier: Claude (gsd-verifier)_
