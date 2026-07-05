# Phase 3: Collections (C) - Context

**Gathered:** 2026-07-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Domains gain **Collections** — opinionated lists (`Collection` + `CollectionItem`, new
`@Model`s filed under a `Domain`) whose items carry *behavior*: a **tap-to-advance status
chip** (COLL-03), an optional **position** driven by a fixed `progressTemplate`
(`none`/`counter`/`seasonEpisode`, COLL-04/05), and **aggregate/cost rollups** (COLL-06). A
`StatusSet` concept (ordered states + terminal, COLL-01) backs the chip; the **generic preset**
(`to-collect → collected`) is the default and prerequisite for user-created lists (COLL-02);
**curated presets** from SPEC §5 ship as a code catalog (COLL-07).

This clarifies HOW to implement COLL-01…COLL-07. It does NOT build Clips (Phase 4), Ideas or
the global capture/promote surface (Phase 5), cross-domain search, or full multi-type
export/import (Phase 6). It does NOT reopen the fixed `progressTemplate` set or make built-in
StatusSet labels editable (both scope-guarded / locked). Habit engines
(Streak/WeeklyGoal/Stats) stay habit-only and are NOT extended to collections.

</domain>

<decisions>
## Implementation Decisions

### StatusSet storage (COLL-01 / COLL-02 / COLL-03)
- **D-01:** StatusSets are a **code-defined catalog**, NOT a SwiftData `@Model`. A
  `StatusSetCatalog` (enum/struct) holds each set's ordered state labels + terminal index,
  keyed by a stable `String` id. Reads COLL-01's "a StatusSet model exists" as a **typed value
  model**, which is valid because built-in labels are non-editable and users never author new
  sets in v1.
