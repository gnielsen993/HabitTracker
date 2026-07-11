---
phase: 05-ideas-promotion-e
plan: 02
subsystem: infra
tags: [swiftdata, codable, export-import, backup]

# Dependency graph
requires:
  - phase: 05-ideas-promotion-e
    provides: "Idea @Model (05-01) — id/title/note/url/isArchived/createdAt/promotedToKindRaw/promotedToID/domain fields to serialize"
provides:
  - "IdeaDTO Codable struct mirroring ClipDTO's flat scalar-only shape"
  - "schemaVersion 6 with Idea participating in export/import/deleteAll round-trip"
  - "SettingsView ideas @Query threaded into the exportData(...) call site"
affects: [05-04, 05-05, 05-06, 05-07, 05-08, 05-09, 05-10, phase-06-polish]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "New leaf @Model export/import round-trip: DTO struct -> exportData map -> import loop (categoryIndex only, no id-index) -> deleteAll ordering before Domain"

key-files:
  created: []
  modified:
    - HabitsTracker/Services/ExportImportDTOs.swift
    - HabitsTracker/Services/ExportImportService.swift
    - HabitsTracker/Features/Settings/SettingsView.swift

key-decisions:
  - "HabitExportBundle's ideas: [IdeaDTO] field and decode-if-present wiring were added in Task 1 (ExportImportDTOs.swift) alongside the IdeaDTO struct itself, rather than deferred to Task 2, so Task 1 remains independently buildable (the struct alone doesn't touch the bundle; the bundle field was folded into Task 1's file to avoid a broken intermediate state) — see Deviations."

patterns-established:
  - "Scalar forward-link fields (promotedToKindRaw/promotedToID) round-trip as plain DTO values with no id-index map, since nothing else references an Idea by id."

requirements-completed: [IDEA-01]

# Metrics
duration: 6min
completed: 2026-07-11
---

# Phase 05 Plan 02: Idea Export/Import Round-Trip Summary

**ExportImportService schemaVersion bumped 5→6 with a full Idea round-trip (IdeaDTO, export map, import loop, nullify-ordered deleteAll) and SettingsView wired to supply the ideas @Query.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-10T21:03:00Z
- **Completed:** 2026-07-11T02:04:33Z
- **Tasks:** 2 completed
- **Files modified:** 3

## Accomplishments
- `IdeaDTO: Codable` added mirroring `ClipDTO`'s flat, scalar-only shape (id/title/note/url/isArchived/createdAt/promotedToKind/promotedToID/domainID)
- `ExportImportService.schemaVersion` bumped to 6; `exportData(...)` takes an `ideas: [Idea]` parameter and emits an `ideas:` array in the bundle
- Import path reconstructs `Idea` from `bundle.ideas`, wiring `domain` via the existing `categoryIndex` (no id-index map — nothing back-references an Idea by id)
- `deleteAll` deletes `Idea` before `Domain` (nullify ordering, same rule proven for `Clip` in 04-04)
- Older (≤5) backups missing the `ideas` key decode as an empty array — graceful degradation at the import boundary
- `SettingsView` adds an `@Query` for ideas and threads `ideas: ideas` into the `exportData(...)` call site

## Task Commits

Each task was committed atomically:

1. **Task 1: Add IdeaDTO** - `2652bf4` (feat)
2. **Task 2: Wire Idea export/import/delete + schemaVersion 6 + call site** - `9d891f3` (feat)

_Note: Task 1's commit also includes the `ideas: [IdeaDTO]` field on `HabitExportBundle` (memberwise init + decode-if-present) — see Deviations below for why this scope shift was made._

## Files Created/Modified
- `HabitsTracker/Services/ExportImportDTOs.swift` - Adds `struct IdeaDTO: Codable`; `HabitExportBundle` grows an `ideas: [IdeaDTO]` field with decode-if-present tolerance for pre-bump backups
- `HabitsTracker/Services/ExportImportService.swift` - `schemaVersion = 6`; `exportData(...)` gains `ideas:` param + `IdeaDTO(...)` export map; `importReplace` reconstructs `Idea` from `bundle.ideas`; `deleteAll` deletes `Idea` before `Domain`
- `HabitsTracker/Features/Settings/SettingsView.swift` - Adds `@Query(sort: \Idea.createdAt) private var ideas: [Idea]`; threads `ideas: ideas` into the `exportData(...)` call

## Decisions Made
- Folded the `HabitExportBundle.ideas` field into Task 1 (ExportImportDTOs.swift) instead of Task 2, so that after Task 1's commit the project still builds cleanly in isolation (adding a new required bundle parameter without updating the sole call site in `ExportImportService.swift` — which Task 2 owns — would have left an intermediate broken build). The plan's `files_modified` list already includes `ExportImportDTOs.swift` at the plan level, so this stays within the plan's declared file scope; only the task-boundary was shifted, not the file scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Moved `HabitExportBundle.ideas` field addition from Task 2 to Task 1**
- **Found during:** Task 1 (Add IdeaDTO)
- **Issue:** The plan's Task 2 action describes making `exportData(...)` "emit an `ideas:` array in the bundle," which requires `HabitExportBundle` (a struct in `ExportImportDTOs.swift`, Task 1's file) to declare an `ideas: [IdeaDTO]` stored property, memberwise-init parameter, and decode-if-present branch. Doing this purely in Task 2 (which only touches `ExportImportService.swift` and `SettingsView.swift`) was not possible without also editing `ExportImportDTOs.swift` in Task 2.
- **Fix:** Added the `IdeaDTO` struct AND the `HabitExportBundle.ideas` field/decoder support together in Task 1's commit, verified Task 1 builds standalone (unused-but-valid `ideas` bundle field with no callers yet — Swift allows this), then had Task 2 wire the actual `exportData`/`importReplace`/`deleteAll`/`SettingsView` call sites against it.
- **Files modified:** HabitsTracker/Services/ExportImportDTOs.swift (both commits touch this file)
- **Verification:** `xcodebuild ... build` exits 0 after both Task 1 and Task 2 commits individually.
- **Committed in:** 2652bf4 (Task 1), 9d891f3 (Task 2)

---

**Total deviations:** 1 auto-fixed (1 blocking — task-boundary only, no file-scope change beyond what the plan's frontmatter already declared)
**Impact on plan:** No scope creep — `ExportImportDTOs.swift` was already listed in the plan's `files_modified`. Both commits build clean in sequence; no behavior differs from what the plan specified.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Idea now fully participates in the export/import backup round-trip (schemaVersion 6), keeping Phase 5's baseline DoD green as later plans (promotion flows, Hub inbox, quick-add) build on top of the `Idea` model.
- Runtime export→wipe→import exercise on a real device/simulator is deferred to the owner device check bundled with a later phase (matching the Clip 04-04 precedent) — build + grep verification only at this stage.
- No blockers for 05-04 onward.

---
*Phase: 05-ideas-promotion-e*
*Completed: 2026-07-11*

## Self-Check: PASSED

All created/modified files found on disk; both task commits (2652bf4, 9d891f3) found in git log.
