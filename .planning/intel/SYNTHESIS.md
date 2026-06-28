# Synthesis Summary

Entry point for `gsd-roadmapper`. Mode: new (net-new .planning bootstrap for HabitsTracker
v1.0's first milestone — the Lifestyle Hub). The SPEC (LIFESTYLE_HUB_PLAN.md) is the source of
truth; DOC-type files supply binding constraints + current-state context.

## Doc counts by type
- SPEC: 1 — Docs/LIFESTYLE_HUB_PLAN.md
- DOC: 3 — CLAUDE.md, Docs/SCHEMA_MIGRATION_PLAYBOOK.md, Docs/STATUS.md
- ADR: 0
- PRD: 0
- Total: 4 (all high-confidence, all manifest-type-overridden)

## Decisions (locked-intent: 12)
Source: all from Docs/LIFESTYLE_HUB_PLAN.md (§1, §2, §3, §8) plus 2 constitution-backed
constraint decisions. No schema-level Accepted ADRs exist, so these are "locked-intent" —
preserved, not re-derivable. See intel/decisions.md.
- DEC-today-is-hero, DEC-rules-reference-first, DEC-domains-chosen-set
- DEC-stem-is-copy, DEC-promote-is-consume
- DEC-fixed-progress-templates, DEC-status-template-instances, DEC-cost-rollup-never-ring
- DEC-capture-first-spine, DEC-four-tabs
- DEC-additive-migration-only, DEC-offline-only-v1 (constraint decisions)

## Requirements (6 phases + 1 deferred)
Source: Docs/LIFESTYLE_HUB_PLAN.md §6 build order + acceptance criteria. Phase structure A-F
and cross-phase dependencies preserved. See intel/requirements.md.
- REQ-phase-a-domain-generalization (foundation; no deps)
- REQ-phase-b-rules (dep: A; PROVIDES shared habit-create sheet to E)
- REQ-phase-c-collections (dep: A; generic StatusSet preset is a prerequisite)
- REQ-phase-d-clips (dep: A; resolve offline-preview Q first)
- REQ-phase-e-ideas-promotion (dep: A, B, C, D; REUSES Phase B habit sheet)
- REQ-phase-f-polish (dep: A-E; absorbs STATUS.md pending "Next 3")
- REQ-deferred-widgets (parked, not v1 scope)

Load-bearing cross-phase dependencies (per ingest prompt):
- Phase B's shared habit-create sheet PRECEDES Phase E promote-to-habit.
- Phase C's generic StatusSet preset PRECEDES user-created collections.

## Constraints (8)
Source: Docs/SCHEMA_MIGRATION_PLAYBOOK.md + CLAUDE.md (+ SPEC §7). See intel/constraints.md.
- schema (3): CON-plan-less-migration, CON-additive-fields-only, CON-renames-via-originalName
- nfr (4): CON-mandatory-upgrade-test, CON-export-import-safety-net, CON-offline-only-v1,
  CON-design-tokens-only
- protocol (2): CON-bundle-id-frozen, CON-app-structure-and-engines

## Context topics (7)
Source: SPEC framing + STATUS.md + playbook current-state. See intel/context.md.
- Product thesis / "why"; Current shipped state (v1.0); Plan status; Seed strategy;
  Success bar / failure mode; Open questions (per-phase, not blockers); Deferred/parked.

## Conflicts
- BLOCKERS: 0
- Competing variants (WARNINGS): 0
- Auto-resolved / INFO: 3 (benign doc-reference cycle; SPEC-vs-playbook migration agreement;
  SPEC locked-intent preservation)
- Detail: /Users/gabrielnielsen/Desktop/HabitsTracker/.planning/INGEST-CONFLICTS.md

## Per-type intel files
- /Users/gabrielnielsen/Desktop/HabitsTracker/.planning/intel/decisions.md
- /Users/gabrielnielsen/Desktop/HabitsTracker/.planning/intel/requirements.md
- /Users/gabrielnielsen/Desktop/HabitsTracker/.planning/intel/constraints.md
- /Users/gabrielnielsen/Desktop/HabitsTracker/.planning/intel/context.md

## Status
READY — no blockers, no competing variants. Safe to route to gsd-roadmapper.
