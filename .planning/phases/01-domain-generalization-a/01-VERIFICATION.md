---
phase: 01-domain-generalization-a
verified: 2026-07-02T18:10:00Z
status: passed
score: 6/6 must-haves verified in code (build-green + DOM-01 store-verified); on-device visual + automated-unit sign-off owner-pending
overrides_applied: 0
reconciled: "2026-07-11 — human_verification cleared. Phase closed by owner device verification (ROADMAP complete 2026-07-02); the 06-04 owner device pass explicitly follows the same pattern that closed Phases 1/4/5 and re-confirmed the 4-tab IA + unchanged-Today invariants on the shipping build. Item 7 (CoreSimulator unit-suite defect) is superseded by CLAUDE.md §9.7 — engine/logic suites run and pass; only @Model persistence suites are build-verify-only on this toolchain."
human_verification:
  - test: "4-tab IA + Today unchanged"
    expected: "Tab bar shows exactly Today / Hub / Progress / Settings (no Calendar tab, no 5th tab); Today screen is visually identical to v1.0."
    why_human: "Visual/layout invariant — grep confirms 4 tabItems and zero Today edits, but pixel-identical Today and tab-bar appearance require a running app."
  - test: "Segmented Calendar inside Progress"
    expected: "Progress shows a Charts/Calendar segmented control (default Charts); tapping Calendar renders the month heatmap under a SINGLE nav bar (no doubled 'Calendar' title); tapping a day presents DayDetailSheet."
    why_human: "Interaction + nesting/nav-bar visual — inner NavigationStack was stripped in code, but the single-nav-bar result and sheet presentation are runtime-visual."
  - test: "Hub grid of focused domains"
    expected: "Hub shows focused domains as accent-tinted icon+color tiles (distinct per-domain accents); merge-added Style/Diet/Money/Media are NOT shown until focused; empty Hub shows 'Your Hub is empty' + working 'Choose Domains' CTA."
    why_human: "Visual rendering + real seeded data on device — @Query filter and accent resolver verified in code; tile appearance and seed presence are runtime."
  - test: "Domain detail only non-empty sections"
    expected: "Tapping a tile opens DomainDetailView with the accent-tinted header + 'Nothing here yet' empty state under a single nav bar (Phase 1 yields zero sections)."
    why_human: "Visual — the real section-loop-with-empty-fallback is verified in code; on-screen result is runtime."
  - test: "Focus toggle never deletes content"
    expected: "In Settings > Manage Domains, toggling focus ON adds a Hub tile; toggling OFF removes the tile but the domain and its habits persist; swipe-deleting a CUSTOM domain confirms 'habits won't be deleted' and a previously-filed habit survives (.nullify)."
    why_human: "Stateful behavior across store writes — flip+save and .nullify delete verified in code; end-to-end persistence/data-safety needs a live store."
  - test: "Custom domain persists and appears in catalog"
    expected: "'New Domain': 'Add Domain' stays disabled until a name is typed; pick a curated symbol + one of 5 swatches (no wheel/hex); save — the new domain appears in the catalog and (created focused) in the Hub."
    why_human: "End-to-end persistence + valid-by-construction UX — insert/save and closed inputs verified in code; catalog/Hub appearance is runtime."
  - test: "Owner-side automated unit suite (CoreSimulator defect)"
    expected: "After a machine reboot / Xcode-CoreSimulator reset, run `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:HabitsTrackerTests test` — Wave-0 tests (DomainMigration, BootstrapBackfill idempotency/previous>0/merge-add, DomainCreate, ExportImport v2 round-trip) go green."
    why_human: "Recorded ENVIRONMENT defect on this machine (XCTest host launch RequestDenied by SBMainWorkspace; 0 tests execute). Not a code failure — TEST BUILD SUCCEEDED and assertions are statically traced. Must run on a healthy CoreSimulator."
---

# Phase 1: Domain Generalization (A) Verification Report

