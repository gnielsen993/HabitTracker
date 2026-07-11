# Roadmap: HabitsTracker — Lifestyle Hub

## Overview

HabitsTracker v1.0 (binary habits + streaks + weekly goals + calendar heatmap) is already shipped. This milestone evolves it into a local-first lifestyle hub without disturbing the hero loop: it generalizes `Category` into `Domain` and adds a Hub home (Phase A), then layers in the four offshoot item types — Rules (Phase B), Collections (Phase C), Clips (Phase D), Ideas (Phase E) — and finishes with a cross-cutting polish pass (Phase F). The connective tissue (Rule→Habit stem, Idea→anything promote) is what turns typed folders into a system. Phases A–F preserve the SPEC's build order; each is a shippable vertical slice where habits keep working throughout. Widgets remain deferred past this milestone.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work. Phases 1–6 correspond to the SPEC's Phases A–F.
- Decimal phases (2.1, 2.2): Urgent insertions (marked INSERTED).

- [x] **Phase 1: Domain Generalization (A)** - Generalize Category→Domain, add the Hub tab, focus picker, and custom domains. (completed 2026-07-02)
- [x] **Phase 2: Rules (B)** - Reference-first Rules plus the Stem-a-habit flow and the shared habit-create-from-source sheet. (completed 2026-07-05)
- [x] **Phase 3: Collections (C)** - StatusSet model, tap-to-advance chips, fixed progress templates, aggregate/cost rollups, curated presets. (completed 2026-07-06)
- [x] **Phase 4: Clips (D)** - Offline-only saved links with tag and saved/acted status, filed by domain. (completed 2026-07-09)
- [ ] **Phase 5: Ideas + Promotion (E)** - Global capture-first quick-add, Hub inbox, File vs Promote graduations.
- [ ] **Phase 6: Polish (F)** - Cross-domain search, empty states, full multi-type export/import, accessibility pass.

## Phase Details

### Phase 1: Domain Generalization (A)
**Goal**: The app's spine becomes Domain-centric — focused domains live in a new Hub home — while Today and all existing habit data are untouched. This is the foundation every later phase files into.
**Depends on**: Nothing (first phase). Resolve open questions Q2 (Category→Domain migration path) and Q3 (seed reconciliation for existing users) before building.
**Requirements**: DOM-01, DOM-02, DOM-03, DOM-04, DOM-05, DOM-06
**Success Criteria** (what must be TRUE):
  1. Upgrade test green — an existing habit user updates over their store, the app launches, and all prior habits/categories remain visible.
  2. The Hub tab shows focused domains as an icon+color grid; tapping a tile opens DomainDetailView showing only non-empty sections.
  3. The focus picker adds/removes a Hub tile; unfocusing hides the tile but never deletes content.
  4. A custom domain (name + SF Symbol + color token) persists and appears in the catalog.
  5. Today is visually unchanged and the tab bar stays at 4 tabs.
**Plans**: 6 plans
- [x] 01-01-PLAN.md — Wave-0 validation scaffold (failing tests + DOM-01 upgrade runbook)
- [x] 01-02-PLAN.md — Category→Domain rename + isFocused + schemaVersion-2 Export/Import + upgrade-test gate
- [x] 01-03-PLAN.md — Seed reconciliation: lastSeededVersion marker, gated focus backfill, merge-add, accentColor resolver
- [x] 01-04-PLAN.md — Tab recomposition: remove Calendar tab, fold into Progress (Charts⇄Calendar)
- [x] 01-05-PLAN.md — Hub UI: HubView grid + DomainTile + DomainDetailView + Hub tab (4-tab IA)
- [x] 01-06-PLAN.md — Focus picker + custom-domain creation (curated icon grid + 5-token swatch row)
**UI hint**: yes

