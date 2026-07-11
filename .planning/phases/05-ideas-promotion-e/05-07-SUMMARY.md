---
phase: 05-ideas-promotion-e
plan: 07
subsystem: ui
tags: [swiftui, swiftdata, ideas, promote, designkit]

# Dependency graph
requires:
  - phase: 05-ideas-promotion-e (05-05)
    provides: IdeaCaptureSheet — shared title-only edit sheet the row's Row-1 tap opens
  - phase: 05-ideas-promotion-e (05-06)
    provides: HabitCreateSheet.idea(Idea)/onSaved, RuleEditorView.init(promotingIdea:), CollectionItemEditorSheet.init(promotingIdea:), PromoteToCollectionPicker — the three prefilled promote targets
provides:
  - "IdeaRow — the one reusable, data-driven idea row (§9.2, D-05) shared by InboxView (05-08) and DomainDetailView's Ideas section (05-09)"
  - "Inline File pill (domain Menu, unfiled-only) and Promote pill (type Menu, always shown) on every idea row"
affects: [05-08, 05-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Button(action:){ label }.buttonStyle(.plain) wrapping a combined-accessibility-element text block, in place of a NavigationLink, as the row's own internal tap-to-detail affordance (D-08 forbids a detail view/NavigationLink here)"
    - "Local PromoteRoute: Identifiable enum + .sheet(item:) with a switch over cases — a lightweight three-way router living entirely inside the row, no navigation-stack coupling"
    - "DKBadge-style pill recipe reimplemented inline (not the DKBadge component) so Menu labels can use radii.chip + accentPrimary/highlight per the UI-SPEC's literal token recipe"

key-files:
  created:
    - HabitsTracker/Features/Ideas/IdeaRow.swift
  modified:
    - HabitsTracker/Features/Habits/HabitCreateSheet.swift

key-decisions:
  - "IdeaRow owns its own @Query(sort: \\Domain.sortIndex) for the File menu's domain list — auxiliary picker data per §9.2's exception, not the row's core subject (still just `let idea: Idea`)"
  - "Row 1 tap-to-edit implemented as Button{...}.buttonStyle(.plain) wrapping the title/note VStack, not a bare .onTapGesture — gives VoiceOver the Button trait/double-tap affordance for free while the accessibilityElement(children:.combine) + explicit label still apply to the same block"
  - "Promote routing modeled as a local Identifiable enum (PromoteRoute: .rule/.habit/.collection) driving one .sheet(item:) rather than three separate .sheet(isPresented:) flags — avoids three mutually-exclusive Bool@States and guarantees only one promote sheet can be presented at a time"

patterns-established:
  - "Inline pill-Menu recipe (caption.weight(.semibold) on accentPrimary/highlight, radii.chip, frame(minHeight:44)+contentShape(Rectangle())) as the house shape for row-level action pills going forward"

requirements-completed: [IDEA-03, IDEA-04, IDEA-05]

# Metrics
duration: 3min
completed: 2026-07-10
---

# Phase 05 Plan 07: IdeaRow — Reusable Row + File/Promote Graduations Summary

**IdeaRow: a data-driven row (§9.2) with tap-to-edit (opens IdeaCaptureSheet), an unfiled-only File domain-Menu, and an always-on Promote Menu that routes into the three prefilled target editors from 05-06 and consumes the idea via PromoteService — the surface where the inbox actually empties.**

## Performance

- **Duration:** ~3 min
- **Completed:** 2026-07-10T21:44:31-05:00
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 edited)

## Accomplishments
- `IdeaRow` — reusable, data-driven presentational row (`let idea: Idea`, no owned query for its subject); `DKCard` surface with Row 1 (title + optional note, `.lineLimit(2)`/`.minimumScaleFactor(0.9)`) wrapped in a plain-styled `Button` opening `IdeaCaptureSheet(idea:)` in edit mode — the row's only detail affordance (D-08, no `IdeaDetailView`)
- File pill: a `Menu` of all domains (`@Query(sort: \Domain.sortIndex)`), shown only when `idea.domain == nil`; tapping a domain sets `idea.domain` + saves, keeping it an Idea (IDEA-03/SC2)
- Promote pill: always shown, a `Menu` with "Rule" / "Habit" / "Collection item" driving a local `PromoteRoute` enum + `.sheet(item:)` — routes into `RuleEditorView(promotingIdea:)`, `HabitCreateSheet(source: .idea(idea), onSaved:)`, and `PromoteToCollectionPicker(idea:)` respectively (IDEA-04/IDEA-05)
- Habit route consumes the idea in its `onSaved` closure via `PromoteService.archiveAndForwardLink(idea:as:.habit,targetID:)` + save; Rule/Collection routes self-consume inside their own editors (05-06) — no duplicate consume logic in the row
- Both pills share one inline DKBadge-style recipe (`caption.weight(.semibold)` on `accentPrimary`/`highlight`, `radii.chip`, `≥44pt`) — tokens only, no `Color(`/`accentColor(forToken`
- Accessibility: Row 1 is a combined `"{title}, idea"` element; File and Promote `Menu`s stay separately VoiceOver-reachable with their own `"File idea, choose a domain"` / `"Promote idea, choose a type"` labels

