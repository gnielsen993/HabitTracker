# Phase 3: Collections (C) - Pattern Map

**Mapped:** 2026-07-05
**Files analyzed:** 18 new/modified files
**Analogs found:** 17 / 18

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Models/Collection.swift` | model | CRUD | `Models/Rule.swift` | exact |
| `Models/CollectionItem.swift` | model | CRUD | `Models/Rule.swift` | exact |
| `Models/Domain.swift` (edit) | model | CRUD | `Models/Domain.swift` (self) | exact |
| `Services/StatusSetCatalog.swift` | utility | transform | `Services/WeeklyGoalEngine.swift` | role-match (pure enum, no persistence) |
| `Services/CollectionPresetCatalog.swift` | utility | transform | `Services/WeeklyGoalEngine.swift` | role-match (pure enum, no persistence) |
| `Services/CollectionRollupEngine.swift` | service | transform | `Services/WeeklyGoalEngine.swift` | exact (pure nonisolated enum, deterministic) |
| `HabitsTrackerTests/CollectionRollupEngineTests.swift` | test | transform | `HabitsTrackerTests/EngineTests.swift` | exact |
| `Services/SeedDataService.swift` (edit) | service | CRUD | `Services/SeedDataService.swift` (self) | exact |
| `Services/ExportImportService.swift` (edit) | service | CRUD | `Services/ExportImportService.swift` (self) | exact |
| `HabitsTrackerApp.swift` (edit) | config | CRUD | `HabitsTrackerApp.swift` (self) | exact |
| `Features/Hub/DomainDetailView.swift` (edit) | component | request-response | `Features/Hub/DomainDetailView.swift` (self) | exact |
| `Features/Collections/CollectionRow.swift` | component | request-response | `Features/Rules/RuleRow.swift` | exact |
| `Features/Collections/CollectionPresetPickerSheet.swift` | component | request-response | `Features/Rules/RuleEditorView.swift` | role-match (sheet, cancel/confirm) |
| `Features/Collections/CollectionDetailView.swift` | component | request-response | `Features/Rules/RuleDetailView.swift` | exact (detail view, no nav stack) |
| `Features/Collections/CollectionItemRow.swift` | component | request-response | `Features/Rules/RuleRow.swift` | exact |
| `Features/Collections/CollectionItemDetailView.swift` | component | request-response | `Features/Rules/RuleDetailView.swift` | exact (block structure) |
| `Features/Collections/CollectionItemEditorSheet.swift` | component | request-response | `Features/Rules/RuleEditorView.swift` | exact |
| `HabitsTrackerTests/CollectionModelTests.swift` | test | CRUD | `HabitsTrackerTests/RuleModelTests.swift` | exact |

---

## Pattern Assignments

---

### `Models/Collection.swift` (model, CRUD)

**Analog:** `HabitsTracker/Models/Rule.swift`

**Imports pattern** (lines 1-3):
```swift
import Foundation
import SwiftData
```

**Core @Model pattern** (lines 4-38):
```swift
@Model
final class Rule {
    @Attribute(.unique) var id: UUID
    var title: String
    var body: String
    var sourceURL: String?
    var createdAt: Date
    var isArchived: Bool = false

    @Relationship
    var domain: Domain?

    @Relationship(deleteRule: .nullify, inverse: \Habit.originRule)
    var stemmedHabits: [Habit] = []

