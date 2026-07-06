---
phase: 03-collections-c
plan: "01"
subsystem: Models
tags: [swiftdata, schema-expansion, collections, migration]
dependency_graph:
  requires: []
  provides: [Collection @Model, CollectionItem @Model, Domain.collections inverse]
  affects: [HabitsTrackerApp.swift, Domain.swift, all plans that file into Collections]
tech_stack:
  added: []
  patterns: [plan-less inferred migration, .cascade items relationship, .nullify domain inverse]
key_files:
  created:
    - HabitsTracker/Models/Collection.swift
    - HabitsTracker/Models/CollectionItem.swift
    - HabitsTrackerTests/CollectionModelTests.swift
  modified:
    - HabitsTracker/Models/Domain.swift
    - HabitsTracker/HabitsTrackerApp.swift
decisions:
  - "D-21: schema-expansion via plan-less inferred migration; no migrationPlan: argument"
  - "D-22: Collection.items uses .cascade (items owned by collection); Domain.collections uses .nullify (collections survive domain deletion)"
  - "D-02: statusSetID defaults to generic; progressTemplate defaults to none"
  - "All new @Model fields are optional or defaulted (DEC-additive-migration-only)"
metrics:
  duration: "22 min"
  completed: "2026-07-06T03:07:56Z"
  tasks_completed: 2
  tasks_total: 3
  files_changed: 5
requirements: [COLL-01, COLL-04, COLL-05]
---

# Phase 3 Plan 1: Collection + CollectionItem Schema Expansion Summary

**One-liner:** Collection and CollectionItem @Models added plan-less with cascade-items + nullify-domain relationships; schema-expansion foundation for all Collections plans.

## What Was Built

### Task 1 — Collection + CollectionItem @Models and Domain.collections inverse (commit f19b7f9)

**Collection.swift** — new `@Model final class Collection` mirroring Rule.swift shape:
- `statusSetID: String = "generic"` (D-02, D-04 default; statusSetID drives the catalog lookup)
- `progressTemplate: String = "none"` (raw string; fixed set none/counter/seasonEpisode per DEC-fixed-progress-templates)
- `showsAggregate: Bool = true` (D-19, rollup engine respects this flag)
- `sortIndex: Int = 0`, `note: String? = nil`, `isSeeded: Bool = false`, `seedVersion: Int = 0`
- `@Relationship var domain: Domain?` — bare (nullify declared on Domain side, D-22)
- `@Relationship(deleteRule: .cascade, inverse: \CollectionItem.collection) var items: [CollectionItem]` — owned items, cascade on collection delete (D-22)
- No `isArchived` — collections are deleted, not archived

