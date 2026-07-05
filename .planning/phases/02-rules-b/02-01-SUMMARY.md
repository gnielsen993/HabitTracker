---
phase: 02-rules-b
plan: 01
subsystem: database
tags: [swiftdata, migration, schema, export-import, relationships]

# Dependency graph
requires:
  - phase: 01-domain-generalization-a
    provides: Domain @Model + Domain<->Habit .nullify relationship pattern
provides:
  - Rule @Model (title, body, sourceURL?, createdAt, isArchived=false, domain?, stemmedHabits)
  - Habit.originRule Rule? relationship (.nullify via Rule.stemmedHabits — never cascades)
  - Domain.rules inverse (domain.rules available for the DomainDetailView section)
  - Rule registered in the plan-less modelContainer type list
  - Export/Import schemaVersion 3 with RuleDTO + habit->rule stem-link serialization
affects: [02-02, 02-03, rules-ui, habit-create-sheet]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Stem link modeled as a SwiftData relationship (not a raw UUID) so .nullify delivers RULE-05 for free"
    - "Owning .nullify inverse declared once (Rule.stemmedHabits / Domain.rules); Habit/Rule sides stay plain"

key-files:
  created:
    - HabitsTracker/Models/Rule.swift
    - HabitsTrackerTests/RuleModelTests.swift
  modified:
    - HabitsTracker/Models/Habit.swift
    - HabitsTracker/Models/Domain.swift
    - HabitsTracker/HabitsTrackerApp.swift
    - HabitsTracker/Services/ExportImportService.swift
    - HabitsTracker/Features/Settings/SettingsView.swift
    - HabitsTrackerTests/ExportImportTests.swift

key-decisions:
  - "Stem link is a SwiftData relationship per D-01 — gives RULE-05 nullify + RULE-04 count/backref directly"
  - "Migration kept plan-less (no migrationPlan) per playbook §9.12 — all new fields optional or defaulted"
  - "Upgrade-test gate (Task 3) accepted on a low-risk basis by Gabe rather than executed — see Deviations"

patterns-established:
  - "Rule mirrors Habit's plain to-one + Domain's owning to-many inverse exactly (no new relationship idiom)"

requirements-completed: [RULE-01, RULE-04, RULE-05]

# Metrics
duration: ~5min
completed: 2026-07-05
---

# Phase 02 Plan 01: Rule schema-expansion Summary

**Rule @Model + bidirectional Rule↔Habit .nullify stem link + Domain.rules inverse, all additive under plan-less inferred migration, with Export/Import bumped to schemaVersion 3.**

## Performance

- **Duration:** ~5 min (executor)
- **Tasks:** 2 of 3 executed as code (Task 3 is a human-verify gate — see Deviations)
- **Files modified:** 8

## Accomplishments
- `Rule` `@Model`: `@Attribute(.unique) id`, title, body, `sourceURL?`, createdAt, `isArchived: Bool = false`, plain `domain: Domain?`, and owning `stemmedHabits` (`.nullify`, inverse `\Habit.originRule`).
- `Habit.originRule: Rule?` — plain relationship; deleting a rule nulls the pointer and never cascades to habits (RULE-05).
- `Domain.rules` owning `.nullify` inverse so `domain.rules` is available to 02-02's DomainDetailView section builder.
- `Rule.self` registered in the plan-less `.modelContainer(for:)` list (no `migrationPlan`).
- Export/Import at `schemaVersion = 3` with `RuleDTO`, `HabitDTO.originRuleID`, correct delete ordering (Rule before Domain), and `SettingsView` call-site updated with `@Query(sort: \Rule.createdAt)`.

## Task Commits

1. **Task 1 (RED): RuleModelTests failing** - `45a1d7c` (test)
2. **Task 1 (GREEN): Rule @Model + Habit.originRule + Domain.rules + container** - `52dda78` (feat)
3. **Task 2 (RED): ExportImportTests v3 round-trip failing** - `6543d3b` (test)
4. **Task 2 (GREEN): schemaVersion 3 + RuleDTO + stem-link serialization** - `66c8b6c` (feat)

## Files Created/Modified
- `HabitsTracker/Models/Rule.swift` - new @Model with nullify stem inverse + isArchived
- `HabitsTracker/Models/Habit.swift` - plain `originRule: Rule?`
- `HabitsTracker/Models/Domain.swift` - `rules` owning `.nullify` inverse
- `HabitsTracker/HabitsTrackerApp.swift` - `Rule.self` in container (plan-less)
- `HabitsTracker/Services/ExportImportService.swift` - schemaVersion 3, RuleDTO, originRuleID, delete order
- `HabitsTracker/Features/Settings/SettingsView.swift` - Rule @Query + exportData `rules:` arg
- `HabitsTrackerTests/RuleModelTests.swift` - default + nullify + both inverses
- `HabitsTrackerTests/ExportImportTests.swift` - v3 round-trip incl. stem link + isArchived

## Decisions Made
- Followed the plan's relationship modeling exactly (D-01): stem link as a relationship, not a UUID.

## Deviations from Plan

**Task 3 (upgrade-test gate) not executed as a build/run verification.**
- **What happened:** The executor correctly halted at the Task 3 human-verify checkpoint. The orchestrator then attempted to run the upgrade test automatically (using the app's seed data as the "prior data" and inspecting the SwiftData SQLite store to confirm survival) plus the unit suite. That background run was terminated by the account's **monthly spend limit** after ~20 min, before returning any verdict. The repo was recovered cleanly to `main`.
- **Resolution:** Gabe elected to **proceed on a low-risk basis**. The migration is purely additive and playbook-compliant (§9.12 Step 1): every new field is optional (`sourceURL?`, `domain?`, `originRule?`) or defaulted (`isArchived = false`, `rules = []`), the container stays plan-less, and no field was renamed or made required-without-default. Inferred lightweight migration handles this class of change.
- **Outstanding verification debt:** The data-survival upgrade test and the unit-suite green run are **not yet confirmed**. These should be exercised at the next RC smoke test (CLAUDE.md §6) or whenever a full simulator run is affordable. Documented here so it surfaces in `/gsd:progress` / audit rather than being silently assumed.

## Issues Encountered
- Account monthly spend limit aborted the automated verification agent mid-run; repo restored from a detached-HEAD (old-commit build) state back to clean `main`.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Schema foundation is in place for 02-02 (Rules UI reads `domain.rules`, `rule.stemmedHabits`) and 02-03 (shared habit-create sheet sets `habit.originRule`).
- Carry-forward: run the deferred upgrade/data-survival test + unit suite before shipping the milestone RC.

---
*Phase: 02-rules-b*
*Completed: 2026-07-05*
