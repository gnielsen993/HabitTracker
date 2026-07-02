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
- **Status after 01-03:** RESOLVED — `BootstrapService(defaults:)` landed; `** TEST BUILD SUCCEEDED **`
  on iPhone 17. The full `HabitsTrackerTests` target now compiles.

## Discovered during 01-03 (seed reconciliation) — OWNER-SIDE INFRA BLOCKER

### SwiftData in-memory ModelContainer traps (EXC_BREAKPOINT) in the test host on this machine

- **Found during:** 01-03 verification (running `HabitsTrackerTests` on iPhone 17, iOS 26.2 simulator).
- **Symptom:** Tests that build an in-memory `ModelContainer(for: Schema([Domain, Habit, DailyEntry,
  HabitState]))` and insert a `Domain` crash the test-host process with `EXC_BREAKPOINT (SIGTRAP)`,
  faulting frame in `SwiftData` at `context.insert`/save (`Executed 0 tests … ** TEST EXECUTE FAILED **`,
  runner restarts 3×). Accompanied by CoreData `errno 30` "read-only file system" / `errno 2`
  "No such file" logs against the simulator's app-container `default.store` path.
- **Why this is NOT a 01-03 code bug:** The crash reproduces on
  `DomainMigrationTests.testIsFocusedDefaultsFalse` — a test that touches ONLY the 01-02 `Domain`
  model (a single `Domain(...)` insert), exercising zero Task-1/Task-2 code. Its insert is
  byte-for-byte identical to `DomainCreateTests.testCustomDomainPersistsWithValidToken`, which
  **passes** in isolation. `EngineTests` and (in one run) `ExportImportTests` also passed. The
  pass/fail is non-deterministic per simulator clone → a CoreSimulator + SwiftData state defect,
  not deterministic logic.
- **Recovery attempted (did not resolve):** `simctl shutdown all` + `erase`; created a brand-new
  `iPhone 17` device; `killall CoreSimulatorService`; `simctl uninstall gn.HabitsTracker`;
  serial (`-parallel-testing-enabled NO`) execution; per-test isolation; and a spike removing the
  self-referential `@Attribute(originalName:)` annotations from `Domain` (reverted — no effect).
- **What IS verified without the simulator runtime:** `** TEST BUILD SUCCEEDED **` (whole suite
  compiles), both 01-03 task `<automated>` grep checks pass, and static review confirms the Task-1
  logic satisfies each of the four `BootstrapBackfillTests` assertions (see 01-03-SUMMARY.md
  "Static verification of the four BootstrapBackfillTests").
- **Owner action to close:** Re-run
  `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:HabitsTrackerTests test`
  on a healthy CoreSimulator (e.g. after a machine reboot / Xcode simulator runtime reinstall, or on
  the owner's own environment). This is the same class as the pre-existing STATE.md owner-side blocker
  ("local Xcode/TestFlight verification is required on the user's side") and CLAUDE.md §9.7
  (stale-store / NSStagedMigrationManager test-runner crashes → uninstall + retry on the owner box).
