# Phase 6: Polish (F) - Pattern Map

**Mapped:** 2026-07-11
**Files analyzed:** 9 (2 new, 7 modified/verified)
**Analogs found:** 9 / 9 (all patterns exist in-repo; this phase reuses, it does not invent)

> This phase is cross-cutting polish over types already built in Phases 1–5. Almost
> everything has a strong in-repo analog. The only genuinely new UI is the search
> results surface, and even that is assembled from three existing patterns
> (HubView's `NavigationStack` host + DomainDetailView's section loop +
> HabitManagerView's `localizedCaseInsensitiveContains` filter). Follow existing
> patterns per §4; do not introduce a search engine, FTS, or new dependency (D-03 note).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Features/Hub/HubView.swift` (MODIFY) | view / search host | request-response | itself (already the `NavigationStack` host) | exact (self) |
| `Features/Hub/SearchResultsView.swift` (NEW) | view (grouped results) | CRUD-read (N filtered fetches) | `DomainDetailView.swift` (section loop) + `HabitManagerView.swift` (filter) | role+flow match |
| `Features/Hub/SearchService.swift` (NEW, optional — planner's discretion D-51) | service | transform / query | `HabitManagerView.filteredHabits` (inline) | partial (no service analog) |
| `Features/Collections/CollectionItemRow.swift` (MODIFY) | component (chip) | event-driven (tap) | `Features/Clips/ClipRow.swift` (reachable Button chip + hint) | exact |
| `Features/Clips/ClipRow.swift` (VERIFY) | component (chip) | event-driven (tap) | itself (already correct) | exact (self) |
| `Features/Ideas/IdeaRow.swift` (VERIFY) | component (row+pills) | event-driven (tap) | itself | exact (self) |
| `Features/Settings/SettingsView.swift` (MODIFY) | view (List/config) | request-response read | itself (existing `Section` rows) | exact (self) |
| `Services/ExportImportService.swift` (VERIFY only, D-14) | service | file-I/O round-trip | itself (v6 DTOs exist) | exact (self) |
| `HabitsTrackerTests/ExportImportTests.swift` (MODIFY) | test | file-I/O round-trip | itself (`testV5FieldsSurviveRoundTrip`) | exact (self) |

## Pattern Assignments

### `Features/Hub/HubView.swift` — MODIFY (POL-01, D-01/D-02)

**Analog:** itself — HubView already owns the single `NavigationStack` and `navigationTitle("Hub")` (lines 24–38). Attach `.searchable` + `.searchToolbarBehavior(.minimize)` to that stack's content; do NOT add a second `NavigationStack`.

**Existing host to extend** (lines 24–38):
```swift
NavigationStack {
    Group {
        if focusedDomains.isEmpty { emptyState(theme: theme) }
        else { grid(theme: theme) }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.colors.background.ignoresSafeArea())
    .navigationTitle("Hub")
    .navigationDestination(for: Domain.self) { domain in
        DomainDetailView(domain: domain)
    }
}
```
The `@State private var searchText = ""` + `.searchable(text: $searchText)` + `.searchToolbarBehavior(.minimize)` go on the `Group`. When `searchText` is non-empty, swap the `Group` content for `SearchResultsView(query: searchText)` (or overlay it). Reuse the existing `.background(theme.colors.background.ignoresSafeArea())` and add `.navigationDestination` entries for the push targets (Rule/Collection/Clip) alongside the existing `Domain` one.

**Search-field state precedent** — the exact `@State searchText` + case-insensitive-contains idiom already exists in `HabitManagerView.swift`:
```swift
@State private var searchText = ""
// ...
.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
```
D-04 asks for `.localizedStandardContains` (diacritic/width-insensitive) over title + free-text fields — same shape, swap the method.

---

### `Features/Hub/SearchResultsView.swift` — NEW (POL-01, D-03..D-08)

**Analog:** `DomainDetailView.swift` (the section-loop-with-empty-fallback, lines 33–100) for the grouped-`Section`-per-type layout, plus `HabitManagerView` for the filter predicate.

**Section-loop layout to copy** (DomainDetailView lines 37–53) — one `Section` per type (Habits / Rules / Collections / Clips / Ideas), each built only when it has matches, Spotlight-style:
```swift
ScrollView {
    VStack(alignment: .leading, spacing: theme.spacing.xl) {
        // one block per non-empty type, e.g.:
        if !ruleMatches.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                Text("Rules").font(theme.typography.title)
                    .foregroundStyle(theme.colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(ruleMatches, id: \.id) { rule in
                    NavigationLink { RuleDetailView(rule: rule) } label: { RuleRow(rule: rule) }
                        .buttonStyle(.plain)
                }
            }
        }
        // ... Collections, Clips, Ideas, Habits
    }
    .padding(theme.spacing.l)
}
```

**Per-type filtered fetch** (D-03/D-04/D-06) — N small `@Query`s, one per model, each filtered in-memory by title + free-text fields via `.localizedStandardContains`, excluding archived/consumed. Searchable fields confirmed from the models:

| Type | Title field | Free-text fields (D-04) | Exclusion filter (D-06) |
|------|-------------|--------------------------|--------------------------|
| Rule | `title` | `body` | `!isArchived` |
| Clip | `title` | `note`, `tag`, `url` | `!isArchived` |
| Idea | `title` | `note`, `url` | `!isArchived && promotedToKindRaw == nil` (consumed = promoted, D-06) |
| CollectionItem | `title` | `note` | (parent) — surface under Collections |
| Collection | `title` | `note` | — |
| Habit | `name` | (title-only) | `!isArchived` (D-05: include habits) |

**Reuse existing row + destination wiring (D-07)** — do NOT build new rows/details. The exact `NavigationLink { Detail } label: { Row }` pairs already exist in DomainDetailView:
- Rule → `NavigationLink { RuleDetailView(rule:) } label: { RuleRow(rule:) }` (DomainDetailView 122–128)
- Collection → `NavigationLink { CollectionDetailView(collection:) } label: { CollectionRow(collection:) }` (167–178)
- Clip → `NavigationLink { ClipDetailView(clip:) } label: { ClipRow(clip:) }` (220–232)
- Idea → sheet, NOT push: `.sheet(isPresented:) { IdeaCaptureSheet(idea: idea) }` (IdeaRow 57–59; `init(idea:)` confirmed at IdeaCaptureSheet.swift:54). Reuse `IdeaRow` directly — it already owns its tap→edit sheet (D-08).
- Habit → sheet: `.sheet(item: $editingHabit) { habit in HabitEditorView(habit: habit) }` (HabitManagerView 56–58; `HabitEditorView` takes `let habit: Habit` at :13). D-08: habit result opens editor sheet, never jumps to Today.

**Detail view init signatures confirmed** (all take a plain `let` value, no custom init needed): `RuleDetailView(rule:)`, `ClipDetailView(clip:)`, `CollectionDetailView(collection:)`, `HabitEditorView(habit:)`, `IdeaCaptureSheet(idea:)`.

**No-results state (D-12)** — reuse the `ContentUnavailableView` idiom already in `AppBootstrapView.swift` (lines 18–22). Use the platform search overload:
```swift
ContentUnavailableView.search(text: searchText)
```
Show it when all per-type match arrays are empty and `searchText` is non-empty.

---

### `Features/Collections/CollectionItemRow.swift` — MODIFY (POL-04, D-10 PRIORITY)

**Analog:** `Features/Clips/ClipRow.swift` (lines 57–69) — the correct, VoiceOver-reachable chip pattern.

**The gap (D-10, correctness bug):** the tap-to-advance chip here is an `.onTapGesture` on a `DKBadge` (lines 49–64), and the whole card is `.accessibilityElement(children: .ignore)` (line 68) — so VoiceOver cannot reach the chip as a control and the advance action is silent. The row exposes only status + a "Reset status" action (lines 69–72), never "advance."

**Fix — copy ClipRow's reachable-Button-chip + hint pattern** (ClipRow 57–69):
```swift
private func statusChip(theme: Theme) -> some View {
    Button {
        tapCounter += 1
        clip.status = clip.status == .saved ? .acted : .saved
    } label: {
        DKBadge(statusLabel, theme: theme).frame(minWidth: 44, minHeight: 44)
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.impact(weight: .light), trigger: tapCounter)
    .accessibilityLabel("Status: \(statusLabel), \(clip.title)")
    .accessibilityHint("Toggles between saved and acted")
}
```
Apply the same shape to CollectionItemRow: make the chip a `Button` (or add a named `.accessibilityAction(named: "Advance status")` alongside the existing "Reset status" action at 70–72) and add an `.accessibilityHint` describing "advances to the next status" (clamped at terminal). Preserve the existing `tapCounter` sensory-feedback pattern (lines 51–64) and the `contextMenu`/Reset action.

---

### `Features/Clips/ClipRow.swift` & `Features/Ideas/IdeaRow.swift` — VERIFY (POL-04, D-09/D-10)

**These are already the reference implementations** — ClipRow chip has label + hint (67–68); IdeaRow has combined title element + labels on File/Promote pills (94–95, 119, 132). Scope is fix-as-found (D-09), so confirm Dynamic Type (`minimumScaleFactor` already present) and tokens-only color, then leave them. Do NOT expand into an app-wide audit (D-09).

---

### `Features/Settings/SettingsView.swift` — MODIFY (POL-04, D-13)

**Analog:** itself — the existing `Section("...") { rows }` pattern (lines 33–82). Add a read-only "About" footer section matching that styling:
```swift
Section("About") {
    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
    LabeledContent("Data schema", value: "\(6)")  // mirror ExportImportService.schemaVersion
}
```
Follow the existing `.scrollContentBackground(.hidden)` / `theme.colors.background` treatment already on the `List` (lines 84–85). No new screen, no new DesignKit component (D-13). Schema version source of truth is `ExportImportService.schemaVersion = 6` (confirmed) — surface the same constant, don't hardcode a divergent literal (expose it, e.g. make the service constant readable, or reference a shared constant).

---

### `Services/ExportImportService.swift` — VERIFY ONLY (POL-03, D-14)

**No new DTO work.** `schemaVersion = 6` (line 7) and all 7 type DTOs already exist (`exportData` signature lines 22–31 takes categories/habits/entries/rules/collections/collectionItems/clips/ideas). `StatusSet` is a code catalog referenced by ID (`StatusSetCatalog.swift`), round-trips via the stored `statusSetID` string (confirmed in CollectionItemRow: `StatusSetCatalog.set(for: collection.statusSetID)`), not a DTO. Import guards schema: `guard bundle.schemaVersion <= schemaVersion` (line 161).

**D-15 (schema bump):** Search + a11y are read-side only — no persisted field is added, so do NOT bump `schemaVersion`. Only bump (and follow `Docs/SCHEMA_MIGRATION_PLAYBOOK.md`, §9.12) if planning actually introduces a stored field.

---

### `HabitsTrackerTests/ExportImportTests.swift` — MODIFY (POL-03)

**Analog:** the existing `testV5FieldsSurviveRoundTrip` (line 164) and `testV4...` (89) methods — each seeds one of every type, calls `service.exportData(...)`, `service.importReplace(data:context:)`, then re-fetches and `XCTAssertEqual`s that every field + relationship survived. Add/extend an all-7-types v6 round-trip assertion in the same shape (`@MainActor`, in-memory `ModelContainer`, lines 27–36).

**Toolchain caveat (§9.7 — carry into the plan):** `ExportImportTests` is a SwiftData `@Model` persistence suite; it **crashes the test host at 0.000s on the iOS 26 simulator** (in-memory `ModelContainer` creation). It is **build-verify-only** on this machine — do not claim it "passed" from a simulator run. To actually execute the round-trip, run on a physical device or a different iOS runtime. The engine/logic suites remain runnable and must be run if any pure logic is added.

## Shared Patterns

### Theme + DesignKit tokens (all UI files)
**Source:** every view in the repo
**Apply to:** SearchResultsView, HubView search, SettingsView row, chip fixes
```swift
@EnvironmentObject private var themeManager: DKThemeManager
@Environment(\.colorScheme) private var colorScheme
// in body:
let theme = themeManager.theme(for: colorScheme)
```
Colors/spacing/radii come only from `theme.colors.*`, `theme.spacing.*`, `theme.radii.*` (§1 Design, §9.4). Rows use `DKCard`, badges use `DKBadge`. No hardcoded colors.

### Data-driven rows own no query (§9.2)
**Source:** `ClipRow`, `RuleRow`, `CollectionRow`, `CollectionItemRow`
**Apply to:** SearchResultsView — the results view owns the `@Query`s; rows take a value. Reuse the existing rows as-is.

### Section header + `.isHeader` trait
**Source:** DomainDetailView `rulesSectionHeader` (lines 134–153)
**Apply to:** SearchResultsView type headers
```swift
Text("Rules").font(theme.typography.title)
    .foregroundStyle(theme.colors.textPrimary)
    .accessibilityAddTraits(.isHeader)