**Phase Goal:** The app's spine becomes Domain-centric — focused domains live in a new Hub home — while Today and all existing habit data are untouched. This is the foundation every later phase files into.
**Verified:** 2026-07-02T18:10:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

Every observable truth is **satisfied in the committed code**, the app target **BUILD SUCCEEDED** on the current tree (independently re-run during this verification, not trusting SUMMARY claims), and the DOM-01 data-integrity merge gate is **store-verified PASSED** (runbook, 2026-06-29). What remains is **owner-side sign-off only** — on-device visual checkpoints and the automated unit-suite run blocked by a recorded CoreSimulator host-launch defect. Per the environment brief, that defect is NOT a code failure. Status is `human_needed` because visual/runtime items exist, not because any code truth failed.

### Observable Truths

| # | Truth (ROADMAP Success Criteria) | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Upgrade test green — existing user updates over their store, app launches, all prior habits/categories remain visible | ✓ VERIFIED | `Docs/UPGRADE_TEST_RUNBOOK.md` "DOM-01 Result — PASSED 2026-06-29": store-verified `ZCATEGORY`→`ZDOMAIN` via `@Attribute(originalName:)`, 12 domains + 20 habits + 2 daily entries survived, PID>0, no migration crash. `Domain.swift` carries all 6 prior fields + defaulted `isFocused`; container plan-less (`Domain.self`, NO `migrationPlan`); `Category.swift` deleted (single `@Model`, no duplicate); schemaVersion==2 with guard. Build green on current tree. |
| 2 | Hub tab shows focused domains as icon+color grid; tapping a tile opens DomainDetailView showing only non-empty sections | ✓ VERIFIED (code) — visual owner-pending | `HubView.swift`: `@Query(filter: #Predicate<Domain>{ $0.isFocused }, sort: \Domain.sortIndex)`, adaptive `LazyVGrid` of `DomainTile` (data-driven, no @Query), `NavigationLink(value:)`→`DomainDetailView`. `DomainDetailView.swift`: real `ForEach(nonEmptySections)` loop yielding zero sections in Phase 1 with `sections.isEmpty` fallback — NOT a hardcoded `EmptyStateView`; no own `NavigationStack`. |
| 3 | Focus picker adds/removes a Hub tile; unfocusing hides the tile but never deletes content | ✓ VERIFIED (code) — behavior owner-pending | `DomainFocusPicker.swift`: per-row `Toggle` binding flips `domain.isFocused` + `modelContext.save()` (flip-only, no delete). Custom-domain swipe-delete gated on `!isSeeded`, behind a confirmation ("Habits filed here won't be deleted"); `confirmDelete()` relies on `Domain.habits` `.nullify` inverse. Backfill (`BootstrapService.swift`) is `previous>0`-guarded + idempotent via `lastSeededVersion`; merge-add stays unfocused (pre-capture of IDs before `restoreMissingDefaults`). |
| 4 | Custom domain (name + SF Symbol + color token) persists and appears in the catalog | ✓ VERIFIED (code) — visual owner-pending | `DomainCreateSheet.swift`: inserts `Domain(name: trimmed, iconName:, colorToken:, isSeeded:false, isFocused:true)` + `save()`; "Add Domain" `.disabled(!isValid)`. `DomainIconPicker.swift`: static curated `[String]` (~31 symbols) in a `LazyVGrid`, no system browser, no third-party dep. `DomainColorSwatchRow.swift`: closed `["forest","navy","maroon","walnut","stone"]`, no `ColorPicker`/`Color(hex:)` — token valid-by-construction. |
| 5 | Today visually unchanged and tab bar stays at 4 tabs | ✓ VERIFIED (code) — visual owner-pending | `RootTabView.swift`: exactly 4 `tabItem`s — Today / Hub / Progress / Settings — no Calendar tab, no 5th. Calendar folded into `ProgressDashboardView.swift` behind `pickerStyle(.segmented)`; `CalendarMonthHeatmapView.swift` inner `NavigationStack` + `navigationTitle("Calendar")` stripped, `@retroactive Identifiable` preserved. TodayView touched only by the mechanical `Category`→`Domain` type retarget (no layout/copy change per 01-02). |

