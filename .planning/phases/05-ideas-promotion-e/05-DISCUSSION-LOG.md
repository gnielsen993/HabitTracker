# Phase 5: Ideas + Promotion (E) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-10
**Phase:** 5-Ideas + Promotion (E)
**Areas discussed:** Global quick-add control, Hub inbox shape, Promote flow UI, Idea surface weight

---

## Global quick-add control

| Option | Description | Selected |
|--------|-------------|----------|
| A1 — Today toolbar "+" | Native top-trailing "+" on Today's nav bar; opens the capture sheet (Idea → inbox); no list pollution/overlay; live only on Today. | ✓ |
| A2 — Floating button over tabs | DesignKit FAB overlaid in RootTabView, reachable from every tab; matches "always-reachable from anywhere"; less-native, overlay layout, overlap risk. | |

**User's choice:** A1 — Today toolbar "+"
**Notes:** Center tab-bar "+" was ruled out up front (would grow/customize the 4-tab bar — violates DEC-four-tabs). A1 chosen for native idiom + zero Today-list pollution + literal "without leaving Today" satisfaction; A2's from-any-tab reach judged nice-to-have, noted as deferred.

---

## Hub inbox shape

| Option | Description | Selected |
|--------|-------------|----------|
| B1 — Pinned inbox card → InboxView | Inbox card above the domain grid with a "N to file" count; tap opens a dedicated inbox list; shown only when unfiled ideas exist. | ✓ |
| B2 — Inbox tile in the grid | An "Inbox" pseudo-tile alongside DomainTiles in the LazyVGrid; simpler placement but mixes an action surface into the domain grid. | |

**User's choice:** B1 — Pinned inbox card → InboxView
**Notes:** Designed empty state deferred to Phase 6 (POL-02); InboxView is data-driven (parent owns the query, §9.2).

---

## Promote flow UI

| Option | Description | Selected |
|--------|-------------|----------|
| C1 — Menu → existing prefilled editor | Tap Promote → pick Rule/Habit/Collection → existing editor opens prefilled from the idea (domain/collection prompt injected) → Save; habit uses HabitCreateSheet(.idea). | ✓ |
| C2 — Bespoke PromoteSheet | One sheet with a type segmented control + inline contextual fields; single surface but re-implements editor fields and still hands off habit to the shared sheet. | |

**User's choice:** C1 — Menu → existing prefilled editor
**Notes:** Chosen for maximum reuse (all three target editors exist) and consistency with the already-forced habit hand-off. The consume/archive/forward-link asymmetry (DEC-promote-is-consume) is locked and centralized in one small promote helper.

---

## Idea surface weight

| Option | Description | Selected |
|--------|-------------|----------|
| D1 — Lightweight row, no detail view | Idea = row + inline File/Promote + title-only capture sheet; no IdeaDetailView/editor; keep per-section "+" (add Ideas "+"); global quick-add is the unifier. | ✓ |
| D2 — Full nav template | IdeaDetailView + IdeaEditorView mirroring Rules/Clips; consistent but heavyweight for a consumed type. | |

**User's choice:** D1 — Lightweight row, no detail view
**Notes:** Deliberate break from the Phase 2 D-12 detail-view template — an idea is staging, meant to be consumed, not curated. Unified domain-level "+" type picker considered and rejected (deferred); the roadmap's "ties together the in-domain '+'" is satisfied by the global quick-add spine.

---

## Claude's Discretion

- Exact `Idea` field names and the forward-link representation (additive/optional + no-backref).
- Row-action affordance for File/Promote (trailing buttons vs swipe vs context menu).
- Whether capture sheet + in-domain Ideas "+" share one title-only sheet component, and layout.
- `InboxView` / row / inbox-card layout and "N to file" copy (designed empty state = Phase 6).
- Whether promote routing lives in a `PromoteService` vs inline coordinator (logic centralized + testable).
- Whether the capture sheet optionally sets a domain at capture time (default: title-only → inbox).

## Deferred Ideas

- Unified domain-level "+" type picker — considered under D1, not taken; future polish refactor.
- Global capture from any tab (FAB over RootTabView) — A2, rejected; revisit if dogfooding needs it.
- Designed empty states, cross-domain search, full 8-type export/import — all Phase 6 (F).
- Optional set-domain-at-capture-time — noted as discretion; default stays title-only → inbox.
