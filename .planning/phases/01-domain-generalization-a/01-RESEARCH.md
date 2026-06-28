# Phase 1: Domain Generalization (A) - Research

**Researched:** 2026-06-28
**Domain:** SwiftData entity rename (`Category`→`Domain`) under plan-less inferred migration; SwiftUI tab/NavigationStack recomposition; additive defaulted field + idempotent version-gated backfill; curated-grid creation UX in a DesignKit-tokens-only app.
**Confidence:** MEDIUM-HIGH (mechanics of locked decisions verified against the live codebase; the one genuine unknown — *entity-class* rename behavior under inferred migration — is flagged LOW and is exactly what the mandatory upgrade test exists to catch.)

## Summary

Phase A is a generalization, not a rewrite. The live `@Model class Category` (id, name, iconName, colorToken, sortIndex, isSeeded, seedVersion, `habits` inverse) is renamed to `Domain`, gains `var isFocused: Bool = false`, and every one of the ~10 reference sites is updated. The container in `HabitsTrackerApp.swift` is and stays **plan-less** (`.modelContainer(for:[...])`, no `migrationPlan:`). The whole rename is gated by the mandatory upgrade test in `Docs/SCHEMA_MIGRATION_PLAYBOOK.md`, run on `iPhone 17`, bundle `gn.HabitsTracker`.

The single non-obvious technical risk is that `@Attribute(originalName:)` is documented and verified only for **property** renames — it does **not** rename the *entity/table*. Whether SwiftData's inferred lightweight migration silently preserves rows when the `@Model` *class* name changes (Core Data historically keys the store table by entity name, which is derived from the class name) is **not** confirmed by any authoritative source I could reach. The playbook's posture — try the `@Attribute(originalName:)` recipe, then hard-gate on the upgrade test, with Export/Import JSON as the always-available safety net — is the correct way to manage that uncertainty. The planner must treat "upgrade test green" as a literal merge gate, not a checkbox.

Two adjacent facts surfaced from the live code that shape the plan: (1) `restoreMissingDefaults` exists but is **only wired to a Settings "Restore Defaults" button** — it does **not** run at bootstrap today, so the D-08 merge-add and D-07 focus-backfill must be deliberately invoked in `BootstrapService`, gated on a **newly added** persisted `seedVersion` marker (none exists today — `SeedDataService.seedVersion` is a hardcoded constant, and nothing persists "what version did we last seed"). (2) **No `colorToken`-string → `Color` resolver exists anywhere** — categories currently render with a uniform `theme.colors.accentPrimary`. The Hub grid (DOM-03) and the 5-swatch row (D-17) both require a small new token→Color mapping that must be built (and confined to the 5 accent tokens).

**Primary recommendation:** Rename `Category`→`Domain` via `@Attribute(originalName:)` on the renamed *properties* + the class rename, keep it plan-less, add `isFocused: Bool = false`, and make the upgrade test the literal merge gate. Add a persisted `lastSeededVersion` marker (UserDefaults/AppStorage) to drive the once-only focus backfill and the merge-add — because the codebase has no seed-version persistence today. Build one small `accentColor(forToken:)` resolver constrained to the 5 tokens; reuse it for both the Hub grid and the swatch row.

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Real rename of `@Model class Category` → `Domain` using `@Attribute(originalName: "Category")` where needed, kept **plan-less** (no `migrationPlan:`, no `SchemaMigrationPlan`). Rationale: pre-launch, ~10 references today, all 5 later phases add more (`Rule.domain`, `Collection.domain`, …).
- **D-02:** Rename is gated by the **mandatory upgrade test** as a hard merge gate.
- **D-03:** Bump `ExportImportService.schemaVersion` 1→2 in the **same change**; keep export/import round-trip green.
- **D-04:** Update the container type list in `HabitsTrackerApp.swift` and all referencing files (incl. `Habit.category`, seeding, views) to `Domain`.
- **D-05:** Add `isFocused: Bool` as **additive, defaulted** (default `false`).
- **D-06:** Bump `SeedDataService.seedVersion` 1→2.
- **D-07:** **One-time, version-gated focus backfill** (gated on prior `seedVersion < 2`, runs once in `BootstrapService`): flip every **pre-existing** Domain to `isFocused = true`.
- **D-08:** **New** hub seed domains (Style, Diet, Money, Media) **merge-added** via existing name-keyed `restoreMissingDefaults` path as `isFocused = false`; existing "Social" dedupes by name.
- **D-09:** **Fresh installs** seed the opinionated subset **pre-focused**.
- **D-10:** Pair merge-add with a **subtle "new domains available in the focus picker" hint**.
- **D-11:** Never destroy user data — merge-add only. Focus backfill must be idempotent (seedVersion gate guarantees once-only).
- **D-12:** Target IA is **Today / Hub / Progress / Settings** (4 tabs). **Calendar tab removed** to free the slot for Hub.
- **D-13:** Calendar surfaces **inside Progress via a segmented control** (`Picker(...).pickerStyle(.segmented)`, Charts ⇄ Calendar).
- **D-14:** Reuse `CalendarMonthHeatmapView` + `DayDetailSheet` near-verbatim; required edit is **removing the view's own `NavigationStack`/`navigationTitle("Calendar")`** so it nests under Progress's stack, re-anchoring the `selectedDay` sheet there.
- **D-15:** **Today stays visually unchanged.**
- **D-16:** Icon picker = curated grid of ~30 hand-picked SF Symbols (no full system browser, no third-party dep). `DomainIconPicker` sheet, static `[String]` in a `LazyVGrid`.
- **D-17:** Color = closed pick-one-of-5 accent tokens (forest, navy, maroon/oxblood, walnut, stone) as a horizontal swatch row with a selected ring. `colorToken` valid-by-construction.

### Claude's Discretion
- The exact ~30-symbol curated icon set (lifestyle-relevant SF Symbols consistent with the seeded ones).
- The precise visual treatment of the "new domains available" hint (badge vs banner) and the Hub grid tile layout, within DesignKit tokens.
- Internal structure/naming of new views (HubView, DomainDetailView, DomainFocusPicker), so long as §9.1 (~400-line cap) and §9.2 (data-driven reusable views) hold.

