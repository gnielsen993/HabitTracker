---
phase: 01-domain-generalization-a
plan: 06
subsystem: domain-management
tags: [domains, focus-picker, custom-domain, settings, swiftui, designkit]
requires:
  - "Domain @Model with isFocused / isSeeded / seedVersion / colorToken (01-02)"
  - "accentColor(forToken:scheme:) resolver (01-03)"
  - "SeedDataService merge-add of Style/Diet/Money/Media unfocused at seedVersion 2 (01-03)"
  - "HubView empty-state Choose Domains CTA placeholder (01-05)"
provides:
  - "DomainFocusPicker: catalog with per-row focus toggle + New hint + safe custom-domain delete (DOM-04, D-10)"
  - "DomainCreateSheet: gated custom-domain creation persisting name+icon+token (DOM-05)"
  - "DomainIconPicker: curated ~30 SF Symbol grid (D-16)"
  - "DomainColorSwatchRow: closed 5-accent-token swatch row (D-17)"
affects:
  - "HabitsTracker/Features/Settings/SettingsView.swift (Manage Categories -> Manage Domains)"
  - "HabitsTracker/Features/Hub/HubView.swift (Choose Domains now opens the real picker)"
tech-stack:
  added: []
  patterns:
    - "Data-driven pickers (binding + theme, no @Query) — §9.2"
    - "Valid-by-construction inputs: closed curated icon set + closed 5-token swatch row (no free glyph/hex)"
    - "Module-qualified HabitsTracker.accentColor(...) to avoid SwiftUI View.accentColor shadowing"
    - "Non-destructive focus toggle: isFocused flip + save; .nullify delete preserves habits"
key-files:
  created:
    - "HabitsTracker/Features/Settings/DomainIconPicker.swift"
    - "HabitsTracker/Features/Settings/DomainColorSwatchRow.swift"
    - "HabitsTracker/Features/Settings/DomainCreateSheet.swift"
    - "HabitsTracker/Features/Settings/DomainFocusPicker.swift"
  modified:
    - "HabitsTracker/Features/Settings/SettingsView.swift"
    - "HabitsTracker/Features/Hub/HubView.swift"
decisions:
  - "New-domain hint uses a per-row DKBadge \"New\" plus a single caption header (UI-SPEC S3 badge-over-banner restraint), gated on isSeeded && !isFocused && seedVersion == 2."
  - "Custom domains are created isFocused: true (a deliberately created domain belongs in the Hub) and isSeeded: false; sortIndex = max existing + 1."
  - "Curated icon set finalized at 31 symbols (16 seeded glyphs + 15 lifestyle additions incl. the neutral square.grid.2x2 default)."
  - "Swipe-delete is offered for custom (non-seeded) domains only; seeded domains are unfocused (hidden), never deletable, matching the no-data-loss posture."
metrics:
  duration: 8 min
  completed: 2026-07-02
---

# Phase 1 Plan 06: Domain Focus Picker and Custom-Domain Creation Summary

Built the domain focus picker (per-row `isFocused` toggle that never deletes content, plus a "New" badge + hint for merge-added domains) and custom-domain creation (a gated name field + a curated ~30 SF Symbol grid + a closed 5-accent-token swatch row), and wired both into Settings and the Hub empty state — completing DOM-04 and DOM-05 and closing out Phase 1.

## What Was Built

