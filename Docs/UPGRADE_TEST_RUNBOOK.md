# DOM-01 Upgrade Test Runbook (Category → Domain merge gate)

**Owner-side / manual procedure.** This is the hard merge gate for **DOM-01**: proof that
renaming the `@Model` class `Category` → `Domain` (plan 01-02) preserves all existing local
data across an in-place app upgrade. The planning SPEC is planning-only; this runbook is run
by the owner on their machine and its PASS is consumed by **plan 01-02's checkpoint** before
any Hub UI is built.

Source of truth for the underlying recipe: **`Docs/SCHEMA_MIGRATION_PLAYBOOK.md`** (Step 4,
the mandatory upgrade test). This runbook extracts that Step-4 sequence into a standalone,
runnable DOM-01 gate with concrete SHAs and the FAIL fallback recorded.

---

## Why this is manual (not a unit test)

The risk surface is the on-device SwiftData SQLite store written by the OLD build. A
`@Model` **class** rename can be interpreted by inferred migration as drop-old-entity +
add-new-entity (silent data loss) — `@Attribute(originalName:)` is only authoritative for
**property** stored-name mapping, not entity/table renames. The only way to prove rows survive
is to install the prior shipped build, create data, then install the new build **over the same
store**. That cannot be expressed as an in-process unit test.

---

## Fixed parameters

| Parameter | Value |
|-----------|-------|
| Bundle id | `gn.HabitsTracker` |
| Scheme | `HabitsTracker` |
| Simulator | `iPhone 17` |
| Last-shipped build SHA (the OLD build) | `f564d15` |
| New build | your working branch with the `Category` → `Domain` rename |

---

## Procedure

### 1. Build and install the OLD (last-shipped) build

```bash
# From the repo root, on a clean tree (commit or set aside in-progress work first).
git checkout f564d15

xcrun simctl uninstall booted gn.HabitsTracker
xcodebuild -scheme HabitsTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/htbuild_old build
xcrun simctl install booted \
  /tmp/htbuild_old/Build/Products/Debug-iphonesimulator/HabitsTracker.app
xcrun simctl launch booted gn.HabitsTracker
```

### 2. Create data in the OLD build, then quit

In the running OLD app, by hand:

- **Create a category** (a new, non-seeded one so you can spot it after the upgrade).
- **Toggle a few habits** on the Today screen.
- **Log a day** (add a note / complete entries for today).

Then terminate so the store is flushed:

```bash
xcrun simctl terminate booted gn.HabitsTracker
```

### 3. Build and install the NEW build over the SAME store

Do **not** uninstall — installing over the top preserves the existing SwiftData store, which
is the entire point of the test.

```bash
git checkout <your-rename-branch>   # the branch with Category → Domain (plan 01-02)
xcodebuild -scheme HabitsTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/htbuild_new build
xcrun simctl install booted \
  /tmp/htbuild_new/Build/Products/Debug-iphonesimulator/HabitsTracker.app
xcrun simctl launch booted gn.HabitsTracker
```

### 4. Confirm the app is alive (PID > 0)

```bash
sleep 6
xcrun simctl spawn booted launchctl list | grep -i habits
# PID > 0 = alive. Empty / no row = crashed during migration.
```

---

## Pass criterion

The upgrade test PASSES only if **both** hold:

1. The NEW build **launches without crashing** — `launchctl list | grep -i habits` shows a
   row with **PID > 0**.
2. **All prior data is visible**: every category you had in the OLD build now appears as a
   **Domain** (including the custom one you created), each domain still owns its **habits**
   (the `habits` inverse relationship survived), and the **logged day / toggled habits** from
   the OLD build are still present in history.

If the app launches but the Hub/Today is empty, or `FetchDescriptor<Domain>()` returns 0 on a
store that had categories, that is a **FAIL** (silent data loss), not a pass.

---

## FAIL action (recorded fallback)

If rows do **NOT** survive the rename:

> **Do NOT merge.** Pivot **D-01** to **relabel-only**: keep the `@Model` class named
> `Category` and surface the label "Domain" in the UI only (zero migration), **before** any
> Hub UI work. Carry `isFocused` as an additive defaulted field on the still-named `Category`
> class. As a data-carry-over backstop, the Export → Import JSON path
> (`Services/ExportImportService.swift`) remains the manual recovery route. **Never** reach for
> a `SchemaMigrationPlan` / `migrationPlan:` to "fix" this — it throws an uncatchable Obj-C
> NSException and kills the process (see `Docs/SCHEMA_MIGRATION_PLAYBOOK.md`, Forbidden moves).

---

## See also

- `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` — Step 4 upgrade test, `@Attribute(originalName:)`
  rename recipe, and the Forbidden moves this runbook enforces.
- `.planning/phases/01-domain-generalization-a/01-VALIDATION.md` — the DOM-01 manual-only
  verification entry this runbook satisfies.
