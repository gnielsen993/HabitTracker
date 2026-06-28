---
phase: 01-domain-generalization-a
plan: 01
subsystem: testing

tags: [xctest, swiftdata, migration, domain, isFocused, bootstrap, export-import, runbook]

# Dependency graph
requires:
  - phase: v1.0 (shipped)
    provides: Category/Habit/DailyEntry/HabitState models, BootstrapService, SeedDataService, ExportImportService (schemaVersion 1)
provides:
  - Wave-0 RED unit-test scaffold for every Phase-1 behavior in 01-VALIDATION.md
  - DomainMigrationTests (isFocused default + Domain field-shape lock)
  - BootstrapBackfillTests (version-gated backfill, two-run idempotency, previous>0 guard, name-keyed merge-add unfocused)
  - DomainCreateTests (custom-domain persistence with closed 5-token accent set)
  - ExportImportTests retargeted to Domain schemaVersion-2 round-trip asserting isFocused survives
  - Docs/UPGRADE_TEST_RUNBOOK.md (DOM-01 manual merge-gate procedure)
affects: [01-02 Domain rename + schemaVersion bump, 01-03 focus backfill, 01-VALIDATION sign-off]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-test isolated UserDefaults(suiteName:) for lastSeededVersion marker (no leak into app defaults)"
    - "In-memory ModelConfiguration(isStoredInMemoryOnly:true) for SwiftData round-trip tests (mirrors ExportImportTests)"
    - "Wave-0 RED-by-design: tests reference not-yet-existing types so they fail until implementation lands"

key-files:
  created:
    - HabitsTrackerTests/DomainMigrationTests.swift
    - HabitsTrackerTests/BootstrapBackfillTests.swift
    - HabitsTrackerTests/DomainCreateTests.swift
    - Docs/UPGRADE_TEST_RUNBOOK.md
  modified:
    - HabitsTrackerTests/ExportImportTests.swift

key-decisions:
  - "Used f564d15 (plan-specified last-shipped SHA) in the runbook, not current HEAD 262e4f7 — the runbook documents the OLD build to install"
  - "Tests construct BootstrapService(defaults:) — assumes 01-03 adds an injectable UserDefaults for testable, isolated lastSeededVersion gating (per 01-RESEARCH Pattern 2)"
  - "Merge-add new hub domains asserted by name Style/Diet/Money/Media (from 01-CONTEXT D-08); Social pre-seeded to prove name-keyed dedupe"

patterns-established:
  - "Wave-0 validation scaffold authored before production code; every downstream task has an automated verify that exists before its implementation (Nyquist rule)"
  - "DOM-01 data-integrity merge gate captured as a committed, runnable owner-side runbook with an explicit FAIL→relabel-only fallback"

requirements-completed: [DOM-01, DOM-02, DOM-04, DOM-05]

# Metrics
duration: 12min
completed: 2026-06-28
---

# Phase 1 Plan 01: Wave-0 Validation Scaffold Summary

**RED-by-design XCTest scaffold (Domain shape + isFocused default, version-gated focus backfill idempotency, custom-domain persistence, schemaVersion-2 Export/Import round-trip) plus a committed DOM-01 upgrade-test merge-gate runbook.**

## Performance

- **Duration:** ~12 min
- **Tasks:** 2
- **Files modified:** 5 (4 created, 1 modified)

## Accomplishments

- Authored three new XCTest files covering every Wave-0 behavior in 01-VALIDATION.md, all RED-by-design (reference not-yet-existing `Domain`/`isFocused`/version-gated backfill).
- Retargeted ExportImportTests to the post-rename `Domain` shape at schemaVersion 2, asserting `isFocused` survives the export→import round-trip.
- Captured the DOM-01 manual upgrade test as a standalone, runnable runbook with concrete commands (OLD build `f564d15` → create data → NEW build over store → PID>0 + data visible) and the FAIL→relabel-only fallback.
- Established isolated `UserDefaults(suiteName:)` per-test pattern so the `lastSeededVersion` idempotency marker never leaks.

## Task Commits