    init(
        id: UUID = UUID(),
        title: String,
        body: String = "",
        sourceURL: String? = nil,
        domain: Domain? = nil,
        isArchived: Bool = false,
        createdAt: Date = .now,
        stemmedHabits: [Habit] = []
    ) { ... }
}
```

**Apply to Collection:** Mirror this shape exactly. New scalar fields (`statusSetID`, `sortIndex`, `showsAggregate`, `progressTemplate`, `note`, `isSeeded`, `seedVersion`) are all defaulted or optional so inferred lightweight migration can handle them. The `@Relationship` to `Domain?` uses the bare `@Relationship` macro (nullify is declared on the Domain side). The owned `items: [CollectionItem]` relationship uses `deleteRule: .cascade` (items are owned, unlike habits which survive rule deletion — see D-22).

**Key differences from Rule:**
- `items` relationship is `.cascade` (not `.nullify`) — items don't exist outside a collection
- `statusSetID: String = "generic"` — defaulted scalar
- `sortIndex: Int = 0` — defaulted scalar
- `showsAggregate: Bool = true` — defaulted scalar
- `progressTemplate: String = "none"` — defaulted scalar (raw string matching enum cases)
- No `isArchived` — collections are deleted, not archived

---

### `Models/CollectionItem.swift` (model, CRUD)

**Analog:** `HabitsTracker/Models/Rule.swift`

Same `@Model final class` shape. Key fields:
- `statusIndex: Int = 0` — defaulted, drives tap-to-advance chip (D-06)
- `sortIndex: Int = 0` — defaulted
- `note: String? = nil`
- `sourceURL: String? = nil`
- `cost: Double? = nil`
- `season: Int = 1`, `episode: Int = 1` — for `seasonEpisode` template
- `counterValue: Int = 0` — for `counter` template
- `counterLabel: String? = nil` — stored on item per Claude's Discretion
- `isSeeded: Bool = false`, `seedVersion: Int = 0`

**Relationship to Collection:** bare `@Relationship var collection: Collection?` — nullify is set on the Collection side (`.cascade`).

---

### `Models/Domain.swift` — add `collections` inverse (edit)

**Analog:** `HabitsTracker/Models/Domain.swift` (self, lines 15-19)

**Existing inverse pattern to mirror** (lines 15-19):
```swift
@Relationship(deleteRule: .nullify, inverse: \Habit.category)
var habits: [Habit]

@Relationship(deleteRule: .nullify, inverse: \Rule.domain)
var rules: [Rule] = []
```

**New line to append** (same idiom):
```swift
@Relationship(deleteRule: .nullify, inverse: \Collection.domain)
var collections: [Collection] = []
```

Add `collections: [Collection] = []` to the `init` signature and body. Use `@Attribute(originalName: "collections")` only if needed for rename — not needed for a new field, so bare `@Relationship` is correct. Keep all existing `@Attribute(originalName:)` annotations on existing fields untouched (§9.16).

---

### `Services/StatusSetCatalog.swift` (utility, transform)

**Analog:** `Services/WeeklyGoalEngine.swift` (pure enum, no persistence)

**Pure enum pattern** (lines 1-29 of WeeklyGoalEngine.swift):
```swift
import Foundation

enum WeeklyGoalEngine {
    nonisolated static func completedCountThisWeek(...) -> Int { ... }
    nonisolated static func remainingSessions(target: Int, completed: Int) -> Int { ... }
    nonisolated static func isTargetMet(target: Int, completed: Int) -> Bool { ... }
}
```

**Apply to StatusSetCatalog:** Use `enum StatusSetCatalog` (not a class — no instantiation). No SwiftData import. Define a `StatusSet` value type (struct) with `id: String`, `states: [String]`, `terminalIndex: Int`. Expose a static `all: [StatusSet]` and a `set(for id: String) -> StatusSet?` lookup. Catalog entries must match the UI-SPEC table exactly:

| ID | States | Terminal |
|----|--------|---------|
| `"generic"` | `["to-collect", "collected"]` | 1 |
| `"shows"` | `["to-watch", "watching", "watched"]` | 2 |
| `"movies"` | `["to-watch", "watching", "watched"]` | 2 |
| `"albums"` | `["to-listen", "listening", "listened"]` | 2 |
| `"concerts"` | `["to-attend", "attended"]` | 1 |
| `"books"` | `["to-read", "reading", "read"]` | 2 |
| `"clothes"` | `["want", "bought"]` | 1 |
| `"spending"` | `["considering", "purchased"]` | 1 |
| `"places"` | `["to-visit", "visited"]` | 1 |

---

### `Services/CollectionPresetCatalog.swift` (utility, transform)

**Analog:** `Services/WeeklyGoalEngine.swift` (pure enum, no persistence)

**Apply:** `enum CollectionPresetCatalog`. Define a `CollectionPreset` value type with `id: String`, `name: String`, `statusSetID: String`, `progressTemplate: String`, `showsAggregate: Bool`. Expose `static let all: [CollectionPreset]`. Order: generic, shows, movies, albums, concerts, books, clothes, spending, places — matches UI-SPEC S2 order (D-12).

No SwiftData import. No `@Model`. This is code-only (D-01, D-12).

---

### `Services/CollectionRollupEngine.swift` (service, transform)

**Analog:** `Services/WeeklyGoalEngine.swift` — same pure enum + nonisolated static func pattern

**Core pattern** (WeeklyGoalEngine.swift lines 1-29):
```swift
import Foundation

