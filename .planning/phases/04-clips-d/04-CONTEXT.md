# Phase 4: Clips (D) - Context

**Gathered:** 2026-07-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Domains gain **Clips** — offline-only saved links (`Clip`, a new `@Model` filed under a
`Domain`) that stop link-rot: each clip carries a `title`, `url`, optional `note`, an optional
free-text `tag`, and a two-state `saved → acted` status (CLIP-02…CLIP-04). Clips appear in a
**Clips section inside `DomainDetailView`**, mirroring the Phase 2 Rules / Phase 3 Collections
nav template exactly. **Success Criterion 1 is a hard gate:** the Q1 offline-vs-preview
decision must be recorded (it is — see D-01) before any Clip code is written.

This clarifies HOW to implement CLIP-01…CLIP-04. It does NOT build Ideas or the global
capture/promote surface (Phase 5), cross-domain search, or full multi-type export/import
(Phase 6). It does NOT introduce any network fetch, rich link previews, or a cross-domain tag
*taxonomy* — all three are explicitly out of scope (constitution offline-only + PROJECT.md Out
of Scope). Habit engines (Streak/WeeklyGoal/Stats) stay habit-only and are NOT extended to
clips.

</domain>

<decisions>
## Implementation Decisions

### Q1 — offline/preview resolution (CLIP-01, Success Criterion 1 — MANDATORY RECORD)
- **D-01:** **Clips are fully offline. There is NO network fetch, ever** — no rich previews,
  no thumbnail/metadata retrieval, no on-demand fetch. A clip stores `url` + user-authored
  `title`/`note`. This resolves and records Q1 per SC1 and the constitution's offline-only v1
  lock (DEC-offline-only-v1). Opt-in link previews remain deferred past this milestone
  (PROJECT.md Out of Scope).
- **D-02:** **Title friction is reduced with a ZERO-NETWORK helper.** On URL entry, a **pure
  string parser** derives an editable *suggested* title from the URL (host and/or last path
  slug — e.g. `tiktok.com` or a readable slug). No network — pure `URLComponents`/string work.
  The user can always overwrite it. This is a pure, testable helper (§9.5): ships with unit
  tests covering a normal URL, a bare-host URL, a URL with a slug, and a malformed/no-scheme
  string (graceful fallback to empty/raw).

