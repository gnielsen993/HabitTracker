---
phase: 01-domain-generalization-a
plan: 05
subsystem: hub-navigation
tags: [hub, domains, navigation, swiftui, designkit]
requires:
  - "Domain.isFocused (01-02)"
  - "accentColor(forToken:scheme:) resolver (01-03)"
  - "RootTabView 3-tab state with Hub slot marker (01-04)"
provides:
  - "HubView: focused-domain grid surface (DOM-03)"
  - "DomainTile: data-driven accent-tinted tile"
  - "DomainDetailView: non-empty-sections-only detail with empty state (DOM-03)"
  - "4-tab IA restored: Today / Hub / Progress / Settings (DOM-06)"
affects:
  - "HabitsTracker/Features/RootTabView.swift"
  - "Downstream Phases B–E plug item-type sections into DomainDetailView's section loop"
tech-stack:
  added: []
  patterns:
    - "Parent-owns-@Query, tile-is-data-driven (§9.2)"
    - "Section-loop-with-empty-fallback for DomainDetailView (DOM-03 non-empty-only contract)"
    - "Module-qualified HabitsTracker.accentColor(...) to avoid SwiftUI View.accentColor shadowing"
key-files:
  created:
    - "HabitsTracker/Features/Hub/DomainTile.swift"
    - "HabitsTracker/Features/Hub/HubView.swift"
    - "HabitsTracker/Features/Hub/DomainDetailView.swift"
  modified:
    - "HabitsTracker/Features/RootTabView.swift"
decisions:
  - "DomainDetailView renders a real sections collection loop (nonEmptySections) that yields zero sections in Phase 1, not a literal EmptyStateView — so Phases B–E append item-type sections without restructuring."
  - "Empty-state Choose Domains button routes to a labelled placeholder pending DomainFocusPicker (01-06), with an explicit TODO(01-06); the heading/body copy is present per UI-SPEC."
metrics:
  duration: 3 min
  completed: 2026-07-02
---

# Phase 1 Plan 05: Hub Surface and 4-Tab IA Summary

Built the Hub tab as an adaptive grid of focused domains (accent-tinted, data-driven tiles), added DomainDetailView as a non-empty-sections-only detail surface with a real section loop, and restored the Today / Hub / Progress / Settings 4-tab IA — completing DOM-03 and DOM-06.

## What Was Built