### Deferred Ideas (OUT OF SCOPE)
- New hub seed **domains' content** (Rules/Collections starter items for Style, Money, Media, etc.) — lands with Phases B/C. Phase 1 adds **only the domains + focus**, not offshoot content.
- Q5 product naming (keep "HabitTracker" vs rename) — not this phase.
- Cross-domain tagging (Q4) — after Phase F.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOM-01 | `Category` generalized to `Domain` via plan-less migration; upgrade leaves habits/categories intact | "Category→Domain Migration Mechanics" + "Runtime State Inventory" + upgrade-test gate (D-01/D-02) |
| DOM-02 | Each Domain carries `isFocused: Bool` (additive, defaulted) plus existing fields | "isFocused Field & Backfill" — `var isFocused: Bool = false`, playbook-compliant additive change |
| DOM-03 | Hub tab shows focused domains as icon+color grid; tile → DomainDetailView (non-empty sections only) | "Hub Grid + token→Color resolver" — new `accentColor(forToken:)`, `@Query` filtered on `isFocused`, data-driven tile per §9.2 |
| DOM-04 | Focus picker focuses/unfocuses; focus adds tile, unfocus hides but never deletes | "Focus Picker" — toggles `isFocused`; never deletes; lives in Settings per plan §3 |
| DOM-05 | Create custom domain (name + SF Symbol + color *token*) that persists and appears in catalog | "Custom Domain Creation UX" — `DomainIconPicker` grid + 5-swatch row; reuses existing insert+save pattern from `CategoryManagerView` |
| DOM-06 | Today visually unchanged; 4-tab structure holds with no growth | "Tab Recomposition" — remove Calendar tab, add Hub, fold Calendar into Progress; Today untouched |

## Project Constraints (from CLAUDE.md)

These carry the same authority as locked decisions. Plans MUST NOT contradict them.

- **§1 Stack:** Swift + SwiftUI, SwiftData, lightweight MVVM, **offline-only** (no network, no fetch).
- **§1 Design:** No hard-coded colors in UI. **All UI uses DesignKit semantic tokens.** Accents constrained to exactly: forest, navy, maroon/oxblood, walnut, stone.
- **§9.1:** ~400-line file cap. Split by concern when crossed (HubView + DomainDetailView + DomainFocusPicker + DomainIconPicker should be separate files, not one mega-view).
- **§9.2:** Reusable views are **data-driven, not data-fetching** — a reusable view takes props; the parent owns the `@Query`. (Governs the Hub tile, swatch row, icon grid.)
- **§9.3:** Every data-driven view ships with an explicit empty state. Hub with zero focused domains, DomainDetailView with no content, focus picker — all need empty-state copy written before "done."
- **§9.4:** Verify theme tokens exist before use; no hardcoded radii/spacing/opacities. Check `DesignKit/Layout/*` and `DesignKit/Theme/Tokens.swift`.
- **§9.5:** New pure services ship with unit tests in the same commit (happy/empty/edge). Applies to any new seed/backfill logic.
- **§9.6:** Never tolerate Finder-dupe files (`X 2.swift`) — `objectVersion = 77` compiles every file in the folder; a dupe is "invalid redeclaration."
- **§9.7:** Test runner crash in `NSStagedMigrationManager` → `xcrun simctl uninstall <device> gn.HabitsTracker` (stale store), don't chase it through a migration plan.
- **§9.8:** New `.swift` files auto-register (synchronized root group). Drop into `Features/<area>/`, `Services/`, `Models/`. **Never hand-patch `project.pbxproj`** to add a file.
- **§9.12:** All `@Model` changes go through `Docs/SCHEMA_MIGRATION_PLAYBOOK.md`. Renames via `@Attribute(originalName:)`, **never** a `SchemaMigrationPlan`. Run the upgrade test before merge.
- **§9.13:** Logging via `os.Logger`, **never `print()`** (codebase is at zero `print()` — keep it there).
- **§9.14:** DesignKit is a separate sibling repo (`../DesignKit`), consumed by local path. Do **not** edit DesignKit for an app-only need (the token→Color resolver belongs in the app, not DesignKit, until proven in 2+ apps per §4).
- **§9.15:** Accessibility is part of "done": Dynamic Type, meaningful VoiceOver labels on chips/buttons/grid, token-only colors.

## Architectural Responsibility Map

Single-tier local SwiftUI app (no client/server split). "Tier" here = layer.

| Capability | Primary Layer | Secondary Layer | Rationale |
|------------|--------------|-----------------|-----------|
| `Category`→`Domain` entity rename + `isFocused` | Model (`Models/Category.swift`→`Domain.swift`) | App entry (container type list) | Schema shape is owned by the `@Model`; container must list the renamed type |
| Inferred migration of existing store | SwiftData runtime (implicit) | — | No app code runs the migration; the framework infers it from the live class shape — which is exactly why the upgrade test is the only proof |
| One-time focus backfill + merge-add new domains | Service (`BootstrapService` + `SeedDataService`) | Persistence marker (UserDefaults) | Deterministic, testable, idempotent; must NOT live in a view |
| Hub grid + focus picker + custom creation | View (`Features/Hub/*`, `Features/Settings/*`) | Model writes via `modelContext` | UI surfaces; parent owns `@Query`, tiles are data-driven (§9.2) |
| Calendar fold into Progress | View (`Features/Progress/*`) | reused Calendar views | Pure SwiftUI recomposition; no model change |
| token→Color resolution | App-level utility (NOT DesignKit) | DesignKit `ThemeColors` for source colors | App-specific mapping of a stored string to one of 5 accents; §9.14 keeps it out of DesignKit until 2+ apps need it |

## Standard Stack