```

### VoiceOver chip contract (§9.15, D-10)
**Source:** `ClipRow.statusChip` (57–69)
**Apply to:** CollectionItemRow chip — reachable `Button` + `.accessibilityLabel` (current status) + `.accessibilityHint`/named `.accessibilityAction` (the advance outcome). Keyed sensory feedback via a `tapCounter` `@State` so terminal taps still buzz.

### ContentUnavailableView for empty/error states (§9.3, D-12)
**Source:** `AppBootstrapView` (18–22)
**Apply to:** search no-results (`ContentUnavailableView.search(text:)`). Existing empty states (HubView 101–126, DomainDetailView 329–341 "Nothing here yet", InboxView, PromoteToCollectionPicker) already satisfy §9.3 and are reused as-is (D-11) — no bespoke per-section copy.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `Features/Hub/SearchService.swift` (only if planner chooses a service over inline `@Query`s) | service | query/transform | No cross-model search service exists; closest is `HabitManagerView.filteredHabits` (inline in-view filter). If a service is chosen, model it as a pure struct returning per-type arrays (§4 testability, §9.5). Inline `@Query` per type in SearchResultsView is the lower-risk default and matches every existing list surface — recommended. |

## Metadata

**Analog search scope:** `HabitsTracker/Features/{Hub,Settings,Collections,Clips,Ideas,Rules,Habits}`, `HabitsTracker/Services`, `HabitsTracker/Models`, `HabitsTrackerTests`
**Files scanned:** ~24 read/grepped
**Pattern extraction date:** 2026-07-11
