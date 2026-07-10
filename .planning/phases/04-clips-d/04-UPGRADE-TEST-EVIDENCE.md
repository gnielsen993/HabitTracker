# Phase 4 — Schema Upgrade Test Evidence (automated)

**Date:** 2026-07-09
**Result:** ✅ PASS — inferred migration preserves Phase-3 data when the `Clip` `@Model` is added.
**Gate:** 04-01 Task 3 (CLIP-01 schema upgrade test) — the data-integrity + no-crash portion.
**Method:** Real-app `xcrun simctl` procedure per `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` §Step 4, made deterministic with a sentinel (no hand-tapping, no XCTest — the in-process SwiftData test path is unreliable on this toolchain per §9.7).

## Procedure

1. Clean-booted iPhone 17 sim (`82FBCB79…`), erased.
2. Built the **pre-Clip** app from `f8d6cf6` (confirmed: no `Clip.swift`, 0 `Clip.self` container refs) in a throwaway Desktop-sibling worktree (so `../DesignKit` resolved, §9.14). Build exit 0.
3. Installed + launched the OLD app → `BootstrapService.seedIfNeeded` auto-seeded **16 domains / 10 habits / 2 collections / 1 daily entry**. Terminated to flush the store.
4. **Injected a sentinel** a fresh seed can never reproduce: renamed one seeded domain to `SENTINEL_MIGRATION_9Z7Q` directly in `default.store` via `sqlite3`, then `PRAGMA wal_checkpoint(FULL)`.
5. Built the **with-Clip** app from `main` (schemaVersion-5, `Clip` registered). Build exit 0. Installed **over** the existing store (no uninstall) and launched → triggers plan-less inferred migration.
6. Inspected the resulting on-disk store with `sqlite3`.

## Observations

| Check | Before (pre-Clip) | After (with-Clip) | Verdict |
|-------|-------------------|-------------------|---------|
| App launches without crashing | — | PID alive in `launchctl list` | ✅ no crash |
| Sentinel domain (`SENTINEL_MIGRATION_9Z7Q`) | present (injected) | **present** | ✅ data genuinely migrated, not re-seeded |
| ZDOMAIN rows | 16 | 16 | ✅ preserved |
| ZHABIT rows | 10 | 10 | ✅ preserved |
| ZCOLLECTION rows | 2 | 2 | ✅ preserved |
| `ZCLIP` table | absent | present, 0 rows | ✅ additive expansion applied |

The sentinel is the decisive control: because it is a value the seed logic never produces, its survival proves the new build read and migrated the *old* store's actual contents rather than starting a fresh seeded store. (The app-data container UUID shifts across erase/reinstall churn, but the store content carried across — verified by scanning every container on the device: exactly one store, and it holds the sentinel.)

## Scope / what this does and does not cover

- **Covered (automated):** no-crash launch over an existing Phase-3 store; prior data preserved intact; `Clip` type present and empty after migration. This is exactly the playbook Step-4 assertion.
- **Not covered here (still owner device UAT — see `04-HUMAN-UAT.md` item 2):** the interactive Clips *flow* — create/toggle/Open-Link/edit/delete, the Airplane-Mode offline gate, VoiceOver/Dynamic Type, and the Settings export→wipe→import round-trip. Those need real UI interaction and can't be driven headlessly here.

## Reproduce

See `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` §Step 4 (bundle id `lauterstar.HabitsTracker`, last-shipped SHA `f8d6cf6`). Add the sentinel step between the old-app terminate and the new-app install for a data-integrity assertion that doesn't depend on eyeballing the UI.