1. **Task 1: Failing unit tests for Domain shape, backfill, custom-domain persistence** - `18c5c4c` (test)
2. **Task 2: ExportImportTests → schemaVersion-2 Domain round-trip + DOM-01 upgrade runbook** - `281f7cc` (test)

## Files Created/Modified

- `HabitsTrackerTests/DomainMigrationTests.swift` - `testIsFocusedDefaultsFalse` + `testDomainCarriesAllPriorFields` (DOM-01/02 shape lock).
- `HabitsTrackerTests/BootstrapBackfillTests.swift` - four methods: upgrade flip, two-run idempotency, fresh-install no-flip (`previous>0` guard), name-keyed merge-add unfocused (DOM-04).
- `HabitsTrackerTests/DomainCreateTests.swift` - `testCustomDomainPersistsWithValidToken` asserting `colorToken` ∈ {forest, navy, maroon, walnut, stone} (DOM-05).
- `HabitsTrackerTests/ExportImportTests.swift` - now constructs `Domain(isFocused:true)`, schema `[Domain.self …]`, asserts `isFocused == true` after import; schema-version guard untouched.
- `Docs/UPGRADE_TEST_RUNBOOK.md` - DOM-01 owner-side merge-gate procedure; references `Docs/SCHEMA_MIGRATION_PLAYBOOK.md`.

## Decisions Made

- **Runbook OLD-build SHA is `f564d15`** (the plan-specified last-shipped commit), even though current HEAD is `262e4f7`. The runbook documents which build to install/check-out, so the plan's literal SHA is authoritative.
- **Tests assume `BootstrapService(defaults:)`** — an injectable `UserDefaults` initializer that 01-03 must add for testable, isolated `lastSeededVersion` gating (the marker does not exist in code today; it is greenfield per 01-RESEARCH Pattern 2/Pitfall 2). This is a contract the backfill plan must honor; the tests are the spec.
- **New hub seed domains named Style/Diet/Money/Media** in the merge-add assertions, drawn from 01-CONTEXT D-08's example set. The exact seed list is finalized by 01-03; if names differ, those test expectations must be aligned at implementation time.

## Deviations from Plan

None - plan executed exactly as written. The three new test files match the ExportImportTests in-memory XCTest pattern, no `print(` introduced, all use `@testable import HabitsTracker` + in-memory store, and the runbook contains every required literal string.

## Issues Encountered

None. Tests were not built/run on purpose: per the environment brief and the plan's verification notes, this is a Wave-0 plan whose tests are EXPECTED to fail to compile against current code until 01-02/01-03 implement `Domain`/`isFocused`/the version-gated backfill. Building them now would yield the intended RED, not a signal of plan failure. Verification was done via the plan's `<automated>` checks (file count, required strings, no-`Category(`), all of which passed.

## Threat Flags

None - this plan only adds test scaffolding and an owner-side documentation runbook; no new runtime network endpoints, auth paths, file-access patterns, or trust-boundary schema changes are introduced.

## Next Phase Readiness

- Plan 01-02 (Domain rename + schemaVersion 1→2) and 01-03 (version-gated focus backfill) now have their automated verifies in place and turn these RED tests GREEN as they implement. Contracts the implementations must honor: `Domain(name:iconName:colorToken:sortIndex:isSeeded:seedVersion:isFocused:)` initializer with `isFocused` defaulting to `false`; `BootstrapService(defaults:)` injectable; merge-add new domains unfocused + name-keyed dedupe; Export/Import carries `isFocused` at schemaVersion 2.
- DOM-01 hard merge gate is now a concrete runbook (`Docs/UPGRADE_TEST_RUNBOOK.md`) for plan 01-02's checkpoint; the owner runs it manually before any Hub UI.
- Open: if 01-03 finalizes a different new-domain seed list than Style/Diet/Money/Media, `BootstrapBackfillTests` name expectations must be updated in lockstep.

## Self-Check: PASSED

All created/modified files exist on disk; both task commits (`18c5c4c`, `281f7cc`) are present in git history.

---
*Phase: 01-domain-generalization-a*
*Completed: 2026-06-28*
