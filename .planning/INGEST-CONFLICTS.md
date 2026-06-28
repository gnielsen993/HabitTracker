## Conflict Detection Report

Mode: new (net-new .planning bootstrap). Precedence: ADR > SPEC > PRD > DOC.
Ingest set: 1 SPEC (LIFESTYLE_HUB_PLAN.md), 3 DOC (CLAUDE.md, SCHEMA_MIGRATION_PLAYBOOK.md,
STATUS.md). 0 ADR, 0 PRD. All docs high-confidence with manifest type overrides.

### BLOCKERS (0)

None.

No ADR-type documents in the ingest set, so no LOCKED-vs-LOCKED contradiction is possible.
No UNKNOWN or low-confidence classifications. No reference cycle that drives a synthesis loop
(see INFO below). Nothing gates the workflow.

### WARNINGS (0)

None.

No PRD-type documents, so there are no competing acceptance-criteria variants to resolve.
The SPEC's per-phase acceptance criteria are internally consistent (each phase defines a
distinct, non-overlapping success set) and were preserved as-is in requirements.md.

### INFO (3)

[INFO] Cross-reference cycle is benign (documentation back-links, not derivation edges)
  Found: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md cross-refs
    Docs/SCHEMA_MIGRATION_PLAYBOOK.md
  Found: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md cross-refs
    Docs/LIFESTYLE_HUB_PLAN.md and CLAUDE.md (mutual "See also" links)
  Note: These are documentation back-references, not precedence/derivation edges. They do not
    cause a synthesis loop. Traversal depth well under the 50 cap. Synthesis proceeded on all
    four docs. Recorded for transparency only — no action needed.

[INFO] SPEC migration approach and DOC migration playbook agree exactly (no conflict)
  Found: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§7) requires
    additive-only changes, plan-less inferred migration, renames via @Attribute(originalName:),
    and strikes the SchemaMigrationPlan path.
  Found: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md
    (Forbidden Moves) asserts the identical rules and the same NSException crash rationale.
  Note: Checked for a SPEC-vs-DOC contradiction on the migration strategy. None found — the
    two sources are complementary and corroborating. No precedence tiebreak was needed.
    Merged into a single constraint set (CON-plan-less-migration, CON-renames-via-originalName)
    in constraints.md.

[INFO] SPEC locked decisions preserved as locked-intent (not schema-level Accepted ADRs)
  Found: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§1, §2, §8)
    carries locked product/design decisions; self-status is "planning only (not approved to
    build)" so the classifier correctly set locked=false (only Accepted ADRs are schema-locked).
  Note: Per ingest prompt, these decisions were preserved verbatim-in-intent in decisions.md as
    status "locked-intent" rather than re-derived. They cannot hard-block another decision (no
    ADR authority), but downstream planning must honor them as settled. No contradiction exists
    between any two of them.