This is a pure first-party Apple stack. **No new packages are installed in this phase.**

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData | iOS 17+ (Apple SDK) | `@Model`, `@Query`, `ModelContainer`, inferred lightweight migration, `@Attribute(originalName:)` | Already the app's persistence layer; the playbook is built around its plan-less path |
| SwiftUI | iOS 17+ (Apple SDK) | `TabView`, `NavigationStack`, `Picker(.segmented)`, `LazyVGrid`, `.sheet(item:)` | Already the app's UI layer |
| Swift Charts | Apple SDK | Existing Progress charts (untouched, becomes the "Charts" segment) | Already in `ProgressDashboardView` |
| DesignKit | local sibling (`../DesignKit`) | Semantic tokens + `DKCard`/`DKBadge`/`DKSectionHeader`/etc. | Constitution mandate; consumed by path (§9.14) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `os.Logger` | Apple SDK | Diagnostics in the backfill/migration path | Any logging (§9.13 — never `print()`) |
| Swift Testing (`import Testing`) + XCTest | Apple SDK | Unit tests | Existing `HabitsTrackerTests/` uses both: `HabitsTrackerTests.swift` uses `import Testing`; `ExportImportTests.swift` uses `XCTest`. Match the file you extend. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `@Attribute(originalName:)` plan-less rename (D-01) | Relabel-only (keep class `Category`, show "Domain" in UI) | **Struck by CONTEXT.** Relabel is zero-migration but accrues naming debt across 5 future phases. Locked. |
| `@Attribute(originalName:)` plan-less rename | `SchemaMigrationPlan` + `MigrationStage` | **Forbidden** (playbook): proven to throw uncatchable Obj-C `NSException` and kill the process. Never use. |
| New `accentColor(forToken:)` in the app | Add it to DesignKit | §9.14/§4: only extract to DesignKit once proven in 2+ apps. Keep in-app for now. |
| Full SF Symbol system browser | Curated `[String]` grid (D-16) | **Locked.** Curated grid enforces "Balanced Luxury" restraint structurally; system browser allows off-brand glyphs. |

**Installation:** None. No `npm`/`pip`/SPM additions. (Package Legitimacy Audit therefore N/A — see below.)

**Version verification:** Not applicable — all dependencies are Apple SDK frameworks (versioned by the iOS deployment target, not a registry) and the local-path DesignKit sibling. No external registry package is added in this phase.

## Package Legitimacy Audit

**N/A — this phase installs no external packages.** All code uses Apple first-party frameworks (SwiftData, SwiftUI, Swift Charts, os.Logger, Swift Testing/XCTest) and the existing local-path DesignKit sibling. D-16 explicitly forbids a third-party icon-picker dependency. No registry (npm/PyPI/crates/SPM-remote) is touched, so slopcheck and registry-existence checks do not apply.

## Architecture Patterns

### System Architecture Diagram

```
                          App launch
                              │
                              ▼
                 ┌─────────────────────────┐
                 │  HabitsTrackerApp        │
                 │  .modelContainer(for:[   │
                 │    Domain, Habit,        │◄── inferred lightweight migration
                 │    DailyEntry, HabitState│    runs HERE, implicitly, when the
                 │  ])                      │    store opens against renamed class
                 └────────────┬────────────┘
                              ▼
                 ┌─────────────────────────┐
                 │  AppBootstrapView.task   │
                 │  → BootstrapService      │
                 │     .bootstrapIfNeeded   │
                 └────────────┬────────────┘
            ┌─────────────────┼─────────────────────────┐
            ▼                 ▼                         ▼
   seedIfNeeded()     (NEW) focus backfill      (NEW) merge-add new
   fresh install:     if lastSeededVersion<2:   domains via
   seed subset        flip pre-existing         restoreMissingDefaults()
   PRE-FOCUSED        Domains isFocused=true     (isFocused=false),
   (D-09)             ONCE, then persist         dedupe "Social" by name
                      marker (D-07, idempotent)  (D-08)
                              │
                              ▼  persist lastSeededVersion = 2
                 ┌─────────────────────────┐
                 │      RootTabView         │   4 tabs (was 5-1):
                 │  Today │ Hub │ Progress  │   Calendar tab REMOVED
                 │        │     │ Settings  │
                 └───┬────┴──┬──┴─────┬─────┘
                     │       │        │
        unchanged ◄──┘       │        └──► Progress: Picker(.segmented)
        (D-15)               │             Charts ⇄ Calendar
                             ▼             (CalendarMonthHeatmapView,
                  HubView @Query           NavigationStack stripped, D-14)
                  filter isFocused==true
                  → LazyVGrid of tiles
                  → tile colored via
                    accentColor(forToken:)  ◄── NEW resolver (5 tokens)
                  → tap → DomainDetailView
                          (non-empty sections only)
                  Settings → DomainFocusPicker (toggle isFocused)
                          → "Add custom domain":
                             DomainIconPicker grid + 5-swatch row
```

### Recommended Project Structure
```
HabitsTracker/
├── Models/
│   └── Domain.swift              # renamed from Category.swift (delete old, add new — §9.6 no dupes)
├── Services/
│   ├── BootstrapService.swift    # + invoke focus-backfill + merge-add, version-gated
│   ├── SeedDataService.swift     # seedVersion 1→2; defaultDomains() adds Style/Diet/Money/Media
│   └── ExportImportService.swift # schemaVersion 1→2; CategoryDTO→DomainDTO + isFocused
├── Features/
│   ├── Hub/                      # NEW folder (auto-registers, §9.8)
│   │   ├── HubView.swift         # @Query isFocused; LazyVGrid of tiles
│   │   ├── DomainTile.swift      # data-driven (§9.2): takes name/icon/color props
│   │   └── DomainDetailView.swift# non-empty sections only
│   ├── Settings/
│   │   ├── DomainFocusPicker.swift   # toggle isFocused (replaces/augments CategoryManagerView)
│   │   ├── DomainIconPicker.swift     # curated ~30 SF Symbols in LazyVGrid (D-16)
│   │   └── DomainColorSwatchRow.swift # 5-token horizontal swatches w/ selected ring (D-17)
│   ├── Progress/
│   │   └── ProgressDashboardView.swift # + Picker(.segmented) Charts⇄Calendar (D-13)
│   ├── Calendar/                 # views stay; inner NavigationStack stripped (D-14)
│   └── RootTabView.swift         # drop Calendar tab, add Hub (D-12)
└── Utilities/ or Theme/
    └── AccentTokenColor.swift    # NEW: accentColor(forToken:) → one of 5 (app-level, NOT DesignKit)
```

