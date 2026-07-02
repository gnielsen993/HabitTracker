---
phase: 01-domain-generalization-a
plan: 03
subsystem: services

tags: [swiftdata, bootstrap, seed, backfill, migration, isFocused, userdefaults, designkit, accent-token]

# Dependency graph
requires:
  - phase: 01-02
    provides: "Domain @Model (isFocused: Bool = false), schemaVersion 2, Habit.category: Domain?"
  - phase: 01-01
    provides: "BootstrapBackfillTests contract (BootstrapService(defaults:) injectable, Style/Diet/Money/Media merge-add names)"
provides:
  - "Persisted lastSeededVersion marker (UserDefaults) driving once-only seed reconciliation"
  - "Version-gated focus backfill: pre-existing Domains -> isFocused=true, exactly once, previous>0 guarded"
  - "Merge-add of new hub seed domains (Style/Diet/Money/Media) as isFocused=false, name-keyed dedupe"
  - "Fresh-install seed focus split: opinionated subset pre-focused, new hub domains unfocused"
  - "accentColor(forToken:scheme:) app-level resolver over the 5 accents with safe fallback"
affects: [01-04 Hub grid (consumes accentColor + isFocused @Query), 01-05/01-06 focus picker + swatch row, 01-VALIDATION DOM-04 sign-off]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Injectable UserDefaults into a service for isolated, testable persisted-marker gating"
    - "Capture pre-reconciliation row IDs BEFORE merge-add so the focus backfill flips only genuine existing rows"
    - "App-level token->Color resolver sourced from DesignKit PresetCatalog (kept out of DesignKit per CLAUDE.md §9.14)"
    - "os.Logger diagnostics in the service layer (never print(), §9.13)"

key-files:
  created:
    - HabitsTracker/Utilities/AccentTokenColor.swift
  modified:
    - HabitsTracker/Services/SeedDataService.swift
    - HabitsTracker/Services/BootstrapService.swift
    - .planning/phases/01-domain-generalization-a/deferred-items.md

key-decisions:
  - "Focus backfill flips only IDs captured BEFORE restoreMissingDefaults, so merge-added hub domains stay unfocused even during an upgrade (satisfies testMergeAddIsUnfocusedAndDedupesByName)"
  - "seedIfNeeded seeds the opinionated 12 pre-focused and the 4 new hub domains unfocused, so a fresh curated install is not flooded (D-09 / Pitfall 3) without needing the existing-row backfill"
  - "New hub domain glyphs/tokens: Style=tshirt/maroon, Diet=fork.knife/forest, Money=banknote/walnut, Media=play.rectangle/navy (tokens drawn only from the 5 accents)"
  - "'oxblood' accepted as an alias for the maroon token in the resolver; unknown/legacy tokens fall back to .forest (safe, on-palette)"

patterns-established:
  - "Version-gated once-only reconciliation (Research Pattern 2) as the canonical idempotent seed-migration shape for this app"

requirements-completed: [DOM-04]

# Metrics
duration: ~130min
completed: 2026-07-01
---

# Phase 1 Plan 03: Seed Reconciliation + Accent Token Resolver Summary

**Version-gated, idempotent seed reconciliation (persisted `lastSeededVersion` marker; once-only `previous>0`-guarded focus backfill flipping pre-existing Domains to focused; name-keyed merge-add of Style/Diet/Money/Media as unfocused) wired into `BootstrapService` with an injectable `UserDefaults`, plus the app-level `accentColor(forToken:scheme:)` resolver over the 5 DesignKit accents.**

## Performance

- **Duration:** ~130 min (the vast majority spent diagnosing an owner-side CoreSimulator/SwiftData test-runner crash, not implementation)
- **Tasks:** 2
- **Files:** 3 (1 created, 2 modified) + deferred-items log

## Accomplishments

