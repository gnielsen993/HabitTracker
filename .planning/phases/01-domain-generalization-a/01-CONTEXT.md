# Phase 1: Domain Generalization (A) - Context

**Gathered:** 2026-06-28
**Status:** Ready for planning

<domain>
## Phase Boundary

The app's spine becomes Domain-centric and gains a Hub home. `Category` is generalized to
`Domain` (gaining `isFocused`), a new Hub tab shows focused domains as an icon+color grid,
a focus picker and custom-domain creation are added, and the tab bar is recomposed to stay at
four tabs. Today and all existing habit data remain untouched. This phase clarifies HOW to
implement DOM-01…DOM-06 — it does not add the offshoot item types (Rules/Collections/Clips/
Ideas), which are later phases.

</domain>

<decisions>
## Implementation Decisions

### Category → Domain migration (resolves open question Q2)
- **D-01:** Do a **real rename** of the `@Model` class `Category` → `Domain` using
  `@Attribute(originalName: "Category")` where needed, kept **plan-less** (no
  `migrationPlan:`, no `SchemaMigrationPlan` — that path is struck per the playbook).
  Rationale: pre-launch, the type has only ~10 references today and all 5 later phases add
  more (`Rule.domain`, `Collection.domain`, …); relabel-only is debt that compounds.
- **D-02:** The rename is gated by the **mandatory upgrade test** (build old → create data →
  build new over the store → launch with all prior data visible) as a hard merge gate.
- **D-03:** Bump `ExportImportService.schemaVersion` (1 → 2) in the **same change** as the
  rename, and keep the export/import round-trip test green.
- **D-04:** Update the container type list in `HabitsTrackerApp.swift` and all referencing
  files (incl. `Habit.category` relationship, seeding, views) to the new `Domain` name.

### Seed reconciliation + default focus (resolves open question Q3)
- **D-05:** Add `isFocused: Bool` as an **additive, defaulted** field (default `false` for
  SwiftData lightweight migration of existing rows).
- **D-06:** Bump `SeedDataService.seedVersion` **1 → 2**.
- **D-07:** **One-time, version-gated focus backfill** (gated on prior `seedVersion < 2`,
  runs once in `BootstrapService`): flip every **pre-existing** Domain to `isFocused = true`
  so upgraders open the Hub to their familiar 12 — **no empty screen, no data touched.**
- **D-08:** **New** hub seed domains (e.g. Style, Diet, Money, Media) are **merge-added** via
  the existing name-keyed `restoreMissingDefaults` path as `isFocused = false` — so a curated
  install isn't flooded, and the existing "Social" dedupes by name automatically.
- **D-09:** **Fresh installs** seed the opinionated subset **pre-focused** (per the plan's
  "never an empty screen" thesis).
- **D-10:** Pair the merge-add with a **subtle "new domains available in the focus picker"
  hint** so upgraders discover new content rather than have it silently buried.
- **D-11:** Never destroy user data — merge-add only (honors the constitution's seed-merge
  rule). The focus backfill must be idempotent (the `seedVersion` gate guarantees once-only).

### Tab bar recomposition (DOM-03 / DOM-06)
- **D-12:** Target IA is **Today / Hub / Progress / Settings** (4 tabs, no growth). The
  **Calendar tab is removed** to free the slot for Hub.
- **D-13:** Calendar surfaces **inside Progress via a segmented control** at the top
  (`Picker(...).pickerStyle(.segmented)` with **Charts ⇄ Calendar** segments) — full density,
  discoverability preserved.
- **D-14:** Reuse `CalendarMonthHeatmapView` + `DayDetailSheet` near-verbatim; the one
  required edit is **removing the view's own `NavigationStack`/`navigationTitle("Calendar")`**
  so it nests under Progress's stack, and re-anchoring the `selectedDay` sheet there.
- **D-15:** **Today stays visually unchanged.**

### Custom domain creation UX (DOM-05)
- **D-16:** Icon picker is a **curated grid of ~30 hand-picked SF Symbols** (matching the
  restrained aesthetic / existing seeded glyphs), **not** the full system browser and **no
  third-party dependency**. Build as a `DomainIconPicker` sheet with a static `[String]`
  array in a `LazyVGrid`.
