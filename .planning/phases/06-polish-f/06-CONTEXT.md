# Phase 6: Polish (F) - Context

**Gathered:** 2026-07-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Cross-cutting polish that makes the Lifestyle Hub feel finished and durable, operating across ALL types delivered in Phases 1–5 (Domain, Habit, Rule, Collection, CollectionItem, Clip, Idea). Four deliverables:

1. **POL-01** — Cross-domain search across all item types that navigates to a tapped result.
2. **POL-02** — A designed empty state for every section, the inbox, and the Hub.
3. **POL-03** — Full export/import round-trip of all types under the (bump-if-needed) `schemaVersion`.
4. **POL-04** — Accessibility pass (Dynamic Type, VoiceOver labels on chips/buttons/Hub grid, tokens-only colors) + schema/version visibility in Settings. Absorbs the pre-existing "Next 3" debt.

**Not in scope:** new item types, new capabilities, widgets (deferred post-milestone), any new tab (4-tab IA is locked). Discussion clarified HOW to implement what is scoped — no new features were added.
</domain>

<decisions>
## Implementation Decisions

### Search — home & invocation (POL-01)
- **D-01:** Cross-domain search lives on the **Hub tab's root**, attached via SwiftUI `.searchable`. Hub is the app's cross-domain "offshoot home," so this is the self-evident host given the locked 4-tab IA (`DEC-four-tabs` — no Search tab possible). Today stays untouched (hero habit loop).
- **D-02:** Invocation uses iOS 26's **`.searchToolbarBehavior(.minimize)`** — a magnifying-glass nav-bar item that expands to an inline search field on tap. This is native (deployment target is iOS 26 / Xcode 26), gives correct VoiceOver semantics for free, and keeps Hub's existing domain grid + inbox card uncluttered. No new screen, no hand-rolled toolbar button.
- Search need only be reachable from Hub (accepted trade-off — Hub is the designated cross-domain surface).

### Search — scope & result grouping (POL-01)
- **D-03:** Results are **grouped by item type** — one `Section` per type (Habits / Rules / Collections / Clips / Ideas), Spotlight/Settings-search style. Implementation is N small per-model filtered fetches (one per type), each row keeping its own navigation target. No relevance-ranking heuristic (no payoff at personal-scale datasets). Grouped-by-domain was rejected: Hub → DomainDetailView already IS the domain lens; type-grouping is the layer search adds.
- **D-04:** Match is **title + free-text fields** (Rule.body, Clip/Idea/CollectionItem.note, and URL fields where present) via `.localizedStandardContains` — cheap at this dataset size, meaningfully better recall than title-only.
- **D-05:** **Include Habits** in search (POL-01 = "ALL types"; excluding the one type that lives outside a domain would be a surprising gap).
- **D-06:** **Exclude archived / soft-deleted and consumed/promoted items** by default (`isArchived == false`; for Idea, treat a set `promotedToKind` as consumed). A search that surfaces dead items the user can't act on breaks the durable-feel goal.
- Note: SwiftData has no cross-model full-text search, so per-model fetches are the idiom regardless — no FTS engine, no new dependency.

### Search — result tap destination (POL-01)
- **D-07:** A tapped result opens the **item's own existing detail/editor surface**, reusing the destinations already wired from DomainDetailView / IdeaRow / HabitManagerView. Concretely: **push** RuleDetailView / CollectionDetailView / ClipDetailView; **sheet** for Idea (`IdeaCaptureSheet(idea:)`) and Habit (`HabitEditorView(habit:)`). No new detail UI.
- **D-08:** **Habit results open `HabitEditorView` as a sheet** (its existing Settings/HabitManager entry point) — NOT a jump to Today. Today is a live-toggle surface, not an editor. This is the only tap model that handles the habit case coherently.
- Deep-linking into DomainDetailView + scroll-to-item was rejected: no scroll-to-item infra exists, DomainDetailView is already ~342 lines (near the §9.1 ~400-line cap), and it still would not cover habits.

### Empty states, accessibility & schema visibility (POL-02, POL-04)
- **D-09:** Accessibility is a **fix-as-found** pass this phase (not audit-only) — matches §9.15 (a11y is a "done" gate) and POL-04's explicit debt-absorption framing. Scope is the enumerable set POL-04 names: tap-to-advance status **chips**, **buttons**, **Hub grid**, Dynamic Type, tokens-only color verification. Do NOT expand into a full app-wide audit.
- **D-10:** The **tap-to-advance status chips are the priority a11y fix** — today they read state but not the action outcome. They need explicit `.accessibilityLabel` (current status) + `.accessibilityHint` / named `.accessibilityAction` describing "advances to next status." Treat as a VoiceOver correctness bug, not polish.
- **D-11:** Empty states reuse the **existing shared DomainDetailView fallback** ("Nothing here yet") rather than bespoke per-section copy — bespoke copy is speculative ("architect for extension, not prediction," §4). Existing empty states (HubView, DomainDetailView, InboxView, PromoteToCollectionPicker) already satisfy §9.3.
- **D-12:** Add a dedicated **search "no results" state via `ContentUnavailableView.search(text:)`** (platform-idiomatic; matches existing `ContentUnavailableView` usage in AppBootstrapView). No hand-rolled empty view.
- **D-13:** Surface **`schemaVersion` (currently 6) + marketing version (`CFBundleShortVersionString`, currently 1.0)** as a read-only row in an existing Settings "About"/footer section — no new screen, no new DesignKit component, existing list-row styling.