### Pattern 1: `@Attribute(originalName:)` on renamed properties + plan-less class rename
**What:** Rename the file/class `Category`→`Domain`, add `@Attribute(originalName: "...")` on properties whose *stored* name changes, add `isFocused` with a default, keep the container plan-less.
**When to use:** This phase's D-01.
**Important nuance:** `@Attribute(originalName:)` is verified to map a **property's** old stored name to a new one `[CITED: hackingwithswift.com/quick-start/swiftdata/how-to-rename-properties-without-losing-data]`. The property *names* here (`name`, `iconName`, `colorToken`, `sortIndex`, `isSeeded`, `seedVersion`, `id`, `habits`) are **not changing** — only the class name is. So `@Attribute(originalName:)` may strictly not even be required on individual properties; the live risk is the **entity/table** rename, which `originalName` at the property level does **not** address (see Pitfall 1). The playbook prescribes adding `@Attribute(originalName: "name")`-style annotations defensively and gating on the upgrade test — follow it exactly.
```swift
// HabitsTracker/Models/Domain.swift  (was Category.swift — delete the old file, §9.6)
@Model
final class Domain {                                   // was: final class Category
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorToken: String                             // stays one of the 5 tokens
    var sortIndex: Int
    var isSeeded: Bool
    var seedVersion: Int
    var isFocused: Bool = false                         // D-05: additive, defaulted ✓ playbook §2

    @Relationship(deleteRule: .nullify, inverse: \Habit.category)
    var habits: [Habit]                                // inverse: keep \Habit.category for now
    // ...init with isFocused: Bool = false...
}
```
**Inverse relationship note:** `Habit` declares `var category: Domain?` (the forward side). The inverse `\Habit.category` keyPath survives the type rename because it references the *Swift property* `category`, not the type name. **Decision the planner must make explicit:** rename `Habit.category` → `Habit.domain` too, or leave it as `category` for this phase. Renaming the Swift property `category`→`domain` IS a stored-attribute rename and **would** require `@Attribute(originalName: "category")` on `Habit` + an upgrade-test pass. CONTEXT D-04 says "incl. `Habit.category` relationship" — interpret as: update the *type* to `Domain?` (required); renaming the *property* to `domain` is optional but if done, needs `originalName`. Recommend keeping the property name `category` this phase to shrink migration surface, OR doing the property rename with `@Attribute(originalName:)` and an extra upgrade-test assertion — flag for planner.

### Pattern 2: Idempotent, version-gated one-time backfill in BootstrapService
**What:** A pass that runs once per store, flips pre-existing Domains to focused, then records that it ran.
**When to use:** D-07/D-11.
**Critical codebase fact:** There is **no persisted seed-version marker today.** `SeedDataService.seedVersion` is a hardcoded `private let = 1` (a *code* constant, not stored state), and `restoreMissingDefaults` is wired **only** to the Settings "Restore Defaults" button (`SettingsView.swift:68`) — it does **not** run at bootstrap. `BootstrapService.bootstrapIfNeeded` calls only `seedIfNeeded` (which early-returns if any Domain exists) + `ensureDailyEntryExists`. So the gate `seedVersion < 2` has **nothing to read from** unless you add it. Add a persisted marker:
```swift
// idempotency source of truth — add this; it does NOT exist today
@AppStorage("lastSeededVersion") private var lastSeededVersion = 0   // or UserDefaults in the service

func bootstrapIfNeeded(context: ModelContext) throws {
    try seedDataService.seedIfNeeded(context: context)            // fresh-install path (D-09)
    let previous = UserDefaults.standard.integer(forKey: "lastSeededVersion")
    if previous < 2 {
        try seedDataService.restoreMissingDefaults(context: context)  // D-08 merge-add new domains
        if previous > 0 {                                            // i.e. a genuine upgrade, had data
            try backfillFocusOnExistingDomains(context: context)     // D-07 flip pre-existing → focused
        }
        UserDefaults.standard.set(2, forKey: "lastSeededVersion")    // once-only guarantee (D-11)
    }
    _ = try ensureDailyEntryExists(for: .now, context: context)
}
```
**Why `previous > 0` matters for fresh vs migrated rows:** On a fresh install, `seedIfNeeded` seeds the subset **already** `isFocused = true` (D-09) and `lastSeededVersion` is 0, so the backfill of *existing* rows must NOT run (there are no "pre-existing" user rows). On an upgrade, the store opened, inferred migration set every existing row's new `isFocused` column to the default `false`, and `previous` is the old marker — so we flip those to `true` (D-07). This is the precise "fresh rows vs migrated rows" distinction the objective asks about: **migrated existing rows get `false` from the column default and are corrected to `true` by the backfill; freshly-seeded rows are written `true` at seed time.**

### Pattern 3: Strip inner NavigationStack to nest under a parent (Calendar → Progress)
**What:** Remove `CalendarMonthHeatmapView`'s own `NavigationStack` + `navigationTitle("Calendar")` so it renders inside Progress's `NavigationStack`, and re-anchor its `.sheet(item: $selectedDay)`.
**When to use:** D-13/D-14.
```swift
// ProgressDashboardView.swift
@State private var progressTab: ProgressTab = .charts   // enum { charts, calendar }
NavigationStack {                                       // Progress owns the ONE stack
    VStack {
        Picker("", selection: $progressTab) { Text("Charts").tag(...); Text("Calendar").tag(...) }
            .pickerStyle(.segmented).padding(.horizontal, theme.spacing.l)
        switch progressTab {
        case .charts:   chartsBody          // current body extracted
        case .calendar: CalendarMonthHeatmapView()   // now WITHOUT its own NavigationStack
        }
    }
    .navigationTitle("Progress")
}
```
The `.sheet(item: $selectedDay) { DayDetailSheet(date:) }` can stay attached inside `CalendarMonthHeatmapView`'s body (sheets present from any view in the hierarchy) — `DayDetailSheet` already has its own `NavigationStack` and is unaffected. **Verify:** the `extension Date: @retroactive Identifiable` lives in `CalendarMonthHeatmapView.swift` and must survive the edit (don't delete it).

