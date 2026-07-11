---
phase: 05-ideas-promotion-e
reviewed: 2026-07-11T20:51:18Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - HabitsTracker/Models/Idea.swift
  - HabitsTracker/Models/Domain.swift
  - HabitsTracker/HabitsTrackerApp.swift
  - HabitsTracker/Services/PromoteService.swift
  - HabitsTracker/Services/ExportImportDTOs.swift
  - HabitsTracker/Services/ExportImportService.swift
  - HabitsTracker/Features/Settings/SettingsView.swift
  - HabitsTracker/Features/Ideas/IdeaCaptureSheet.swift
  - HabitsTracker/Features/Ideas/IdeaRow.swift
  - HabitsTracker/Features/Ideas/InboxView.swift
  - HabitsTracker/Features/Ideas/PromoteToCollectionPicker.swift
  - HabitsTracker/Features/Today/TodayView.swift
  - HabitsTracker/Features/Habits/HabitCreateSheet.swift
  - HabitsTracker/Features/Rules/RuleEditorView.swift
  - HabitsTracker/Features/Collections/CollectionItemEditorSheet.swift
  - HabitsTracker/Features/Hub/HubView.swift
  - HabitsTracker/Features/Hub/DomainDetailView.swift
  - HabitsTrackerTests/IdeaModelTests.swift
  - HabitsTrackerTests/PromoteServiceTests.swift
  - HabitsTrackerTests/ExportImportTests.swift
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-07-11T20:51:18Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Reviewed the Ideas + promote/consume slice: the new `Idea` @Model, the pure `PromoteService`,
the three promote target editors (Rule/Habit/CollectionItem), the Inbox/Hub UI surfaces, and
the schemaVersion 5→6 export/import extension.

Core correctness is solid. Migration safety holds: `Idea` is a wholly new entity (additive —
inferred lightweight migration creates a new table with no existing rows to migrate) and the
new `Domain.ideas` relationship is defaulted (`= []`), so no `migrationPlan:` and no
required-no-default field is introduced. The consume path is well-guarded — `archiveAndForwardLink`
is idempotent on an already-archived idea, so a repeat promote never double-archives or clobbers
the forward-link (proven by `PromoteServiceTests`, which run in the §9.7 runnable tier). The
export/import round-trip wires `IdeaDTO` correctly (domain via `categoryIndex`, forward-link kept
as plain scalars), and `deleteAll` deletes ideas before their domain per the `.nullify` inverse
ordering. Token usage and os.Logger discipline are clean.

The findings below are all sub-critical: a task-relevant test-coverage gap (no Idea passes through
the export round-trip), a duplicate-item vector in the collection promote flow, a non-atomic
consume, and three minor quality/staleness items.

No `<structural_findings>` block was provided, so this report is entirely narrative.

## Warnings

### WR-01: No Idea export/import round-trip test — schemaVersion 6 fields are unverified

**File:** `HabitsTrackerTests/ExportImportTests.swift:35,85,159`
**Issue:** This phase adds `Idea` to the export/import payload (schemaVersion 6) with a
non-trivial encode/decode surface: the `promotedToKind` raw-string forward-link, `promotedToID`,
and `domainID` re-wiring through `categoryIndex`. All three existing round-trip tests pass
`ideas: []` and none construct, export, and re-import an `Idea`. The `promotedToKindRaw`↔
`promotedToKind` field-name crossover and the domain re-link are exactly the kind of wiring that
silently breaks and ships undetected. This also violates §9.5 (new persisted fields ship with a
round-trip test in the same commit). These are build-verify-only on the iOS 26 sim per §9.7, but
the test must still exist and be authored.
**Fix:** Add `testV6IdeaFieldsSurviveRoundTrip`: create a filed, promoted idea
(`promotedTo = .rule`, `promotedToID = someRuleID`, `domain = domain`), export, `importReplace`,
then assert `idea.title`, `idea.isArchived`, `idea.promotedTo == .rule`,
`idea.promotedToID == someRuleID`, and `idea.domain?.id == domain.id` all survive. Mirror the
shape of `testV5FieldsSurviveRoundTrip`.

### WR-02: PromoteToCollectionPicker stays presented after consume — enables a duplicate collection item