### Export/import (POL-03)
- **D-14:** Export/import DTOs for all types (Domain, Habit, Rule, Collection, CollectionItem, Clip, Idea) **already exist and round-trip at `schemaVersion = 6`**. StatusSet is a **code catalog** referenced by ID (`StatusSetCatalog.swift`), not a persisted model — it round-trips via the stored statusSet identifier, not a DTO. POL-03 is therefore primarily **round-trip verification** (§9.12 playbook), not new DTO work.
- **D-15:** **Bump `schemaVersion` only if this phase actually introduces a persisted field.** Search and the a11y pass are read-side; no schema change is expected. Do not perform a cosmetic bump. If a field is added, follow `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` (plan-less additive migration, optional/default fields, `@Attribute(originalName:)` for renames — never a `SchemaMigrationPlan`).

### Claude's Discretion
- Exact search view file layout, the shared search view-model/service shape, and how the 5 per-type fetches are wired (one `SearchService` vs inline `@Query`s) — planner/executor decide, following existing patterns.
- Whether the search field is always visible on Hub or only when non-empty — pick the native/idiomatic default; search must always be reachable from Hub.
- Precise empty/"About" copy strings — follow existing DesignKit token + copy conventions.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 6: Polish (F)" — goal, requirements (POL-01..04), success criteria SC1–SC4.
- `.planning/REQUIREMENTS.md` (POL-01 … POL-04, lines ~56–59) — requirement statements.
- `Docs/LIFESTYLE_HUB_PLAN.md` — milestone spec (Phase F is its final cross-cutting polish pass).

### Data safety / schema (POL-03)
- `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` — MANDATORY before any `@Model` change or `schemaVersion` bump; plan-less additive-only migration rules (§9.12).
- `HabitsTracker/Services/ExportImportService.swift` — current export/import at `schemaVersion = 6`; all DTOs live here.
- `HabitsTracker/Services/StatusSetCatalog.swift` — StatusSet is a code catalog referenced by ID (not persisted).

### Project rules (constitution)
- `CLAUDE.md` §9.3 (every data-driven view ships an empty state), §9.15 (accessibility is part of "done"), §9.1 (~400-line file cap — relevant to DomainDetailView), §9.12/§9.16 (schema playbook + do-not-hand-edit), §1 Design (tokens only, no hardcoded colors).

### Surfaces this phase touches (reusable destinations for D-07)
- `HabitsTracker/Features/Hub/HubView.swift`, `DomainDetailView.swift` — search host + existing empty states.
- `HabitsTracker/Features/Rules/` (RuleDetailView), `Features/Collections/` (CollectionDetailView), `Features/Clips/` (ClipDetailView), `Features/Ideas/` (IdeaCaptureSheet), `Features/Settings/HabitEditorView.swift` — tap destinations.
- `HabitsTracker/Features/Settings/SettingsView.swift` — schema/version row (D-13) + export/import entry (POL-03).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`.searchable` + `.searchToolbarBehavior(.minimize)`** (SwiftUI/iOS 26) — native search host + invocation, free VoiceOver semantics.
- **`ContentUnavailableView` / `.search(text:)`** — already used in `AppBootstrapView.swift`; reuse for the search no-results state.
- **Existing detail/editor surfaces** — RuleDetailView, CollectionDetailView, ClipDetailView, IdeaCaptureSheet(idea:), HabitEditorView(habit:) are already standalone and wired as tap targets elsewhere; search reuses them (D-07).
- **ExportImportService (v6)** already carries all 7 type DTOs — POL-03 is verification, not new DTO code.
- **DesignKit components** — DKCard, DKBadge, DKSectionHeader, DKButton; tokens only (no hardcoded colors).

### Established Patterns
- Per-model SwiftData `@Query` (no cross-model FTS) — search = N small filtered fetches, one per type, each mapped to its own row + destination.
- Domain-filed mental model (Domain owns Habits/Rules/Collections/Clips/Ideas) — search adds the orthogonal type-grouped lens.
- `isArchived` / consumed flags exist across types — search filters them out (D-06).
- Habits live on Today + are edited via HabitEditorView (sheet), NOT under a domain — drives D-08.

### Integration Points
- HubView root gets `.searchable` + a results subview under Hub's existing `NavigationStack`.
- SettingsView gets an About/footer version row (D-13); export/import round-trip re-verified here (POL-03).
- Status-chip components (Collections tap-to-advance, Clip/Idea status chips) get accessibility label/hint/action (D-10).
</code_context>

<specifics>
## Specific Ideas

- Search invocation should feel native — the iOS 26 "magnifying glass expands to a field" minimize behavior, not a custom control.
- Search results should read like Spotlight/Settings search: type-sectioned, scannable, each row navigates to the thing itself.
- The tap-to-advance chips are singled out as the real accessibility gap (silent state change under VoiceOver) — treat as a correctness bug.
</specifics>

<deferred>
## Deferred Ideas

- **Domain-context in search rows** (showing which domain a hit belongs to, e.g. disambiguating two "Watchlist" collections) — not needed for POL-01; revisit only if type-grouping proves ambiguous in use.
- **Relevance ranking / flat search feed** — only worth it if datasets ever grow into the thousands.
- **Bespoke per-item-type empty copy** — deferred as speculative; shared fallback stands until a concrete need appears.
- **Widgets (WDGT-01)** — deferred to post-Phase-6 per roadmap; out of milestone.
</deferred>

---

*Phase: 6-Polish (F)*
*Context gathered: 2026-07-11*