### Pattern 4: Data-driven Hub tile (§9.2) + 5-token color resolver
**What:** Hub `@Query`s focused domains; each tile is a reusable view taking props, not fetching.
```swift
// AccentTokenColor.swift (app-level, NOT DesignKit — §9.14)
func accentColor(forToken token: String, theme: Theme) -> Color {
    switch token {
    case "navy":   return /* navy from theme/preset */
    case "maroon", "oxblood": return ...
    case "walnut": return ...
    case "stone":  return ...
    default:       return theme.colors.accentPrimary   // "forest" / unknown → safe default
    }
}
```
**Open implementation question (flag for planner):** the 5 token strings have **no Color source in the app today** — categories render with uniform `accentPrimary`. The cleanest source is the matching `ThemePreset` cases (`.forest/.navy/.maroon/.walnut/.stone` exist in `DesignKit/Theme/ThemePreset.swift`) resolved via `PresetCatalog`/`PresetTheme`, but confirm the exact public API (`PresetCatalog.theme(for:).<accent>` or `swatch(for:)`) before wiring. Keep this resolver tiny and app-local.

### Anti-Patterns to Avoid
- **Adding `migrationPlan:` to the container** — Forbidden (playbook). Uncatchable Obj-C `NSException`.
- **Bare class rename without the upgrade test** — entity-rename behavior is unverified; the test is the only proof rows survived.
- **Running the focus-backfill on every launch** — must be gated by the persisted marker (idempotent), else it re-focuses domains the user deliberately unfocused.
- **Putting the token→Color map in DesignKit** — §9.14/§4: app-only need; keep in-app until 2+ apps share it.
- **A reusable Hub tile that runs its own `@Query`** — §9.2 violation; parent owns the query, tile takes props.
- **`print()` anywhere in the backfill** — §9.13: use `os.Logger`.
- **A `Category 2.swift` left next to `Domain.swift`** — §9.6: rename = delete old file + add new; a leftover dupe breaks the whole target.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Migrating existing store on rename | A custom data-copy migration / `SchemaMigrationPlan` | SwiftData **inferred** lightweight migration + `@Attribute(originalName:)`, gated by the upgrade test | Explicit plan is Forbidden (crashes); inferred path handles additive `isFocused` and is what the playbook is built around |
| Knowing "did we already seed v2?" | Scanning rows / heuristics on `isSeeded` | A persisted `lastSeededVersion` marker (UserDefaults/AppStorage) | Deterministic, idempotent, trivially testable; row-scanning is fragile |
| Merge-adding new seed domains without dupes | Custom dedupe loop | Existing **name-keyed `restoreMissingDefaults`** path (already dedupes "Social" by name) | Already written and tested-by-use; D-08 names it explicitly |
| Picking an SF Symbol | A full system symbol browser / 3rd-party picker | Curated static `[String]` in a `LazyVGrid` (D-16) | Enforces brand restraint structurally; no dependency (offline-only, §1) |
| Validating a color choice | Color wheel / hex field with validation | Closed 5-swatch row → store the token string (D-17) | `colorToken` becomes valid-by-construction; matches the 5-accent constraint |
| Calendar inside Progress | Re-implementing the heatmap | Reuse `CalendarMonthHeatmapView` + `DayDetailSheet` verbatim minus the inner `NavigationStack` (D-14) | Zero behavior change, smallest diff |

**Key insight:** Almost everything here is recomposition of code that already exists. The only genuinely *new* code is: the `isFocused` field, the persisted version marker + backfill, the small token→Color resolver, and the Hub/picker/creation views. The migration itself must be *delegated to the framework*, not hand-coded.

## Runtime State Inventory

This phase renames a `@Model` class — runtime state beyond source files must be accounted for.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | The on-device SwiftData store (Core-Data-backed SQLite) holds `Category` rows for every existing user, keyed by the entity name SwiftData derives from the class. Renaming the class is the one store-incompatible move. | **Inferred migration via `@Attribute(originalName:)` + mandatory upgrade test** (D-02). Export/Import JSON is the safety net (D-03). |
| **Live service config** | None. App is offline-only (§1) — no external services, no remote config, no server-side state. | None — verified: no network code, no backend in the repo. |
| **OS-registered state** | None. No widgets shipped yet (WDGT-01 deferred post-Phase F), no App Intents, no background tasks, no notifications (§1, §11). | None — verified: no `Widgets/` target, no `*.appex`. |
| **Secrets/env vars** | None. Bundle id `gn.HabitsTracker` is frozen and must NOT change (constitution + STATE.md). No SOPS/.env/keychain usage. | None — and explicitly do **not** touch the bundle id or App Group. |
| **Build artifacts / persisted defaults** | (1) The simulator's installed app + its SwiftData store from the *old* schema — if the test runner crashes in `NSStagedMigrationManager`, that's a stale store (§9.7), fix by `xcrun simctl uninstall booted gn.HabitsTracker`. (2) **No persisted seed-version exists today** — `SeedDataService.seedVersion` is a code constant; nothing in UserDefaults records what was last seeded. The new `lastSeededVersion` marker is greenfield (no migration of an existing key needed). | Upgrade test must run against an old-build store (playbook Step 4). New UserDefaults key starts at 0 for everyone → upgrade path treats a populated store correctly via the `previous > 0` check (Pattern 2). |

**The canonical question — after every file is updated, what still has the old string cached?** The on-device SwiftData SQLite store. That is the entire risk surface, and it is exactly what the upgrade test exercises. There is no UI-stored config, no OS registration, and no persisted "Category"-keyed default beyond the store itself.

## Common Pitfalls