## Task Commits

Each task was committed atomically:

1. **Task 1: IdeaRow layout + tap-to-edit + File pill** - `895ae70` (feat)
2. **Task 2: Promote pill (Menu -> Rule / Habit / Collection routing)** - `3dd1531` (feat)

**Plan metadata:** (this commit, following)

## Files Created/Modified
- `HabitsTracker/Features/Ideas/IdeaRow.swift` - New reusable idea row: title/note Row 1 with tap-to-edit, File domain-Menu (unfiled only), Promote type-Menu (always shown) routing into the three prefilled promote target editors
- `HabitsTracker/Features/Habits/HabitCreateSheet.swift` - `init(source:onSaved:)` now threads the `onSaved` completion through the initializer (see Deviations)

## Decisions Made
- `IdeaRow` owns its own `@Query(sort: \Domain.sortIndex)` for the File menu — auxiliary picker data per §9.2's stated exception, not a violation of "data-driven, not data-fetching" since the row's core subject is still the passed-in `Idea`.
- Row 1 tap-to-edit uses `Button { editingIdea = true } label: { titleBlock }.buttonStyle(.plain)` rather than `.onTapGesture` — gives VoiceOver users the standard Button double-tap affordance while the `accessibilityElement(children:.combine)` + explicit label still describe the whole block as one element.
- Promote routing is one `PromoteRoute: Identifiable` enum (`.rule`/`.habit`/`.collection`) feeding a single `.sheet(item:)`, rather than three independent `Bool` flags — simpler state, and structurally guarantees at most one promote sheet is ever presented.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `HabitCreateSheet`'s custom init didn't accept `onSaved`**
- **Found during:** Task 2 (Promote pill — Habit route)
- **Issue:** 05-06 added `var onSaved: ((Habit) -> Void)? = nil` as a stored property with a default, but the struct's custom `init(source: HabitSource = .manual)` never set it. Since a custom init suppresses the memberwise init, the call site both this plan and the 05-06 SUMMARY specify — `HabitCreateSheet(source: .idea(idea), onSaved: { habit in ... })` — failed to compile with "extra argument 'onSaved' in call".
- **Fix:** Changed the init to `init(source: HabitSource = .manual, onSaved: ((Habit) -> Void)? = nil)` and assigned `self.onSaved = onSaved`. No other line in the sheet touched — chrome, fields, and every other call site (which omit `onSaved` and get the same `nil` default as before) are unaffected.
- **Files modified:** `HabitsTracker/Features/Habits/HabitCreateSheet.swift`
- **Verification:** `xcodebuild ... build` exits 0 after the fix; grep confirms `HabitCreateSheet(source: .idea(idea), onSaved:` now resolves.
- **Committed in:** `3dd1531` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary compile-fix for the exact promote-to-habit call site the plan (and 05-06's own SUMMARY) specified verbatim; no scope creep, no chrome change to `HabitCreateSheet`.

## Issues Encountered

None beyond the auto-fixed blocking issue above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `IdeaRow` is ready to be dropped into `InboxView` (05-08, every row unfiled so File always shows) and `DomainDetailView`'s Ideas section (05-09, `idea.domain != nil` so File is naturally absent, only Promote shows) with zero modification — it takes only an `Idea` value.
- All three promote routes are exercised end-to-end at the type level (build-verified): Rule and Collection self-consume in their own editors; Habit consumes via the row's `onSaved` closure.
- A promoted idea's `isArchived` flips true inside the consume call, so it automatically drops out of any `!isArchived`-filtered query (Inbox, Ideas section) with no manual list mutation needed here.
- Owner on-device confirmation of the full File/Promote flow (tap-to-edit, File a domain, Promote to each of the three targets, verify the idea vanishes from its list) rides the phase-end owner check per this plan's success criteria — not yet exercised on a simulator/device.
- No blockers.

---
*Phase: 05-ideas-promotion-e*
*Completed: 2026-07-10*