enum WeeklyGoalEngine {
    nonisolated static func completedCountThisWeek(
        habit: Habit,
        entries: [DailyEntry],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        ...
        return entries
            .filter { ... }
            .compactMap { ... }
            .filter(\.isCompleted)
            .count
    }

    nonisolated static func remainingSessions(target: Int, completed: Int) -> Int {
        max(target - completed, 0)
    }

    nonisolated static func isTargetMet(target: Int, completed: Int) -> Bool {
        completed >= target
    }
}
```

**Apply to CollectionRollupEngine:**
```swift
import Foundation

enum CollectionRollupEngine {
    enum Result {
        case count(x: Int, y: Int)
        case costSum(total: Double)
        case none
    }

    nonisolated static func rollup(
        collection: Collection,
        items: [CollectionItem]
    ) -> Result {
        guard collection.showsAggregate else { return .none }
        // cost-flavored: showsAggregate && some item has non-nil cost &&
        //   no meaningful completion semantics (terminal == last state but
        //   all statusSets have a terminal — defer to presence of cost)
        // See D-20 for derivation logic
        ...
    }
}
```

Result enum drives all UI branching (D-16 through D-20). No SwiftData or DesignKit import — pure Foundation only.

---

### `HabitsTrackerTests/CollectionRollupEngineTests.swift` (test, transform)

**Analog:** `HabitsTrackerTests/EngineTests.swift`

**Test file structure** (lines 1-50 of EngineTests.swift):
```swift
import XCTest
@testable import HabitsTracker

final class EngineTests: XCTestCase {
    func testCustomScheduleMatching() { ... }
    func testOptionalExcludedFromRequiredCompletion() { ... }
    func testWeeklyGoalRemainingNeverNegative() { ... }
    func testRequiredStreakStopsAtMiss() { ... }
}
```

**Required test cases (§9.5 — ship with the engine):**
1. `testCompletionistHappyPath` — X items at terminal, Y total → `.count(x, y)` correct
2. `testEmptyList` — zero items → `.count(0, 0)` (y == 0 handled gracefully)
3. `testMidStepItemNotCounted` — 3-state set, item at state 1 (not terminal) → NOT counted in X
4. `testCostSumWithMixedNilCosts` — some items nil cost, some non-nil → sum of non-nil only
5. `testTrackerShowsAggregateOff` → `.none`

No SwiftData import needed — build `Collection`/`CollectionItem` instances in-memory and pass directly. Mirror the in-line object construction style from EngineTests (no `makeInMemoryContext()` required for a pure engine).

---

### `HabitsTrackerTests/CollectionModelTests.swift` (test, CRUD)

**Analog:** `HabitsTrackerTests/RuleModelTests.swift`

**Test infrastructure pattern** (lines 1-18 of RuleModelTests.swift):
```swift
import XCTest
import SwiftData
@testable import HabitsTracker