**Score:** 6/6 requirement-truths verified in code (DOM-01..DOM-06); build green; DOM-01 store-verified. All ROADMAP success criteria met at the code level.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `HabitsTracker/Models/Domain.swift` | Renamed @Model with all prior fields + isFocused + .nullify habits | ✓ VERIFIED | 39 lines; 6 carried fields (`@Attribute(originalName:)`) + `isFocused: Bool = false`; `.nullify` inverse `\Habit.category`; contract init. |
| `HabitsTracker/Models/Category.swift` | GONE (no duplicate @Model) | ✓ VERIFIED | Absent on disk; git recorded clean rename; only 4 @Models total (Domain/Habit/DailyEntry/HabitState). |
| `HabitsTracker/HabitsTrackerApp.swift` | Container lists Domain.self, plan-less | ✓ VERIFIED | `.modelContainer(for: [Domain, Habit, DailyEntry, HabitState])`; NO `migrationPlan`. |
| `HabitsTracker/Services/ExportImportService.swift` | schemaVersion==2, DomainDTO+isFocused, guard, delete(model:Domain.self) | ✓ VERIFIED | `schemaVersion = 2`; `DomainDTO` carries `isFocused`; `guard bundle.schemaVersion == 2`; `delete(model: Domain.self)`. |
| `HabitsTracker/Features/Hub/HubView.swift` | Grid of focused domains | ✓ VERIFIED | 89 lines; @Query isFocused; grid + empty state → real DomainFocusPicker. |
| `HabitsTracker/Features/Hub/DomainTile.swift` | Data-driven tile | ✓ VERIFIED | 38 lines; props-only, no @Query; accent glyph via resolver. |
| `HabitsTracker/Features/Hub/DomainDetailView.swift` | Real section loop, zero sections now | ✓ VERIFIED | 92 lines; `nonEmptySections` loop + `isEmpty` fallback; no own NavigationStack. |
| `HabitsTracker/Services/BootstrapService.swift` | Version-gated backfill, previous>0 guard, injectable defaults | ✓ VERIFIED | `init(defaults:)`; `previous < 2` gate; `previous > 0` backfill; pre-capture IDs; os.Logger. |
| `HabitsTracker/Services/SeedDataService.swift` | seedVersion 2, 16 domains (12 focused + 4 unfocused), merge-add unfocused | ✓ VERIFIED | `seedVersion = 2`; `defaultDomains()` = 12 `isFocused:true` + Style/Diet/Money/Media `isFocused:false`; `restoreMissingDefaults` name-keyed dedupe, merge-add `isFocused=false`. |
| `HabitsTracker/Features/Settings/DomainFocusPicker.swift` | Focus toggle + New hint + safe delete | ✓ VERIFIED | 163 lines; flip+save toggle; DKBadge "New" gated `isSeeded && !isFocused && seedVersion==2`; hint caption; .nullify delete. |
| `HabitsTracker/Features/Settings/DomainCreateSheet.swift` | Persists custom Domain | ✓ VERIFIED | 107 lines; gated insert/save. |
| `HabitsTracker/Features/Settings/DomainIconPicker.swift` | Curated ~30 SF Symbols, no dep | ✓ VERIFIED | 79 lines; ~31-symbol static array in LazyVGrid; no browser/dep. |
| `HabitsTracker/Features/Settings/DomainColorSwatchRow.swift` | Closed 5 accent tokens | ✓ VERIFIED | 54 lines; closed token set; no ColorPicker/hex. |
| `HabitsTracker/Utilities/AccentTokenColor.swift` | Token→Color resolver in Utilities (NOT DesignKit) | ✓ VERIFIED | 34 lines; app-level; DesignKit `PresetCatalog`-sourced; safe `.forest` fallback; no literal colors. |
| `HabitsTracker/Features/RootTabView.swift` | Exactly 4 tabs | ✓ VERIFIED | Today/Hub/Progress/Settings; no Calendar. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| HubView | Domain store | `@Query(filter: isFocused)` → grid | ✓ WIRED | Focused domains drive the grid; NavigationLink pushes detail. |
| HubView empty state | DomainFocusPicker | NavigationLink "Choose Domains" | ✓ WIRED | 01-05 placeholder removed in 01-06; routes to real picker. |
| SettingsView | DomainFocusPicker | NavigationLink "Manage Domains" | ✓ WIRED | `CategoryManagerView` link replaced. |
| DomainFocusPicker | Domain.isFocused | Toggle binding + save | ✓ WIRED | Flip persists to store; never deletes. |
| DomainCreateSheet | Domain store | insert + save | ✓ WIRED | Custom domain persists focused; picked-up by HubView @Query. |
| BootstrapService | Domain store | version-gated backfill/merge-add | ✓ WIRED | Idempotent reconciliation; upgraders' rows flipped focused once. |
| DomainTile / SwatchRow / row | accentColor resolver | `HabitsTracker.accentColor(forToken:scheme:)` | ✓ WIRED | Module-qualified to avoid `View.accentColor` shadowing; DesignKit-sourced. |
| ProgressDashboardView | CalendarMonthHeatmapView | segmented Picker + call | ✓ WIRED | Calendar folded; inner stack stripped; single nav bar. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| HubView grid | `focusedDomains` | `@Query` over SwiftData `Domain` filtered `isFocused` | Yes — real seeded/backfilled store (DOM-01 store-verified 12 domains) | ✓ FLOWING |
| DomainFocusPicker rows | `domains` | `@Query(sort: \Domain.sortIndex)` | Yes — all domains incl. merge-added | ✓ FLOWING |
| DomainDetailView sections | `nonEmptySections` | Local builder, intentionally empty in Phase 1 | Empty BY CONTRACT (DOM-03 "only non-empty"); real loop appends in Phases B–E | ✓ FLOWING (by-design empty; documented, not a stub) |
| DomainTile glyph | `colorToken` → Color | `accentColor(forToken:)` over DesignKit PresetCatalog | Yes — real DesignKit accents, safe fallback | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| App target compiles on current tree | `xcodebuild -scheme HabitsTracker -destination 'generic/platform=iOS Simulator' build` | `** BUILD SUCCEEDED **` | ✓ PASS |
| Runtime UI behavior (tabs, grid, focus, create flows) | (requires XCTest host / interactive app) | XCTest host cannot launch — recorded CoreSimulator defect | ? SKIP → routed to Human Verification |
| Automated unit suite (Wave-0) | `xcodebuild ... -only-testing:HabitsTrackerTests test` | 0 tests execute (RequestDenied by SBMainWorkspace) — ENVIRONMENT defect, not code | ? SKIP → routed to Human Verification |

