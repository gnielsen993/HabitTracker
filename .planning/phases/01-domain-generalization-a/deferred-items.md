# Phase 1 Deferred Items

## Discovered during 01-02 (Domain rename + schemaVersion 2)

### Test target does not compile until 01-03 lands `BootstrapService(defaults:)`

- **Found during:** 01-02 Task 3 (attempting to run DomainMigrationTests + ExportImportTests for the DOM-01 gate).
- **Issue:** `HabitsTrackerTests/BootstrapBackfillTests.swift` (lines 77, 97, 122, 146) calls
  `BootstrapService(defaults:)` — an injectable `UserDefaults` initializer that does **not** exist
  on `BootstrapService` yet. Swift compiles the whole `HabitsTrackerTests` target as one unit, so this
  RED-by-design Wave-0 file blocks compilation of the entire test target — including
  `DomainMigrationTests` and `ExportImportTests`, which 01-02 makes green at the source level.
- **Why deferred (NOT a 01-02 bug):** The 01-01 SUMMARY explicitly records this as a contract that
  **plan 01-03 must honor** ("Tests assume `BootstrapService(defaults:)` — an injectable `UserDefaults`
  initializer that 01-03 must add for testable, isolated `lastSeededVersion` gating; the marker does not
  exist in code today"). Adding the version-gated focus backfill + injectable defaults is 01-03 scope
  (the version-gated backfill plan), not the rename plan. The 01-02 **app target** builds clean
  (`** BUILD SUCCEEDED **`, zero errors, iPhone 17).
- **Resolved by:** 01-03 — once `BootstrapService(defaults:)` and the backfill land, the full test
  target compiles and `DomainMigrationTests` + `ExportImportTests` (already source-complete from 01-02)
  + `BootstrapBackfillTests` can all run green.
- **Impact on DOM-01 gate:** The owner-side manual upgrade test (Task 3) can still be run independently
  of the unit suite (it installs OLD vs NEW app builds — the app target builds). The "full automated
  suite green at schemaVersion 2" portion of the gate's acceptance is satisfied at the wave merge once
  01-03 lands the missing initializer; the unit tests that 01-02 owns are source-complete and verified
  to reference only the now-existing `Domain`/`isFocused`/schemaVersion-2 API.