final class RuleModelTests: XCTestCase {

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self, Rule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }
    ...
}
```

**Update schema for new tests:** Add `Collection.self, CollectionItem.self` to the `Schema([ ... ])` array inside `makeInMemoryContext()`.

**Required test cases:**
1. `testStatusIndexDefaultsZero` — mirrors `testIsArchivedDefaultsFalse`
2. `testDeleteCollectionCascadesItems` — cascade rule: delete Collection → items deleted (contrast with `testDeleteRuleNullifiesStemmedHabits` which verifies `.nullify`)
3. `testDomainCollectionsInverse` — mirrors `testDomainRulesInverse`
4. `testDeleteCollectionNullifiesDomainRelationship` — domain.collections shrinks after delete

---

### `Services/SeedDataService.swift` (edit)

**Analog:** `Services/SeedDataService.swift` (self)

**Fresh-install guard pattern** (lines 7-21):
```swift
func seedIfNeeded(context: ModelContext) throws {
    let existingCategories = try context.fetch(FetchDescriptor<Domain>())
    guard existingCategories.isEmpty else { return }

    let categories = defaultDomains()
    categories.forEach { context.insert($0) }
    ...
    try context.save()
}
```

**Merge-add pattern** (lines 22-46):
```swift
func restoreMissingDefaults(context: ModelContext) throws {
    ...
    for template in defaultDomains() where resolved[template.name] == nil {
        template.isFocused = false   // upgrader guard — merge unfocused
        context.insert(template)
        resolved[template.name] = template
    }

    let existingHabits = try context.fetch(FetchDescriptor<Habit>())
    let habitKey = Set(existingHabits.map { ... })
    for habit in defaultHabits(categoryByName: resolved) {
        if !habitKey.contains(key) { context.insert(habit) }
    }
    try context.save()
}
```

**Apply for collections (D-14):** Add a `defaultCollections(domainByName: [String: Domain]) -> [Collection]` private helper and seed ONE generic starter (e.g., `Collection(title: "My List", domain: <"Media" or "Lifestyle">`, `statusSetID: "generic"`, `isSeeded: true`, `seedVersion: seedVersion`). Guard it in both `seedIfNeeded` and `restoreMissingDefaults` using an `isSeeded` check on fetched collections — same dedup key pattern as habits (`collection.title + "::" + (collection.domain?.name ?? "None")`).

---

### `Services/ExportImportService.swift` (edit)

**Analog:** `Services/ExportImportService.swift` (self)

**Bundle struct pattern** (lines 4-11):
```swift
struct HabitExportBundle: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let categories: [DomainDTO]
    let habits: [HabitDTO]
    let dailyEntries: [DailyEntryDTO]
    let rules: [RuleDTO]
}
```

**DTO struct pattern** (lines 24-32 — RuleDTO):
```swift
struct RuleDTO: Codable {
    let id: UUID
    let title: String
    let body: String
    let sourceURL: String?
    let isArchived: Bool
    let createdAt: Date
    let domainID: UUID?
}
```

**Schema version guard** (lines 150-152):
```swift
guard bundle.schemaVersion == schemaVersion else {
    throw ImportError.unsupportedSchema(bundle.schemaVersion)
}
```

**Export mapping pattern** (lines 132-142):
```swift
rules: rules.map {
    RuleDTO(
        id: $0.id,
        title: $0.title,
        ...
        domainID: $0.domain?.id
    )
}
```

**Import reconstruction pattern with id→model index** (lines 173-186):
```swift
var ruleIndex: [UUID: Rule] = [:]
for dto in bundle.rules {
    let rule = Rule(id: dto.id, title: dto.title, ...)
    context.insert(rule)
    ruleIndex[dto.id] = rule
}
```

**Apply for Phase 3:**
1. Bump `private let schemaVersion = 3` → `4`
2. Add `CollectionDTO` and `CollectionItemDTO` Codable structs — scalar fields only (`statusSetID`, `statusIndex`, `sortIndex`, `progressTemplate`, `showsAggregate`, `note?`, `sourceURL?`, `cost?`, `season`, `episode`, `counterValue`, `counterLabel?`, `isSeeded`, `seedVersion`, `domainID?` on CollectionDTO, `collectionID?` on CollectionItemDTO)
3. Add `collections: [CollectionDTO]` and `collectionItems: [CollectionItemDTO]` to `HabitExportBundle`
4. Extend `exportData(...)` signature to include `collections: [Collection], collectionItems: [CollectionItem]`
5. Extend `importReplace` with a new reconstruction block — build collection index (`[UUID: Collection]`) before building items, wire `collectionItem.collection` via the index (mirrors rule→domain wiring)
6. Extend `deleteAll` to include `try context.delete(model: CollectionItem.self)` and `try context.delete(model: Collection.self)` **before** deleting Domain (owns them via cascade)

---

### `HabitsTrackerApp.swift` (edit)

**Analog:** `HabitsTrackerApp.swift` (self, lines 14-20)

**Container registration pattern** (lines 14-20):
```swift
.modelContainer(for: [
    Domain.self,
    Habit.self,
    DailyEntry.self,
    HabitState.self,
    Rule.self
])
```

**Apply:** Append `Collection.self` and `CollectionItem.self` to the array. No `migrationPlan:` argument — plan-less inferred migration (D-21, CLAUDE.md §9.12).

```swift
.modelContainer(for: [
    Domain.self,
    Habit.self,
    DailyEntry.self,
    HabitState.self,
    Rule.self,
    Collection.self,
    CollectionItem.self
])
```

---

### `Features/Hub/DomainDetailView.swift` (edit)

**Analog:** `Features/Hub/DomainDetailView.swift` (self)

**Section-loop hook pattern** (lines 64-74):
```swift
private func nonEmptySections(theme: Theme) -> [DomainSection] {
    var sections: [DomainSection] = []

    // Phase B: Rules section (RULE-01)
    if let rulesSection = buildRulesSection(theme: theme) {
        sections.append(rulesSection)
    }

    // Phase C–E: append Collections / Clips / Ideas sections here.
    return sections
}
```

**Rules section builder pattern** (lines 78-87):
```swift
private func buildRulesSection(theme: Theme) -> DomainSection? {
    let activeRules = domain.rules
        .filter { !$0.isArchived }
        .sorted { $0.createdAt > $1.createdAt }

    guard !activeRules.isEmpty else { return nil }

    let content = AnyView(rulesSectionContent(rules: activeRules, theme: theme))
    return DomainSection(id: "rules", title: "Rules", content: content)
}
```

**Section header pattern** (lines 109-127 — `rulesSectionHeader`):
```swift
HStack(alignment: .center) {
    Text("Rules")
        .font(theme.typography.title)
        .foregroundStyle(theme.colors.textPrimary)
        .accessibilityAddTraits(.isHeader)

    Spacer()

    Button {
        creatingRule = true
    } label: {
        Image(systemName: "plus")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(theme.colors.accentPrimary)
            .frame(minWidth: 44, minHeight: 44)
    }
    .accessibilityLabel("Add rule to \(domain.name)")
}
```

**NavigationLink row pattern** (lines 97-103):
```swift
NavigationLink {
    RuleDetailView(rule: rule)
} label: {
    RuleRow(rule: rule)
}
.buttonStyle(.plain)
```

**Apply for Collections section:**
- Add `@State private var creatingCollection = false` alongside existing `@State private var creatingRule`
- Add `buildCollectionsSection(theme:)` using the same nil-guard pattern — guard: `!domain.collections.isEmpty` (D-15). Sort by `sortIndex` ascending.
- Collections section header uses `accessibilityLabel("Add collection to \(domain.name)")`
- Row: `CollectionRow(collection: collection)` inside `NavigationLink { CollectionDetailView(collection: collection) }`
- Append to `nonEmptySections` after the rules block: `if let s = buildCollectionsSection(theme: theme) { sections.append(s) }`
- Sheet: `.sheet(isPresented: $creatingCollection) { CollectionPresetPickerSheet(domain: domain) }`

---

### `Features/Collections/CollectionRow.swift` (component, request-response)

**Analog:** `Features/Rules/RuleRow.swift`

**Full file pattern** (RuleRow.swift lines 1-62):
```swift
import SwiftUI
import DesignKit