### Probe Execution

Not applicable — no `scripts/*/tests/probe-*.sh` in repo; phase declares no probes. Validation contract uses XCTest + a manual upgrade runbook (DOM-01), the latter already PASSED and recorded in `Docs/UPGRADE_TEST_RUNBOOK.md`.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DOM-01 | 01-01/01-02 | Category→Domain via chosen migration path; upgrade leaves data intact | ✓ SATISFIED | Runbook PASSED 2026-06-29 (store-verified, 12/20/2 rows survived); code confirms rename path. |
| DOM-02 | 01-02 | Domain carries isFocused + all prior fields | ✓ SATISFIED | `Domain.swift` all 6 fields + `isFocused: Bool = false`. |
| DOM-03 | 01-05 | Hub tab icon+color grid; detail shows only non-empty sections | ✓ SATISFIED (code) | HubView grid + DomainDetailView real section loop. Visual owner-pending. |
| DOM-04 | 01-03/01-06 | Focus picker focus/unfocus, never deletes content | ✓ SATISFIED (code) | Toggle flip+save; backfill guarded/idempotent; .nullify delete. Automated-unit + behavior owner-pending. |
| DOM-05 | 01-06 | Create custom domain (name+SF Symbol+color token), persists in catalog | ✓ SATISFIED (code) | DomainCreateSheet + curated icon/closed-swatch pickers persist a Domain. Visual owner-pending. |
| DOM-06 | 01-04/01-05 | Today unchanged; 4-tab structure holds | ✓ SATISFIED (code) | RootTabView 4 tabs; Calendar folded into Progress; Today untouched. Visual owner-pending. |

