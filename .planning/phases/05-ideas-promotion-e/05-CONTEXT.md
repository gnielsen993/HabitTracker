# Phase 5: Ideas + Promotion (E) - Context

**Gathered:** 2026-07-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase E adds the **capture-first spine** that turns the typed folders of Phases 2–4 into a
system. It delivers three things and nothing else:

1. **A global quick-add** — one always-reachable capture affordance that defaults to **Idea**,
   takes **title-only minimum**, files **no domain by default**, and drops the new idea into the
   **Hub inbox**. It must be reachable **without leaving Today** and must **NOT add a row to
   Today's list** (`DEC-today-is-hero`, `DEC-capture-first-spine`).
2. **The Hub inbox** — the surface where **unfiled ideas** live until filed or promoted. It lives
   in the **Hub**, never on Today (`DEC-four-tabs`, spec §3 IA rule).
3. **The two one-tap graduations** — **File** (assign a domain; the item stays an Idea) and
   **Promote** (consume the idea into a **Rule / Habit / Collection item**; the idea is archived
   with a forward-link and leaves the active inbox; the result carries **no** backref).

This implements IDEA-01…IDEA-05. It reuses everything already built: the `HabitCreateSheet`
(`HabitSource` already reserves `.idea(Idea)`), the `DomainDetailView` section-loop hook (the
"Phase E: append Ideas section here" slot at ~line 90), and the per-section "+" nav template.

**Out of scope for this phase** (belongs elsewhere): cross-domain search, designed empty states
for every surface, and full 8-type export/import completeness — all **Phase 6 (F)**. Habit
engines (Streak/WeeklyGoal/Stats) stay **habit-only** and are NOT extended to ideas. No network,
no notifications, no new tab (4 tabs hold).

</domain>

<decisions>
## Implementation Decisions

### Global quick-add control (IDEA-02) — DISCUSSED
- **D-01:** The global quick-add is a **native top-trailing "+" toolbar item on Today's
  `NavigationStack`** (option A1). It opens the capture sheet (defaults to Idea → Hub inbox).
  Chosen over a floating button overlaid in `RootTabView` (A2) because A1 is the native iOS
  compose idiom (Notes/Mail), adds **zero overlay/list pollution** (it's nav-bar chrome, not a
  Today row — satisfies the hard "capture must not pollute Today" rule cleanly), and literally
  satisfies "reachable without leaving Today." The from-any-tab reach of a FAB was judged a
  nice-to-have, not a requirement; the overlap/idiom cost of a FAB over Progress/Settings
  scroll content wasn't worth it.
- **D-02:** `TodayView`'s `NavigationStack` currently has **no toolbar** — this "+" is net-new
  chrome. It presents the capture sheet via `.sheet`. The capture sheet is a **title-only
  minimum** quick-capture (optional note/URL/domain post-save), NOT the heavy editor — see D-08.

### Hub inbox shape (IDEA-03) — DISCUSSED
- **D-03:** The inbox is a **card pinned above the domain grid in `HubView`**, showing a
  **"N to file" count**, that navigates to a **dedicated `InboxView` list** (option B1). Chosen
  over an inbox pseudo-tile in the `LazyVGrid` (B2) because B2 mixes an action surface into the
  domain-tile semantics. The card is the "unfiled ideas surface in the Hub as a 'to file'
  affordance" the spec calls for.
- **D-04:** The inbox card is **shown only when unfiled (domain-less, non-archived) ideas
  exist**. Its polished empty state is **Phase 6** territory (POL-02) — Phase 5 may hide it or
  use a minimal placeholder; do not build the full empty-state design here.
- **D-05:** `InboxView` is **data-driven** (§9.2): the parent (`HubView` or `InboxView` itself)
  owns the `@Query` for unfiled ideas; the row is a reusable presentational view fed its data.

### Promote flow UI (IDEA-04, IDEA-05) — DISCUSSED
- **D-06:** Promote is a **menu that routes to the existing prefilled editor** (option C1):
  tap **Promote → pick Rule / Habit / Collection item → the existing target editor opens
  prefilled from the idea → Save** (≤2 taps to a saved result — the locked success metric).
  Chosen over a bespoke `PromoteSheet` (C2) to **maximize reuse** — every target editor already
  exists (`RuleEditorView`, the collection-item editor, `HabitCreateSheet`) — and because the
  **habit case is already forced to hand off** to the shared `HabitCreateSheet`, so
  route-to-editor is the consistent shape. C2 would re-implement fields the editors already own.