struct RuleRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let rule: Rule

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        DKCard(theme: theme) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(rule.title)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                if let secondary = secondaryLine {
                    Text(secondary)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
    ...
}
```

**Apply to CollectionRow:** Nearly identical shape. Replace the secondary line with:
- StatusSet sub-label from `StatusSetCatalog` (e.g. `"Shows — watched"`)
- Trailing rollup `HStack` (D-17): when `showsAggregate == true`, show `"X/Y"` in `caption/textSecondary` or `"$NNN"` in `monoNumber/textSecondary`. Use `CollectionRollupEngine.rollup(...)` to compute.

The row body becomes an `HStack` (leading VStack + Spacer + trailing rollup) rather than a plain `VStack`. Accessibility label: `"\(collection.name), \(itemCount) items\(rollupText)"`.

---

### `Features/Collections/CollectionPresetPickerSheet.swift` (component, request-response)

**Analog:** `Features/Rules/RuleEditorView.swift`

**Sheet scaffold pattern** (RuleEditorView.swift lines 64-101):
```swift
var body: some View {
    let theme = themeManager.theme(for: colorScheme)

    NavigationStack {
        Form {
            ...
        }
        .scrollContentBackground(.hidden)
        .background(theme.colors.background)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                saveCTAButton(theme: theme)
            }
        }
    }
}
```

**Apply to CollectionPresetPickerSheet:** Takes `domain: Domain`. Presents a `NavigationStack` sheet with title `"Choose a type"`. Toolbar has only a cancel button (no confirm — tapping a preset row creates + dismisses). Body is a `List` or `VStack` of preset rows from `CollectionPresetCatalog.all`. Each row tap:
1. Creates a `Collection` from the preset via `modelContext.insert(...)`
2. Sets `collection.domain = domain`, `collection.sortIndex`, etc.
3. `try? modelContext.save()`
4. `dismiss()`

Needs `@Environment(\.modelContext)` and `@Environment(\.dismiss)` — same as `RuleEditorView`.

---

### `Features/Collections/CollectionDetailView.swift` (component, request-response)

**Analog:** `Features/Rules/RuleDetailView.swift`

**Detail view scaffold** (RuleDetailView.swift lines 16-68):
```swift
struct RuleDetailView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    let rule: Rule

    @State private var editingRule = false

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                headerBlock(theme: theme)
                // conditional blocks...
            }
            .padding(theme.spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { editingRule = true }
                    .foregroundStyle(theme.colors.accentPrimary)
            }
        }
        .sheet(isPresented: $editingRule) {
            RuleEditorView(rule: rule)
        }
    }
    ...
}
```

**Header block pattern** (lines 73-97):
```swift
private func headerBlock(theme: Theme) -> some View {
    HStack(alignment: .top, spacing: theme.spacing.m) {
        if let domain = rule.domain {
            Image(systemName: domain.iconName)
                .font(.system(size: 28))
                .foregroundStyle(
                    HabitsTracker.accentColor(forToken: domain.colorToken, scheme: colorScheme)
                )
                .accessibilityHidden(true)
        }
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(rule.title)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
        }
    }
}
```

**Source URL block pattern** (lines 118-154):
```swift
Link(destination: url) {
    HStack(spacing: theme.spacing.s) {
        Image(systemName: "link")
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.textPrimary)
            .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(host).font(theme.typography.body).foregroundStyle(theme.colors.textPrimary)
            Text(urlString).font(theme.typography.caption).foregroundStyle(theme.colors.textSecondary).lineLimit(1)
        }
        Spacer()
    }
    .padding(theme.spacing.m)
    .background(theme.colors.surface)
    .cornerRadius(theme.radii.card)
    .overlay(RoundedRectangle(cornerRadius: theme.radii.card).stroke(theme.colors.border, lineWidth: 1))
    .frame(minHeight: 44)
}
.accessibilityLabel("Open source link, \(host)")
```

**Apply to CollectionDetailView:** Block ordering: header (domain glyph + name + rollup + StatusSet sub-label), items `ForEach` with `CollectionItemRow` in `NavigationLink`, empty state. Toolbar: `"+"` to add item, optional `"Edit"` for collection settings. Rollup renders `DKProgressRing` (completionist) or `"$NNN"` text (cost). Empty state uses the UI-SPEC copy.

---

### `Features/Collections/CollectionItemRow.swift` (component, request-response)

**Analog:** `Features/Rules/RuleRow.swift`

**DKCard + VStack + accessibilityElement pattern** (RuleRow.swift lines 19-37):
```swift
DKCard(theme: theme) {
    VStack(alignment: .leading, spacing: theme.spacing.xs) {
        Text(rule.title)
            .font(theme.typography.headline)
            .foregroundStyle(theme.colors.textPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.9)
        ...
    }
    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
}
.accessibilityElement(children: .ignore)
.accessibilityLabel(accessibilityLabel)
```

**Apply to CollectionItemRow:** `DKCard` with `HStack`:
- Leading `VStack`: item title (`headline/textPrimary`, 2 lines), compact position label (caption/textSecondary, conditional on `progressTemplate`)
- Trailing: `DKBadge(statusLabel, theme: theme)` as the status chip

Status chip has `.onTapGesture` (advance `statusIndex`, clamp at terminal, D-06), `.contextMenu { Button("Reset", role: .destructive) {...} }` (D-07), `.sensoryFeedback(.impact(.light), trigger: statusIndex)` (D-08).

Accessibility: `.accessibilityElement(children: .ignore)` on row container; compose single label per UI-SPEC S4.

**Note:** `CollectionItemRow` takes both `item: CollectionItem` and `collection: Collection` (to resolve the StatusSet and access `showsAggregate`). Owns no query (§9.2).

---

### `Features/Collections/CollectionItemDetailView.swift` (component, request-response)

**Analog:** `Features/Rules/RuleDetailView.swift`

Same `ScrollView + VStack(spacing: theme.spacing.xl)` block structure. Block ordering per UI-SPEC S5:
1. Status block — always (large `DKBadge` chip with same tap/reset/VoiceOver as S4)
2. Position controls block — conditional on `progressTemplate != .none`
3. Metadata block — note, URL, cost (each omitted when nil/empty; URL uses the `sourceBlock` pattern from `RuleDetailView` lines 118-154 verbatim)

**Toolbar:** trailing `"Edit"` → `CollectionItemEditorSheet(item: item)` as sheet. Same toolbar pattern as `RuleDetailView` lines 52-65.

Position display (read-only, `theme.typography.title`) sits above buttons. Buttons follow `RuleDetailView`'s `stemButton` CTA style but are bordered surface buttons rather than filled primary:
```swift
// From RuleDetailView stemButton:
Text("Stem habit")
    .font(theme.typography.headline)
    .foregroundStyle(theme.colors.background)
    .frame(maxWidth: .infinity, minHeight: 44)
    .background(theme.colors.accentPrimary)
    .cornerRadius(theme.radii.button)
