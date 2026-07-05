# Phase 3: Collections (C) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-05
**Phase:** 3-Collections (C)
**Areas discussed:** StatusSet storage model, Chip behavior + position, Preset delivery + nesting, Aggregate rollup rendering
**Mode:** Advisor (research-backed comparison tables; calibration tier `minimal_decisive` — opinionated vendor philosophy). 4 parallel research agents (sonnet).

---

## StatusSet storage model

| Option | Description | Selected |
|--------|-------------|----------|
| Code catalog + IDs | `StatusSetCatalog` enum in code; Collection `statusSetID:String`, CollectionItem `statusIndex:Int`; no new @Model. Trivial export, structural non-editability, smallest additive migration. | ✓ |
| Full @Model StatusSet | StatusSet (+ StatusState) as SwiftData @Model types with relationships — more container/seed/export surface + seed-drift risk. | |

**User's choice:** Code catalog + IDs (recommended).
**Notes:** COLL-01's "a StatusSet model exists" read as a typed value model — valid because built-in labels are non-editable and users author no new sets in v1. Future user-defined sets are a single well-scoped additive @Model migration at that time, not a reason to pay full model surface now.

---

## Tap-to-advance chip at terminal

| Option | Description | Selected |
|--------|-------------|----------|
| Stop + long-press reset | Terminal sticky; tap at terminal is a no-op; reset via context-menu / long-press with VoiceOver custom action. Protects completion signal. | ✓ |
| Wrap-around cycle | Tapping terminal loops to first state — simpler but a stray tap destroys completion state with no friction. | |

**User's choice:** Stop + long-press reset (recommended).
**Notes:** "Cycles including the terminal state" interpreted as terminal being reachable by tapping, not wrap-around. Advance = `min(statusIndex+1, terminal)`. Add sensory feedback so the terminal no-op isn't perceived as broken.

---

## Position controls (+episode / +season / finished, +1)

| Option | Description | Selected |
|--------|-------------|----------|
| In item detail view | Row shows compact `S2 E4` + chip as a NavigationLink to CollectionItemDetailView, where steppers + note/url/cost live. Mirrors Phase 2 Rules row→detail; Dynamic-Type safe. | ✓ |
| Inline row steppers | +episode/+season/+1 buttons on the row for one-tap advance — lowest friction but breaks at larger Dynamic Type and crowds 44pt targets. | |

**User's choice:** In item detail view (recommended).
**Notes:** A swipe-action "+1 / +Episode" row shortcut stays open as a later low-risk add if daily incrementing feels heavy; row layout kept compatible.

---

## Preset delivery + nesting

| Option | Description | Selected |
|--------|-------------|----------|
| Catalog + generic starter | `CollectionPresetCatalog` in code drives a preset picker on "+"; seed only ONE generic starter collection on fresh install. Upgrader-safe; avoids "empty Notion folders". | ✓ |
| Seed all 8 curated collections | Pre-instantiate all 8 curated (empty) collections into domains + the picker — floods the Hub with empty folders, complicates upgrader merge-add. | |

**User's choice:** Catalog + generic starter (recommended).
**Notes:** "Ship as seed content" (COLL-07) satisfied by the code catalog; "create from preset" (criterion 1) by the picker. Presets are not domain-locked (the "+" is already domain-scoped). Collections section shows when `!domain.collections.isEmpty` — a 0-item collection is a valid non-empty section (mirrors the Rules contract).

---

## Aggregate rollup rendering

> Single strong recommendation (no competing fork at `minimal_decisive`); presented and accepted as locked.

| Decision | Resolution | Selected |
|----------|------------|----------|
| X/Y semantics | Strictly terminal: `X = items where statusIndex == terminalIndex`, `Y = total` (a mid-step `watching` item is NOT counted). | ✓ |
| Where it renders | Dual-surface: trailing label on the collection row in DomainDetailView + CollectionDetailView header. | ✓ |
| Ring vs text | Completionist X/Y may use a small DKProgressRing; cost sum is ALWAYS plain text (`$340`), never a ring (DEC-cost-rollup-never-ring). | ✓ |
| Compute home | Pure `CollectionRollupEngine` → `.count(x,y)` / `.costSum(total)` / `.none`, with unit tests (§9.5). "Money-flavored" derived (no new stored flag). | ✓ |

**User's choice:** Accepted as presented.
**Notes:** Rollup engine tests: completionist happy path, empty list, multi-step set with mid-step items, cost list with mixed nil/non-nil costs, tracker with `showsAggregate` off → `.none`.

---

## Claude's Discretion

- Exact `Collection`/`CollectionItem` field set beyond the decided ones (SPEC lists title/note?/url?/cost?/sortIndex/isSeeded + position + counter label).
- Generic starter collection name + which domain it seeds into.
- Preset picker + detail view layouts and Collections empty-state copy (within DesignKit tokens, ~400-line cap, data-driven views).
- Cost formatting / currency locale.
- Whether the counter label is stored on the item or the collection.
- Collection delete rule for its items (default lean: `.cascade` — items are collection-owned, unlike hero habits).

## Deferred Ideas

- Swipe-action "+1 / +Episode" row shortcut — optional later add (D-11).
- User-defined / editable StatusSets — scope-guarded; future additive @Model if ever approved.
- More progress templates beyond the fixed set — locked (DEC-fixed-progress-templates).
- Full multi-type export/import completeness — Phase 6.
- Clips section / Ideas + promote-to-collection — Phases 4/5 (promote targets these collections).
