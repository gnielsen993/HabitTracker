---
phase: 01-domain-generalization-a
plan: 04
subsystem: navigation-ia
tags: [swiftui, tab-bar, progress, calendar, segmented-control]
requires:
  - CalendarMonthHeatmapView (existing)
  - DayDetailSheet (existing)
  - ProgressDashboardView (existing)
provides:
  - "Progress Charts ⇄ Calendar segmented control hosting the folded month heatmap"
  - "3-tab bar (Today / Progress / Settings) with a freed slot for the Hub tab (01-05)"
affects:
  - HabitsTracker/Features/RootTabView.swift
  - HabitsTracker/Features/Progress/ProgressDashboardView.swift
  - HabitsTracker/Features/Calendar/CalendarMonthHeatmapView.swift
tech-stack:
  added: []
  patterns:
    - "Two-stack nesting avoided: Progress owns the single NavigationStack; folded calendar view strips its own stack (D-14, Research Pitfall 4)"
    - "@ViewBuilder computed sub-view (chartsBody) to keep the container body small under the ~400-line cap (§9.1)"
key-files:
  created: []
  modified:
    - HabitsTracker/Features/Progress/ProgressDashboardView.swift
    - HabitsTracker/Features/Calendar/CalendarMonthHeatmapView.swift
    - HabitsTracker/Features/RootTabView.swift
decisions:
  - "Extracted the charts content into a private @ViewBuilder chartsBody(theme:) rather than a separate file — smallest change, keeps the view well under the 400-line cap."
  - "Kept the segmented Picker at system tint (no accent) per D-13/UI-SPEC S5 so the 5 domain accents stay reserved for domain identity."
metrics:
  duration: 2 min
  tasks_completed: 2
  files_modified: 3
  completed: 2026-07-02
requirements: [DOM-06]
---

# Phase 1 Plan 04: Tab Recomposition — Fold Calendar into Progress Summary

Removed the Calendar top-level tab and folded `CalendarMonthHeatmapView` (+ its `DayDetailSheet`) into `ProgressDashboardView` behind a `Charts ⇄ Calendar` segmented `Picker`, freeing a tab slot for the Hub while preserving calendar density and leaving Today untouched (DOM-06, partial).

## What Was Built

**Task 1 — Fold calendar into Progress behind a segmented control** (`26f24ed`)
- `CalendarMonthHeatmapView.swift`: stripped the wrapping `NavigationStack` and `.navigationTitle("Calendar")` so the view nests under Progress's single stack (D-14). The bare `VStack` retains its `.background(theme.colors.background.ignoresSafeArea())` and the `.sheet(item: $selectedDay) { DayDetailSheet(date:) }` (re-anchored directly on the VStack — sheets present from anywhere in the hierarchy, Research Pitfall 4). The `extension Date: @retroactive Identifiable` was preserved (required for `.sheet(item:)`). Month nav buttons, `LazyVGrid`, and `DayCell` are unchanged.
- `ProgressDashboardView.swift`: added a private `ProgressTab { charts, calendar }` enum, `@State private var progressTab: ProgressTab = .charts`, and a top-of-stack `Picker("", selection:).pickerStyle(.segmented)` with Charts/Calendar segments (`.padding(.horizontal, theme.spacing.l)`, system tint). A `switch` renders `chartsBody(theme:)` (a new `@ViewBuilder` holding the existing chart blocks) or `CalendarMonthHeatmapView()`. Progress keeps its single `NavigationStack` with `.navigationTitle("Progress")`. Default selection: Charts.

**Task 2 — Remove the Calendar tab from RootTabView** (`4ca634a`)
- Dropped the `CalendarMonthHeatmapView().tabItem { Label("Calendar", ...) }` entry. The `TabView` now holds exactly three `tabItem`s — Today, Progress, Settings — with `.tint(theme.colors.accentPrimary)` retained. A comment marks the slot where plan 01-05 inserts the Hub tab to reach the final 4-tab Today/Hub/Progress/Settings IA (D-12).

## Verification

Per the recorded owner-side CoreSimulator blocker, the XCTest host cannot launch on this machine, so verification is build-success + the plan's grep acceptance criteria (correct for a pure-SwiftUI, no-schema, no-engine plan):

- `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' build` → **BUILD SUCCEEDED** (after each task).
- Task 1 greps: `pickerStyle(.segmented)` present, `CalendarMonthHeatmapView()` present, `@retroactive Identifiable` present, `navigationTitle("Calendar")` absent → PASS.
- Task 2 greps: no `Label("Calendar"...)`, exactly 3 `tabItem` occurrences, `.tint(theme.colors.accentPrimary)` retained → PASS.

## Deviations from Plan

None — plan executed exactly as written. (The charts content was extracted into a `@ViewBuilder chartsBody(theme:)` computed helper, which the plan explicitly permitted as "a `chartsBody` computed view or @ViewBuilder".)

## Known Stubs

None. The folded calendar is fully wired to the existing `@Query` habit/entry data; no placeholder values or empty data sources were introduced.

## Deferred / Pending

- **Task 3 (checkpoint:human-verify, gate="blocking") — PENDING owner verification.** Machine-side verification (build + grep) is complete; the remaining device-visual confirmation requires launching on a simulator on the owner's side (XCTest host cannot launch here — recorded blocker). Owner to confirm on iPhone 17: (1) tab bar shows Today/Progress/Settings with no Calendar tab; (2) Progress shows a Charts/Calendar segmented control (default Charts) and tapping Calendar renders the heatmap with a single nav bar (no doubled "Calendar" title); (3) tapping a day presents `DayDetailSheet`; (4) Today is visually unchanged.

Note: after this plan the tab bar is intentionally 3 tabs (Today/Progress/Settings). Plan 01-05 restores the 4th (Hub) — the final 4-tab DOM-06 assertion completes there.

## Self-Check: PASSED

- FOUND: `.planning/phases/01-domain-generalization-a/01-04-SUMMARY.md`
- FOUND commit `26f24ed` (Task 1)
- FOUND commit `4ca634a` (Task 2)