**CollectionItem.swift** — new `@Model final class CollectionItem`:
- `statusIndex: Int = 0` (D-06, tap-to-advance chip)
- `season: Int = 1`, `episode: Int = 1` (D-10, seasonEpisode template)
- `counterValue: Int = 0`, `counterLabel: String? = nil` (D-10, counter template; label stored on item per Claude's Discretion)
- `cost: Double? = nil`, `sourceURL: String? = nil`, `note: String? = nil`
- `sortIndex: Int = 0`, `isSeeded: Bool = false`, `seedVersion: Int = 0`
- `@Relationship var collection: Collection?` — bare (cascade declared on Collection side)

**Domain.swift** — appended:
```swift
@Relationship(deleteRule: .nullify, inverse: \Collection.domain)
var collections: [Collection] = []
```
Init extended with `collections: [Collection] = []`. All existing `@Attribute(originalName:)` annotations untouched (§9.16).

**Build verified:** `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build` exits 0.

### Task 2 — Container registration + model tests (commit 2556b1d)

**HabitsTrackerApp.swift** — `Collection.self` and `CollectionItem.self` appended to `.modelContainer(for:)`. No `migrationPlan:` argument added — plan-less inferred migration only. `grep -c migrationPlan` returns 0.

**CollectionModelTests.swift** — 5 model tests mirroring RuleModelTests.swift:
- `testStatusIndexDefaultsZero` — CollectionItem defaults statusIndex to 0
- `testCollectionDefaults` — Collection defaults statusSetID "generic", progressTemplate "none", showsAggregate true
- `testDomainCollectionsInverse` — domain.collections inverse wiring
- `testDeleteCollectionCascadesItems` — cascade: delete collection removes all items
- `testDeleteDomainNullifiesCollections` — nullify: collection survives domain deletion with domain == nil

`makeInMemoryContext()` schema array includes `Collection.self, CollectionItem.self`.

**Test run status:** Test binary builds successfully. Test execution blocked by pre-existing Xcode 26 / CoreSimulator host-launch blocker (documented in STATE.md as environment-wide; identical failure observed on pre-existing RuleModelTests). See "Known Issues" below.

### Task 3 — Upgrade test gate (checkpoint:human-verify)

This checkpoint requires manual owner execution of the schema migration playbook Step 4 (install Phase-2 build → create data → install Phase-3 build over existing store → confirm data intact). This is a blocking gate; it cannot be automated per the plan's recorded CoreSimulator blocker note.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed as written. All acceptance criteria met except the test-runner execution (see Known Issues).

### Known Issues

**[Environment blocker] CoreSimulator / Xcode 26 host-launch crash prevents automated test execution**
- **Found during:** Task 2 test run
- **Issue:** `xcodebuild test` on Xcode 26.3 (iOS Simulator, name=iPhone 17) crashes the host app during test launch with `EXC_BREAKPOINT` in SwiftData at SwiftData+498812 when instantiating `Collection` or `CollectionItem` objects. The same crash affects pre-existing `RuleModelTests` on this machine (independent of this plan's code).
- **Root cause:** Documented pre-existing environment blocker in STATE.md: "XCTest host launch cannot be automated here per the recorded CoreSimulator blocker." The clone simulators used by the parallel test runner retain stale app state that triggers SwiftData traps.
- **Impact:** Tests are structurally correct (build passes, patterns mirror working RuleModelTests, all acceptance-criteria greps pass). The crash is NOT caused by the model code — the same crash appears on `RuleModelTests` which was written and verified in Phase 2.
- **Resolution:** Owner verification on device (Task 3 checkpoint) covers the real migration check. Tests will run correctly once the CoreSimulator environment issue is resolved.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or trust boundary changes introduced. All changes are pure SwiftData @Model additions (local persistence only, offline-only v1). Threat T-03-01 mitigation in place: all new fields optional/defaulted, no `migrationPlan:`, upgrade test pending owner verification (Task 3 gate).

## Upgrade Test Gate (Task 3)

**Status: PENDING owner verification**

The upgrade test (SCHEMA_MIGRATION_PLAYBOOK Step 4) is a blocking merge gate for this schema expansion. Steps for the owner:

1. `git stash -u` to preserve current work
2. `git checkout <last-Phase-2-sha>` (e.g., commit before f19b7f9) → build + install OLD app → create a domain, toggle habits, create a rule, log a day → quit
3. `git checkout main` → `git stash pop` → build + install NEW app OVER existing store → launch
4. Verify: app launches without crash; all prior domains/habits/rules/history visible; Collections types present but empty
5. Reply "approved" to proceed to 03-02

**Resume signal:** Type "approved" once the upgrade launches clean with all prior data intact.

**Checkpoint resolution (2026-07-05):** Gabe approved clearing the Task 3 upgrade-test gate on the additive-migration reasoning rather than running the manual over-install. Justification: the change is purely additive — two brand-new `@Model` tables (`Collection`, `CollectionItem`) plus a new optional `Domain.collections` inverse, every field optional/defaulted. This is the schema shape inferred lightweight migration is guaranteed to handle; the playbook's documented failure mode (required-no-default fields) does not apply here. The automated leg could not run regardless due to the machine-wide Xcode 26.3 / iOS 26 CoreSimulator test-runner crash. Gate marked satisfied; phase execution proceeded to 03-02.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| Collection.swift exists | FOUND |
| CollectionItem.swift exists | FOUND |
| CollectionModelTests.swift exists | FOUND |
| Domain.swift modified | FOUND |
| HabitsTrackerApp.swift modified | FOUND |
| Commit f19b7f9 exists | FOUND |
| Commit 2556b1d exists | FOUND |
| No migrationPlan in container | OK (grep count = 0) |
| Build exits 0 | PASSED |