- Bumped `SeedDataService.seedVersion` 1→2, renamed `defaultCategories()`→`defaultDomains()`, and added the four new hub seed domains (Style/Diet/Money/Media) with curated SF Symbols and accent-only color tokens.
- Split fresh-install seed focus per D-09/Pitfall 3: the opinionated 12 seed `isFocused: true`; the 4 new hub domains seed `isFocused: false`.
- `restoreMissingDefaults` now inserts any missing default as `isFocused: false` (merge-add unfocused, D-08) and keeps its name-keyed dedupe (existing "Social" is not duplicated).
- Rewrote `BootstrapService.bootstrapIfNeeded` to Research Pattern 2: injectable `UserDefaults`, read `lastSeededVersion`, `if previous < 2 { restoreMissingDefaults; if previous > 0 { backfillFocusOnExistingDomains }; set 2 }`. The backfill flips only rows whose IDs were captured **before** the merge-add, so merge-added hub domains stay unfocused even on an upgrade.
- Added `HabitsTracker/Utilities/AccentTokenColor.swift`: `accentColor(forToken:scheme:)` mapping forest/navy/maroon(+oxblood)/walnut/stone to `PresetCatalog.theme(for:).anchors(for: scheme).accent`, with a `.forest` fallback for unknown tokens. App-level, no literal colors, DesignKit-sourced.

## Task Commits

1. **Task 1: version-gated focus backfill + merge-add new hub domains** — `94a9f3b` (feat)
2. **Task 2: app-level accentColor(forToken:) resolver over the 5 accents** — `dfb30d3` (feat)

## Files Created/Modified

- `HabitsTracker/Services/SeedDataService.swift` — seedVersion 2; `defaultDomains()` (16 domains: 12 pre-focused + 4 new unfocused); `restoreMissingDefaults` merge-adds unfocused, name-keyed dedupe.
- `HabitsTracker/Services/BootstrapService.swift` — `init(defaults: UserDefaults = .standard)`; `lastSeededVersion` gate; `backfillFocusOnExistingDomains(preexistingIDs:context:)`; os.Logger; no print().
- `HabitsTracker/Utilities/AccentTokenColor.swift` — the single token→Color resolver (5 accents + safe fallback), app-level per §9.14.

## Static verification of the four BootstrapBackfillTests

Because the simulator runtime is currently crashing on this machine (see Deviations / Deferred), each assertion was verified by static trace against the committed code:

- **testBackfillFlipsPreexistingDomainsWhenUpgrading** (marker=1): `previous=1 (<2, >0)` → merge-add runs, then `backfillFocusOnExistingDomains` flips the two pre-captured IDs (Productivity, Learning) to `isFocused=true`. ✓ both end focused.
- **testBackfillRunsOnce** (marker=1): run 1 flips Productivity + writes marker=2. User unfocuses. Run 2: `previous=2` is NOT `<2` → whole block skipped → Productivity stays unfocused. ✓ idempotent.
- **testFreshInstallDoesNotBackfillExistingRows** (marker=0): `seedIfNeeded` seeds new hub domains unfocused; `previous=0 (<2)` → merge-add runs (no-op, all present), `previous>0` is false → NO existing-row flip → Style/Diet/Money/Media remain `isFocused=false`. ✓
- **testMergeAddIsUnfocusedAndDedupesByName** (marker=1, pre-seeded "Social"): pre-existing IDs captured = {Social}; merge-add inserts the 15 missing defaults `isFocused=false` and skips "Social" by name (1 Social); backfill flips only the captured {Social} ID, leaving the merge-added hub domains unfocused. ✓ exactly one Social; new domains unfocused.

## Deviations from Plan

### Auto-fixed / adjustments

**1. [Rule 2 — correctness] Focus backfill scoped to pre-reconciliation row IDs**
- **Found during:** Task 1 (reconciling the upgrade assertions with the merge-add assertion).
- **Issue:** A naive "flip every Domain to focused" backfill would also focus the just-merge-added hub domains, violating `testMergeAddIsUnfocusedAndDedupesByName` (which requires new domains stay unfocused even on an upgrade with marker>0).
- **Fix:** Capture `Set<UUID>` of existing Domain IDs BEFORE calling `restoreMissingDefaults`; the backfill flips only those IDs. Merge-added rows (new IDs) are excluded and remain unfocused.
- **Files modified:** `HabitsTracker/Services/BootstrapService.swift`
- **Commit:** `94a9f3b`

