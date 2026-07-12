# Phase 6: Polish (F) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-11
**Phase:** 6-Polish (F)
**Areas discussed:** Search home & invocation, Search scope & result grouping, Result tap destination, Empty-state & a11y/schema bar
**Mode:** Advisor (research-backed comparison tables) · calibration `minimal_decisive` (opinionated vendor philosophy) · technical framing (non-technical-owner heuristic overridden to false — profile shows overwhelming technical-background evidence)

---

## Search home & invocation

| Option | Description | Selected |
|--------|-------------|----------|
| Hub `.searchable` + `.searchToolbarBehavior(.minimize)` | Native iOS 26 magnifying-glass → inline field on Hub root; free VoiceOver; no new screen | ✓ |
| Pushed dedicated search screen | Nav-bar toolbar item pushes a full-screen search view; hand-rolls what minimize gives, adds a nav hop | |

**User's choice:** Hub `.searchable` + minimize
**Notes:** Hub is the locked-IA cross-domain home (`DEC-four-tabs` forbids a Search tab); Today stays untouched. Deployment target iOS 26 makes `.minimize` available.

---

## Search scope & result grouping

| Option | Description | Selected |
|--------|-------------|----------|
| Grouped by type, title+body match | Sections per type; match title + body/note/URL; include habits; exclude archived/consumed | ✓ |
| Flat ranked list | Single mixed feed sorted by match quality; needs a ranking heuristic | |
| Grouped by type, title-only match | Same layout but title-only matching; misses body/note/URL hits | |

**User's choice:** Grouped by type, title+body match
**Notes:** Spotlight/Settings-search convention; N per-model filtered fetches (SwiftData has no cross-model FTS). Grouped-by-domain rejected — Hub→DomainDetailView already is the domain lens. Include habits (POL-01 = all types); exclude archived/consumed by default.

---

## Result tap destination

| Option | Description | Selected |
|--------|-------------|----------|
| Item's own detail/editor | Push Rule/Collection/Clip detail; sheet for Idea + Habit; reuses wired destinations; only option coherent for habits | ✓ |
| Deep-link into DomainDetailView + scroll | Land on domain screen and scroll/highlight; no scroll infra exists, grows a near-cap file, misses habits | |

**User's choice:** Item's own detail/editor
**Notes:** Habit results open `HabitEditorView` as a sheet (existing Settings entry point), not a jump to Today. No new navigation infrastructure.

---

## Empty-state & accessibility/schema bar

| Option | Description | Selected |
|--------|-------------|----------|
| Fix-as-found | Land VoiceOver labels/traits (incl. tap-to-advance chips), Dynamic Type, token verification now; shared empty fallback + `ContentUnavailableView.search`; schema/version row in Settings | ✓ |
| Audit-only | Document a11y gaps, fix later; defers the POL-04 debt, contradicts §9.15 | |

**User's choice:** Fix-as-found
**Notes:** Tap-to-advance chips flagged as the priority VoiceOver correctness fix. Shared empty fallback kept (bespoke per-section copy deferred as speculative). Schema (6) + marketing version (1.0) as a read-only Settings About row. POL-03 is round-trip verification at v6 — bump only if a persisted field is genuinely added.

---

## Claude's Discretion

- Search view file layout / view-model shape / how the 5 per-type fetches are wired.
- Whether the search field is always visible or only when non-empty (pick native default; must always be reachable from Hub).
- Precise empty/"About" copy strings.

## Deferred Ideas

- Domain-context in search rows (disambiguate same-named hits across domains) — revisit only if type-grouping proves ambiguous.
- Relevance ranking / flat search feed — only if datasets grow into the thousands.
- Bespoke per-item-type empty copy — speculative; shared fallback stands.
- Widgets (WDGT-01) — deferred post-Phase-6, out of milestone.
