# Phase 1: Domain Generalization (A) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-28
**Phase:** 1-Domain Generalization (A)
**Mode:** advisor (research-backed tables; calibration tier `minimal_decisive`)
**Areas discussed:** Category→Domain migration, Seed reconciliation + default focus, Tab bar recomposition, Custom domain creation UX

---

## Category → Domain migration (Q2)

| Option | Description | Selected |
|--------|-------------|----------|
| Real rename now | Rename @Model class to Domain via `@Attribute(originalName:)`, plan-less; gated by upgrade test + schemaVersion bump | ✓ |
| Relabel-only | Keep class `Category`, show "Domain" in UI; zero migration but permanent code/concept mismatch | |

**User's choice:** Real rename now (Recommended)
**Notes:** Advisor rationale — pre-launch, ~10 references today; 5 later phases add `Rule.domain`/`Collection.domain`; relabel-only compounds debt. Migration-plan path remains struck.

---

## Seed reconciliation + default focus (Q3)

| Option | Description | Selected |
|--------|-------------|----------|
| Backfill-focus + merge new unfocused | seedVersion 1→2; existing rows backfill isFocused=true (no empty Hub); new domains merge-add unfocused (name-keyed dedupe) + hint; fresh installs pre-focus subset | ✓ |
| All unfocused (uniform) | Everything lands unfocused; user picks from catalog; upgraders hit an empty Hub | |

**User's choice:** Backfill-focus + merge new unfocused (Recommended)
**Notes:** Once-only version-gated backfill in BootstrapService; never destroys data; pair with "new domains available" hint.

---

## Tab bar recomposition

| Option | Description | Selected |
|--------|-------------|----------|
| Segmented control atop Progress | Charts ⇄ Calendar segments; reuse CalendarMonthHeatmapView/DayDetailSheet near-verbatim | ✓ |
| Scrollable section in Progress | Heatmap below charts; raises density, below the fold | |
| Nav-push to calendar detail | Toolbar glyph → dedicated screen; lowest discoverability | |

**User's choice:** Segmented control atop Progress (Recommended)
**Notes:** Calendar tab removed to fit Hub at 4 tabs; strip inner NavigationStack, re-anchor selectedDay sheet under Progress's stack. Today unchanged.

---

## Custom domain creation UX

| Option | Description | Selected |
|--------|-------------|----------|
| Curated grid + 5 swatches | ~30 hand-picked SF Symbols in a LazyVGrid + 5 accent-token swatch row; no dependency | ✓ |
| Full SF Symbols browser | Searchable full catalog; max freedom but off-aesthetic glyphs + third-party dep | |

**User's choice:** Curated grid + 5 swatches (Recommended)
**Notes:** Restraint enforced by construction; color is closed pick-one-of-5 DesignKit tokens.

## Claude's Discretion

- Final ~30-symbol curated icon set.
- Visual treatment of the "new domains available" hint (badge vs banner) and Hub tile layout, within DesignKit tokens.
- Internal naming/structure of new views (HubView, DomainDetailView, DomainFocusPicker), respecting §9.1 / §9.2.

## Deferred Ideas

- New hub seed domains' starter *content* (Rules/Collections items) lands in Phases B/C, not here.
- Q5 product naming — non-blocking, not this phase.
- Cross-domain tagging (Q4) — after Phase F.
