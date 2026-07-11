---
phase: 05-ideas-promotion-e
plan: 09
subsystem: ui
tags: [swiftui, swiftdata, ideas, domain-detail, designkit]

# Dependency graph
requires:
  - phase: 05-ideas-promotion-e (05-05)
    provides: "IdeaCaptureSheet — the in-domain '+' reuses its place-first init(domain:) create mode"
  - phase: 05-ideas-promotion-e (05-07)
    provides: "IdeaRow — the reusable, data-driven idea row rendered directly (no NavigationLink) in the new section"
provides:
  - "DomainDetailView Ideas section — filed-ideas trio (buildIdeasSection/ideasSectionContent/ideasSectionHeader) appended at the reserved Phase E hook"
  - "In-domain Ideas '+' presenting IdeaCaptureSheet(domain: domain), place-first capture"
affects: [05-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Fourth domain-section trio (Rules/Collections/Clips/Ideas) in DomainDetailView, all following the same buildXSection -> XSectionContent -> XSectionHeader shape"
    - "Deliberate one-off deviation from the trio precedent: IdeaRow is rendered with NO NavigationLink/detail-view wrapper (D-08) — the only section among the four whose rows don't push a detail screen"

key-files:
  modified:
    - HabitsTracker/Features/Hub/DomainDetailView.swift

key-decisions:
  - "Ideas section filter/sort mirrors the Clips section exactly (!isArchived, createdAt descending) rather than Collections' sortIndex shape — filed ideas want recency-first ordering like Clips, not manual reordering like Collections"
  - "Kept the per-section in-domain '+' (not a unified domain-level add picker) per D-09 — the global Today capture '+' (05-05) is the app's single unifier for unfiled capture; in-domain '+' stays place-first"

patterns-established: []

requirements-completed: [IDEA-01, IDEA-03]

# Metrics
duration: ~5min
completed: 2026-07-11
---

# Phase 05 Plan 09: Ideas Section in DomainDetailView Summary

**DomainDetailView gains a fourth offshoot section — filed Ideas, rendered via the reusable IdeaRow with no detail-view wrapper (D-08) — plus an in-domain "+" that captures a new idea pre-filed under that domain (D-09).**

## Performance

- **Duration:** ~5 min
- **Completed:** 2026-07-11T13:16:13Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- `buildIdeasSection(theme:)` filters `domain.ideas.filter { !$0.isArchived }.sorted { $0.createdAt > $1.createdAt }`, returning `nil` (section hidden) when empty — the same DOM-03 "only non-empty sections" contract as Rules/Collections/Clips
- `ideasSectionContent(ideas:theme:)` renders `IdeaRow(idea:)` directly with no `NavigationLink`/detail-view wrapper — the deliberate D-08 deviation from the other three sections' trio shape, since `IdeaRow` already owns its own tap-to-edit affordance (opens `IdeaCaptureSheet(idea:)`) and inline File/Promote pills
- `ideasSectionHeader(theme:)` mirrors the Rules/Collections/Clips header exactly: "Ideas" title (`theme.typography.title`, `.isHeader` trait) + trailing "+" (`plus` glyph, `.font(.system(size: 18, weight: .semibold))`, `accentPrimary`, `≥44pt` tap target) with `accessibilityLabel("Add idea to \(domain.name)")`
- The "+" sets `creatingIdea = true`, presenting `.sheet(isPresented: $creatingIdea) { IdeaCaptureSheet(domain: domain) }` — place-first capture, no domain picker, added alongside the existing `creatingRule`/`creatingCollection`/`creatingClip` sheets
- Section registered at the reserved "Phase E: append Ideas section here" hook (former line 90), replacing the comment with `if let ideasSection = buildIdeasSection(theme: theme) { sections.append(ideasSection) }`

## Task Commits

Each task was committed atomically:

1. **Task 1: Ideas section trio + hook registration + in-domain '+'** - `f008f4d` (feat)

**Plan metadata:** (this commit, following)

## Files Created/Modified
- `HabitsTracker/Features/Hub/DomainDetailView.swift` - Added `buildIdeasSection`/`ideasSectionContent`/`ideasSectionHeader` trio, `creatingIdea` @State, `.sheet(isPresented: $creatingIdea) { IdeaCaptureSheet(domain: domain) }`, and the section registration at the Phase E hook

## Decisions Made
- Filter/sort matches the Clips section (`!isArchived` + `createdAt` descending) rather than Collections' `sortIndex` — filed ideas are recency-ordered, not manually reordered, same reasoning as Clips (04-05).
- Preserved D-09's per-section "+" pattern instead of a unified domain-level add-type picker — Today's global capture "+" (05-05) already serves as the single unfiled-capture entry point; the in-domain "+" stays place-first and consistent with Rules/Collections/Clips.

## Deviations from Plan

None - plan executed exactly as written. The one "deviation" from the trio shape (no `NavigationLink` around `IdeaRow`) was explicitly specified by the plan itself (D-08), not an executor decision.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Build clean (`xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build` exits 0, no new warnings).
- Grep-verified: `buildIdeasSection`, `id: "ideas"`, `IdeaRow(idea:` with no wrapping `NavigationLink`, `creatingIdea`, `IdeaCaptureSheet(domain: domain)`, `"Add idea to \(domain.name)"` all present in `DomainDetailView.swift`.
- A domain with filed ideas now shows all four possible offshoot sections (Rules, Collections, Clips, Ideas); a domain with zero items of any type still falls through to the shared "Nothing here yet" empty state (copy already mentions "ideas").
- Owner on-device confirmation of the full in-domain flow (Ideas section appears/hides correctly, "+" captures pre-filed under the right domain, File pill is naturally absent on these rows since `idea.domain != nil`, only Promote shows, tap-to-edit works) rides the phase-end owner check in 05-10, per this plan's success criteria — not yet exercised on a simulator/device.
- No blockers.

---
*Phase: 05-ideas-promotion-e*
*Completed: 2026-07-11*