- **D-17:** Color is a **closed pick-one-of-5** accent tokens (forest, navy, maroon/oxblood,
  walnut, stone), presented as a horizontal **swatch row** with a selected ring — no color
  wheel, no hex. `colorToken` is valid-by-construction (always a real DesignKit token).

### Claude's Discretion
- The exact ~30-symbol curated icon set (pick lifestyle-relevant SF Symbols consistent with
  the seeded ones; planner/executor may finalize the list).
- The precise visual treatment of the "new domains available" hint (badge vs banner) and the
  Hub grid tile layout, within DesignKit tokens.
- Internal structure/naming of new views (HubView, DomainDetailView, DomainFocusPicker), so
  long as §9.1 (~400-line cap) and §9.2 (reusable views are data-driven) hold.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Plan & requirements
- `Docs/LIFESTYLE_HUB_PLAN.md` §2 (model), §3 (navigation/IA), §5 (seed strategy), §6 Phase A,
  §7 (migration), §8 (open questions Q2/Q3) — the source-of-truth build plan.
- `.planning/ROADMAP.md` — Phase 1 goal, success criteria, dependencies.
- `.planning/REQUIREMENTS.md` — DOM-01…DOM-06 + shared baseline DoD.
- `.planning/PROJECT.md` — locked-intent decisions, constraints, open questions Q1–Q5.

### Migration (mandatory before any @Model change)
- `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` — plan-less inferred migration, `@Attribute(originalName:)`
  rename recipe (Step 3), the mandatory upgrade test (Step 4), Forbidden Moves.
- `CLAUDE.md` §9.12 (schema changes), §8 (commands, bundle id `gn.HabitsTracker`),
  §1 (constraints), §9.1/§9.2/§9.3/§9.15 (file cap, data-driven views, empty states, a11y).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HabitsTracker/Models/Category.swift` — the `@Model` to rename to `Domain`; already has
  `name, iconName, colorToken, sortIndex, isSeeded, seedVersion` + `habits` (`.nullify`).
- `HabitsTracker/Features/Calendar/CalendarMonthHeatmapView.swift` + `DayDetailSheet.swift` —
  move into Progress under the segmented control (strip inner `NavigationStack`).
- `HabitsTracker/Features/Progress/ProgressDashboardView.swift` — host the Charts ⇄ Calendar
  segmented control; current body becomes the "Charts" branch.
- `HabitsTracker/Services/SeedDataService.swift` — `seedVersion` constant, name-keyed
  `restoreMissingDefaults` merge path, `defaultCategories()` to extend with new hub domains.
- `HabitsTracker/Services/BootstrapService.swift` — where the once-only, `seedVersion`-gated
  focus-backfill pass runs.
- `HabitsTracker/Features/RootTabView.swift` — drop Calendar tab, add Hub tab (keep 4).

### Established Patterns
- ModelContainer is **plan-less** via `.modelContainer(for:[…])` in `HabitsTrackerApp.swift` —
  no VersionedSchema scaffolding; inferred lightweight migration.
- DesignKit tokens only (no hard-coded colors); accents constrained to 5 tokens.
- Xcode synchronized root groups (`objectVersion 77`) — new `.swift` files auto-register;
  never hand-edit `project.pbxproj` (§9.8); no Finder-dupe files (§9.6).

### Integration Points
- `HabitsTrackerApp.swift` `.modelContainer(for:[…])` type list — add renamed `Domain` (and
  later types). Bundle id `gn.HabitsTracker` frozen.
- `ExportImportService` schemaVersion (1→2) + round-trip test.

</code_context>

<specifics>
## Specific Ideas

- Upgraders must see their existing 12 domains **already in the Hub** on first open after
  update (familiarity > empty curated screen) — this drove the focus-backfill decision.
- "Balanced Luxury" restraint should be **structurally enforced** in custom creation (user
  cannot pick an off-brand glyph or color), not merely encouraged.

</specifics>

<deferred>
## Deferred Ideas

- The actual **new hub seed domains' content** (Rules/Collections starter items for Style,
  Money, Media, etc.) lands with the phases that introduce those item types (B/C) — Phase 1
  only adds the domains + focus, not the offshoot content.
- **Q5 product naming** (keep "HabitTracker" vs rename) — non-blocking, not this phase.
- Cross-domain tagging (Q4) — after Phase F.

</deferred>

---

*Phase: 1-Domain Generalization (A)*
*Context gathered: 2026-06-28*
