# Phase 2: Rules (B) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-04
**Phase:** 2-Rules (B)
**Areas discussed:** Rule↔Habit link storage, Shared create-sheet lifecycle, Rule surface & entry points, Rule edit & archive pattern
**Calibration:** minimal_decisive (vendor_philosophy: opinionated). Technical framing retained — developer working in own Swift/SwiftData codebase; product-outcome reframing not applied.
**Research:** No advisor research agents spawned — internal SwiftData/architecture decisions where codebase + migration playbook already constrain the answers; recommendations drawn from direct model/code inspection.

---

## Rule↔Habit link storage

| Option | Description | Selected |
|--------|-------------|----------|
| Relationship (.nullify) | `Habit.originRule: Rule?` with `.nullify` inverse `Rule.stemmedHabits`; free nullify-on-delete, direct N-count, mirrors Domain↔Habit | ✓ |
| Raw originRuleID UUID | Literal UUID field; hand-rolled nullify + both-direction fetches | |

**User's choice:** Relationship (.nullify)
**Notes:** Requirement's `originRuleID` names intent (nulled, never cascade); relationship delivers it idiomatically and matches the existing `Habit.category ↔ Domain.habits` pattern.

---

## Shared habit-create sheet lifecycle

| Option | Description | Selected |
|--------|-------------|----------|
| Fill-then-commit (new sheet) | New `HabitCreateSheet` over in-memory draft; inserts only on Save; orphan-free cancel | ✓ |
| Reuse insert-then-edit | Extend `HabitEditorView`; can leave orphan "New Habit" on cancel | |

**User's choice:** Fill-then-commit (new sheet)
**Notes:** Load-bearing for Phase 5 promote. Follow-up asked → **also migrate the existing "Add Habit" button** to the new sheet (one create path everywhere).

---

## Rule surface & entry points

| Option | Description | Selected |
|--------|-------------|----------|
| RuleDetailView + section "+" | Dedicated detail view (body, sourceURL, Stem, Stemmed:N); Rules section in DomainDetailView with "+"; sets pattern for C–E | ✓ |
| Flat / inline only | No detail view; edit + stem from list row | |

**User's choice:** RuleDetailView + section "+"
**Notes:** Reference-first items need room for body + source; nav shape becomes the template Phases C–E mirror.

---

## Rule edit & archive pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror Habit (isArchived + editor form) | `isArchived` soft-archive + `RuleEditorView` form; soft-confirm delete when stemmed | ✓ |
| Delete-only, lighter editor | No archive; simpler inline editor | |

**User's choice:** Mirror Habit (isArchived + editor form)
**Notes:** Consistent with existing patterns (§4 reuse); RULE-01 explicitly lists archive.

---

## Claude's Discretion

- `HabitCreateSheet` prefill shape (enum `HabitSource` vs prefill struct) — must stay source-agnostic.
- `RuleDetailView` / `RuleEditorView` layout within DesignKit tokens; file-split per §9.1; data-driven per §9.2.
- Rules-section empty-state copy (§9.3) and sourceURL affordance styling.

## Deferred Ideas

- Global Idea capture + Hub inbox + Promote — Phase 5 (reuses this phase's create sheet).
- Full multi-type export/import completeness — Phase 6.
- Collections / Clips sections in DomainDetailView — Phases 3/4 (mirror the Rules-section pattern).