```
Position control buttons use `theme.colors.surface` background + `theme.colors.border` stroke (bordered style, not filled) per UI-SPEC S5.

---

### `Features/Collections/CollectionItemEditorSheet.swift` (component, request-response)

**Analog:** `Features/Rules/RuleEditorView.swift`

**Exact structural match.** Copy the two-mode (`create`/`edit`) `EditorMode` enum pattern, the `@State` field vars initialized via `init(collection: Collection)` / `init(item: CollectionItem)`, the `NavigationStack` + `Form` + `.scrollContentBackground(.hidden)` scaffold, the cancel/save toolbar pattern, the `confirmationDialog` pattern for delete, and the `trimmedTitle` guard.

**Create mode pattern** (lines 262-269):
```swift
case .create:
    let rule = Rule(title: trimmed, body: bodyText, sourceURL: storedURL, domain: resolvedDomain())
    modelContext.insert(rule)
```

**Edit mode pattern** (lines 271-275):
```swift
case .edit(let rule):
    rule.title = trimmed
    rule.body = bodyText
    rule.sourceURL = storedURL
    rule.domain = resolvedDomain()
```

**Delete dialog pattern** (lines 200-226):
```swift
.confirmationDialog(deleteDialogTitle, isPresented: $showDeleteConfirm, titleVisibility: .visible) {
    Button("Delete Rule", role: .destructive) {
        if case .edit(let rule) = editorMode {
            modelContext.delete(rule)
            try? modelContext.save()
            dismiss()
        }
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This can't be undone.")
}
```

**Apply for CollectionItemEditorSheet:** Fields are `title`, `note` (TextEditor), `sourceURL` (`.keyboardType(.URL)`), `cost` (`.keyboardType(.decimalPad)`). Save CTAs: `"Add Item"` / `"Save Changes"` (never bare "Save"). Delete triggers `modelContext.delete(item)` — cascade removes from collection automatically. Delete confirmation copy is from UI-SPEC copywriting contract.

---

## Shared Patterns

### DesignKit Token Access (all view files)
**Source:** `Features/Hub/DomainDetailView.swift`, `Features/Rules/RuleRow.swift`
**Apply to:** All 7 new view/component files
```swift
@EnvironmentObject private var themeManager: ThemeManager
@Environment(\.colorScheme) private var colorScheme

var body: some View {
    let theme = themeManager.theme(for: colorScheme)
    // All spacing/color/typography/radii from theme.*
}
```

### Domain Accent Color (detail views + CollectionRow)
**Source:** `Features/Rules/RuleDetailView.swift` lines 78-81
**Apply to:** `CollectionDetailView` header (domain glyph tint only — exhaustive per UI-SPEC Color section)
```swift
HabitsTracker.accentColor(forToken: domain.colorToken, scheme: colorScheme)
```

### 44pt Minimum Tap Target (all interactive elements)
**Source:** `Features/Hub/DomainDetailView.swift` line 123; `Features/Rules/RuleRow.swift` line 33
**Apply to:** Every button, row, and chip across all 7 new view files
```swift
.frame(minWidth: 44, minHeight: 44)
// or on content container:
.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
```

### SwiftData Model Context (editor sheets + SeedDataService)
**Source:** `Features/Rules/RuleEditorView.swift` lines 18-19
**Apply to:** `CollectionPresetPickerSheet`, `CollectionItemEditorSheet`
```swift
@Environment(\.dismiss) private var dismiss
@Environment(\.modelContext) private var modelContext
```

### Confirmation Dialog for Destructive Action
**Source:** `Features/Rules/RuleEditorView.swift` lines 91-99
**Apply to:** `CollectionItemEditorSheet` (delete item), collection-level delete
```swift
.confirmationDialog(title, isPresented: $showDeleteConfirm, titleVisibility: .visible) {
    Button("Delete Item", role: .destructive) { ... }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This can't be undone.")
}
```

### Pure Engine Pattern (os.Logger constraint)
**Source:** `Services/StreakEngine.swift`, `Services/WeeklyGoalEngine.swift`
**Apply to:** `CollectionRollupEngine`, `StatusSetCatalog`, `CollectionPresetCatalog`
- No `print()` / `debugPrint()` calls (§9.13 — codebase is at zero raw prints)
- `nonisolated static func` on all engine methods
- `import Foundation` only — never DesignKit or SwiftData in a pure engine

### In-Memory Schema for Tests
**Source:** `HabitsTrackerTests/RuleModelTests.swift` lines 11-17, `HabitsTrackerTests/ExportImportTests.swift` lines 14-18
**Apply to:** `CollectionModelTests.swift`
```swift
@MainActor
private func makeInMemoryContext() throws -> ModelContext {
    let schema = Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self, Rule.self,
                         Collection.self, CollectionItem.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    return container.mainContext
}
```

### Export/Import schemaVersion Guard
**Source:** `Services/ExportImportService.swift` lines 150-152
**Apply to:** ExportImportService edit — bump to `4`, guard is unchanged
```swift
guard bundle.schemaVersion == schemaVersion else {
    throw ImportError.unsupportedSchema(bundle.schemaVersion)
}
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none — all files have analogs) | — | — | — |

The closest "no prior art" situation is the tap-to-advance status chip behavior inside `CollectionItemRow`. There is no existing interactive chip in the codebase. The chip renders as `DKBadge` (existing component) but the `.onTapGesture` + `.contextMenu` + `.sensoryFeedback` combination is new to this phase. Planner should reference UI-SPEC S4 interaction contract and D-06/D-07/D-08 directly for that specific sub-pattern.

---

## Metadata

**Analog search scope:** `HabitsTracker/Models/`, `HabitsTracker/Services/`, `HabitsTracker/Features/Rules/`, `HabitsTracker/Features/Hub/`, `HabitsTrackerApp.swift`, `HabitsTrackerTests/`
**Files read:** 14 source files + 3 test files
**Pattern extraction date:** 2026-07-05
