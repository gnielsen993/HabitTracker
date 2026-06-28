---
phase: 01-domain-generalization-a
plan: 02
subsystem: models

tags: [swiftdata, migration, domain, isFocused, export-import, schemaVersion, rename, plan-less]

# Dependency graph
requires:
  - phase: 01-01
    provides: Wave-0 RED test scaffold (DomainMigrationTests, ExportImportTests retargeted to Domain schemaVersion 2), DOM-01 upgrade runbook
  - phase: v1.0 (shipped)
    provides: Category/Habit/DailyEntry/HabitState models, ExportImportService (schemaVersion 1), SeedDataService, plan-less container
provides:
  - "@Model class Domain (renamed from Category) carrying name/iconName/colorToken/sortIndex/isSeeded/seedVersion + additive defaulted isFocused: Bool = false"
  - "Habit.category relationship retyped to Domain? (property name kept)"
  - "plan-less container type list listing Domain.self (no migrationPlan)"
  - "ExportImportService at schemaVersion 2 with DomainDTO + isFocused (round-trip-symmetric)"
  - "SeedDataService mechanically retargeted to Domain (seedVersion 1, same 12 domains)"
  - "all ~10 reference sites compile-clean against Domain; app target BUILD SUCCEEDED on iPhone 17"
affects: [01-03 focus backfill (adds BootstrapService(defaults:) + seedVersion 2 + new domains), 01-04..01-06 Hub UI, 01-VALIDATION DOM-01 gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Plan-less @Model class rename via @Attribute(originalName:) on carried-over stored properties + class rename; NO SchemaMigrationPlan, NO migrationPlan: argument"
    - "Additive defaulted field (isFocused: Bool = false) — inferred lightweight migration backfills existing rows to false"
    - "Relationship TYPE change (Category? -> Domain?) WITHOUT a property rename, to minimize migration surface (no originalName needed on Habit)"
    - "Coupled one-pass Export/Import edit: schemaVersion + DTO shape + model type + deleteAll changed together (avoids Research Pitfall 5)"

key-files:
  created:
    - HabitsTracker/Models/Domain.swift
    - .planning/phases/01-domain-generalization-a/deferred-items.md
  modified:
    - HabitsTracker/Models/Habit.swift
    - HabitsTracker/HabitsTrackerApp.swift
    - HabitsTracker/Services/ExportImportService.swift
    - HabitsTracker/Services/SeedDataService.swift
    - HabitsTracker/Features/Today/TodayView.swift
    - HabitsTracker/Features/Settings/CategoryManagerView.swift
    - HabitsTracker/Features/Settings/HabitEditorView.swift
    - HabitsTracker/Features/Settings/HabitManagerView.swift
    - HabitsTracker/Features/Settings/SettingsView.swift
  deleted:
    - HabitsTracker/Models/Category.swift

key-decisions:
  - "Kept Habit.category property NAME (only retyped to Domain?) per Research A3/Q2 — a relationship-target type change, not a stored-attribute rename, so no @Attribute(originalName:) on Habit and minimal migration surface"
  - "Applied @Attribute(originalName:) defensively on Domain's carried-over stored properties per the playbook, even though property names are unchanged (only the class is)"
  - "Kept the JSON bundle key `categories` and the exportData parameter name `categories` to match the 01-01 test contract and avoid a wider rename; only the DTO type/shape changed (CategoryDTO -> DomainDTO + isFocused)"
  - "SeedDataService is a pure mechanical Category->Domain substitution this plan (seedVersion 1, same 12 domains, restoreMissingDefaults body unchanged); seedVersion bump + new domains + focus backfill are 01-03 scope"

# Metrics
duration: 11min
completed: 2026-06-28
---

# Phase 1 Plan 02: Category to Domain Rename + schemaVersion 2 Summary

**Plan-less `@Model` rename of `Category` to `Domain` with the additive defaulted `isFocused: Bool = false` field, `Habit.category` retyped to `Domain?`, all ~10 reference sites updated compile-clean, and Export/Import bumped to schemaVersion 2 with `DomainDTO` + `isFocused` — app target builds green on iPhone 17. The DOM-01 manual upgrade-test merge gate is surfaced as a PENDING owner-side checkpoint (not satisfied by this agent).**

## Performance

- **Duration:** ~11 min
- **Tasks:** 2 of 2 non-checkpoint tasks complete; Task 3 (checkpoint) PENDING owner verification
- **Files modified:** 11 (1 created model + 1 deferred-items doc, 8 modified, 1 deleted via rename)

## Accomplishments

- Created `HabitsTracker/Models/Domain.swift` as `@Model final class Domain` with all six carried Category fields plus the new `isFocused: Bool = false`, the `.nullify` `habits` inverse, and an initializer matching the 01-01 test contract `Domain(name:iconName:colorToken:sortIndex:isSeeded:seedVersion:isFocused:)` with `isFocused` defaulted last among value params.
- Deleted `Category.swift` (git recorded a clean rename, R status — no §9.6 duplicate `@Model`).
- Retyped `Habit.category` to `Domain?` keeping the Swift property name `category` (minimal migration surface; no `originalName` needed on Habit).
- Updated the plan-less container type list to `Domain.self` with NO `migrationPlan` argument (playbook-compliant).
- Bumped `ExportImportService.schemaVersion` 1 to 2 and made the three coupled edits in one pass: `CategoryDTO` to `DomainDTO` (+ `isFocused`), `exportData`/`importReplace` retyped to `Domain` and carrying `isFocused`, `deleteAll` to `delete(model: Domain.self)`.
- Mechanically retargeted `SeedDataService` to `Domain` (seedVersion 1, the same 12 default domains, `restoreMissingDefaults` body unchanged).
- Retargeted every reference view (`TodayView`, `CategoryManagerView`, `HabitEditorView`, `HabitManagerView`, `SettingsView`) `@Query` sort to `\Domain.sortIndex`; `TodayView.grouped()` tuple to `(category: Domain, ...)`; `CategoryManagerView` now constructs `Domain`; `SettingsView` fileExporter filename `-v1` to `-v2`.
- **App target build: `** BUILD SUCCEEDED **`, zero errors, iPhone 17 simulator.** Today layout/copy/spacing untouched (D-15).

## Task Commits

1. **Task 1: Rename Category @Model to Domain with isFocused; retype Habit.category; update container** - `36a7112` (feat)
2. **Task 2: Update all reference sites compile-clean + bump ExportImport to schemaVersion 2 with DomainDTO + isFocused** - `db911af` (feat)

Task 3 (DOM-01 manual upgrade test) is a `checkpoint:human-verify gate="blocking"` — NOT executed by this agent (see Checkpoint below).

## Files Created/Modified/Deleted

- `HabitsTracker/Models/Domain.swift` (created) - renamed `@Model class Domain`, six carried fields + `isFocused: Bool = false`, `.nullify habits` inverse, contract-matching init.
- `HabitsTracker/Models/Category.swift` (deleted) - removed to avoid a duplicate `@Model` (git rename to Domain.swift).
- `HabitsTracker/Models/Habit.swift` (modified) - `var category: Domain?` + init param retyped (property name kept).
- `HabitsTracker/HabitsTrackerApp.swift` (modified) - container lists `Domain.self`; still plan-less.
- `HabitsTracker/Services/ExportImportService.swift` (modified) - schemaVersion 2, `DomainDTO` + `isFocused`, `Domain` import/delete.
- `HabitsTracker/Services/SeedDataService.swift` (modified) - mechanical `Category`->`Domain` substitution; seedVersion 1; same 12 domains.
- `HabitsTracker/Features/Today/TodayView.swift` (modified) - `@Query` + `grouped()` tuple retyped to `Domain`; no layout change.
- `HabitsTracker/Features/Settings/{CategoryManagerView,HabitEditorView,HabitManagerView,SettingsView}.swift` (modified) - `@Query` to `\Domain.sortIndex`; `Domain(...)` construction; `-v2` filename.
- `.planning/phases/01-domain-generalization-a/deferred-items.md` (created) - records the 01-03-owned test-target compile dependency (`BootstrapService(defaults:)`).

## Decisions Made

- **Retype-only on `Habit.category`** (keep the property name `category`, change the type to `Domain?`) per Research A3/Q2 — a relationship-target type change is not a stored-attribute rename, so no `@Attribute(originalName:)` is needed on Habit and the migration surface stays minimal. Renaming the property to `domain` is a deliberately deferred, lower-risk future move.
- **Defensive `@Attribute(originalName:)`** on Domain's carried stored properties per the playbook, even though the property names are unchanged (only the class name changed). The empirical entity-rename risk (Research A1/Pitfall 1) is what the DOM-01 upgrade test exists to catch.
- **Kept the bundle JSON key and `exportData` parameter named `categories`** to match the 01-01 `ExportImportTests` contract (`exportData(categories: [domain], ...)`) and avoid a wider, unnecessary rename. Only the DTO type and shape changed.
- **SeedDataService stays seedVersion 1 / 12 domains this plan.** The seedVersion bump, new hub domains, the persisted `lastSeededVersion` marker, and the version-gated focus backfill are explicitly 01-03 scope.

## Deviations from Plan

None - plan executed exactly as written for the two non-checkpoint tasks. No Rule 1-4 deviations were triggered. The pre-existing actor-isolation warnings in the habit engines (`StatsEngine`/`StreakEngine`/`TodayEngine`/`WeeklyGoalEngine`) are out of scope (not caused by this plan's changes) and were left untouched per the scope boundary.

## Deferred Issues

- **Test target does not compile until 01-03 lands `BootstrapService(defaults:)`.** `HabitsTrackerTests/BootstrapBackfillTests.swift` references the injectable `BootstrapService(defaults:)` initializer that 01-03 must add (per the 01-01 SUMMARY contract). Because Swift compiles the whole test target as one unit, this RED-by-design Wave-0 file blocks compiling `DomainMigrationTests` + `ExportImportTests` too — so the unit suite cannot be run green until 01-03. This is **out of scope for 01-02** (the rename plan) and is logged in `deferred-items.md`. The 01-02 **app target** builds clean, and the source of `DomainMigrationTests`/`ExportImportTests` is already aligned to the now-existing `Domain`/`isFocused`/schemaVersion-2 API.

## Checkpoint: DOM-01 Upgrade Test — PENDING OWNER VERIFICATION (BLOCKING)

Task 3 is a `checkpoint:human-verify` with `gate="blocking"`. It is the hard merge gate for the `@Model` class rename and **cannot be performed by this agent** — it requires installing the OLD build (`f564d15`), interactively creating data in the simulator, then installing the NEW build over the same store and visually confirming all categories survive as Domains with their habits + logged day. Per `Docs/UPGRADE_TEST_RUNBOOK.md`:

- **Owner runs:** OLD build `f564d15` -> create a custom category + toggle habits + log a day -> NEW build (this branch) installed OVER the same store (do NOT uninstall between builds) -> confirm PID > 0 AND all prior data visible as Domains.
- **PASS:** app launches (PID > 0) and all prior categories-as-Domains + habits + the logged day are visible.
- **FAIL fallback (recorded):** do NOT merge. Pivot D-01 to **relabel-only** (keep the `@Model` class named `Category`, label "Domain" in UI only), carry `isFocused` as an additive defaulted field on the still-named class, use Export -> Import JSON as the data-carry-over backstop. NEVER reach for a `SchemaMigrationPlan` / `migrationPlan:`.

**DOM-01 is NOT marked satisfied.** It is recorded as pending owner verification. DOM-02 (Domain carries `isFocused` + all prior fields, default false) and the schemaVersion-2 Export/Import round-trip are delivered at the source level by this plan.

## Threat Flags

None - this plan renames an existing `@Model` and bumps an existing schemaVersion; no new network endpoints, auth paths, or new trust-boundary surface. The two registered threats (T-01-01 class-rename data loss; T-01-02 malformed-backup import) are mitigated exactly as the threat model prescribes: the DOM-01 upgrade test (blocking gate, pending owner) and the `schemaVersion == 2` hard guard in `importReplace`.

## Next Phase Readiness

- 01-03 (version-gated focus backfill) builds directly on this: it adds `BootstrapService(defaults:)` + the persisted `lastSeededVersion` marker, bumps `SeedDataService.seedVersion` 1->2, merge-adds the new hub domains (unfocused), and runs the once-only focus backfill — turning `BootstrapBackfillTests` green and unblocking the full unit suite (which also makes `DomainMigrationTests`/`ExportImportTests` runnable).
- Contracts honored for downstream: `Domain(name:iconName:colorToken:sortIndex:isSeeded:seedVersion:isFocused:)` with `isFocused` defaulting false; Export/Import carries `isFocused` at schemaVersion 2; `Habit.category: Domain?`.
- **Blocking before any Hub UI:** the owner must run the DOM-01 upgrade test per the runbook and report PASS (or invoke the relabel-only pivot).

## Self-Check: PASSED

All created/modified files exist on disk; `Category.swift` confirmed deleted; both task commits (`36a7112`, `db911af`) present in git history; app target `** BUILD SUCCEEDED **` on iPhone 17.

---
*Phase: 01-domain-generalization-a*
*Completed: 2026-06-28 (Task 3 DOM-01 upgrade gate PENDING owner verification)*
