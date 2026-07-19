# Schema Migration Playbook (HabitsTracker)

The recipe for changing `@Model` types in HabitsTracker without crashing
existing users on launch. Read this BEFORE adding, removing, or renaming a
SwiftData model field — and before any work on `Docs/LIFESTYLE_HUB_PLAN.md`,
which is schema-expansion by definition.

> Adapted from the sibling `FitnessTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md`,
> which documents the same failure modes the hard way. The rules are identical;
> only the bundle id, model set, and container-construction site differ.

## TL;DR

1. Construct the container **plan-less**. HabitsTracker does this today via
   the SwiftUI modifier in `HabitsTrackerApp.swift`:
   ```swift
   .modelContainer(for: [Category.self, Habit.self, DailyEntry.self, HabitState.self])
   ```
   There is **no** `migrationPlan:` argument and no explicit `SchemaMigrationPlan`.
   The plan-less path uses inferred lightweight migration, which handles every
   additive change we ship and dodges the Obj-C `NSException` the explicit plan
   throws on storage-equivalent adjacent versions.
2. New fields must be **optional or have a default value**. Never add a
   required-no-default field — inferred migration can't backfill the column for
   existing rows.
3. Renames go through **`@Attribute(originalName: "old")`**, never a migration
   plan. A bare rename is interpreted as drop + add and loses data.
4. After every model change, run the **upgrade test** (below) before merging.

If you only remember one thing: **do not add a `migrationPlan:` argument to
`ModelContainer(...)` / `.modelContainer(...)`.** The sibling repo proved it
crashes with an uncatchable Obj-C exception.

## Current state of HabitsTracker

- Live `@Model` types (in `HabitsTracker/Models/`): `Domain` (renamed from
  `Category` via `@Attribute(originalName:)` in Phase 1), `Habit`, `DailyEntry`,
  `HabitState`, `Rule` (Phase 2), `Collection` + `CollectionItem` (Phase 3),
  `Clip` (Phase 4), `Idea` (Phase 5), and `HabitScheduleRevision` (experience
  redesign). The container type list in `HabitsTrackerApp.swift` is:
  ```swift
  .modelContainer(for: [
      Domain.self, Habit.self, DailyEntry.self, HabitState.self,
      HabitScheduleRevision.self, Rule.self, Collection.self,
      CollectionItem.self, Clip.self, Idea.self
  ])
  ```
- Container is built by the `.modelContainer(for:)` modifier — **no
  `VersionedSchema` scaffolding exists yet.** Inferred migration runs directly
  against the live class shapes.
- Export/Import backup exists (`Services/ExportImportService.swift`, currently
  `schemaVersion = 7`) as the fallback safety net — bump + round-trip test it
  whenever a new `@Model` type or field is added.
