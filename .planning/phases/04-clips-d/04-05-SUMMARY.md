---
phase: 04-clips-d
plan: 05
subsystem: ui
tags: [swiftui, designkit, nav-template, clips, domain-detail]

# Dependency graph
requires:
  - phase: 04-clips-d (plan 01)
    provides: Clip @Model, ClipStatus enum, Domain.clips .nullify inverse
  - phase: 04-clips-d (plan 03)
    provides: ClipEditorView(domain:)/(clip:), ClipRow(clip:), ClipDetailView(clip:)
provides:
  - Clips section wired into DomainDetailView.nonEmptySections (CLIP-03) — clips are now reachable, filed by domain
  - creatingClip sheet presenting ClipEditorView(domain:) from the section header "+"
  - buildClipsSection/clipsSectionContent/clipsSectionHeader trio (Rules-shape isArchived filter + createdAt-descending sort, D-10)
affects: [05-ideas (reuses the same domain-section append template), rc-uat (owner device verification gate)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Third domain-section trio (Clips) appended at the reserved Phase D-E hook without restructuring the Phase 1 non-empty-sections loop — confirms the append-a-section template scales to N leaf types (Ideas next)"
    - "buildClipsSection uses the Rules isArchived+createdAt-descending shape (NOT the Collections sortIndex shape) because Clip carries a soft-archive flag and wants recency-first ordering"

key-files:
  created: []
  modified:
    - HabitsTracker/Features/Hub/DomainDetailView.swift

key-decisions:
  - "Mirrored the buildRulesSection shape (isArchived filter + createdAt-descending) rather than buildCollectionsSection (sortIndex, no archive filter) — Clips has a soft-archive flag and a recency-first 'did I save this?' ordering goal (D-10, UI-SPEC S1)"
  - "No Clips-specific empty state — the shared domain-level empty state already name-checks 'clips' and the section simply falls through when empty (§9.3, DOM-03)"
  - "Kept the Clips trio inline in DomainDetailView (file at 279 lines, well under the ~400-line cap) — no extension-file split needed (§9.1)"

patterns-established:
  - "The three-domain-section-trio DomainDetailView (Rules + Collections + Clips) is now the proven, uniform nav template for domain-filed leaf types — Ideas (Phase 5) appends a fourth trio at the reserved hook the same way"

requirements-completed: [CLIP-03]

# Metrics
duration: ~10min
completed: 2026-07-09
---

# Phase 04 Plan 05: Wire Clips into DomainDetailView Summary

**A Clips section appended to `DomainDetailView` — reachable "+" → `ClipEditorView(domain:)` create, non-archived clips listed recency-first, each row pushing `ClipDetailView` — mirroring the locked Rules/Collections nav template exactly and rendering only when the domain has clips (D-10, CLIP-03).**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-07-09
- **Tasks:** 1 of 2 executed as code (Task 2 is a DEFERRED owner-verification checkpoint — see below)
- **Files modified:** 1

## Accomplishments

- Added `@State private var creatingClip = false` beside the existing `creatingRule`/`creatingCollection` state, plus a `.sheet(isPresented: $creatingClip) { ClipEditorView(domain: domain) }` beside the existing Rules/Collections sheets.
- Appended `if let clipsSection = buildClipsSection(theme: theme) { sections.append(clipsSection) }` at the reserved `// Phase D–E: append Clips / Ideas sections here.` hook in `nonEmptySections(theme:)`, preserving the DOM-03 "only non-empty sections" contract.
- Added the `buildClipsSection` / `clipsSectionContent` / `clipsSectionHeader` trio — `buildClipsSection` filters `domain.clips` on `!$0.isArchived`, sorts by `createdAt` descending, and `guard !activeClips.isEmpty else { return nil }` (D-10, the Rules isArchived-filter shape, NOT the Collections sortIndex shape). Rows are `NavigationLink { ClipDetailView(clip:) } label: { ClipRow(clip:) }.buttonStyle(.plain)`; the header carries the "Clips" title (`.accessibilityAddTraits(.isHeader)`) + a ≥44pt `accentPrimary` "+" button with `accessibilityLabel("Add clip to \(domain.name)")`.
- Rules/Collections sections and their trios are untouched (both `buildRulesSection`/`buildCollectionsSection` still present); DesignKit-token-only (zero `Color(hex:)`/`Color(red:)`); file at 279 lines, under the ~400-line cap (§9.1) — no extension split needed.

## Task Commits

Each task was committed atomically:

1. **Task 1: Append the Clips section to DomainDetailView (buildClipsSection trio + creatingClip sheet)** - `7c9d811` (feat)
2. **Task 2: Owner visual verification — full Clips flow, export/import round-trip, offline gate (device)** - DEFERRED owner-verification checkpoint, NOT executed (see below)

**Plan metadata:** committed with this SUMMARY + STATE + ROADMAP (docs commit).

## Files Created/Modified

- `HabitsTracker/Features/Hub/DomainDetailView.swift` - added the Clips section trio + `creatingClip` sheet (63 insertions, 1 deletion)

## Decisions Made

- Used the `buildRulesSection` shape (`.filter { !$0.isArchived }` + `.sorted { $0.createdAt > $1.createdAt }`) rather than the Collections `sortIndex` shape — Clip carries a soft-archive flag and wants recency-first ordering (D-10, UI-SPEC S1).
- No Clips-specific empty state — the shared domain-level empty state already covers "clips" and the section falls through when empty (§9.3, DOM-03).
- Kept the trio inline (file at 279 lines) — no `DomainDetailView+Clips.swift` extraction needed (§9.1).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Build (`xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build`) exits 0. All grep-based acceptance criteria satisfied.

## Deferred Owner-Verification Checkpoint (Task 2)

**Task 2 is a BLOCKING owner visual-verification checkpoint that CANNOT be executed here** — XCTest cannot launch the UI host on this toolchain (§9.7 CoreSimulator SwiftData `@Model` / UI-launch blocker), and the export/import round-trip + the offline gate (SC1/D-01) can only be truly confirmed by a human on device. It is persisted as a HUMAN-UAT item and remains a **PENDING owner gate**. The exact verification steps (carry into the UAT file):

Build + run on iPhone 17 (bundle id `lauterstar.HabitsTracker`):

1. Focus a domain (Hub → focus picker) and open its DomainDetailView. Confirm NO Clips section shows with zero clips (DOM-03).
2. Tap the domain's add affordance → `ClipEditorView` opens pre-scoped to the domain. Paste a URL (e.g. `https://www.nytimes.com/2026/01/how-to-make-sourdough`); confirm the Title field auto-suggests (D-02), then type your own Title and confirm the URL no longer overwrites it. Add a note + tag. Confirm "Add Clip" is disabled until Title and URL are both non-empty. Save.
3. Confirm a Clips section now appears with the new row: title, tag caption, "Saved" status chip.
4. Tap the status chip on the row → flips to "Acted" with a haptic; tap again → back to "Saved" (D-05).
5. Tap the row → `ClipDetailView`: confirm the full-width "Open Link" primary CTA, status chip (tap-toggles), tag pill, note block. Tap "Open Link" → Safari opens the URL. Tap "Edit" → editor reopens prefilled; test "Delete Clip" → confirm "Delete this clip?" / "This can't be undone." dialog; cancel (keep the clip).
6. OFFLINE GATE (SC1/D-01): turn on Airplane Mode. Create a new clip and open its link — confirm it works fully offline with NO spinner/preview/thumbnail ever appearing (no network fetch, ever). Turn Airplane Mode off.
7. EXPORT/IMPORT (RC smoke §6, D-13): Settings → export a backup (confirm success). Delete the clip(s) or erase+reinstall. Import the backup → confirm the clip returns with title, url, note, tag, and status intact, still filed under the right domain.
8. Accessibility spot-check: VoiceOver reads the row as "\(title), status: \(statusLabel)[, tag: ...]"; Dynamic Type at a large size does not clip the layout (title caps at 2 lines).

Expected: every step passes; Today is unchanged; the 4-tab structure holds. Report any visual/interaction deviation from `04-UI-SPEC.md`.

**Resume signal:** owner types "approved" once the full Clips flow, the offline gate, and the export/import round-trip are confirmed on device, or describes what deviated.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The Clips section is fully wired to `domain.clips` (live SwiftData relationship) — no hardcoded/empty data path. Clips created via the "+" persist and appear in the section; the row/detail/editor surfaces (04-03) are now reachable end-to-end.

## Threat Flags

None beyond the plan's own `<threat_model>` (T-04-10 offline-gate and T-04-11 archived-clip-leak — both mitigated as designed: `buildClipsSection` filters `!$0.isArchived` + `guard !activeClips.isEmpty else { return nil }`; the "Open Link" surface remains a Safari handoff with zero network APIs in `Features/Clips/`). The offline gate (T-04-10) is confirmed at the code level (grep-verified zero network APIs in 04-03) and awaits the owner's on-device Airplane-Mode confirmation (Task 2).

## Next Phase Readiness

- Clips are now reachable and filed by domain — CLIP-03's "found in that domain's Clips section" is satisfied at the code level.
- `DomainDetailView` now carries three domain-section trios (Rules + Collections + Clips) — the uniform template Phase 5 (Ideas) appends its fourth trio to at the reserved hook.
- **Two PENDING owner-verification checkpoints remain open** (both device-only per §9.7, do not block subsequent planning but gate the milestone RC):
  - CLIP-01 upgrade test (04-01 Task 3) — Clip `@Model` schema-expansion vs a Phase-3 store.
  - CLIP-03 full-flow visual verification (04-05 Task 2, this plan) — create → toggle → open link → edit → delete-confirm → offline gate → export/import round-trip.

---
*Phase: 04-clips-d*
*Completed: 2026-07-09*

## Self-Check: PASSED

- FOUND: HabitsTracker/Features/Hub/DomainDetailView.swift (Clips trio + creatingClip sheet)
- FOUND commit: 7c9d811 (Task 1)
- Build exits 0; grep acceptance criteria satisfied (creatingClip, buildClipsSection, DomainSection(id: "clips"), ClipDetailView(clip:), ClipRow(clip:), "Add clip to \(domain.name)", !$0.isArchived + createdAt-descending)
- Task 2 recorded as a DEFERRED owner-verification checkpoint (PENDING), not a failure