### Pitfall 1: `@Attribute(originalName:)` does NOT rename the entity/table
**What goes wrong:** You annotate properties with `@Attribute(originalName:)`, rename the class, and assume rows are preserved — but `originalName` is documented and verified only for **property** stored-name mapping `[CITED: hackingwithswift.com/quick-start/swiftdata/how-to-rename-properties-without-losing-data]`. There is **no authoritative confirmation** that inferred migration preserves rows when the `@Model` *class name* changes; Core Data historically keys the store table by entity name (derived from the class), so a class rename can be interpreted as drop-old-entity + add-new-entity = silent data loss.
**Why it happens:** The property `originalName` recipe gets over-generalized to entity renames; the distinction isn't surfaced in most tutorials.
**How to avoid:** Treat the upgrade test (D-02) as the literal proof and merge gate — build old → create a Category + habits + a logged day → build new over the store → confirm the renamed `Domain` rows + their `habits` are still visible. If rows vanish, fall back: keep the Swift class named `Category` and relabel "Domain" in UI only (the struck-but-safe option (a)), or use Export→Import as the data carry-over. **Do NOT reach for a `SchemaMigrationPlan`** to "fix" it (Forbidden).
**Warning signs:** App launches but the Hub/Today is empty after upgrade; `FetchDescriptor<Domain>()` returns 0 on a store that had categories.
**Confidence:** LOW that a bare class rename is loss-free; HIGH that the upgrade test will catch it either way.

### Pitfall 2: Backfill re-focuses domains the user unfocused
**What goes wrong:** The focus-backfill runs on every launch (no gate), so a user who unfocuses "Fitness" finds it focused again next open.
**Why it happens:** No persisted seed-version marker exists today, so an unguarded backfill has no "already ran" memory.
**How to avoid:** Gate strictly on the persisted `lastSeededVersion` marker; flip the marker to 2 inside the same pass; assert idempotency in a unit test (run the pass twice, second run is a no-op).
**Warning signs:** Unit test "backfill runs twice → second run changes nothing" fails; manual unfocus doesn't stick across launches.

### Pitfall 3: Fresh install gets pre-existing-row backfill it shouldn't
**What goes wrong:** On a fresh install, the "flip every existing Domain to focused" pass fires and over-focuses the curated subset that was intentionally seeded mixed (D-08 new domains should be `isFocused = false`).
**Why it happens:** Conflating "first seed" with "upgrade." On fresh install `lastSeededVersion == 0` and the subset is seeded already-focused (D-09); the *existing-row* flip is only for upgraders.
**How to avoid:** The `previous > 0` guard (Pattern 2) — run the existing-row flip only when the marker shows a prior seeded version (i.e. a real upgrade with prior data).
**Warning signs:** A fresh install shows Style/Diet/Money/Media already focused (should be unfocused until the user picks them).

### Pitfall 4: Two NavigationStacks (Progress + Calendar) → broken title/sheet anchoring
**What goes wrong:** Folding Calendar into Progress without stripping Calendar's own `NavigationStack` yields a nested stack: doubled nav bars, `navigationTitle("Calendar")` fighting `navigationTitle("Progress")`, and the `selectedDay` sheet anchoring oddly.
**Why it happens:** `CalendarMonthHeatmapView` wraps its body in its own `NavigationStack` (line 19) for standalone-tab use; that assumption breaks when nested.
**How to avoid:** Remove the inner `NavigationStack` + `navigationTitle("Calendar")` (D-14); let Progress own the single stack; keep `DayDetailSheet` (which has its own stack) as the sheet content.
**Warning signs:** Two stacked nav bars in the Calendar segment; the day sheet doesn't present or presents under the wrong title.

### Pitfall 5: Export/Import schema mismatch breaks round-trip
**What goes wrong:** You bump `ExportImportService.schemaVersion` to 2 but forget to (a) add `isFocused` to `CategoryDTO`→`DomainDTO`, or (b) update `deleteAll`/import to the `Domain` type, so the round-trip test or import of a v2 file fails.
**Why it happens:** Three coupled edits (schemaVersion, DTO shape, model type) in one file; easy to miss one. `importReplace` hard-rejects `bundle.schemaVersion != schemaVersion`.
**How to avoid:** In the same change: rename `CategoryDTO`→`DomainDTO`, add `isFocused`, update both `exportData`/`importReplace`/`deleteAll(model: Domain.self)`, bump to 2, update the round-trip test (currently `ExportImportTests.swift` uses `HabitsTracker.Category` — rename to `Domain`). Update the `fileExporter` default filename (`habittracker-backup-v1` → `-v2`).
**Warning signs:** `testExportImportRoundTrip` fails to compile (references `Category`) or asserts 0 domains.

## Code Examples

### Strip inner NavigationStack (verified against live file)
```swift
// CalendarMonthHeatmapView.swift — current lines 19 & 56–57 to change:
// BEFORE:
//   NavigationStack {            <- line 19, REMOVE
//       VStack { ... }
//       .navigationTitle("Calendar")   <- line 56, REMOVE
//       .sheet(item: $selectedDay) { day in DayDetailSheet(date: day) }  <- KEEP
//   }
// AFTER: just the VStack { ... }.background(...).sheet(item: $selectedDay){...}
//        (no NavigationStack wrapper, no navigationTitle)
```

### Additive field — playbook-compliant (verified rule)
```swift
// Source: Docs/SCHEMA_MIGRATION_PLAYBOOK.md Step 1
var isFocused: Bool = false   // non-optional WITH default ✓ — inferred migration backfills existing rows
```

