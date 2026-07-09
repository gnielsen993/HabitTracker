---
phase: 04-clips-d
fixed_at: 2026-07-09T00:00:00Z
review_path: .planning/phases/04-clips-d/04-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 4: Code Review Fix Report

**Fixed at:** 2026-07-09
**Source review:** .planning/phases/04-clips-d/04-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (all Warning-severity; Info items IN-01..IN-05 intentionally out of scope)
- Fixed: 4
- Skipped: 0
- Build: `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build` exited 0, zero errors (pre-existing main-actor-isolation warnings unchanged).

## Fixed Issues

### WR-01: Status-chip toggle on ClipRow non-functional inside NavigationLink

**Files modified:** `HabitsTracker/Features/Clips/ClipRow.swift`
**Commit:** 98665c9
**Applied fix:** Replaced the chip's raw `.onTapGesture` with a `Button { … } label: { DKBadge(...) }` styled `.buttonStyle(.plain)` — a control-based tap is not swallowed by the enclosing `NavigationLink` the way a sibling gesture is. Removed the row-wide `.accessibilityElement(children: .ignore)` (which had collapsed the chip out of the a11y tree) and instead scoped `.accessibilityElement(children: .combine)` + label to the title/tag VStack only, so the chip Button remains a separately reachable element. Kept DesignKit `DKBadge` styling, the ≥44pt tap target, and `.sensoryFeedback`. Added `.accessibilityHint`. `Button` carries the `.isButton` trait implicitly, which also satisfies the ClipRow half of WR-04.
**Note:** Compiles clean. The gesture-priority behavior inside a NavigationLink (chip toggles without navigating) should be confirmed on a physical device, as the reviewer flagged — build verification cannot exercise touch routing.

### WR-02: Title-suggestion guard flag can go stale, overwriting a user-typed title

**Files modified:** `HabitsTracker/Features/Clips/ClipEditorView.swift`
**Commit:** d759888
**Applied fix:** Removed the fragile `isApplyingTitleSuggestion` `@State` (which was cleared only via `.onChange(of: title)` and went stale whenever a suggestion equalled the current title, so `.onChange` never fired). Replaced it with a `@FocusState private var titleFieldIsFocused` bound to the Title `TextField`. Manual-edit detection now keys off focus: `.onChange(of: title)` sets `titleWasManuallyEdited = true` only when the Title field is focused. The URL-driven suggestion writes `title` while the URL field is focused, so it can never flip the manual flag — the ordering race is eliminated entirely rather than patched. Preserves the intended behavior: URL entry suggests a title only until the user manually edits Title; a user-typed title is never overwritten by a later URL change; edit-mode still seeds `titleWasManuallyEdited = true`.
**Status:** fixed: requires human verification — this is a state-machine/logic change. Build passes, but the focus-timing behavior (suggest-then-manual-edit-then-URL-change sequences) is best confirmed interactively.

### WR-03: Editor "None" domain option orphans a clip out of every UI surface

**Files modified:** `HabitsTracker/Features/Clips/ClipEditorView.swift`
**Commit:** e0835d9
**Applied fix:** Removed the `Text("None").tag(UUID?.none)` row from the domain `Picker` so the editor can no longer file a clip under no domain (per UI-SPEC open item #5 — the only clip-rendering surface is `DomainDetailView`'s per-domain section, so a `domain == nil` clip is unreachable until Phase 5). Added a `guard let domain = resolvedDomain() else { … return }` in `saveClip()` (logging via `os.Logger`, no `print`) so both create and edit paths require a resolved domain before insert/mutate. `Clip.domain` stays optional at the schema level for `.nullify` on domain delete. Export/import already tolerates any pre-existing nil-domain clips — `dto.domainID.flatMap { categoryIndex[$0] }` maps a missing/nil id to `nil` without crashing — so no decode change was needed.

### WR-04: Interactive status chips not exposed as accessibility actions (§9.15)

**Files modified:** `HabitsTracker/Features/Clips/ClipDetailView.swift`
**Commit:** 8c61343
**Applied fix:** Converted the `ClipDetailView` status chip from a bare `.onTapGesture` on a `DKBadge` to a `Button { … } label: { DKBadge(...) }` with `.buttonStyle(.plain)`, preserving the badge visual, ≥44pt target, and `.sensoryFeedback`. VoiceOver now surfaces it as an activatable control with a reliable double-tap action; added `.accessibilityHint("Toggles between saved and acted")` alongside the existing status label. The ClipRow half of WR-04 was resolved by the WR-01 Button conversion.

## Skipped Issues

None — all four in-scope findings were fixed.

---

_Fixed: 2026-07-09_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
