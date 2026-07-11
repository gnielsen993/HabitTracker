---
phase: 05-ideas-promotion-e
plan: 06
subsystem: ui
tags: [swiftui, swiftdata, promote, ideas, designkit]

# Dependency graph
requires:
  - phase: 05-ideas-promotion-e
    provides: "PromoteService.archiveAndForwardLink + requiresDomainBeforePromote (05-03)"
  - phase: 05-ideas-promotion-e
    provides: "Idea @Model + Domain.ideas nullify inverse (05-01)"
provides:
  - "HabitCreateSheet.HabitSource.idea(Idea) prefill + additive onSaved completion for the promote-to-habit caller (05-07)"
  - "RuleEditorView.init(promotingIdea:) with widened optional-domain EditorMode + domain-required Save gate + consume-on-save"
  - "CollectionItemEditorSheet.init(collection:promotingIdea:) + consume-on-save"
  - "PromoteToCollectionPicker — app-wide Collection picker that routes into the prefilled CollectionItemEditorSheet"
affects: [05-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Additive optional completion (onSaved: ((Habit) -> Void)? = nil) on an existing chrome-stable sheet, so a new caller can hook a post-save side effect without touching the sheet's own persistence logic"
    - "Source-compatible enum-payload widening (Domain -> Domain?) that keeps every existing non-optional call site compiling unchanged via Swift's automatic promotion"
    - "Save-gate extended via a computed property (isDomainRequiredButMissing) composed into .disabled(...) alongside the existing trimmedTitle.isEmpty check, rather than replacing the existing gate"

key-files:
  created:
    - HabitsTracker/Features/Ideas/PromoteToCollectionPicker.swift
  modified:
    - HabitsTracker/Features/Habits/HabitCreateSheet.swift
    - HabitsTracker/Features/Rules/RuleEditorView.swift
    - HabitsTracker/Features/Collections/CollectionItemEditorSheet.swift

key-decisions:
  - "RuleEditorView and CollectionItemEditorSheet self-consume the idea (archiveAndForwardLink called directly in saveRule()/saveItem()); HabitCreateSheet stays chrome-clean and exposes onSaved so the promote-caller (IdeaRow, 05-07) performs the consume — this asymmetry was locked by the plan (Habit hands off to the shared sheet, Rule/CollectionItem editors already own their own save path)"
  - "CollectionItemEditorSheet's promote init clears noteText/costText (idea has no note/cost fields to carry) but threads url into urlText — only title and url are meaningful prefill fields from an Idea"
  - "saveRule()/saveItem() now call modelContext.save() twice on the promote path (once after the target insert, once after the idea-side consume) rather than batching into one save — keeps the consume strictly after a successful target save, matching T-05-04's ordering requirement literally"

patterns-established:
  - "Promote-prefill inits added directly to the three existing target editors rather than a bespoke PromoteSheet (D-06) — maximal reuse of already-built forms, ≤2 taps to a saved result"

requirements-completed: [IDEA-04, IDEA-05]

# Metrics
duration: 4min
completed: 2026-07-11
---

# Phase 05 Plan 06: Promote Target Editors — Prefill + Consume-on-Save Summary

**The three existing target editors (Rule/Habit/CollectionItem) now accept an idea prefill and self-consume (or hand off) via PromoteService on Save, plus a new app-wide PromoteToCollectionPicker — no bespoke PromoteSheet, maximal reuse (D-06/D-07).**

## Performance

- **Duration:** ~4 min
- **Completed:** 2026-07-11T02:35:49Z
- **Tasks:** 3
- **Files modified:** 4 (3 edited, 1 created)

## Accomplishments
- `HabitCreateSheet.HabitSource` gains `.idea(Idea)` prefilling title + selectedDomain (no backref, D-07); an additive `onSaved: ((Habit) -> Void)? = nil` fires once after save, before dismiss, for the promote-caller to consume the idea — existing call sites unaffected (default nil)
- `RuleEditorView`'s private `EditorMode.create(domain: Domain)` widened to `Domain?` (source-compatible — the existing `init(domain: Domain)` call auto-promotes); new `init(promotingIdea:)` prefills title/body/sourceURL/selectedDomainID with no force-unwrap of a possibly-nil `idea.domain`
- RuleEditorView's Save CTA gate extended (`isDomainRequiredButMissing`) so promoting an unfiled idea requires a domain be chosen via the existing Picker before Save enables (IDEA-05); on a successful create-branch save, `PromoteService.archiveAndForwardLink(idea:as:.rule,targetID:)` consumes the idea
- `CollectionItemEditorSheet` gains `init(collection:promotingIdea:)` prefilling title + url, no extra domain gate (the chosen collection already implies the domain, S7); consumes the idea via `PromoteService` after a successful create-branch save
- New `PromoteToCollectionPicker`: app-wide `@Query(sort: \Collection.title)` list rendered as `DKCard` rows (title + owning-domain caption), tapping dismisses and opens the prefilled `CollectionItemEditorSheet`; empty edge case "No lists yet. Create a collection first."; toolbar Cancel copied verbatim from `RuleEditorView`

## Task Commits

Each task was committed atomically:

1. **Task 1: HabitSource.idea(Idea) case + prefill arm + additive onSaved completion** - `41bf378` (feat)
2. **Task 2: RuleEditorView promote prefill + widened EditorMode + domain-required gate + consume-on-save** - `ae7d8e1` (feat)
3. **Task 3: CollectionItemEditorSheet idea prefill + PromoteToCollectionPicker + consume-on-save** - `05c16b4` (feat)

## Files Created/Modified
- `HabitsTracker/Features/Habits/HabitCreateSheet.swift` - `.idea(Idea)` case, prefill arm, `originRule = nil` for `.idea`, additive `onSaved` completion invoked after save
- `HabitsTracker/Features/Rules/RuleEditorView.swift` - widened `EditorMode.create(domain: Domain?)`, `sourceIdea: Idea?` stored property, `init(promotingIdea:)`, `isDomainRequiredButMissing` gate, consume call in `saveRule()`'s create branch
- `HabitsTracker/Features/Collections/CollectionItemEditorSheet.swift` - `sourceIdea: Idea?` stored property, `init(collection:promotingIdea:)`, consume call in `saveItem()`'s create branch
- `HabitsTracker/Features/Ideas/PromoteToCollectionPicker.swift` - new app-wide Collection picker

## Decisions Made
- Habit stays chrome-untouched with an additive completion (per D-07's explicit "smallest possible diff" instruction); Rule and CollectionItem self-consume since they already own a single insert/save point in their existing `saveRule()`/`saveItem()` methods
- Two `modelContext.save()` calls on the promote-create path (target insert, then idea consume) rather than one combined save — keeps the consume unambiguously "after a successful save," matching the threat model's T-05-04 ordering requirement literally rather than batching for a marginal efficiency gain
- `PromoteToCollectionPicker` composes `DomainFocusPicker`'s row-list shape with `RuleEditorView`'s toolbar Cancel per the pattern map's guidance (no single strong analog existed for a cross-domain app-wide picker)

## Deviations from Plan

None - plan executed exactly as written. All three tasks matched their acceptance criteria on the first pass; build was clean after each task (only a pre-existing, out-of-scope `nonisolated(unsafe)` warning from 05-03's `PromoteService.swift`, untouched by this plan).

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `PromoteService.archiveAndForwardLink` is now wired into two of the three target editors (Rule, CollectionItem) directly, plus the `onSaved` hook on Habit's sheet.
- 05-07 (IdeaRow's Promote affordance) can now route: `RuleEditorView(promotingIdea:)`, `HabitCreateSheet(source: .idea(idea), onSaved: { habit in PromoteService.archiveAndForwardLink(...) })`, or present `PromoteToCollectionPicker(idea:)` — all three targets are ready with prefilled forms and no bespoke PromoteSheet needed.
- `requiresDomainBeforePromote` is exercised live in RuleEditorView's Save gate; 05-07 will likely also consult it to decide whether Promote-to-Rule needs a domain-picker nudge before even opening the editor (planner's call).
- No blockers.

---
*Phase: 05-ideas-promotion-e*
*Completed: 2026-07-11*