- **D-07:** The **promote-consume asymmetry** (`DEC-promote-is-consume`) is LOCKED, not up for
  discussion — implement it as spec'd:
  - **Carries per target:** → Rule: idea text → `title`/`body`, idea URL → `sourceURL`.
    → Habit: idea text → title, then `HabitCreateSheet(source: .idea(idea))` (add the
    `.idea(Idea)` case to the existing `HabitSource` enum — already reserved in code).
    → Collection item: idea text → title, **user picks the target collection** (IDEA-05);
    URL/cost carry if present.
  - **On success:** the idea is **archived with a forward-link** to what it became (auditable),
    **leaves the active inbox**, and the result carries **no backref** to the idea.
  - **Missing-context prompts (IDEA-05):** an **unfiled** idea's promote **must capture a
    domain** (Rules & Collections live in domains) — reuse the editor's existing domain picker,
    just require it be set before Save; a **filed** idea defaults to its own domain.
    Promote-to-collection **prompts for the target list**.
  - Keep the archive-with-forward-link + no-backref logic in **one small promote service/helper**
    (pure and testable where feasible, §9.5), not scattered across the editors.

### Idea surface weight (IDEA-01) — DISCUSSED
- **D-08:** Ideas are **lightweight** (option D1): an Idea renders as a **row** (in the inbox and
  in a domain's Ideas section) carrying **inline File / Promote actions**, plus a **title-only
  capture sheet** for create/edit. There is **NO `IdeaDetailView` and NO heavyweight
  `IdeaEditorView`**. Rationale: an idea is **staging, meant to be consumed and archived**, not
  curated — a full detail view is over-build and fights "keep the inbox clean." This is the one
  type that deliberately **breaks** the Phase 2 D-12 detail-view nav template, and that's correct.
- **D-09:** **Keep the per-section "+" pattern.** Add an **Ideas "+"** to a domain's Ideas
  section header alongside the existing Rules / Collections / Clips "+" buttons (the in-domain,
  place-first entry per spec §3). Do **NOT** build a new unified domain-level "+" type picker —
  the roadmap goal's "ties together the in-domain '+' creation" is satisfied by the **global
  quick-add being the unifying spine**, not by a per-domain "+" refactor. A unified domain "+"
  menu is noted as a deferred polish idea, not this phase.
- **D-10:** The exact placement of File/Promote on the row (trailing buttons vs `.swipeActions`
  vs context menu) is **Claude's discretion** within the accessibility gate (§9.15) and tokens
  (§9.4). File likely wants a quick **domain picker** (it's the one required field File adds).

### Idea model shape (IDEA-01) — schema-expansion, playbook territory
- **D-11:** Add an **`Idea` `@Model`** mirroring the minimal leaf-model shape of `Rule.swift` /
  `Clip.swift`: `@Attribute(.unique) id`, a freeform **`text` / `title`** field (title-only
  minimum), optional `note?`, optional `url?` (so promote → Rule `sourceURL` and → Clip-style
  carries work), an optional `domain: Domain?` (`.nullify` inverse `Domain.ideas`, matching the
  house idiom), `createdAt`, and the soft-archive / forward-link fields (D-12). All new fields
  **optional or defaulted** (`DEC-additive-migration-only`).
- **D-12:** Promote's **archive-with-forward-link** needs persisted state on `Idea`: an
  additive **`isArchived: Bool = false`** (mirrors Rule D-13 / Clip D-11 soft-archive) plus a
  **forward-link record of what it became** (e.g. a promoted-type tag + the target's id — exact
  shape is Claude's discretion, kept as a lean value, **no** SwiftData backref per D-07). An
  archived (promoted or filed-away) idea leaves the **active** inbox query.
- **D-13:** Register `Idea` in the `.modelContainer(for: […])` type list in
  `HabitsTrackerApp.swift`, follow `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` (plan-less inferred
  migration, no `migrationPlan:`, additive-only), and run the **mandatory upgrade test**
  (install prior build → log data → install over → confirm launch + data intact).
- **D-14:** Bump `ExportImportService.schemaVersion` **5 → 6** and extend the round-trip to cover
  `Idea` (text/title, note, url, domain ref, `isArchived`, forward-link fields). Full 8-type
  export/import completeness stays **Phase 6**; Phase 5 keeps the round-trip green for what it
  adds.

### Claude's Discretion
- Exact `Idea` field names and the forward-link representation (D-11, D-12) — within
  additive/optional + no-backref constraints.
- Row-action affordance for File/Promote (trailing buttons vs swipe vs context menu) (D-10).
- Whether the capture sheet and the in-domain Ideas "+" share one title-only sheet component
  (they should, §4 reuse) and its exact layout within tokens (§9.4) and the ~400-line cap (§9.1).
- `InboxView` list layout, row layout, and the inbox card's exact "N to file" copy/visual
  (within tokens; the *designed* empty state is Phase 6).
- Whether promote's per-target routing lives in a small `PromoteService` vs inline coordinator
  — so long as the consume/archive/forward-link logic is centralized and testable (D-07, §9.5).
- Whether the capture sheet lets the user optionally set a domain at capture time (making the
  idea "filed" immediately) or is strictly title-only with filing deferred to the inbox.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Plan & requirements
- `Docs/LIFESTYLE_HUB_PLAN.md` — Phase E spec: the Idea type (~line 105), the **Stem & Promote
  asymmetry** and per-target carries (§2, ~lines 113–137), the **Creation model** — global
  quick-add vs in-domain "+", "capture must not pollute Today," title-only minimum, inbox-lives-
  in-Hub (§3, ~lines 159–182), and the Phase E success bar (§"E — Ideas + promotion", ~line 286).
- `.planning/ROADMAP.md` — Phase 5 goal, the 4 success criteria, and the dependency note
  (Depends on Phases 1–4; **REUSES Phase 2's shared habit-create sheet — load-bearing**).
- `.planning/REQUIREMENTS.md` — IDEA-01…IDEA-05 + the shared baseline DoD (upgrade test,
  round-trip, tokens, structure).
- `.planning/PROJECT.md` — locked-intent decisions (`DEC-capture-first-spine`,
  `DEC-promote-is-consume`, `DEC-today-is-hero`, `DEC-four-tabs`, `DEC-additive-migration-only`)
  and Out-of-Scope boundaries.

### Prior-phase context this phase reuses (load-bearing)
- `.planning/phases/02-rules-b/02-CONTEXT.md` — the **shared `HabitCreateSheet`** contract
  (D-04 fill-then-commit, D-07 source-agnostic: `HabitSource` already reserves `.idea(Idea)`),
  the row→detail nav template (D-12) that Ideas **deliberately opt out of** (D-08 here), and the
  soft-archive + plan-less migration stance this phase mirrors.
- `.planning/phases/04-clips-d/04-CONTEXT.md` — the most recent leaf-model + section-append +
  schemaVersion-bump precedent (Clip D-10…D-14), and the `nonEmptySections` hook that reserves
  the "Phase E: append Ideas section here" slot.
- `.planning/phases/03-collections-c/03-CONTEXT.md` — the **promote-to-collection target**:
  Collection/CollectionItem shape and the item editor promote routes into.

### Migration (mandatory before any @Model change)
- `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` — plan-less inferred migration, additive-defaulted field
  rule, the mandatory upgrade test, Forbidden Moves (no `migrationPlan:`, no required-no-default,
  no bare renames).
- `CLAUDE.md` §9.12 (schema changes), §9.5 (pure services ship with tests — the promote helper),
  §9.1/§9.2/§9.3/§9.15 (file cap, data-driven views, empty states, accessibility), §9.4 (verify
  tokens exist), §9.13 (os.Logger not print), §9.8 (synchronized root groups auto-register),
  §9.6 (no Finder-dupe files), §8 (commands; bundle id `lauterstar.HabitsTracker`), §1 (tokens-only).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HabitsTracker/Features/Habits/HabitCreateSheet.swift` — the shared fill-then-commit habit
  sheet. `HabitSource` (lines ~6–9) **already reserves `.idea(Idea)`** with the comment
  "Phase 5 will add `.idea(Idea)` without touching the sheet." Promote-to-habit adds that case
  and passes the idea; the sheet chrome is untouched (D-07).
- `HabitsTracker/Features/Hub/DomainDetailView.swift` — `nonEmptySections(theme:)` reserves the
  Ideas slot at ~line 90 ("Phase E: append Ideas section here"). Copy the Clips section trio
  (`buildClipsSection` / content / header with the "+" button, ~lines 197–241) in shape for
  Ideas (D-09).
- `HabitsTracker/Features/Hub/HubView.swift` — a `LazyVGrid` of focused `DomainTile`s + empty
  state (~lines 42–78). The inbox card pins **above** this grid (D-03); parent owns the `@Query`.
- `HabitsTracker/Features/Today/TodayView.swift` — the `NavigationStack` (~line 24) has **no
  toolbar today**; add the top-trailing capture "+" here (D-01/D-02).
- `HabitsTracker/Features/RootTabView.swift` — plain 4-item `TabView` (Today/Hub/Progress/
  Settings). Confirms the 4-tab lock; the A2 FAB option (rejected) would have lived here.
- `HabitsTracker/Models/Rule.swift` / `HabitsTracker/Models/Clip.swift` — the minimal leaf-`@Model`
  shape (`@Attribute(.unique) id`, scalar fields, defaulted `isArchived`, `.nullify` domain
  relationship) to mirror for `Idea` (D-11). **Note:** `@Model` default expressions need full
  qualification (`Date.now`, not `.now`) — see State log Phase 04-01.
- `HabitsTracker/Models/Domain.swift` — add `Domain.ideas` inverse with the same `.nullify` +
  `inverse:` idiom used for `.rules` / `.collections` / `.clips` / `.habits` (D-11).
- Phase 2 `RuleEditorView`, the Phase 3 collection-item editor, `HabitCreateSheet` — the three
  **promote targets** the D-06 menu routes into, prefilled.
- `HabitsTracker/Services/ExportImportService.swift` — `schemaVersion` currently `5`; bump to
  `6` and add an `IdeaDTO` mirroring `ClipDTO`/`RuleDTO` shape; delete `Idea` before `Domain` in
  `deleteAll` (nullify ordering, matches Clip 04-04) (D-14).
- `HabitsTracker/HabitsTrackerApp.swift` — the `.modelContainer(for: [ … ])` type list (line 15);
  register `Idea` here (D-13).
- DesignKit `DKCard` / `DKSectionHeader` / `DKBadge` (inbox card, "N to file" count, section
  header "+"), tokens only (§9.4).

### Established Patterns
- ModelContainer is **plan-less** (`.modelContainer(for:[…])`, no `migrationPlan:`) — inferred
  lightweight migration; new fields optional/defaulted (`DEC-additive-migration-only`).
- `.nullify` relationships with `inverse:` are the house idiom; Xcode synchronized root groups
  (`objectVersion 77`) auto-register new `.swift` files — never hand-edit `project.pbxproj`
  (§9.8); no Finder-dupe files (§9.6).
- Nav template: domain section → "+" in section header → editor → row → detail view (Phase 2
  D-12). **Ideas deliberately opt out of the detail-view tail** (D-08) — row + inline actions only.
- One shared creation code path funneled through `HabitCreateSheet` (Phase 2 D-06): the manager
  "Add Habit", Rule Stem, and now **Idea Promote-to-habit** all use it.
- Pure services ship with unit tests in the same commit (§9.5) — the promote consume/archive/
  forward-link helper is the testable core here (happy path, unfiled-needs-domain, promote-to-
  collection-needs-list, already-archived skip).

### Integration Points
- New `Idea` `@Model` + `Domain.ideas` inverse → container type list + inferred migration +
  upgrade test + schemaVersion 5→6 round-trip.
- Global capture "+" → `TodayView` toolbar → title-only capture sheet → inserts an unfiled Idea
  → surfaces in the Hub inbox card / `InboxView`.
- Ideas section slots into `DomainDetailView.nonEmptySections` next to Rules/Collections/Clips
  (D-09); the in-domain Ideas "+" files an idea directly to that domain (place-first).
- Promote menu → routes to `RuleEditorView` / collection-item editor / `HabitCreateSheet(.idea)`
  prefilled; on Save the promote helper archives the idea with a forward-link.

</code_context>

<specifics>
## Specific Ideas

- **Capture-first is the whole spine.** The 11pm "saw a TikTok / had a thought" path must be
  near-zero friction: one "+", title-only, no domain required, lands in the inbox. Everything
  else (filing, promoting) is deferred and post-save. This is why the capture sheet is
  title-only, not the heavy editor.
- **The inbox exists to be emptied.** File and Promote are the two ways out; both are one-tap
  from the inbox row. An idea that's promoted is **consumed** (archived + forward-link, gone from
  the active list) — keeping the inbox clean is the entire point. The named failure mode is
  "it became empty Notion folders" / a Notes graveyard.
- **Ideas are the one type that's deliberately lightweight** — no detail view, because a staging
  item you're about to consume doesn't earn curation chrome. This is a considered break from the
  Rules/Clips template, not an oversight.
- **Promote reuses, never re-implements.** Every promote target already has an editor; promote
  prefills and routes. The only net-new logic is the small consume/archive/forward-link service.

</specifics>

<deferred>
## Deferred Ideas

- **Unified domain-level "+" type picker** (one "+" per domain that lets you choose Rule/List/
  Idea/Clip/Habit) — considered under D-09, **not taken**. Phase 5 keeps the per-section "+"
  pattern; the global quick-add is the unifier. A domain-"+" menu is a future polish refactor.
- **Global capture reachable from any tab (FAB over `RootTabView`)** — the A2 option, rejected
  in favor of the native Today toolbar "+" (D-01). Revisit only if dogfooding shows a real need
  to capture while sitting on Progress/Settings.
- **Designed empty states** for the inbox / Hub / every section, **cross-domain search**, and
  **full 8-type export/import completeness** — all **Phase 6 (F)**. Phase 5 keeps its own
  round-trip green and may use minimal/hidden placeholders where Phase 6 will add the real copy.
- **Optional set-domain-at-capture-time** (making a captured idea "filed" immediately, skipping
  the inbox) — noted as Claude's-discretion in D-08's capture-sheet scope; the default remains
  title-only capture → inbox.

None outside phase scope — discussion stayed within the Ideas + Promotion domain.

</deferred>

---

*Phase: 5-Ideas + Promotion (E)*
*Context gathered: 2026-07-10*