- **D-02:** `Collection` stores `statusSetID: String` (defaulted to the generic set's id).
  `CollectionItem` stores `statusIndex: Int = 0` (index into the catalog set). Both are
  additive, defaulted scalar fields — the smallest possible plan-less inferred migration
  (DEC-additive-migration-only). No new `@Model` beyond `Collection` + `CollectionItem`.
- **D-03:** **Non-editability is structural** — built-in labels live in code, so there is
  nothing persisted to edit (satisfies "built-in labels not user-editable" for free).
- **D-04:** The **generic set** (`to-collect → collected`) is a catalog entry and the default
  `statusSetID`; it exists before any user-created collection can save (COLL-02).
- **D-05:** Export/import serializes the status as `statusSetID: String` + `statusIndex: Int`
  (plain scalars, no id-graph) — trivially round-trippable under the bumped schemaVersion.

### Tap-to-advance chip behavior (COLL-03)
- **D-06:** **Terminal is sticky (stop-at-terminal), not wrap-around.** Tapping the chip
  advances `statusIndex` by 1, clamped at the terminal index (`min(statusIndex+1, terminal)`).
  Tapping an already-terminal item does nothing destructive. Interprets COLL-03's "cycles
  through states including the terminal state" as *terminal is reachable by tapping*, not that
  a further tap wraps to the start. Rationale: a `watched`/`flown` item is precious completion
  signal; a stray tap must not silently reset it.
- **D-07:** **Reset** (leave terminal / go back to start) is an explicit gesture —
  a `contextMenu` / long-press "Reset" with a VoiceOver **custom accessibility action**
  (§9.15). No confirm dialog needed for forward advances; the reset gesture is the guarded one.
- **D-08:** Add `.sensoryFeedback` (or equivalent) so a tap at terminal is perceived as a
  no-op rather than feeling broken.

### Position controls — seasonEpisode / counter (COLL-04 / COLL-05)
- **D-09:** Position controls (**+episode / +season / finished** for `seasonEpisode`; **+1**
  for `counter`) live in a **`CollectionItemDetailView`**, NOT inline on the list row. The row
  shows a compact position label (e.g. `S2 E4`) + the status chip and is a `NavigationLink`
  into the detail view (which also hosts note / url / cost). Mirrors the Phase 2
  Rules row→detail nav shape (D-12 from Phase 2) and stays Dynamic-Type safe (inline row
  steppers break at larger text sizes and crowd 44pt targets).
- **D-10:** `seasonEpisode` semantics: **+episode** → episode+=1; **+season** → season+=1,
  episode→1; **finished** → `statusIndex = terminal`. `counter`: **+1** bumps a single value
  with a label (e.g. "Chapter"). **No total is ever required** — no upfront "how many?" cost.
- **D-11 (Discretion / deferred-safe):** A swipe-action **"+1 / +Episode"** shortcut on the
  row is an OPTIONAL later low-risk add if daily incrementing proves too heavy — not built now,
  noted so the row layout doesn't preclude it.

### Preset delivery + nesting (COLL-07 + success criterion 1)
- **D-12:** **Catalog is the single source of truth.** A `CollectionPresetCatalog` (code) holds
  the 8 curated presets from SPEC §5 (Shows, Movies/franchises, Albums, Concerts, Books,
  Clothes to buy, Want to spend on, Planes/places) + the generic preset, each as
  `{name, statusSetID, progressTemplate, showsAggregate default}`. "Ship as seed content"
  (COLL-07) = the catalog ships in code.
- **D-13:** **"+" in a domain's Collections section opens a preset picker** → creates a
  collection from the chosen preset (success criterion 1). Presets are **not domain-locked** —
  the "+" is already domain-scoped, so any preset can be created in any domain; no
  preset→domain mapping table is needed.
- **D-14:** **Seed exactly ONE generic starter collection** on fresh install (guarded like the
  existing seed: only when appropriate), NOT all 8 curated collections. Rationale: seeding 8
  empty lists across freshly-seeded *unfocused* domains recreates the project's named failure
  mode ("empty Notion folders") and complicates the upgrader merge-add path. Upgraders get the
  generic starter via the merge-add path only if missing.
- **D-15:** **Section visibility:** the Collections section in `DomainDetailView` shows when
  `!domain.collections.isEmpty` — a 0-item collection is a real configured list and is a valid
  non-empty section (mirrors the Phase 2 Rules contract exactly; composes with the DOM-03
  "only non-empty sections" loop).

### Aggregate / cost rollup (COLL-06 + DEC-cost-rollup-never-ring)
- **D-16:** **X/Y semantics — strictly terminal:** `X = items where statusIndex == terminalIndex`,
  `Y = total item count`. A mid-step item (e.g. a `watching` show in `to-watch→watching→watched`)
  is **NOT** counted in X. Stated crisply so downstream doesn't guess.
- **D-17:** **Dual-surface rendering** — the rollup shows both as a **trailing label on the
  collection's row** in `DomainDetailView` (scannability is the whole point of `showsAggregate`)
  and in the **`CollectionDetailView` header**.
- **D-18:** Completionist **X/Y may use a small `DKProgressRing`** (completion is
  ring-appropriate). **Cost sum is ALWAYS plain text** (`$340`), **never a ring**
  (DEC-cost-rollup-never-ring). Tracker lists with `showsAggregate` off show **no** rollup.
- **D-19:** **Compute in a pure `CollectionRollupEngine`** returning `.count(x, y)` /
  `.costSum(total)` / `.none`. Ships with unit tests in the same commit (§9.5): completionist
  happy path, empty list, multi-step set with mid-step items (only terminal counted), cost list
  with mixed nil/non-nil costs, tracker with `showsAggregate` false → `.none`.
- **D-20:** **"Money-flavored" is derived, no new stored flag.** Signal: `showsAggregate == true`
  AND some item has non-nil `cost` AND the list has no meaningful completion semantics → `.costSum`;
  else `showsAggregate == true` with a terminal state → `.count(x, y)`; else `.none`. Presets set
  a sensible `showsAggregate` default; the user can flip the flag (COLL-06).

### Schema / migration (playbook territory)
- **D-21:** Adding `Collection` + `CollectionItem` `@Model`s + their `Domain.collections`
  inverse is **schema-expansion** — follow `Docs/SCHEMA_MIGRATION_PLAYBOOK.md`: plan-less
  inferred migration, all new fields optional/defaulted, register both types in
  `.modelContainer(for:[…])` in `HabitsTrackerApp.swift`, run the mandatory upgrade test.
- **D-22:** `Collection.domain` / `Domain.collections` use the house `.nullify` +`inverse:`
  idiom (mirrors `Domain.rules ↔ Rule.domain`). `CollectionItem.collection` likewise; deleting
  a collection may **cascade** its items (items are owned by the collection, unlike hero
  habits) — planner to confirm delete rule, default lean = `.cascade` for items.
- **D-23:** Bump `ExportImportService.schemaVersion` (3 → 4) and extend the round-trip to cover
  `Collection` + `CollectionItem` (+ their scalar status/position/cost fields). Full multi-type
  export/import completeness stays Phase 6; Phase 3 keeps the round-trip green for what it adds.

### Claude's Discretion
- Exact `Collection`/`CollectionItem` field set beyond the decided ones (the SPEC lists
  `title`, `note?`, `url?`, `cost?`, `sortIndex`, `isSeeded`; plus position fields for
  season/episode/counter and a counter label) — planner/executor finalize within D-01…D-23.
- The generic starter collection's name + which domain it seeds into (D-14).
- Preset picker sheet layout, `CollectionDetailView` / `CollectionItemDetailView` layout, and
  Collections-section empty-state copy (§9.3) — within DesignKit tokens (§9.4) and the
  ~400-line file cap (§9.1), data-driven-view rule (§9.2).
- Cost formatting / currency locale.
- Whether the counter label is stored on the item or the collection.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Plan & requirements
- `Docs/LIFESTYLE_HUB_PLAN.md` — Phase C spec: the **Collection behavior model** (status vs.
  position vs. aggregate, lines ~80–104), the **curated collection presets table** (SPEC §5,
  lines ~210–232), and the fixed `progressTemplate` scope guard.
- `.planning/ROADMAP.md` — Phase 3 goal, the 5 success criteria, and the "generic StatusSet
  preset is a prerequisite / do not reopen the fixed progressTemplate set" dependency notes.
- `.planning/REQUIREMENTS.md` — COLL-01…COLL-07 + shared baseline DoD.
- `.planning/PROJECT.md` — locked-intent decisions (DEC-status-template-instances,
  DEC-fixed-progress-templates, DEC-cost-rollup-never-ring, DEC-additive-migration-only),
  constraints, and Out-of-Scope boundaries.
- `.planning/phases/02-rules-b/02-CONTEXT.md` — the row→detail nav template (D-08/D-12),
  `DomainDetailView` section-loop hook, and plan-less migration stance this phase mirrors.

### Migration (mandatory before any @Model change)
- `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` — plan-less inferred migration, additive-defaulted field
  rule, the mandatory upgrade test (install prior build → log data → install over → verify),
  Forbidden Moves.
- `CLAUDE.md` §9.12 (schema changes), §9.5 (pure services ship with tests), §9.1/§9.2/§9.3/
  §9.15 (file cap, data-driven views, empty states, accessibility), §9.4 (verify tokens exist),
  §8 (commands, bundle id `gn.HabitsTracker`), §1 (design constraints, tokens-only).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HabitsTracker/Features/Hub/DomainDetailView.swift` — `nonEmptySections(theme:)` is the
  Phase-1 hook; append a filtered **Collections** section here alongside the existing Rules
  section (D-15). The Rules section (header + "+" button + `NavigationLink` rows) is the exact
  shape to copy for Collections.
- `HabitsTracker/Models/Domain.swift` — add `Domain.collections` inverse with the same
  `.nullify` + `inverse:` idiom already used for `Domain.rules` / `Domain.habits` (D-22).
- `HabitsTracker/Models/Rule.swift` — the minimal `@Model` shape (id, scalar fields, defaulted
  `isArchived`, a `@Relationship domain`) to mirror for `Collection` / `CollectionItem`.
- `HabitsTracker/Services/SeedDataService.swift` — `seedIfNeeded` (fresh-install guard) +
  `restoreMissingDefaults` (merge-add) are where the single generic starter collection seeds
  (D-14); reuse `isSeeded`/`seedVersion`.
- `HabitsTracker/Services/ExportImportService.swift` — `schemaVersion` 3→4; extend round-trip
  for `Collection` + `CollectionItem` (D-23).
- `HabitsTrackerApp.swift` — register `Collection` + `CollectionItem` in
  `.modelContainer(for:[…])` (D-21).
- DesignKit `DKProgressRing` (completionist X/Y only), `DKBadge`/pill (status chip),
  `DKSectionHeader`, `DKCard` — tokens only (§9.4).

### Established Patterns
- ModelContainer is **plan-less** (`.modelContainer(for:[…])`, no `migrationPlan:`) — inferred
  lightweight migration; new fields optional/defaulted (DEC-additive-migration-only).
- `.nullify` relationships with `inverse:` are the house idiom; Xcode synchronized root groups
  (objectVersion 77) auto-register new `.swift` files — never hand-edit `project.pbxproj`
  (§9.8); no Finder-dupe files (§9.6).
- Pure engines ship with unit tests in the same commit (§9.5) — `CollectionRollupEngine` is the
  testable core here. Habit engines stay habit-only (not extended to collections).
- Nav template: domain section → "+" in section header → editor/picker → detail view
  (Phase 2 D-12).

### Integration Points
- New `Collection` + `CollectionItem` `@Model`s → container type list + inferred migration +
  upgrade test + schemaVersion 3→4.
- Collections section slots into `DomainDetailView.nonEmptySections` next to Rules (D-15).
- `StatusSetCatalog` + `CollectionPresetCatalog` are new code-only sources of truth (no
  persistence) consumed by the create picker, the chip, and the rollup engine.

</code_context>

<specifics>
## Specific Ideas

- The whole point of `showsAggregate` is **seeing "23/50" without opening the list** — hence the
  trailing rollup label on the collection row, not just the detail header (D-17).
- A completed item is **precious signal** — this drove stop-at-terminal + explicit-reset (D-06/
  D-07) over a wrap-around cycle.
- Avoid the named failure mode: **"it became empty Notion folders."** Seed ONE tangible generic
  starter, let curated lists arrive on demand via the picker (D-14).
- Presets should *feel* different, not just be a different title — StatusSet + progress template
  + aggregate default per preset (the catalog carries all three).

</specifics>

<deferred>
## Deferred Ideas

- **Swipe-action "+1 / +Episode" row shortcut** — optional later add if one-tap-via-detail
  proves too heavy (D-11). Not in Phase 3 scope; row layout kept compatible.
- **User-defined / editable StatusSets** — explicitly scope-guarded in PROJECT.md; would be its
  own future migration (one additive `@Model`) if ever approved. Not this milestone.
- **More progress templates** beyond `none`/`counter`/`seasonEpisode` — locked fixed set
  (DEC-fixed-progress-templates); deferred per SPEC §9.
- **Full multi-type export/import completeness** (all 8 types under one schemaVersion) — Phase 6.
  Phase 3 keeps the round-trip green only for the types it adds.
- **Clips section / Ideas + promote-to-collection** — Phases 4/5. Promote-to-collection will
  target the collections built here; they mirror the Collections section pattern established now.

None outside phase scope — discussion stayed within the Collections domain.

</deferred>

---

*Phase: 3-Collections (C)*
*Context gathered: 2026-07-05*