### Upgrade test command (verified, from playbook Step 4, iPhone 17 / gn.HabitsTracker)
```bash
git checkout <last-shipped-sha>
xcrun simctl uninstall booted gn.HabitsTracker
xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/htbuild_old build
xcrun simctl install booted /tmp/htbuild_old/Build/Products/Debug-iphonesimulator/HabitsTracker.app
xcrun simctl launch booted gn.HabitsTracker
# create a category + toggle habits + log a day, then terminate
git checkout main && git stash pop
xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/htbuild_new build
xcrun simctl install booted /tmp/htbuild_new/Build/Products/Debug-iphonesimulator/HabitsTracker.app
xcrun simctl launch booted gn.HabitsTracker
# MUST launch + show all prior data as Domains; PID>0 = alive
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Core Data `.xcmappingmodel` for renames | SwiftData `@Attribute(originalName:)` for **property** renames, inferred lightweight | iOS 17 / WWDC23 | No mapping model needed for property renames; entity-class renames remain under-documented (Pitfall 1) |
| Explicit `SchemaMigrationPlan` for any change | Plan-less inferred migration for all additive/optional/defaulted changes | This project's playbook (ecosystem lesson) | Explicit plan is Forbidden here (crashes); additive `isFocused` needs no plan |

**Deprecated/outdated:**
- `ModelContainer(for:migrationPlan:)` for this project — Forbidden (uncatchable NSException). Never use.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A `@Model` **class** rename (Category→Domain) under inferred migration preserves existing rows when properties keep their stored names | Pitfall 1, Pattern 1 | **High** — silent data loss for existing users. Mitigated by the mandatory upgrade test (D-02) and Export/Import fallback (D-03). This is the phase's #1 thing to verify empirically, not assume. |
| A2 | The 5 accent token colors can be sourced from `ThemePreset.forest/.navy/.maroon/.walnut/.stone` via `PresetCatalog`/`PresetTheme` public API | Pattern 4 | Low-Med — if the API differs, the resolver needs a different source; cosmetic, caught at compile/build. Confirm the exact public accessor before wiring. |
| A3 | Keeping the Swift property name `Habit.category` (only retyping it to `Domain?`) avoids an extra property-rename migration | Pattern 1 | Low — if the planner chooses to rename the property to `domain`, add `@Attribute(originalName: "category")` + an extra upgrade-test assertion. Either path is safe; this just scopes migration surface. |
| A4 | No persisted seed-version state exists today, so the new `lastSeededVersion` marker is greenfield | Pattern 2, Runtime State Inventory | Low — verified by grep: `seedVersion` is a code constant and `restoreMissingDefaults` is only button-wired. If a hidden persisted key existed it would change the gate logic. |

## Open Questions

1. **Does a bare `@Model` class rename survive inferred migration?**
   - What we know: `@Attribute(originalName:)` handles *property* renames (verified). The properties here aren't renamed — only the class is.
   - What's unclear: whether SwiftData keys the store table by class-derived entity name such that the rename = drop+add.
   - Recommendation: Run the upgrade test FIRST, before building any Hub UI, so the whole phase plan can pivot to relabel-only (option a) if rows don't survive. Make this the earliest task.

2. **Rename `Habit.category` property to `Habit.domain`, or only retype it?**
   - What we know: D-04 says update "incl. `Habit.category` relationship." Retyping to `Domain?` is required; renaming the property is optional.
   - What's unclear: product preference for consistency vs migration-surface minimization.
   - Recommendation: This phase, retype only (keep property name `category`) to keep the migration minimal; rename the property in a later, lower-risk phase if desired. Planner to confirm.

3. **Where does the `lastSeededVersion` marker live — UserDefaults in the service, or `@AppStorage` in the view?**
   - Recommendation: UserDefaults read/written inside `BootstrapService`/`SeedDataService` (keeps idempotency logic in the testable service layer, §9.2/§9.5), not in a view.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode + iOS 17+ SDK (SwiftData/SwiftUI/Charts) | entire phase | Assumed ✓ (project builds today) | per `MARKETING_VERSION` / deployment target | — |
| iOS Simulator "iPhone 17" | upgrade test (D-02) | Owner-side ✓ (named in playbook) | — | any booted sim matching the playbook device |
| `xcodebuild` / `xcrun simctl` | upgrade test, build/run verification | Owner-side ✓ | — | — |
| DesignKit sibling (`../DesignKit`) | tokens/components | ✓ present at `/Users/gabrielnielsen/Desktop/DesignKit` | local path | — |

**Missing dependencies with no fallback:** None for planning. **Note (not a planning blocker):** per STATE.md, on-device/simulator verification (the upgrade test, build/run) is owner-side and the SPEC is "planning only — not approved to build." The plan can be fully authored; the upgrade-test execution is a human/owner gate.

## Validation Architecture

`.planning/config.json` is absent → `nyquist_validation` treated as **enabled**; section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Mixed: **Swift Testing** (`import Testing`, `@Test`) in `HabitsTrackerTests.swift`; **XCTest** in `ExportImportTests.swift` / `EngineTests.swift`. Match the file you extend. |
| Config file | none (Xcode test target `HabitsTrackerTests`, synchronized root group, `objectVersion 77`) |
| In-memory store pattern | `ModelConfiguration(isStoredInMemoryOnly: true)` + `ModelContainer(for: Schema([...]))` — verified in `ExportImportTests.swift:17-19` |
| Quick run command | `xcodebuild test -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:HabitsTrackerTests` |
| Full suite command | `xcodebuild test -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17'` |
| Upgrade test | **Manual/scripted** per playbook Step 4 (not an XCTest) — old build → data → new build over store → launch + data visible. This is the DOM-01 gate. |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOM-01 | Upgrade over old store preserves all categories→domains + habits + history | manual upgrade test (playbook §4) | scripted `xcodebuild`/`simctl` sequence above | ❌ Wave 0 (script/checklist) |
| DOM-01 | `isFocused` defaults `false` on inferred migration of existing rows | unit (in-memory) | `-only-testing:HabitsTrackerTests/DomainMigrationTests` | ❌ Wave 0 |
| DOM-02 | `Domain` has `isFocused` + all prior fields; default `false` | unit | same file | ❌ Wave 0 |
| DOM-03/04 | Focus backfill: pre-existing rows → `true`; **idempotent** (run twice = no-op); fresh rows respect seed focus | unit (in-memory, two-run) | `-only-testing:HabitsTrackerTests/BootstrapBackfillTests` | ❌ Wave 0 |
| DOM-05 | Custom domain (name + curated symbol + token) persists with valid `colorToken` ∈ 5 tokens | unit | `BootstrapBackfillTests` or new `DomainCreationTests` | ❌ Wave 0 |
| DOM-03 (data safety) | Export/Import round-trip green at `schemaVersion == 2` incl. `isFocused` | unit | `-only-testing:HabitsTrackerTests/ExportImportTests` (update existing) | ✅ exists — must update Category→Domain + isFocused |
| DOM-06 | 4-tab invariant: Today, Hub, Progress, Settings (no Calendar tab) | smoke/manual (UI count) | manual build+run, or UI test asserting 4 tab items | ✅ `HabitsTrackerUITests/` dir exists (assertion to add) |
| DOM-06 | Today visually unchanged | manual visual | build+run, compare Today | ❌ manual-only (visual) — justified: no behavior change to assert programmatically |