- **DomainTile.swift** (38 lines) — a props-only, data-driven view (`name`, `iconName`, `colorToken`, `theme`, `scheme`; no SwiftData query). Renders a `DKCard` with a centered SF Symbol tinted via `HabitsTracker.accentColor(forToken:scheme:)` and the name in `theme.typography.headline` (2-line cap, `minimumScaleFactor`). Whole tile is a ≥44pt tap target with `.accessibilityElement(children: .combine)` + label `"<name>, domain"`.
- **HubView.swift** (103 lines) — owns `@Query(filter: #Predicate<Domain> { $0.isFocused }, sort: \Domain.sortIndex)` (parent owns the query, §9.2). Inside a `NavigationStack`: an adaptive `LazyVGrid` of `DomainTile` (inter-item spacing `theme.spacing.m`, screen padding `theme.spacing.l`) where each tile is a `NavigationLink(value: domain)` pushing `DomainDetailView`; when no domains are focused, the "Your Hub is empty" state with body copy and a "Choose Domains" CTA. Background `theme.colors.background`, navigationTitle "Hub".
- **DomainDetailView.swift** (92 lines) — `let domain: Domain`, no navigation container of its own (nests under HubView's stack; single nav bar). Accent-tinted header glyph + name (`theme.typography.title`), combined-element VoiceOver. Body iterates a `nonEmptySections(theme:)` collection (a real loop rendering a `DKSectionHeader` per section) that yields **zero** sections in Phase 1, so the "Nothing here yet" empty state shows via the loop's `isEmpty` fallback — deliberately structured so Phases B–E append Rules/Collections/Clips/Ideas sections without restructuring (DOM-03 "only non-empty sections" contract).
- **RootTabView.swift** — inserted `HubView().tabItem { Label("Hub", systemImage: "square.grid.2x2") }` between Today and Progress; removed the 01-04 placeholder comment. Final order: Today, Hub, Progress, Settings (4 `tabItem`s). Kept `.tint(theme.colors.accentPrimary)`.

## Verification

- **Build:** `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' build` → **BUILD SUCCEEDED**.
- **Grep acceptance (Task 1):** `isFocused` in HubView; `accentColor` in DomainTile; "Your Hub is empty" in HubView; `DomainDetailView` referenced in HubView; no `@Query` in DomainTile — all pass.
- **Grep acceptance (Task 2):** `let domain: Domain` and "Nothing here yet" in DomainDetailView; `HubView()` in RootTabView; exactly 4 `tabItem`; no `NavigationStack` token in DomainDetailView — all pass.
- **Structure:** all new files well under the ~400-line cap (§9.1); tiles data-driven (§9.2); empty states present for both Hub and DomainDetail (§9.3); DesignKit tokens only, accent reserved for glyph/tile tint (no hard-coded colors); no `print()`.
- **Unit suite:** NOT run — recorded CoreSimulator defect (`xcodebuild test` cannot launch the XCTest host, RequestDenied by SBMainWorkspace); tracked in deferred-items.md.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `accentColor` free function shadowed by SwiftUI `View.accentColor`**
- **Found during:** Task 1/2 build.
- **Issue:** Calling `accentColor(forToken:scheme:)` inside a `View` body resolved to SwiftUI's deprecated `View.accentColor` instance method instead of the app's global resolver, failing compilation.
- **Fix:** Qualified both call sites as `HabitsTracker.accentColor(forToken:scheme:)` (per the compiler's own note). Substring "accentColor" is preserved, so the plan's grep criterion still holds.
- **Files modified:** DomainTile.swift, DomainDetailView.swift.
- **Commits:** e755e81, b41b902.

**2. [Rule 3 - Blocking] "Choose Domains" destination does not exist yet**
- **Found during:** Task 1.
- **Issue:** The empty-state CTA should route to `DomainFocusPicker`, which lands in 01-06 and does not exist at build time.
- **Fix:** As the plan explicitly permits, the button navigates to a labelled placeholder destination ("Focus picker arrives in 01-06.") with a `TODO(01-06)` comment; the heading/body copy is present per UI-SPEC so the empty state is never bare.
- **Files modified:** HubView.swift.
- **Commit:** e755e81.

## Checkpoint Status

**Task 3 (checkpoint:human-verify, gate=blocking) — PENDING owner device verification.**
Automated gates (build + grep) pass here; the XCTest host / interactive run cannot be launched on this machine (recorded CoreSimulator defect). Owner must confirm on iPhone 17:
1. Tab bar shows exactly Today, Hub, Progress, Settings.
2. Hub shows focused domains as accent-tinted tiles (distinct per-domain accents); merge-added Style/Diet/Money/Media are NOT shown until focused.
3. With no focused domains, the "Your Hub is empty" state + "Choose Domains" button appears.
4. Tapping a tile opens DomainDetailView with the accent-tinted header + "Nothing here yet" empty state under a single nav bar.
5. Today is visually unchanged.

## Known Stubs

- **DomainDetailView `nonEmptySections(theme:)` returns `[]`** (DomainDetailView.swift) — intentional per the DOM-03 contract: Phase 1 has no offshoot item types. Structured as a real section loop so Phases B–E (Rules/Collections/Clips/Ideas) append their non-empty sections without restructuring. Documented, not a blocker.
- **`focusPickerPlaceholder` in HubView** — intentional placeholder route for the "Choose Domains" CTA; `DomainFocusPicker` resolves this in 01-06 (TODO annotated).

## Self-Check: PASSED

All three created files exist on disk; both task commits (e755e81, b41b902) present in git history.