### Phase 2: Rules (B)
**Goal**: Rules exist as clean, reference-first items filed by domain, and the user can spin a habit off a rule via a shared, reusable habit-create sheet that flows the new habit into Today.
**Depends on**: Phase 1 (Domain model + DomainDetailView). PROVIDES the shared habit-create-from-source sheet that Phase 5 reuses for promote-to-habit — load-bearing.
**Requirements**: RULE-01, RULE-02, RULE-03, RULE-04, RULE-05
**Success Criteria** (what must be TRUE):
  1. User can create, edit, and archive a Rule (title + body + optional sourceURL), filed under a domain.
  2. "Stem habit" opens a prefilled sheet (title + rule's domain, editable schedule); the new habit appears on Today and the rule is left untouched.
  3. The rule shows "Stemmed: N habits" that jumps to a habit; the habit shows a "from rule" backref that jumps to the rule.
  4. One rule can stem ≥2 habits.
  5. Deleting a rule with stemmed habits soft-confirms; the habits survive and originRuleID is nulled (never cascade).
**Plans**: TBD
**UI hint**: yes

### Phase 3: Collections (C)
**Goal**: Domains can hold opinionated lists whose items carry behavior — a tap-to-advance status chip, an optional position, and aggregate/cost rollups — so a Shows list or a wishlist feels considered, not like inert text.
**Depends on**: Phase 1 (Domain model). The generic StatusSet preset (to-collect → collected) is a prerequisite and must exist before any user-created collection can be saved. Scope guard: do not reopen the fixed progressTemplate set mid-phase.
**Requirements**: COLL-01, COLL-02, COLL-03, COLL-04, COLL-05, COLL-06, COLL-07
**Success Criteria** (what must be TRUE):
  1. User can create a collection from a preset; items carry status from its StatusSet and the tap-to-advance chip cycles through states including the terminal state.
  2. The seasonEpisode template works (+episode, +season resets episode→1, finished→terminal) and shows "S2 E4"; the counter template's +1 increments its label.
  3. showsAggregate ON shows "X/Y" for completionist lists; tracker mode shows no progress ring; money lists roll up a cost sum.
  4. The generic preset exists and is the default StatusSet for user-created lists.
  5. Built-in StatusSet labels are not editable.
**Plans**: 5 plans
- [x] 03-01-PLAN.md — Schema foundation: Collection + CollectionItem @Models + Domain.collections inverse + container registration + upgrade-test gate
- [x] 03-02-PLAN.md — Code catalogs (StatusSet + Preset) + CollectionRollupEngine with unit tests
- [x] 03-03-PLAN.md — Collections section + preset picker + CollectionRow + CollectionDetailView (rollups)
- [x] 03-04-PLAN.md — Item surfaces: tap-to-advance chip + seasonEpisode/counter controls + item editor
- [x] 03-05-PLAN.md — Seed one generic starter + Export/Import schemaVersion 4 round-trip
**UI hint**: yes

### Phase 4: Clips (D)
**Goal**: Saved links stop rotting — a clip carries a tag, a saved→acted status, and a domain, found exactly where you'd look, fully offline.
**Depends on**: Phase 1 (Domain model). Requires resolving open question Q1 (Clip preview vs offline-only) before building (default: store URL + manual title/note, fully offline).
**Requirements**: CLIP-01, CLIP-02, CLIP-03, CLIP-04
**Success Criteria** (what must be TRUE):
  1. The offline-preview decision (Q1) is resolved and recorded before any Clip code is written.
  2. User can save a URL with title + note + tag + status fully offline, with no network fetch.
  3. A clip is filed by domain and found in that domain's Clips section.
  4. A clip's status toggles saved → acted.
**Plans**: 5 plans
- [x] 04-01-PLAN.md — Schema foundation: Clip @Model + ClipStatus enum + Domain.clips inverse + container registration + upgrade-test gate
- [x] 04-02-PLAN.md — Zero-network title-suggestion helper (ClipTitleSuggestion) + runnable unit tests
- [x] 04-03-PLAN.md — Clip surfaces: ClipEditorView + ClipRow + ClipDetailView (Open Link CTA, status chip toggle)
- [x] 04-04-PLAN.md — Export/Import schemaVersion 4→5 round-trip for Clip
- [x] 04-05-PLAN.md — Wire Clips section into DomainDetailView + owner visual/offline/round-trip verification
**UI hint**: yes

### Phase 5: Ideas + Promotion (E)
**Goal**: A single always-reachable capture point feeds a Hub inbox, and unfiled ideas graduate in one tap — File to keep them as ideas, or Promote to consume them into a rule, habit, or collection item — tying together the in-domain "+" creation delivered across Phases 2–4.
**Depends on**: Phase 1 (Domain), Phase 2 (REUSES the shared habit-create sheet for promote-to-habit — load-bearing), Phase 3 (promote-to-collection-item target), Phase 4 (in-domain "+" per type). This phase adds the global capture surface that unifies the per-domain entry points.
**Requirements**: IDEA-01, IDEA-02, IDEA-03, IDEA-04, IDEA-05
**Success Criteria** (what must be TRUE):
  1. The global quick-add is reachable without leaving Today and without adding a row to Today's list; it defaults to Idea and lands in the Hub inbox.
  2. File assigns a domain and the item stays an Idea.
  3. Promote converts an idea to a rule/habit/collection item per the asymmetry rule — the idea is archived with a forward-link and leaves the active list — and promote-to-habit reuses Phase 2's sheet.
  4. An unfiled-idea promote prompts for a domain; promote-to-collection prompts for the target list.
**Plans**: 10 plans (6 waves)
- [x] 05-01-PLAN.md — Schema spine: Idea @Model + PromotedKind facade + Domain.ideas inverse + container registration + IdeaModelTests [wave 1]
- [x] 05-02-PLAN.md — Export/Import schemaVersion 5→6 + IdeaDTO round-trip + SettingsView call site [wave 2]
- [x] 05-03-PLAN.md — PromoteService consume/archive/forward-link core + runnable engine-tier tests (§9.5) [wave 2]
- [x] 05-04-PLAN.md — Mandatory upgrade test (Phase-4 store → Idea-expanded schema, data intact) — owner/simctl checkpoint [wave 2]
- [x] 05-05-PLAN.md — Capture spine: IdeaCaptureSheet (title-only) + Today top-trailing "+" [wave 2]
- [x] 05-06-PLAN.md — Promote target editors: HabitSource.idea + RuleEditorView/CollectionItemEditorSheet prefill+gate + PromoteToCollectionPicker [wave 3]
- [x] 05-07-PLAN.md — IdeaRow: reusable row + tap-to-edit + inline File/Promote menus + promote routing [wave 4]
- [x] 05-08-PLAN.md — Hub inbox card (count-gated) + data-driven InboxView [wave 5]
- [ ] 05-09-PLAN.md — Ideas section in DomainDetailView + in-domain place-first "+" [wave 5]
- [ ] 05-10-PLAN.md — Owner full-flow device verification (SC1–SC4 + baseline DoD) [wave 6]
**UI hint**: yes

### Phase 6: Polish (F)
**Goal**: The hub feels finished and durable — searchable across domains, gracefully empty where empty, fully exportable, and accessible — and the pre-existing "Next 3" debt is cleared.
**Depends on**: Phases 1–5 (operates across all new types).
**Requirements**: POL-01, POL-02, POL-03, POL-04
**Success Criteria** (what must be TRUE):
  1. Cross-domain search returns items across all types and navigates to a tapped result.
  2. Every section, the inbox, and the Hub have a designed empty state.
  3. Full export/import round-trips ALL types (Domain, Habit, Rule, Collection, CollectionItem, Idea, Clip, StatusSet) under the bumped schemaVersion.
  4. Accessibility holds: Dynamic Type, VoiceOver labels on chips/buttons/grid, tokens-only colors; schema/version is visible in Settings.
**Plans**: TBD
**UI hint**: yes

### Deferred — Widgets (Later, out of milestone)
**Goal**: WidgetKit widgets from the original v1 spec.
**Depends on**: Hub stabilization (post-Phase 6). NOT scheduled in this milestone — listed for traceability only (WDGT-01, see REQUIREMENTS.md v2).
**Status**: Deferred.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Domain Generalization (A) | 6/6 | Complete   | 2026-07-02 |
| 2. Rules (B) | 3/3 | Complete   | 2026-07-05 |
| 3. Collections (C) | 5/5 | Complete   | 2026-07-07 |
| 4. Clips (D) | 5/5 | Complete   | 2026-07-09 |
| 5. Ideas + Promotion (E) | 8/10 | In Progress|  |
| 6. Polish (F) | 0/TBD | Not started | - |