- **DomainIconPicker.swift** (79 lines) — data-driven (`@Binding selection` + `theme`, no query). A static `curatedSymbols: [String]` of 31 lifestyle-relevant SF Symbols (the 16 seeded domain glyphs plus 15 hand-picked additions, ending with the neutral `square.grid.2x2` default) rendered in a `LazyVGrid` (cell gap `theme.spacing.m`). Each cell is a ≥44pt `Button` (`.frame(minWidth: 44, minHeight: 44)`); the selected cell is backed by `theme.colors.fillSelected` with an `accentPrimary` ring. VoiceOver labels the humanized symbol name + `.isSelected`. No system symbol browser, no third-party dependency (D-16).
- **DomainColorSwatchRow.swift** (54 lines) — data-driven. A horizontal `HStack` (gap `theme.spacing.s`) over the closed `tokens: ["forest","navy","maroon","walnut","stone"]`, each a ≥44pt circular `Button` filled via `HabitsTracker.accentColor(forToken:scheme:)`; the selected swatch carries an `accentPrimary` ring (D-17). VoiceOver labels the capitalized token name + `.isSelected`. No `ColorPicker`, no `Color(hex:)` — `colorToken` is valid-by-construction.
- **DomainCreateSheet.swift** (107 lines) — a `NavigationStack` `Form` sheet with three inputs: a Name `TextField` (trim + 40-char length guard mirroring CategoryManagerView), `DomainIconPicker`, and `DomainColorSwatchRow`. The "Add Domain" confirmation button is `.disabled(!isValid)` until the trimmed name is non-empty, with the inline validation copy "Give this domain a name to continue." On save it inserts `Domain(name: trimmed, iconName:, colorToken:, sortIndex: max+1, isSeeded: false, isFocused: true)` + `try? modelContext.save()` and dismisses (DOM-05). Entry-point title "New Domain", CTA "Add Domain".
- **DomainFocusPicker.swift** (163 lines) — owns `@Query(sort: \Domain.sortIndex)`. Each row: accent-tinted glyph + name (`theme.typography.headline`) + a system `Toggle` bound to `isFocused` (flips + saves on change; NEVER deletes — unfocus only hides the Hub tile, DOM-04). Rows where `isSeeded && !isFocused && seedVersion == 2` show an inline `DKBadge("New")`; when any exist, a caption header surfaces "New domains are available — focus any to add it to your Hub." (D-10). Custom (non-seeded) domains get a trailing swipe-delete behind a `confirmationDialog` reading "Delete '<name>'? Habits filed here won't be deleted — they'll just lose this domain." (Delete destructive / Cancel), relying on the `.nullify` rule so habits survive. A "New Domain" toolbar button presents `DomainCreateSheet`; an empty state covers zero domains (§9.3). navigationTitle "Domains".
- **SettingsView.swift** — the Management section link `Manage Categories → CategoryManagerView()` replaced with `Manage Domains → DomainFocusPicker()`; Appearance/Backup/Restore left untouched.
- **HubView.swift** — the 01-05 `TODO(01-06)` empty-state placeholder removed; the "Choose Domains" CTA now pushes the real `DomainFocusPicker()`, and the `focusPickerPlaceholder` helper was deleted.

## Verification

- **Build:** `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' build` → **BUILD SUCCEEDED**.
- **Grep acceptance (Task 1):** `LazyVGrid` + `curatedSymbols` in DomainIconPicker; `accentColor` + `forest` + `stone` in DomainColorSwatchRow; no `ColorPicker`/`Color(hex` in DomainColorSwatchRow — all pass.
- **Grep acceptance (Task 2):** `DomainFocusPicker` in SettingsView; "Add Domain" in DomainCreateSheet; `isFocused` + "New domains are available" + "won't be deleted" in DomainFocusPicker — all pass.
- **Structure:** all four new files under the ~400-line cap (§9.1, largest is 163); pickers data-driven (§9.2); focus-picker + create-sheet empty/validation states present (§9.3); DesignKit tokens only, accent reserved to glyph/selected-ring/swatch (no hard-coded colors); no `print()`.
- **Unit suite:** NOT run — recorded CoreSimulator defect (`xcodebuild test` cannot launch the XCTest host, RequestDenied by SBMainWorkspace); tracked in deferred-items.md.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `accentColor` free function shadowed by SwiftUI `View.accentColor`**
- **Found during:** Task 2 build (BUILD FAILED — "use of 'accentColor' refers to instance method rather than global function").
- **Issue:** Calling the app's global `accentColor(forToken:scheme:)` inside a `View` body resolved to SwiftUI's deprecated `View.accentColor` instance method (the same shadowing hit in 01-05).
- **Fix:** Qualified both call sites as `HabitsTracker.accentColor(forToken:scheme:)` (per the compiler's own note). Substring "accentColor" is preserved, so the plan's grep criterion still holds.
- **Files modified:** DomainColorSwatchRow.swift, DomainFocusPicker.swift.
- **Commit:** b45a55d.

Otherwise the plan executed as written.

## Checkpoint Status

**Task 3 (checkpoint:human-verify, gate=blocking) — PENDING owner device verification.**
Automated gates (build + grep) pass here; the interactive XCTest host / app run cannot be launched on this machine (recorded CoreSimulator defect). Owner must confirm on iPhone 17, in Settings > Manage Domains:
1. Toggling a domain's focus ON adds its Hub tile; toggling OFF removes the tile but the domain (and its habits) still exist in the picker — no data deleted (DOM-04).
2. Merge-added domains (Style/Diet/Money/Media) show a "New" badge + the hint caption; focusing one adds its Hub tile.
3. "New Domain": "Add Domain" stays disabled until a name is typed; pick a curated symbol and one of the 5 swatches (no wheel/hex); save — the new domain appears in the catalog and (created focused) in the Hub (DOM-05).
4. Swipe-delete a custom domain: the confirmation states habits won't be deleted; confirm and verify a habit previously filed under it survives (`.nullify`).

## Known Stubs

None. Both surfaces are fully wired: the focus toggle persists to the store, custom domains persist and appear in the Hub `@Query`, and the Hub/Settings entry points open the real picker.

## Self-Check: PASSED

All four created files exist on disk (DomainIconPicker, DomainColorSwatchRow, DomainCreateSheet, DomainFocusPicker); both task commits (f5a9b84, b45a55d) present in git history; BUILD SUCCEEDED on iPhone 17.
