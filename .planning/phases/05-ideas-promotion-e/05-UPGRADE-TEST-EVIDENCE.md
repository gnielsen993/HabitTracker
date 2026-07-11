# Phase 5 — Schema Upgrade Test Evidence (automated)

**Date:** 2026-07-10
**Result:** ✅ PASS — inferred migration preserves the Phase-4 store when the `Idea` `@Model` (+ `Domain.ideas` nullify inverse) is added.
**Gate:** 05-04 Task 1 (IDEA-01 schema upgrade test) — the data-integrity + no-crash portion.
**Method:** Real-app `xcrun simctl` procedure per `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` §Step 4, made deterministic with a sentinel — reusing the exact CLIP-01 precedent (`04-clips-d/04-UPGRADE-TEST-EVIDENCE.md`) since the in-process SwiftData test path remains unreliable on this toolchain (§9.7).

## Procedure

1. Clean-booted iPhone 17 sim (`82FBCB79-5A7B-4627-8CFD-F72BBF7A3C81`), erased.
2. Built the **pre-Idea** app from `793b220` ("docs(05): add pattern map" — the last commit before `c5b7eb0` introduced `Idea.swift`; confirmed via `git show 793b220:HabitsTracker/Models/Idea.swift` → path does not exist) in a throwaway Desktop-sibling worktree (`../htbuild_old_worktree`, so `../DesignKit` resolved, §9.14). Build exit 0 (warnings only, no errors).
3. Installed + launched the OLD app → `BootstrapService.seedIfNeeded` auto-seeded **16 domains / 10 habits / 2 collections / 1 daily entry / 0 rules / 0 clips / 0 collection items**. Terminated to flush the store.
4. **Injected a sentinel** a fresh seed can never reproduce: renamed one seeded domain (`Lifestyle`, Z_PK 1) to `SENTINEL_IDEA_MIGRATION_4K2P` directly in `default.store` via `sqlite3`, then `PRAGMA wal_checkpoint(FULL)`.
5. Built the **with-Idea** app from `main` (`7e5507c`, schemaVersion-6, `Idea` registered + `Domain.ideas` nullify inverse). Build exit 0 (warnings only). Installed **over** the existing store (no uninstall/erase between installs) and launched → triggers plan-less inferred migration.
6. Inspected the resulting on-disk store with `sqlite3`.

## Observations

| Check | Before (pre-Idea) | After (with-Idea) | Verdict |
|-------|--------------------|--------------------|---------|
| App launches without crashing | — | PID alive in `launchctl list` (13362) | ✅ no crash |
| Sentinel domain (`SENTINEL_IDEA_MIGRATION_4K2P`) | present (injected) | **present** | ✅ data genuinely migrated, not re-seeded |
| ZDOMAIN rows | 16 | 16 | ✅ preserved |
| ZHABIT rows | 10 | 10 | ✅ preserved |
| ZCOLLECTION rows | 2 | 2 | ✅ preserved |
| ZCOLLECTIONITEM rows | 0 | 0 | ✅ preserved |
| ZCLIP rows | 0 | 0 | ✅ preserved |
| ZRULE rows | 0 | 0 | ✅ preserved |
| ZDAILYENTRY rows | 1 | 1 | ✅ preserved |
| `ZIDEA` table | absent | present, 0 rows | ✅ additive expansion applied |

The sentinel is the decisive control: because it is a value the seed logic never produces, its survival proves the new build read and migrated the *old* store's actual contents rather than starting a fresh seeded store. Every persisted-row-count check (domains through daily entries) matched exactly pre- vs. post-migration, so the assertion covers the full Phase-4 model set, not just domains/habits.

## No forbidden moves

- `grep -rn "migrationPlan" HabitsTracker/` → no matches.
- `HabitsTrackerApp.swift` still constructs the container plan-less via `.modelContainer(for: [...])`, with `Idea.self` appended additively to the existing type list (`Domain`, `Habit`, `DailyEntry`, `HabitState`, `Rule`, `Collection`, `CollectionItem`, `Clip`, `Idea`).

## Scope / what this does and does not cover

- **Covered (automated):** no-crash launch over an existing Phase-4 store; prior data (domains/habits/collections/collectionItems/clips/rules/dailyEntries) preserved intact; `Idea` type present and empty after migration. This is exactly the playbook Step-4 assertion, extended to the full Phase-4 model set.
- **Not covered here (still owner device sign-off per the Task 2 checkpoint):** the interactive Ideas capture/promote *flow* (global quick-add, Hub inbox, File vs Promote), VoiceOver/Dynamic Type, and the Settings export→wipe→import round-trip for `Idea`. Those need real UI interaction and can't be driven headlessly here.

## Reproduce

See `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` §Step 4 (bundle id `lauterstar.HabitsTracker`, last-pre-Idea SHA `793b220`). Same sentinel-injection technique as `04-clips-d/04-UPGRADE-TEST-EVIDENCE.md` — inject between the old-app terminate and the new-app install for a data-integrity assertion that doesn't depend on eyeballing the UI.
