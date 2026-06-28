# Constraints

Synthesized from the SPEC's technical sections and the DOC-type constitution + migration
playbook. The classifier tagged CLAUDE.md and SCHEMA_MIGRATION_PLAYBOOK.md as DOC, but both
carry hard technical constraints (noted in their classification `notes`); those are extracted
here so downstream planning treats them as binding, not background.

These constraints complement (do not contradict) the SPEC's locked decisions. Verified: the
SPEC §7 migration approach and the playbook's Forbidden Moves agree exactly — no conflict.

---

## CON-plan-less-migration
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md (TL;DR #1, Forbidden Moves)
- type: schema
- content: Construct the SwiftData container plan-less via
  `.modelContainer(for: [Category.self, Habit.self, DailyEntry.self, HabitState.self])`.
  There is NO `migrationPlan:` argument and no explicit `SchemaMigrationPlan`. The plan-less
  path uses inferred lightweight migration. FORBIDDEN: `ModelContainer(for: schema,
  migrationPlan: ...)` — proven to throw an uncatchable Obj-C NSException and kill the process
  (sibling FitnessTracker repo proved it the hard way).

## CON-additive-fields-only
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md (TL;DR #2, recipe Step 1, Forbidden Moves)
- type: schema
- content: New `@Model` fields must be optional OR have a default value. NEVER add a
  required-no-default field (inferred migration cannot backfill the column for existing rows).
  NEVER change a field's type (treated as drop + add, data lost). New standalone `@Model`
  classes (Rule, Collection, CollectionItem, Idea, Clip) are additive and safe; register each
  in the container type list in `HabitsTrackerApp.swift`.

## CON-renames-via-originalName
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md (TL;DR #3, recipe Step 3)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§7)
- type: schema
- content: Renames go through `@Attribute(originalName: "old")`, never a migration plan. A bare
  rename is interpreted as drop + add and loses data. The `Category` -> `Domain` rename is the
  one store-incompatible move; decide before Phase A between (a) keep Swift class `Category`,
  relabel "Domain" in UI only (zero migration), or (b) rename via `@Attribute(originalName:
  "Category")` kept plan-less. The migration-plan path is struck.

## CON-mandatory-upgrade-test
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md (TL;DR #4, recipe Step 4)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§6 baseline DoD)
- type: nfr
- content: After every model change, run the upgrade test before merging: build the OLD shipped
  app, create data, then build the NEW app over the existing store. App must launch without
  crashing and all prior data (categories/habits/history) must remain visible. PID > 0 = alive.
  If the new build crashes, do NOT merge. This is part of every phase's baseline DoD.

## CON-export-import-safety-net
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md (Always-available safety net)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/CLAUDE.md (§1 Data safety)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§7)
- type: nfr
- content: Export/Import JSON (`Services/ExportImportService.swift`, currently `schemaVersion = 1`)
  is the manual recovery path. Implement Export/Import in every app (schemaVersion + replace
  import at minimum). Bump `schemaVersion` and keep round-trip tests green whenever new `@Model`
  types or fields are added. Never break existing local data without a migration path or
  export/import workaround.

## CON-bundle-id-frozen
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/CLAUDE.md (§1 Data safety)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md (Current state)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§8 Q5, §11)
- type: protocol
- content: Bundle ID is `gn.HabitsTracker` and must NOT change — even if the product is renamed
  to reflect the hub. Avoid bundle ID / App Group ID changes.

## CON-offline-only-v1
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/CLAUDE.md (§1 Stack)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§8 Q1)
- type: nfr
- content: Offline-only in v1 (no cloud/backends). Constrains Clip rich previews: any network
  thumbnail fetch conflicts with this rule. v1 ships URL + manual title/note only; opt-in
  on-demand fetch is deferred past Phase D.

## CON-design-tokens-only
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/CLAUDE.md (§1 Design, §2 DesignKit)
- type: nfr
- content: No hard-coded colors in UI. All UI uses DesignKit semantic tokens. Theme identity is
  Balanced Luxury (light = warm cream, dark = charcoal; accents constrained to forest, navy,
  maroon/oxblood, walnut, stone). Custom domains pick a color TOKEN, not a raw color. New
  components (status chip, position stepper, Hub grid tile) extract into DesignKit ONLY once
  proven in 2+ apps.

## CON-app-structure-and-engines
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/CLAUDE.md (§2-4)
- type: protocol
- content: Keep the shared app structure (Models/, Services/, Features/, UIComponents/,
  Widgets/, Resources/, Docs/). Domain models (Habit, Rule, etc.) and business engines stay in
  the app, NOT DesignKit. Habit engines (Streak / WeeklyGoal / Stats) apply ONLY to habits —
  not to rules, collections, ideas, or clips. Reuse existing patterns; prefer the smallest
  change; do not invent new architectures. The Domain generalization is a generalization, not
  a rewrite — existing engines, seeding, export/import, and management dashboard carry over.