### Status modeling (CLIP-04)
- **D-03:** Status is a **dedicated 2-case value**, NOT the Phase 3 StatusSet catalog:
  `enum ClipStatus: String { case saved, acted }`, stored as its raw `String` (export-friendly,
  room to read as more than a bool). Toggling advances `saved → acted`. Chosen over reusing
  `StatusSetCatalog` because a Clip's two states are **fixed and inherent**, not
  template-driven — coupling Clip to the StatusSet abstraction would be over-abstraction
  (mirrors D-01's "typed value model" reasoning from Phase 3).
- **D-04:** **Visual consistency without coupling** — render the status as a chip using the
  **same DesignKit chip styling** Collections use (`DKBadge`/pill, tokens only §9.4), so it
  *looks and feels* consistent across the hub even though the storage is a dedicated enum. The
  chip is tappable to toggle `saved → acted`.
- **D-05:** **Toggle direction / reset:** `saved → acted` is the forward tap. Whether tapping
  an `acted` clip toggles back to `saved` (simple 2-way toggle) or requires an explicit
  reset gesture is **Claude's discretion** — a 2-state clip is far less "precious" than a
  Collections terminal (Phase 3 D-06), so a plain two-way toggle is acceptable here. Add
  `.sensoryFeedback` on the tap.

### Tag modeling (CLIP-02)
- **D-06:** `tag` is a **single, optional, free-text `String?`** — `Clip.tag: String?`. Optional
  to honor the title-only-minimum capture rule (SPEC §"minimum field set = title only, plus URL
  for Clip"). This is a per-clip label, **NOT** a tag taxonomy/system — cross-domain free tags
  are explicitly deferred (PROJECT.md Out of Scope; revisit after Phase F). No autocomplete /
  suggestion UI in v1.

### Clip surface shape (CLIP-03)
- **D-07:** Ship a **dedicated `ClipDetailView`**, consistent with the locked Phase 2/3 nav
  template (D-12): domain **Clips section → "+" in the section header → editor → row →
  detail view**. Chosen over a row-only/tap-opens-URL shape so the `note` stays visible and the
  milestone's nav template stays uniform; the minor "one extra tap to open the link" cost is
  accepted.
- **D-08:** `ClipDetailView` prominently features an **"Open Link" action** that opens `url`
  in Safari via SwiftUI `openURL` (or a tappable link affordance), plus the `note`, the status
  chip, `tag`, and an **Edit** entry into the editor sheet. The **status chip also renders on
  the row** in `DomainDetailView` for at-a-glance scannability (mirrors the Collections rollup
  label rationale, Phase 3 D-17).
- **D-09:** A **`ClipEditorView` form sheet** (title, url, note, tag, domain picker) shaped like
  `RuleEditorView`/`HabitEditorView` handles create + edit (§4 reuse). The D-02 zero-network
  title suggestion prefills the title field on url entry.
- **D-10:** **Section visibility:** the Clips section in `DomainDetailView` shows when the
  domain has non-archived clips — append it in `nonEmptySections(theme:)` alongside Rules and
  Collections (the file already reserves this slot at the "Phase D–E: append Clips / Ideas
  sections here" hook). Mirrors the Rules/Collections section contract exactly.
- **D-11:** Mirror the house **soft-archive** pattern — `Clip` gets an additive
  `isArchived: Bool = false` (Rules D-13 / §9.12 additive-defaulted). Archive hides, never
  deletes. Delete is a hard delete of a thin owned item (no stem-style dependents to protect,
  unlike Rules D-15) — planner confirms whether a delete confirm is warranted.

### Schema / migration (playbook territory)
- **D-12:** Adding the `Clip` `@Model` + a `Domain.clips` inverse is **schema-expansion** —
  follow `Docs/SCHEMA_MIGRATION_PLAYBOOK.md`: plan-less inferred migration, ALL new fields
  optional/defaulted, register `Clip` in `.modelContainer(for:[…])` in `HabitsTrackerApp.swift`,
  and run the **mandatory upgrade test** (install prior build → log data → install over →
  confirm launch + data intact). `Clip.domain` / `Domain.clips` use the house `.nullify` +
  `inverse:` idiom (matches `Domain.rules ↔ Rule.domain`, `Domain.collections`).
- **D-13:** Bump `ExportImportService.schemaVersion` **4 → 5** and extend the round-trip to
  cover `Clip` (title, url, note, tag, `status` raw string, `isArchived`, domain ref). Full
  multi-type export/import completeness stays Phase 6; Phase 4 keeps the round-trip green for
  what it adds.

### Claude's Discretion
- Exact `Clip` field set beyond the decided ones (`id`, `title`, `url`, `note?`, `tag?`,
  `status`, `isArchived`, `createdAt`, `domain`, plus any `sortIndex`) — finalize within
  D-01…D-13.
- The precise host/slug extraction rule for the D-02 title suggestion (host vs slug vs both,
  humanization) — within the "pure, zero-network, unit-tested" constraint.
- Whether tapping an `acted` chip toggles back to `saved` or needs an explicit reset (D-05).
- Whether a hard delete needs a confirm dialog (D-11).
- URL normalization (e.g. prepend `https://` when scheme is missing) and invalid-URL handling
  in the editor.
- `ClipDetailView` / `ClipEditorView` layout, the Clips-section empty-state copy (§9.3), and
  the row layout — within DesignKit tokens (§9.4), the ~400-line file cap (§9.1), the
  data-driven-view rule (§9.2), and the accessibility gate (§9.15).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Plan & requirements
- `Docs/LIFESTYLE_HUB_PLAN.md` — Phase D (Clips) spec: the Clip field set (`title`, `url`,
  `note`, `tag`, `status` saved/acted, ~line 107), the offline-preview open question (~line
  329), the "minimum field set = title only, plus URL for Clip" friction rule (~line 174), and
  the DomainDetailView section list (~line 149).
- `.planning/ROADMAP.md` — Phase 4 goal, the 4 success criteria (SC1 = Q1 must be recorded
  first), and the "Depends on Phase 1 / resolve Q1 before building" dependency note.
- `.planning/REQUIREMENTS.md` — CLIP-01…CLIP-04 + shared baseline DoD.
- `.planning/PROJECT.md` — locked-intent decisions (DEC-offline-only-v1,
  DEC-additive-migration-only), Out-of-Scope boundaries (Clip rich previews, cross-domain free
  tags), and Q1 in Open Questions.
- `.planning/phases/02-rules-b/02-CONTEXT.md` — the row→detail nav template (D-08/D-12),
  `RuleEditorView`/`RuleDetailView` form idiom, soft-archive (D-13), and plan-less migration
  stance this phase mirrors.
- `.planning/phases/03-collections-c/03-CONTEXT.md` — the `DomainDetailView.nonEmptySections`
  section-append pattern (D-15), the DesignKit status-chip styling to match (D-04 here), and
  the schemaVersion-bump + round-trip discipline (D-23).

### Migration (mandatory before any @Model change)
- `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` — plan-less inferred migration, additive-defaulted field
  rule, the mandatory upgrade test, Forbidden Moves (no `migrationPlan:`, no required-no-default
  fields, no bare renames).
- `CLAUDE.md` §9.12 (schema changes), §9.5 (pure services ship with tests — the D-02 title
  helper), §9.1/§9.2/§9.3/§9.15 (file cap, data-driven views, empty states, accessibility),
  §9.4 (verify tokens exist), §9.13 (os.Logger not print), §8 (commands; bundle id is
  `lauterstar.HabitsTracker` — supersedes the stale `gn.HabitsTracker` in PROJECT.md), §1
  (design constraints, tokens-only).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HabitsTracker/Features/Hub/DomainDetailView.swift` — `nonEmptySections(theme:)` already
  reserves the Clips slot ("Phase D–E: append Clips / Ideas sections here", ~line 81). Copy the
  `buildCollectionsSection` / `collectionsSectionContent` / `collectionsSectionHeader` trio
  (~lines 140–169) verbatim in shape for Clips (D-10). The shared empty-state copy at ~line 210
  already name-checks "clips".
- `HabitsTracker/Models/Domain.swift` — add `Domain.clips` inverse with the same
  `.nullify` + `inverse:` idiom already used for `.rules` / `.collections` / `.habits` (D-12).
- `HabitsTracker/Models/Rule.swift` — the minimal `@Model` shape (`@Attribute(.unique) id`,
  scalar fields, defaulted `isArchived`, a `@Relationship domain`) to mirror for `Clip` (D-11).
- `HabitsTracker/Features/Settings/HabitEditorView.swift` + the Phase 2 `RuleEditorView` —
  the form-sheet idiom to mirror for `ClipEditorView` (D-09).
- `HabitsTracker/Services/ExportImportService.swift` — `schemaVersion` currently `4` (line 98);
  bump to `5` and extend the round-trip for `Clip` (D-13).
- `HabitsTrackerApp.swift` — the `.modelContainer(for: [ … ])` type list (line 15); register
  `Clip` here (D-12).
- DesignKit `DKBadge`/pill (status chip, D-04), `DKSectionHeader`, `DKCard`, `openURL`
  environment action (Open Link, D-08) — tokens only (§9.4).

### Established Patterns
- ModelContainer is **plan-less** (`.modelContainer(for:[…])`, no `migrationPlan:`) — inferred
  lightweight migration; new fields optional/defaulted (DEC-additive-migration-only).
- `.nullify` relationships with `inverse:` are the house idiom; Xcode synchronized root groups
  (`objectVersion 77`) auto-register new `.swift` files — never hand-edit `project.pbxproj`
  (§9.8); no Finder-dupe files (§9.6).
- Pure helpers ship with unit tests in the same commit (§9.5) — the D-02 zero-network
  title-suggestion parser is the testable core here. Habit engines stay habit-only.
- Nav template: domain section → "+" in section header → editor → row → detail view
  (Phase 2 D-12, Phase 3 D-09).

### Integration Points
- New `Clip` `@Model` + `Domain.clips` inverse → container type list + inferred migration +
  upgrade test + schemaVersion 4→5.
- Clips section slots into `DomainDetailView.nonEmptySections` next to Rules and Collections
  (D-10).
- The D-02 title helper is a new pure function (no persistence) consumed only by `ClipEditorView`.

</code_context>

<specifics>
## Specific Ideas

- The whole reason Clips exist: **"saved links rot"** — a clip must carry status + domain so it
  is *found where you'd look* and you *remember to act on it*. That drove the on-row status chip
  (D-08) and strict domain filing.
- Offline-only is non-negotiable here (SC1 is a gate) — but a **zero-network** title suggestion
  (D-02) is a legitimate friction win that stays inside the constraint. No network, ever.
- Clips are **action-oriented** (the URL is the payload) — this was the argument *for* a
  row-primary tap-opens-URL shape, but template consistency + note visibility won (D-07). The
  "Open Link" action is made prominent in the detail view to preserve the act-on-it feel.
- Don't over-abstract: a fixed 2-state saved→acted is a dedicated enum, not the StatusSet
  catalog (D-03) — same visual, no coupling.

</specifics>

<deferred>
## Deferred Ideas

- **Clip rich previews / link thumbnails / on-demand fetch** — explicitly out of scope
  (offline-only v1); opt-in fetch revisited past Phase D (PROJECT.md Out of Scope).
- **Cross-domain free tags / tag taxonomy** — deferred; v1 is strict domain filing + a single
  free-text per-clip label only (revisit after Phase F).
- **In-domain tag autocomplete** — considered (Tag option 2), not taken; would edge toward the
  deferred tag system.
- **Full multi-type export/import completeness** (all 8 types under one schemaVersion) — Phase 6.
  Phase 4 keeps the round-trip green only for the `Clip` it adds.
- **Ideas + promote-to-anything** (including the in-domain "+" unification) — Phase 5. Promote
  targets will reuse the per-domain entry points established across Phases 2–4.

None outside phase scope — discussion stayed within the Clips domain.

</deferred>

---

*Phase: 4-Clips (D)*
*Context gathered: 2026-07-08*