No orphaned requirements: REQUIREMENTS.md maps only DOM-01..DOM-06 to Phase A, all claimed by phase plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| (all phase files) | — | print() | — | None found (os.Logger used in BootstrapService). |
| (all new views) | — | hard-coded Color / hex | — | None found (DesignKit tokens + resolver only). |
| (all phase files) | — | TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER | — | None found. The 01-05 `TODO(01-06)` placeholder and `focusPickerPlaceholder` were removed in 01-06 (confirmed absent). |
| `DomainDetailView.swift` | 59-63 | `nonEmptySections` returns `[]` | ℹ️ Info | Intentional per DOM-03 contract ("only non-empty sections"); structured as a real loop so Phases B–E append sections. Documented in code + SUMMARY. NOT a stub — no empty data flows to a user-facing "broken" state; the empty branch is a designed empty state (§9.3). |
| `*.pbxproj` | — | hand-edits | ℹ️ Info | Only touched in the initial commit; synchronized root groups (objectVersion 77) auto-registered new files. No §9.8 violation. |

### Human Verification Required

Seven items require owner sign-off (see YAML frontmatter for full detail). Six are on-device visual/behavioral checkpoints (4-tab IA + Today unchanged; segmented Calendar; Hub grid; domain detail; focus toggle data-safety; custom-domain creation) that grep/build cannot confirm as pixels/interactions. The seventh is the **owner-side automated unit-suite run**, blocked on this machine by a recorded CoreSimulator XCTest-host-launch defect (0 tests execute; `TEST BUILD SUCCEEDED`; assertions statically traced in the 01-03 SUMMARY) — to be run after a machine reboot / CoreSimulator reset on a healthy simulator.

**These are owner-side sign-off items, NOT phase failures.** Per the environment brief and `deferred-items.md`, the CoreSimulator defect is an environment issue (CLAUDE.md §9.7), and the app both BUILDS clean and RUNS via simctl (the DOM-01 upgrade test executed the real app, PID>0). No code gap blocks these.

### Gaps Summary

**No code gaps.** All six DOM requirements are delivered in the committed source, the app target builds green on the current tree (re-verified during this pass, not trusted from SUMMARYs), and DOM-01 — the one hard data-integrity merge gate — is store-verified PASSED. The Domain rename is loss-free, the Hub/detail/focus/create surfaces are fully wired (empty-state CTAs and the Settings entry point route to the real `DomainFocusPicker`, not placeholders), the tab bar is exactly four tabs with Calendar folded into Progress, and Today is untouched. DesignKit-token and structural rules (no print, no hard-coded colors, resolver in Utilities not DesignKit, all files < 400 lines, no pbxproj hand-edits) hold.

The only outstanding work is **owner-side sign-off**: (1) the on-device visual/behavioral checkpoints, and (2) the automated Wave-0 unit suite, which cannot run here due to a recorded CoreSimulator host-launch defect (an environment issue, not a code defect — the suite compiles and its assertions are statically traced against the committed code). Because runtime/visual verification items remain, overall status is `human_needed` rather than `passed`; no gap requires re-planning or code changes.

---

_Verified: 2026-07-02T18:10:00Z_
_Verifier: Claude (gsd-verifier)_