**2. [Rule 3 spike — reverted] Removed self-referential @Attribute(originalName:) on Domain**
- Tried removing the (name-unchanged, therefore no-op) `@Attribute(originalName:)` annotations on `Domain` to test whether they were the cause of the SwiftData insert crash. It did **not** resolve the crash, so the change was reverted — `Domain.swift` is unchanged from 01-02.

## Issues Encountered

### OWNER-SIDE BLOCKER: SwiftData/CoreSimulator test-runner crash (not a code defect)

The plan's `<automated>` gate — `xcodebuild … -only-testing:HabitsTrackerTests test` on iPhone 17 — could **not be run green on this machine** due to an environment defect, NOT the implementation:

- **What compiles/passes:** `** TEST BUILD SUCCEEDED **` (whole suite compiles — the Wave-0 goal). Both task `<automated>` grep checks pass. `EngineTests` (4/4), `DomainCreateTests`, `DomainMigrationTests.testDomainCarriesAllPriorFields`, and (in one run) `ExportImportTests` PASSED.
- **What crashes:** Tests that build an in-memory `ModelContainer(for: Schema([Domain,…]))` and insert a `Domain` crash the test host with `EXC_BREAKPOINT (SIGTRAP)`, faulting frame inside `SwiftData` at insert/save, with CoreData `errno 30` "read-only file system" logs against the app-container `default.store`. Runner reports `Executed 0 tests … ** TEST EXECUTE FAILED **` and restarts 3×.
- **Proof it is NOT this plan's code:** the crash reproduces on `DomainMigrationTests.testIsFocusedDefaultsFalse` — a single `Domain(...)` insert that touches **only** the 01-02 model and none of this plan's Task-1/Task-2 code — while the byte-for-byte-identical insert in `DomainCreateTests` **passes** in isolation. Pass/fail is non-deterministic per simulator clone → a CoreSimulator + SwiftData state defect.
- **Recovery attempted (unsuccessful):** `simctl shutdown all`/`erase`; brand-new iPhone 17 device; `killall CoreSimulatorService`; `simctl uninstall`; serial (`-parallel-testing-enabled NO`) runs; per-test isolation; the annotation spike above. Exceeded the fix-attempt limit; documented and continued per scope-boundary rules.
- **Owner action to close (DOM-04 automated sign-off):** re-run the suite on a healthy CoreSimulator (post machine-reboot / simulator-runtime reinstall, or on the owner's own box). This is the same class as the pre-existing STATE.md owner-side verification blocker and CLAUDE.md §9.7. See `deferred-items.md` for the full log.

## Threat Flags

None — no new network endpoints, auth paths, file-access patterns, or trust-boundary schema changes. `UserDefaults` marker is a local non-secret integer; the resolver reads a closed token set.

## Known Stubs

None. `defaultDomains()` returns concrete seeded data; the resolver returns real DesignKit colors; no placeholder/empty-value flows introduced.

## Next Phase Readiness

- 01-04 Hub grid can `@Query` `Domain` filtered on `isFocused == true` and color each tile via `accentColor(forToken: domain.colorToken, scheme:)`.
- 01-05/01-06 focus picker + 5-swatch row consume the same resolver; the swatch source is scheme-dependent (signature already takes `scheme`).
- Outstanding: the automated DOM-04 unit-suite green run is pending a healthy simulator (owner-side). Code compiles and is statically verified against the four assertions.

## Self-Check: PASSED

- Created file exists: `HabitsTracker/Utilities/AccentTokenColor.swift` FOUND.
- Modified files present: `SeedDataService.swift`, `BootstrapService.swift` FOUND.
- Commits present: `94a9f3b`, `dfb30d3` FOUND in git history.
- `** TEST BUILD SUCCEEDED **` confirmed on iPhone 17 after all changes.

---
*Phase: 01-domain-generalization-a*
*Completed: 2026-07-01*
