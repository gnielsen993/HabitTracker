# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — Lifestyle Hub

**Shipped:** 2026-07-11
**Phases:** 6 (A–F) | **Plans:** 33 | **Swift LOC:** ~6,866

### What Was Built
- **Domains (A):** generalized `Category`→`Domain` via `@Attribute(originalName:)`, added the Hub tab, focus picker, and custom domains — without touching Today or existing habit data.
- **Rules (B):** reference-first `Rule` @Model + the Stem-a-habit flow (Rule→Habit copy via a shared `HabitCreateSheet`, `.nullify` link, one rule→many habits).
- **Collections (C):** `StatusSet` template model, tap-to-advance chips, fixed progress templates (`none`/`counter`/`seasonEpisode`), completionist/cost rollups, curated presets.
- **Clips (D):** offline-only saved links with tag + saved/acted status, zero-network title suggestion, filed by domain.
- **Ideas + Promotion (E):** global capture-first "+" on Today → Hub inbox → File vs Promote (Idea→anything) via a pure `PromoteService` (consume + forward-link, no backref) reusing the existing target editors.
- **Polish (F):** cross-domain search over all types, empty-state pass, full 8-type export/import round-trip at `schemaVersion 6`, accessibility fixes (VoiceOver-reachable Collections chip, Settings schema/version row).

### What Worked
- **Additive plan-less schema expansion.** Five new `@Model` types added across five phases, each an incremental `schemaVersion` bump (1→6) with optional/defaulted fields and an upgrade test — zero data-loss incidents, no `migrationPlan:` ever introduced.
- **Maximal reuse over bespoke surfaces.** Promotion reused the existing Rule/Habit/CollectionItem editors instead of a dedicated PromoteSheet; Clips/Ideas surfaces mirrored the Phase-2 Rule template exactly. Kept the codebase coherent and small.
- **Owner-device-verification pattern.** Device-only properties (VoiceOver, live SwiftData render, real export/import execution) were closed by a dedicated final owner-verification plan per phase — the right split given the toolchain constraint below.
- **Wave-based execution with worktrees disabled → sequential main-tree.** Clean, conflict-free for a solo repo.

### What Was Inefficient
- **Stale verification-status hygiene.** Phases 1–3 left `human_needed` VERIFICATION statuses (and Phase 1 "PENDING" SUMMARY checkpoints, Phase 2 a `partial` HUMAN-UAT) that were never reconciled after the owner cleared the device flows. The milestone audit had to retroactively reconcile them. Cheap to avoid: bump the phase status when the owner signs off, not two milestones later.
- **CoreSimulator/SwiftData test-runner crash cost real coverage** before it was correctly diagnosed (see §9.7). Early phases over-assumed "tests blocked," under-running the engine suites that actually pass.

### Patterns Established
- **§9.7 (CLAUDE.md):** engine/logic tests RUN and must be run; only SwiftData `@Model` persistence suites are build-verify-only on the iOS 26 sim (they crash the host at 0.000s). Execute `@Model`/round-trip tests on device.
- **Reconciliation-at-close:** when device sign-off happens via checkpoints rather than a formal UAT run, record the basis explicitly (`reconciled:`/`resolution_basis:`) rather than leaving artifacts `human_needed`/`pending`.
- **Domain as the single filing axis** for every offshoot type — the connective tissue that made typed folders a system rather than parallel silos.

### Key Lessons
1. Bump phase verification/UAT status the moment the owner clears a device checkpoint — stale `human_needed` compounds into milestone-close debt.
2. Trust the diagnosed toolchain reality (§9.7): don't claim "tests blocked" for suites that demonstrably run.
3. Additive-only, plan-less SwiftData migration with a per-phase upgrade test is a reliable path to expand a shipped schema without data loss.

### Cost Observations
- Executor/verifier model: sonnet (per config); orchestration on opus.
- Notable: worktrees disabled kept the wave model simple and conflict-free for a single-writer solo repo.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 Lifestyle Hub | 6 | 33 | First GSD milestone on a brownfield shipped app; established additive-schema + owner-device-verification patterns |

### Cumulative Quality

| Milestone | Persisted @Models | schemaVersion | Requirements |
|-----------|-------------------|---------------|--------------|
| v1.0 Lifestyle Hub | 8 (Domain/Habit/DailyEntry/HabitState/Rule/Collection/CollectionItem/Clip/Idea) | 6 | 32/32 satisfied |

### Top Lessons (Verified Across Milestones)

1. Reconcile verification/UAT status at sign-off time, not at milestone close. *(first observed v1.0)*