### Sampling Rate
- **Per task commit:** `-only-testing:HabitsTrackerTests` (quick, in-memory unit tests).
- **Per wave merge:** full `xcodebuild test` suite green.
- **Phase gate (DOM-01):** the **manual upgrade test must pass** + full suite green before `/gsd:verify-work`. Treat upgrade-test failure as a hard stop (do not merge — playbook).

### Wave 0 Gaps
- [ ] `HabitsTrackerTests/DomainMigrationTests.swift` — `isFocused` default-on-migration + Domain field shape (DOM-01/02)
- [ ] `HabitsTrackerTests/BootstrapBackfillTests.swift` — version-gated backfill: existing→focused, **two-run idempotency**, fresh-install respects seed focus, merge-add dedupes "Social" (DOM-03/04)
- [ ] Update `HabitsTrackerTests/ExportImportTests.swift` — rename `HabitsTracker.Category`→`Domain`, add `isFocused`, assert `schemaVersion == 2` round-trip (DOM-03)
- [ ] (Optional) `HabitsTrackerUITests/` — assert exactly 4 tab items, labels Today/Hub/Progress/Settings (DOM-06)
- [ ] Upgrade-test runbook/script committed under `Docs/` (or reuse playbook §4) and run on iPhone 17 (DOM-01 gate)

*(No new framework install needed — `HabitsTrackerTests` target exists and already uses both Swift Testing and XCTest with in-memory `ModelContainer`.)*

## Security Domain

`security_enforcement` is absent from config (no `.planning/config.json`) → treated as enabled, but this phase's threat surface is minimal.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | App is single-user, local-only, no accounts |
| V3 Session Management | no | No sessions |
| V4 Access Control | no | No multi-user/server access |
| V5 Input Validation | yes (light) | Custom-domain `name` (TextField) — trim/length-guard as existing `CategoryManagerView` does; `colorToken` is valid-by-construction (closed 5-swatch, D-17); `iconName` from a closed curated set (D-16). No free-form SF Symbol string from the user. |
| V6 Cryptography | no | No crypto; no secrets; bundle id frozen |

### Known Threat Patterns for SwiftData/SwiftUI local app
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed/old Export JSON on import | Tampering / DoS | `importReplace` already hard-rejects `schemaVersion != current`; keep the guard at v2; `try?`/error-surface already present in `SettingsView` |
| Data loss on schema rename | (Availability/Integrity) | Mandatory upgrade test (D-02) + Export/Import safety net (D-03) — the core mitigation of the whole phase |
| User-supplied icon string rendering an arbitrary/empty glyph | (UX integrity) | Curated closed `[String]` set (D-16) — user cannot inject an off-brand or invalid symbol name |

No new attack surface (no network, no auth, no secrets, offline-only). The dominant "security" concern here is **data integrity on migration**, fully covered by the upgrade test and export/import.

## Sources

### Primary (HIGH confidence — verified against live codebase)
- `HabitsTracker/Models/Category.swift`, `Habit.swift` — exact field/relationship shapes, `.nullify` inverse
- `HabitsTracker/HabitsTrackerApp.swift` — plan-less `.modelContainer(for:[Category,Habit,DailyEntry,HabitState])`
- `HabitsTracker/Services/{SeedDataService,BootstrapService,ExportImportService}.swift` — `restoreMissingDefaults` is button-only; `seedVersion` is a code constant; no persisted marker; schemaVersion=1; `importReplace` rejects mismatched schema
- `HabitsTracker/Features/{RootTabView,Calendar/CalendarMonthHeatmapView,Calendar/DayDetailSheet,Progress/ProgressDashboardView,Settings/*,Today/TodayView}.swift` — exact Category reference sites, NavigationStack nesting, `.sheet(item:)` usages, `@retroactive Identifiable Date`
- `HabitsTrackerTests/ExportImportTests.swift` — in-memory `ModelContainer` test pattern; references `HabitsTracker.Category`
- `Docs/SCHEMA_MIGRATION_PLAYBOOK.md`, `CLAUDE.md` §1/§4/§9 — playbook recipe, Forbidden Moves, file/token/logging/a11y rules
- `/Users/gabrielnielsen/Desktop/DesignKit/Sources/DesignKit/Theme/{ThemePreset,Tokens,PresetTheme}.swift` — accent token cases, `ThemeColors`, `swatch(for:)`

### Secondary (MEDIUM confidence — official-adjacent docs, verified)
- [Hacking with Swift — Rename properties without losing data](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-rename-properties-without-losing-data) — `@Attribute(originalName:)` is for **property** renames; bare rename = drop+add data loss
- [Apple — Model your schema with SwiftData (WWDC23)](https://developer.apple.com/videos/play/wwdc2023/10195/) — lightweight migration eligibility (additive/optional/defaulted)
- [Donny Wals — A Deep Dive into SwiftData migrations](https://www.donnywals.com/a-deep-dive-into-swiftdata-migrations/) — property-rename mechanics; does **not** cover entity-class rename (hence Pitfall 1 / A1)

### Tertiary (LOW confidence — flagged for validation)
- Entity/table identification by class-derived name (the A1 risk) — **no authoritative source confirmed**; deliberately left to the empirical upgrade test rather than asserted.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all first-party Apple frameworks already in use; no new packages.
- Architecture / reference-site change set: HIGH — every Category reference and NavigationStack/sheet site read directly from source.
- Migration mechanics (additive `isFocused`, plan-less, upgrade-test gate): HIGH for the additive field; **LOW for whether a bare class rename is loss-free** (A1) — correctly delegated to the mandatory upgrade test.
- Backfill/idempotency design: HIGH — verified there's no existing persisted marker, so the design is greenfield and testable.
- token→Color resolver source API: MEDIUM — DesignKit accent cases exist; exact public accessor to confirm at build time (A2).

**Research date:** 2026-06-28
**Valid until:** ~2026-07-28 (stable first-party stack; the SwiftData entity-rename behavior question is empirical and resolved by the upgrade test, not by source freshness).
