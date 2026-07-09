---
phase: 04-clips-d
plan: 01
subsystem: database
tags: [swiftdata, migration, schema, clip, nullify]

# Dependency graph
requires:
  - phase: 01-domain-generalization-a
    provides: Domain @Model + Domain<->Habit .nullify relationship pattern
  - phase: 02-rules-b
    provides: Rule.swift as the analog minimal leaf @Model shape (id, scalars, isArchived, bare domain relationship)
  - phase: 03-collections-c
    provides: Domain.collections .nullify inverse pattern (append-below idiom)
provides:
  - Clip @Model (title, url, note?, tag?, statusRaw="saved", isArchived=false, createdAt, domain?)
  - ClipStatus String-backed 2-case enum (saved/acted, D-03) with house raw-string computed facade
  - Domain.clips .nullify inverse (never cascade — Clip is a leaf with no owned dependents)
  - Clip registered in the plan-less modelContainer type list
  - ClipModelTests (build-verify only per §9.7) covering defaults, status raw-write, inverse, nullify
affects: [04-02, 04-03, 04-04, 04-05, clips-ui, export-import-v5]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Fixed 2-state enum stored as raw String via computed facade (ClipStatus over statusRaw) — mirrors Habit.scheduleType/mode idiom, chosen over the Phase 3 StatusSet catalog because Clip's states are inherent, not template-driven (D-03)"
    - "@Model default-value expressions must be fully qualified (Date.now, not the .now shorthand) — the Model macro cannot resolve implicit member lookup in a default-value position"

key-files:
  created:
    - HabitsTracker/Models/Clip.swift
    - HabitsTrackerTests/ClipModelTests.swift
  modified:
    - HabitsTracker/Models/Domain.swift
    - HabitsTracker/HabitsTrackerApp.swift

key-decisions:
  - "ClipStatus is a dedicated enum, not StatusSetCatalog — Clip's 2 states are fixed/inherent (D-03)"
  - "Clip.domain is a bare relationship; .nullify + inverse declared only on Domain.clips (owning side) — matches Rule/Collection idiom exactly"
  - "Migration kept plan-less (no migrationPlan) per playbook — all new fields optional or defaulted"
  - "Task 3 (upgrade-test gate) is a BLOCKING checkpoint requiring owner device verification — surfaced, not executed, per §9.7 CoreSimulator XCTest-host-launch blocker"

patterns-established:
  - "Clip mirrors Rule's minimal leaf shape (id, scalars, isArchived, bare domain relationship) with no owned-items array — confirms the leaf-model template for Ideas (Phase E) too"

requirements-completed: [CLIP-02, CLIP-03, CLIP-04]

# Metrics
duration: ~4min
completed: 2026-07-08
---

# Phase 04 Plan 01: Clip schema-expansion Summary

**Clip @Model (title/url/note?/tag?/status/isArchived) with a String-backed ClipStatus facade and a Domain.clips `.nullify` inverse, registered plan-less — the schema foundation every later Clips plan builds on.**

## Performance

- **Duration:** ~4 min (executor)
- **Tasks:** 2 of 3 executed as code (Task 3 is a blocking human-verify gate — see below)
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments
- `Clip` `@Model`: `@Attribute(.unique) id`, `title`, `url`, `note?`, `tag?`, `statusRaw: String = ClipStatus.saved.rawValue`, `isArchived: Bool = false`, `createdAt: Date = Date.now`, bare `domain: Domain?` — no owned-items array (leaf model, D-11).
- `ClipStatus: String` enum (`saved`, `acted`) with a computed `status` facade over `statusRaw` using the house raw-string idiom from `Habit.scheduleType`/`.mode` (D-03).
- `Domain.clips` owning `.nullify` inverse (`inverse: \Clip.domain`), appended below `collections`; init signature extended to match.
- `Clip.self` registered in the plan-less `.modelContainer(for:)` list (no `migrationPlan:`).
- `ClipModelTests` mirroring `RuleModelTests`: status default, isArchived default, status raw-write, Domain.clips inverse, delete-nullify. Build-verify only per §9.7.

## Task Commits

1. **Task 1: Add the Clip @Model + ClipStatus enum and the Domain.clips inverse** - `b16df72` (feat)
2. **Task 2: Register Clip in the plan-less container and add model tests** - `69ac2c1` (feat)
3. **Task 3: Upgrade-test gate** - NOT EXECUTED (blocking human-verify checkpoint, see below)

## Files Created/Modified
- `HabitsTracker/Models/Clip.swift` - new leaf @Model + ClipStatus enum
- `HabitsTracker/Models/Domain.swift` - `clips` owning `.nullify` inverse + init wiring
- `HabitsTracker/HabitsTrackerApp.swift` - `Clip.self` in container (plan-less)
- `HabitsTrackerTests/ClipModelTests.swift` - default/status/inverse/nullify tests (build-verify only)

## Decisions Made
- Followed the plan's field set and relationship modeling exactly (D-03, D-06, D-11, D-12).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `@Model` default-value expression required full qualification**
- **Found during:** Task 1 build verification
- **Issue:** `var createdAt: Date = .now` (as written in the plan's field list) fails to compile — the `@Model` macro synthesizes a `PropertyMetadata` default-value expression at a position where Swift's implicit-member lookup (`.now`) cannot resolve to `Date.now`, producing `error: A default value requires a fully qualified domain named value`.
- **Fix:** Changed to `var createdAt: Date = Date.now` (fully qualified). No behavior change — same default value.
- **Files modified:** HabitsTracker/Models/Clip.swift
- **Verification:** `xcodebuild ... build` exits 0.
- **Committed in:** b16df72 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Cosmetic Swift-macro syntax fix only; no scope creep, no field/behavior change from what the plan specified.

## Issues Encountered
None beyond the auto-fixed compile issue above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness

**BLOCKING CHECKPOINT PENDING:** Task 3 (the mandatory schema-expansion upgrade test per `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` Step 4) requires owner device verification on iPhone 17 — building the OLD (Phase-3) app, logging data, then installing the NEW (+Clip) build over that store and confirming all prior domains/habits/rules/collections/history remain intact. This cannot be automated here: XCTest host launch for SwiftData `@Model` tests crashes at 0.000s on the iOS 26 simulator (CLAUDE.md §9.7), and the upgrade test itself requires interactive app use on a real device/simulator session.

- Schema foundation (Clip model, ClipStatus, Domain.clips inverse, container registration) is code-complete and build-verified.
- Plans 04-02 through 04-05 (Clips UI: editor, detail view, row, DomainDetailView section) can be planned/built against this schema, but the **CLAUDE.md Definition of Done** requires the upgrade test to pass before the milestone ships an RC.
- `ExportImportService.schemaVersion` bump 4→5 + Clip round-trip (D-13) is NOT part of this plan — deferred to a later Clips plan per the plan's file scope (Clip.swift, Domain.swift, HabitsTrackerApp.swift, ClipModelTests.swift only).

---
*Phase: 04-clips-d*
*Completed: 2026-07-08*

## Self-Check: PASSED

- FOUND: HabitsTracker/Models/Clip.swift
- FOUND: HabitsTrackerTests/ClipModelTests.swift
- FOUND: b16df72 (Task 1 commit)
- FOUND: 69ac2c1 (Task 2 commit)