- Bundle id: `lauterstar.HabitsTracker` (migrated from `gn.HabitsTracker` on
  2026-07-06 under Gabe's company account, team `JCWX4BK8GW`; see CLAUDE.md §1).

## The recipe — adding a new field (the common case)

### Step 1: change the live class
```swift
// HabitsTracker/Models/<Model>.swift
@Model
final class Habit {
    // ...existing fields...
    var originRuleID: UUID?          // optional with nil default ✓
    var someFlag: Bool = false       // non-optional with default ✓
    // var required: String          // ✗ DO NOT add required-no-default
}
```
Rules for the new field:
- Optional, OR has a default value. SwiftData fills existing rows during
  inferred migration.
- Never required-without-default.

### Step 2: register any new `@Model` class
A brand-new model class (e.g. `Rule`, `Collection`, `CollectionItem`, `Idea`,
`Clip` from the Lifestyle Hub plan) must be added to the container's type list
in `HabitsTrackerApp.swift`:
```swift
.modelContainer(for: [
    Category.self, Habit.self, DailyEntry.self, HabitState.self,
    Rule.self, /* ...new types... */
])
```
Adding a new standalone model is additive and safe under inferred migration.

### Step 3: renames use `@Attribute(originalName:)`
The one risky move in the Hub plan is `Category` → `Domain`. If you rename the
class (vs. relabel in UI only), keep it plan-less and annotate:
```swift
@Model
final class Domain {            // was: Category
    @Attribute(originalName: "name") var name: String
    // ...
}
```
Never reach for a `SchemaMigrationPlan` / `MigrationStage` to do this.

### Step 4: run the upgrade test (mandatory before merge)
```bash
# Stash work in progress.
git stash -u

# Check out the last shipped commit and build the OLD app.
git checkout <last-shipped-sha>
xcrun simctl uninstall booted lauterstar.HabitsTracker
xcodebuild -scheme HabitsTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/htbuild_old build
xcrun simctl install booted \
  /tmp/htbuild_old/Build/Products/Debug-iphonesimulator/HabitsTracker.app
xcrun simctl launch booted lauterstar.HabitsTracker

# Use the app — create a domain, toggle a few habits, add a rule, add a
# collection with an item, log a day. Quit. (Exercise every persisted type so
# the "data intact" assertion covers the full model set, not just habits.)
xcrun simctl terminate booted lauterstar.HabitsTracker

# Restore work in progress, build the NEW app over the existing store.
git checkout main
git stash pop
xcodebuild -scheme HabitsTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/htbuild_new build
xcrun simctl install booted \
  /tmp/htbuild_new/Build/Products/Debug-iphonesimulator/HabitsTracker.app
xcrun simctl launch booted lauterstar.HabitsTracker

# App must launch without crashing. Domains/habits/rules/collections/history
# from the old build must still be visible.
sleep 6
xcrun simctl spawn booted launchctl list | grep -i habits
# PID > 0 = alive. Empty = crashed.
```
If the new build crashes, do NOT merge. Either (a) figure out why inferred
migration rejected the change, or (b) make the change purely additive.

## Why the upgrade test is a `simctl` real-app run, not an XCTest

In-process SwiftData container tests are **unreliable on this toolchain**
(Xcode 26.3 / iOS 26 sim, verified 2026-07-09). HabitsTracker's own `@Model`
persistence tests crash the XCTest host at 0.000s (CLAUDE.md §9.7). The sibling
`FitnessTracker` repo built the "seed a frozen on-disk store, reopen plan-less,
assert survival" XCTest pattern (`SchemaV9ToV10MigrationTests`) — and that test
**also fatal-errors on this machine** (`Failed to cast model … to WorkoutSession`,
`** TEST FAILED **`, 0 tests executed). So an automated in-process migration
test is NOT a trustworthy substitute here. The **actual shipping app** builds
and opens its on-disk container fine — the crash is XCTest-host-specific — which
is exactly why the Step 4 gate drives the real app via `xcrun simctl` and
inspects the on-disk store, rather than asserting inside a test process.

## If you ever introduce explicit versioned schemas

Not present today. If the model set grows enough to want explicit
`HabitsTrackerSchemaV{N}` enums for clarity, follow the sibling repo's frozen-
nested pattern (`FitnessTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md`): freeze each
shipped version with inlined nested `@Model` snapshots, point the current
version at the live top-level classes, and **still** construct the container
plan-less. Never mutate a shipped frozen schema.

## Forbidden moves

- ❌ `ModelContainer(for: schema, migrationPlan: …)` — throws NSException, kills the process.
- ❌ Adding a required, no-default field — inferred migration can't fill the column.
- ❌ Renaming a field/class without `@Attribute(originalName:)` — interpreted as drop + add, data lost.
- ❌ Changing a field's type — same issue, treated as drop + add.
- ❌ Mutating a frozen versioned-schema snapshot, once any exist.

## Always-available safety net

Export/Import JSON (`Services/ExportImportService.swift`) is the manual recovery
path regardless of migration outcome. Keep `schemaVersion` bumped and round-trip
tested whenever new `@Model` types or fields are added (Lifestyle Hub plan §7).

## See also

- `CLAUDE.md` §9.12 — short pointer to this playbook.
- `HabitsTracker/HabitsTrackerApp.swift` — the plan-less `.modelContainer(for:)` site.
- `Docs/LIFESTYLE_HUB_PLAN.md` §7 — the migration approach for the hub build.
- `FitnessTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md` — the original, with the full
  "why we ship without a migration plan" post-mortem.