**File:** `HabitsTracker/Features/Ideas/PromoteToCollectionPicker.swift:43-46`
**Issue:** After the user picks a collection, `CollectionItemEditorSheet(collection:promotingIdea:)`
is presented as a nested sheet. On Save that editor creates the item, consumes the idea
(`archiveAndForwardLink`), and dismisses **itself only** — `PromoteToCollectionPicker` remains on
screen with `pickedCollection` reset to nil and no success signal. The user is left staring at the
collection list again. If they tap a second collection, a **new** `CollectionItem` is created and
inserted (the editor's create branch always inserts regardless of idea state). The idempotency
guard in `archiveAndForwardLink` protects the idea's forward-link but does nothing to prevent the
duplicate item. Net: a single promote-to-collection can silently produce two collection items.
**Fix:** Dismiss the picker when the child editor completes. Pass a completion into the editor (as
`IdeaRow` already does for the habit path) and call `dismiss()` on the picker inside it, or observe
the idea's `isArchived` and auto-dismiss. Example:
```swift
.sheet(item: $pickedCollection) { collection in
    CollectionItemEditorSheet(collection: collection, promotingIdea: idea)
        .onDisappear { dismiss() } // idea already consumed → close the picker
}
```

### WR-03: Promote consume is non-atomic (two separate `try? save()`) — a silent failure can duplicate the target

**File:** `HabitsTracker/Features/Rules/RuleEditorView.swift:296-304`, `HabitsTracker/Features/Collections/CollectionItemEditorSheet.swift:258-266`, `HabitsTracker/Features/Ideas/IdeaRow.swift:65-68`
**Issue:** The promote flow performs two separate saves: first `insert(target); try? save()`, then
`archiveAndForwardLink(idea:...); try? save()`. Because both use `try?`, if the **second** save
fails, the target (Rule/CollectionItem/Habit) is persisted but the idea stays unarchived and
therefore still visible in the Inbox/domain Ideas section. The user re-promotes → a second target
is created. Splitting the two mutations across two swallowed saves makes the operation
non-atomic for no benefit — both mutations are on the same context and should commit together.
**Fix:** Mutate both the target and the idea, then save once. In `RuleEditorView.saveRule` create-branch:
```swift
modelContext.insert(rule)
if let sourceIdea {
    PromoteService.archiveAndForwardLink(idea: sourceIdea, as: .rule, targetID: rule.id)
}
try? modelContext.save()   // single commit for target + consume
```
Apply the same collapse in `CollectionItemEditorSheet.saveItem`. (Broader `try?`-swallows-error
handling is pre-existing codebase convention and out of scope here — this finding is specifically
about the two-save split in the new promote paths.)

## Info

### IN-01: HubView has an unused `columns` property with a hardcoded spacing value

**File:** `HabitsTracker/Features/Hub/HubView.swift:21`
**Issue:** `private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]` is never
referenced — `grid(theme:)` builds its own inline `[GridItem(.adaptive(minimum: 120), spacing: theme.spacing.m)]`
at line 51. The dead property also hardcodes `spacing: 12` (a magic number that bypasses the
DesignKit spacing token used by the live copy) and duplicates the `GridItem` literal.
**Fix:** Delete line 21 (and the stray `minimum: 120` literal duplication) — the inline
token-based definition at line 51 is the single source of truth.

### IN-02: ExportImportTests docstring states the wrong current schemaVersion

**File:** `HabitsTrackerTests/ExportImportTests.swift:7`
**Issue:** The file header says "the service always stamps the current `schemaVersion` (5)". The
service is now `schemaVersion = 6` (`ExportImportService.swift:7`). Stale comment misleads the next
reader about what version the round-trips actually exercise.
**Fix:** Update the header to `(6)` and note the v6/Idea round-trip once WR-01's test is added.

### IN-03: ExportImportTests header enumerates only v3–v5; v6/Ideas is undocumented

**File:** `HabitsTrackerTests/ExportImportTests.swift:12-19`
**Issue:** The per-test roadmap in the docstring lists `testV3…`/`testV4…`/`testV5…` but never
mentions the schemaVersion-6 Idea fields this phase introduced, reinforcing the WR-01 gap at the
documentation level.
**Fix:** Add a `testV6FieldsSurviveRoundTrip:` line describing Idea title/note/url/promote-link/
domain coverage when the test from WR-01 lands.

---

_Reviewed: 2026-07-11T20:51:18Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
