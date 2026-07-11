---
phase: 05-ideas-promotion-e
plan: 01
subsystem: database
tags: [swiftdata, model, schema-migration, idea, domain]

# Dependency graph
requires:
  - phase: 04-clips-d
    provides: "Clip @Model leaf-model shape (isArchived/createdAt/bare domain relationship) that Idea mirrors"
provides:
  - "Idea @Model (title-only minimum, optional note/url, scalar forward-link fields)"
  - "Nested Idea.PromotedKind raw-string facade over promotedToKindRaw"
  - "Domain.ideas .nullify inverse relationship"
  - "Idea registered in the plan-less .modelContainer(for:) list"
  - "IdeaModelTests (build-verify tier) covering defaults, facade round-trip, inverse, nullify"
affects: [05-02, 05-03, 05-04, 05-06, 05-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Leaf @Model with scalar forward-link fields (no SwiftData backref) instead of an owned relationship, for Idea->anything promote consume (D-12)"
    - "Nested enum-inside-@Model-class as single source of truth for a raw-string facade (Idea.PromotedKind, mirrors Clip.status/ClipStatus)"

key-files:
  created:
    - HabitsTracker/Models/Idea.swift
    - HabitsTrackerTests/IdeaModelTests.swift
  modified:
    - HabitsTracker/Models/Domain.swift
    - HabitsTracker/HabitsTrackerApp.swift

key-decisions:
  - "PromotedKind declared NESTED inside Idea (Idea.PromotedKind) per plan's type-qualification lock — no top-level enum introduced; grep-verified"
  - "Idea is a pure leaf model with zero owned/cascade relationships; forward-link to promoted target is scalar (promotedToKindRaw/promotedToID), not a SwiftData relationship"
  - "Container stays plan-less (no migrationPlan: argument); all new Idea fields are optional or defaulted so inferred lightweight migration applies"

patterns-established:
  - "Scalar forward-link pair (raw String + UUID) for consume-and-link flows without a backref, reusable for future promote-style features"

requirements-completed: [IDEA-01]

# Metrics
duration: 8min
completed: 2026-07-11
---

# Phase 05 Plan 01: Idea Model + Domain Inverse + Container Registration Summary

**Idea @Model with nested Idea.PromotedKind raw-string facade, Domain.ideas .nullify inverse, and plan-less container registration — the schema-expansion foundation every later Phase 5 plan builds on.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-11T01:33:00Z (approx.)
- **Completed:** 2026-07-11T01:41:27Z
- **Tasks:** 2
- **Files modified:** 4 (1 new model, 1 new test file, 2 edited)

## Accomplishments
- Added the `Idea` `@Model` mirroring `Clip.swift`'s leaf shape: `@Attribute(.unique) id`, non-optional `title`, optional `note`/`url`, defaulted `isArchived`/`createdAt`, bare `@Relationship var domain: Domain?`
- Added scalar forward-link fields (`promotedToKindRaw`, `promotedToID`) plus a nested `Idea.PromotedKind` raw-string enum (`rule`/`habit`/`collectionItem`) and a computed `promotedTo` facade mirroring `Clip.status`/`ClipStatus`
- Added `Domain.ideas` as a fourth `.nullify` inverse relationship block, threaded through the memberwise init parameter list and body assignment
- Registered `Idea.self` as the last entry in the plan-less `.modelContainer(for:)` list in `HabitsTrackerApp.swift` (no `migrationPlan:` added)
- Added `IdeaModelTests` covering default values, the `promotedTo`/`promotedToKindRaw` round-trip, the `Domain.ideas` inverse, and nullify-on-domain-delete

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Idea @Model + Domain.ideas inverse + container registration** - `c5b7eb0` (feat)
2. **Task 2: IdeaModelTests (default-value + inverse + nullify + facade)** - `78aacc9` (test)

## Files Created/Modified
- `HabitsTracker/Models/Idea.swift` - New leaf `@Model` with nested `Idea.PromotedKind` facade
- `HabitsTracker/Models/Domain.swift` - Added `ideas` `.nullify` inverse relationship + init threading
- `HabitsTracker/HabitsTrackerApp.swift` - Registered `Idea.self` in the plan-less container list
- `HabitsTrackerTests/IdeaModelTests.swift` - New build-verify-tier model tests (§9.7)

## Decisions Made
- Followed the plan's locked type-qualification: `PromotedKind` is nested inside `Idea` (`Idea.PromotedKind`), never top-level. Grep-verified no top-level declaration exists.
- No owned/cascade relationships added to `Idea` — it stays a pure leaf, consistent with D-11/D-12 and the Clip precedent.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`Idea` @Model, the `Domain.ideas` inverse, and the container registration are in place and compile clean (`build` and `build-for-testing` both exit 0). This unblocks:
- 05-02+ (Ideas capture/inbox UI) which reads/writes `Idea` instances
- 05-03/05-06/05-07 (Promote flows) which reference `Idea.PromotedKind` directly
- 05-04, the mandatory upgrade-test checkpoint plan that must prove this additive schema change migrates a real Phase-4 store cleanly before this schema-expansion work is considered fully safe (per §9.12/CLAUDE.md — this plan intentionally defers that verification, consistent with the plan's stated scope)

No blockers.

---
*Phase: 05-ideas-promotion-e*
*Completed: 2026-07-11*
