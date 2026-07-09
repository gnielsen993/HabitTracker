---
phase: 04-clips-d
plan: 04
subsystem: database
tags: [swiftdata, export-import, schema, clip, codable]

# Dependency graph
requires:
  - phase: 04-clips-d
    provides: "04-01: Clip @Model + ClipStatus enum (statusRaw String facade), Domain.clips .nullify inverse"
provides:
  - "ExportImportService.schemaVersion bumped 4 -> 5"
  - "ClipDTO scalar-only Codable mirroring RuleDTO shape (id, title, url, note?, tag?, status: String, isArchived, createdAt, domainID: UUID?)"
  - "exportData(...) extended with clips: [Clip] parameter, mapping status to statusRaw"
  - "importReplace wires Clip.domain via categoryIndex[dto.domainID] with a defensive ClipStatus(rawValue:) ?? .saved fallback"
  - "deleteAll deletes Clip before Domain (nullify ownership order)"
  - "SettingsView export call site passes clips: clips"
  - "ExportImportTests.testExportImportRoundTripV5 (build-verify only per §9.7)"
affects: [04-05, phase-6-export-import-completeness]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ClipDTO mirrors RuleDTO exactly: scalar-only DTO, status carried as raw String (D-03), single FK as a UUID? resolved through the categoryIndex map at import time"
    - "deleteAll ordering rule: any .nullify-owned model must be deleted before its owning side (Clip before Domain, matching CollectionItem/Collection before Domain from Phase 3)"

key-files:
  created: []
  modified:
    - HabitsTracker/Services/ExportImportService.swift
    - HabitsTracker/Features/Settings/SettingsView.swift
    - HabitsTrackerTests/ExportImportTests.swift

key-decisions:
  - "Followed the plan's ClipDTO field set and RuleDTO-mirroring shape exactly (D-03, D-13)"
  - "v5 round-trip test authored and build-verified only (build-for-testing exits 0) — not executed, per CLAUDE.md §9.7 the SwiftData @Model persistence suite crashes the XCTest host at 0.000s on this simulator; actual execution happens on device via the 04-05 owner checkpoint"

patterns-established:
  - "Fourth type (after Domain/Rule/Collection+CollectionItem) to go through the schemaVersion-bump + scalar-DTO + index-wiring + deleteAll-ordering discipline — confirms the repeatable export/import extension recipe for Ideas (Phase E) and Phase 6 completeness pass"

requirements-completed: [CLIP-02]

# Metrics
duration: ~6min
completed: 2026-07-08
---

# Phase 04 Plan 04: Export/Import schemaVersion 5 (Clip round-trip) Summary

**ExportImportService bumped to schemaVersion 5 with a ClipDTO that round-trips title/url/note/tag/status(raw)/isArchived plus the domain FK, mirroring the existing RuleDTO block exactly.**

## Performance

- **Duration:** ~6 min (executor)
- **Tasks:** 2 of 2 executed
- **Files modified:** 3

## Accomplishments
- `ExportImportService.schemaVersion` bumped 4 -> 5 (D-13); `HabitExportBundle` gains `clips: [ClipDTO]`.
- `struct ClipDTO: Codable` added — scalar-only, `status` carried as the raw `String` (D-03), the only FK is `domainID: UUID?`.
- `exportData(...)` extended with a `clips: [Clip]` parameter, mapping each `Clip` to a `ClipDTO` with `status: $0.statusRaw` and `domainID: $0.domain?.id`.
- `importReplace` reconstructs each `Clip` wired to `categoryIndex[dto.domainID]` via `flatMap` (never force-unwrap), with a defensive `ClipStatus(rawValue: dto.status) ?? .saved` fallback guarding malformed/unknown status strings.
- `deleteAll` now deletes `Clip.self` before `Domain.self`, respecting the `.nullify` ownership order so no orphaned relationship state survives a replace-import.
- `SettingsView` gains `@Query private var clips: [Clip]` and passes `clips: clips` into the `exportData(...)` call.
- `ExportImportTests` Schema registers `Clip.self`; the v3/v4 tests pass `clips: []` to stay compiling; a new `testExportImportRoundTripV5` asserts a `Clip` (status `.acted`, note, tag, url) survives export/import with its domain wiring intact.

## Task Commits

Each task was committed atomically:

1. **Task 1: schemaVersion 4->5 + ClipDTO round-trip + deleteAll ordering** - `d1d1f89` (feat)
2. **Task 2: Wire the SettingsView export call site + v5 round-trip test** - `cefab6b` (feat)

## Files Created/Modified
- `HabitsTracker/Services/ExportImportService.swift` - schemaVersion 5, ClipDTO, exportData clips param, importReplace clip loop, deleteAll ordering
- `HabitsTracker/Features/Settings/SettingsView.swift` - `@Query private var clips: [Clip]` + `clips: clips` in the export call
- `HabitsTrackerTests/ExportImportTests.swift` - Schema gains `Clip.self`; v3/v4 tests pass `clips: []`; new `testExportImportRoundTripV5`

## Decisions Made
Followed the plan's ClipDTO field set and RuleDTO-mirroring shape exactly — no deviation from the specified scalar/FK modeling (D-03, D-13). The v5 round-trip test is authored and compiled (build-for-testing exits 0) but not executed on the simulator, per CLAUDE.md §9.7 (SwiftData `@Model` persistence tests crash the XCTest host at 0.000s on this toolchain) — execution is deferred to a physical device via the 04-05 owner checkpoint.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None. `xcodebuild ... build` confirmed `ExportImportService.swift` compiled cleanly in isolation (the only build error before Task 2 landed was the expected missing `clips:` argument at the `SettingsView.swift` call site, which Task 2 resolved). `xcodebuild ... build-for-testing` exits 0 after Task 2, confirming the test target — including `testExportImportRoundTripV5` — compiles.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness

- Export/Import is green for the type this phase added (baseline DoD satisfied for `Clip`).
- `testExportImportRoundTripV5` is authored and compiles but has NOT been executed — per CLAUDE.md §9.7 this repo's SwiftData `@Model` persistence test suite crashes the XCTest host at 0.000s on the iOS 26 simulator. Actual round-trip execution (export -> wipe -> import) is exercised on-device via the 04-05 owner checkpoint, alongside the still-pending CLIP-01 upgrade-test checkpoint from 04-01.
- Full multi-type export/import completeness (all types under one schemaVersion) remains Phase 6 scope; this plan only extended the round-trip for the type it added.

---
*Phase: 04-clips-d*
*Completed: 2026-07-08*

## Self-Check: PASSED

- FOUND: HabitsTracker/Services/ExportImportService.swift
- FOUND: HabitsTracker/Features/Settings/SettingsView.swift
- FOUND: HabitsTrackerTests/ExportImportTests.swift
- FOUND: d1d1f89 (Task 1 commit)
- FOUND: cefab6b (Task 2 commit)
