# Phase 4: Clips (D) - Pattern Map

**Mapped:** 2026-07-08
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `HabitsTracker/Models/Clip.swift` (new) | model | CRUD | `HabitsTracker/Models/Rule.swift` | exact |
| `HabitsTracker/Models/Domain.swift` (edit — add `clips` inverse) | model | CRUD | same file, existing `rules`/`collections` relationships | exact |
| `HabitsTracker/Features/Clips/ClipRow.swift` (new) | component | request-response | `HabitsTracker/Features/Collections/CollectionItemRow.swift` (chip tap) + `HabitsTracker/Features/Rules/RuleRow.swift` (card shape) | exact (composite) |
| `HabitsTracker/Features/Clips/ClipDetailView.swift` (new) | component | request-response | `HabitsTracker/Features/Rules/RuleDetailView.swift` (header/link block) + `HabitsTracker/Features/Collections/CollectionItemDetailView.swift` (status chip block) | exact (composite) |
| `HabitsTracker/Features/Clips/ClipEditorView.swift` (new) | component (form) | CRUD | `HabitsTracker/Features/Rules/RuleEditorView.swift` | exact |
| `HabitsTracker/Features/Hub/DomainDetailView.swift` (edit — append Clips section) | controller/component | request-response | same file, `buildCollectionsSection`/`collectionsSectionContent`/`collectionsSectionHeader` trio | exact |
| `HabitsTracker/Utilities/ClipTitleSuggestion.swift` (new, D-02 pure helper) | utility | transform | `HabitsTracker/Services/CollectionRollupEngine.swift` (pure static-func enum service) | role-match |
| `HabitsTracker/Services/ExportImportService.swift` (edit — schemaVersion 4→5, `ClipDTO`, export/import/deleteAll) | service | batch (file I/O) | same file, existing `Rule`/`RuleDTO` round-trip block | exact |
| `HabitsTracker/HabitsTrackerApp.swift` (edit — register `Clip.self`) | config | — | same file, `.modelContainer(for:[…])` list | exact |
| `HabitsTracker/Features/Settings/SettingsView.swift` (edit — pass `clips` into `exportData(...)`) | controller | request-response | same file, existing `exportData(categories:habits:entries:rules:collections:collectionItems:)` call site | exact |
| `HabitsTrackerTests/ClipTitleSuggestionTests.swift` (new) | test | transform | `HabitsTrackerTests/CollectionRollupEngineTests.swift` | exact |
| `HabitsTrackerTests/ClipModelTests.swift` (new, build-verify only per §9.7) | test | CRUD | `HabitsTrackerTests/RuleModelTests.swift` | exact |

## Pattern Assignments

### `HabitsTracker/Models/Clip.swift` (model, CRUD)

**Analog:** `HabitsTracker/Models/Rule.swift` (full file, 38 lines — read in one pass)

**Full pattern to mirror** (`HabitsTracker/Models/Rule.swift:1-38`):
```swift
import Foundation
import SwiftData

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
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.sourceURL = sourceURL
        self.domain = domain
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.stemmedHabits = stemmedHabits
    }
}
```

**Apply to `Clip`:** same shape — `@Attribute(.unique) id`, scalar `title`/`url`/`note?`/`tag?`, a `status` field storing `ClipStatus.rawValue` as `String` (D-03: `enum ClipStatus: String { case saved, acted }` — define alongside `Clip.swift` or in `HabitEnums.swift`-style scoping; see `HabitsTracker/Models/HabitEnums.swift` for the house raw-string-enum idiom used by `Habit.scheduleTypeRaw`/`modeRaw`), `isArchived: Bool = false` (D-11), `createdAt: Date = .now`, and `@Relationship var domain: Domain?` (single, non-cascading, `.nullify` owned from the `Domain` side exactly like `Rule.domain` — no `deleteRule:` annotation needed on the `Clip` side itself, matching `Rule.domain`). All new fields optional or defaulted per §9.12/D-12 (inferred lightweight migration).

**No cascade/stem-style relationship needed** — Clip has no dependents (D-11: "no stem-style dependents to protect"), so omit the `stemmedHabits`-equivalent array entirely; `Clip` is a simpler leaf model than `Rule`.

---

### `HabitsTracker/Models/Domain.swift` (model, CRUD — edit)

**Analog:** same file, existing `rules`/`collections` inverse relationships (`HabitsTracker/Models/Domain.swift:15-23` and init `33-47`)

**Pattern to mirror** (add a third inverse relationship, same idiom):
```swift
@Relationship(deleteRule: .nullify, inverse: \Rule.domain)
var rules: [Rule] = []

@Relationship(deleteRule: .nullify, inverse: \Collection.domain)
var collections: [Collection] = []
```

**Apply to Clip:** add `@Relationship(deleteRule: .nullify, inverse: \Clip.domain) var clips: [Clip] = []` immediately below `collections`, plus a matching `clips: [Clip] = []` parameter in `init(...)` and `self.clips = clips` assignment (mirror the existing `rules`/`collections` init wiring verbatim).

---

### `HabitsTracker/Features/Clips/ClipRow.swift` (component, request-response)

**Analogs:** `HabitsTracker/Features/Rules/RuleRow.swift` (card shape, secondary caption line) for structure; `HabitsTracker/Features/Collections/CollectionItemRow.swift` (chip tap-to-toggle + sensory feedback) for the trailing status chip behavior.

**Card shape + secondary line** (`RuleRow.swift:16-37`):
```swift
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
```
Apply: leading `VStack` = clip title (headline, 2-line cap, `.minimumScaleFactor(0.9)`) + optional caption line showing `tag` (per UI-SPEC S1). Wrap in an `HStack` (not the Rule's plain `VStack`) with `Spacer()` + trailing chip, per UI-SPEC S1 layout.

**Tap-to-toggle chip + sensory feedback** (`CollectionItemRow.swift:48-64`, adapt from tap-to-*advance* to tap-to-*toggle*):
```swift
DKBadge(statusLabel, theme: theme)
    .frame(minWidth: 44, minHeight: 44)
    .onTapGesture {
        tapCounter += 1
        let newIndex = min(item.statusIndex + 1, terminalIndex)
        if item.statusIndex != newIndex {
            item.statusIndex = newIndex
        }
    }
    .contextMenu {
        Button("Reset", role: .destructive) {
            item.statusIndex = 0
        }
    }
    .sensoryFeedback(.impact(weight: .light), trigger: tapCounter)
```
Apply to Clip (D-05, plain 2-way toggle — no contextMenu/reset needed, unlike Collections' clamped terminal): `.onTapGesture { clip.status = clip.status == .saved ? .acted : .saved }` with `.sensoryFeedback(.impact(.light), trigger: <tap counter or status>)` firing on every tap. `statusLabel` = `"Saved"` / `"Acted"` computed from `clip.status`.

**Accessibility label composition** (`RuleRow.swift:55-61`, adapt):
```swift
private var accessibilityLabel: String {
    var label = "\(rule.title), rule"
    let stemCount = rule.stemmedHabits.count
    if stemCount > 0 { label += ", stemmed \(stemCount) habit\(stemCount == 1 ? "" : "s")" }
    if rule.sourceURL != nil { label += ", has link" }
    return label
}
```
Apply: `"\(clip.title), status: \(statusLabel)\(tagSuffix)"` per UI-SPEC S1 accessibility contract.

---

### `HabitsTracker/Features/Clips/ClipDetailView.swift` (component, request-response)

**Analogs:** `HabitsTracker/Features/Rules/RuleDetailView.swift` (header block + toolbar Edit wiring + bordered link block, upgraded to CTA per D-08) and `HabitsTracker/Features/Collections/CollectionItemDetailView.swift` (status chip block pattern, metadata block conditionals).

**Data-driven shell, no NavigationStack, toolbar Edit** (`RuleDetailView.swift:16-69`):
```swift
struct RuleDetailView: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    let rule: Rule
    @State private var editingRule = false

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                headerBlock(theme: theme)
                if !rule.body.isEmpty { bodyBlock(theme: theme) }
                if rule.sourceURL != nil { sourceBlock(theme: theme) }
                stemButton(theme: theme)
                if !rule.stemmedHabits.isEmpty { stemmedBlock(theme: theme) }
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
        .sheet(isPresented: $editingRule) { RuleEditorView(rule: rule) }
    }
}
```
Apply: `ClipDetailView(clip: Clip)`, `@State private var editingClip = false`, block order per UI-SPEC S2 = Header → Status/Tag → Open Link (CTA) → Note (conditional). `.sheet(isPresented: $editingClip) { ClipEditorView(clip: clip) }`.

**Header block with domain glyph** (`RuleDetailView.swift:73-103`) — reuse verbatim shape, optional per D-08's UI-SPEC discretion note (executor decides whether to include the domain glyph).

**Status chip block** (`CollectionItemDetailView.swift:57-87`, adapt to 2-way toggle, drop contextMenu/reset):
```swift
private func statusBlock(theme: Theme) -> some View {
    ...
    DKBadge(statusLabel, theme: theme)
        .frame(minWidth: 44, minHeight: 44)
        .onTapGesture {
            chipTapCounter += 1
            let newIndex = min(item.statusIndex + 1, terminalIndex)
            if item.statusIndex != newIndex { item.statusIndex = newIndex }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: chipTapCounter)
        .accessibilityLabel("Status: \(statusLabel), \(item.title)")
}
```
Apply: same tap target/sensory-feedback shape, toggle logic is `clip.status.toggle()`-equivalent (2-way), no `.contextMenu`/no `.accessibilityAction("Reset status")` (D-05 — plain 2-way, no reset gesture needed).

**Bordered Link block, upgraded to primary CTA button per D-08** — base pattern (`RuleDetailView.swift:117-154`, bordered variant) plus the CTA visual treatment from `RuleDetailView.swift:158-170` (`stemButton`, the "Stem habit" full-width primary button):
```swift
// Bordered link affordance base (RuleDetailView.swift:123-153):
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

// Full-width primary CTA treatment (RuleDetailView.swift:158-170):
Button {
    stemming = true
} label: {
    Text("Stem habit")
        .font(theme.typography.headline)
        .foregroundStyle(theme.colors.background)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(theme.colors.accentPrimary)
        .cornerRadius(theme.radii.button)
}
.accessibilityLabel("Stem habit from this rule")
```
Apply per UI-SPEC S2 Block 4: use `Link(destination: url) { Text("Open Link") ... }` styled with the CTA treatment (`accentPrimary` background, `theme.colors.background` foreground, `theme.radii.button`, full-width, ≥44pt) — NOT the plain bordered-card treatment. `accessibilityLabel("Open link, \(host)")`.

**Metadata block (Note, conditional)** — mirror `CollectionItemDetailView.swift:180-192` note block exactly (label caption + body value + `.textSelection(.enabled)`).

---

### `HabitsTracker/Features/Clips/ClipEditorView.swift` (component/form, CRUD)

**Analog:** `HabitsTracker/Features/Rules/RuleEditorView.swift` (full file, 282 lines — read in one pass)

**Mode enum + field state + init pattern** (`RuleEditorView.swift:16-60`):
```swift
private enum EditorMode {
    case create(domain: Domain)
    case edit(rule: Rule)
}
private let editorMode: EditorMode

@State private var title: String
@State private var bodyText: String
@State private var sourceURLText: String
@State private var selectedDomainID: UUID?
@State private var showDeleteConfirm = false

init(domain: Domain) {
    self.editorMode = .create(domain: domain)
    _title = State(initialValue: "")
    _bodyText = State(initialValue: "")
    _sourceURLText = State(initialValue: "")
    _selectedDomainID = State(initialValue: domain.id)
}

init(rule: Rule) {
    self.editorMode = .edit(rule: rule)
    _title = State(initialValue: rule.title)
    _bodyText = State(initialValue: rule.body)
    _sourceURLText = State(initialValue: rule.sourceURL ?? "")
    _selectedDomainID = State(initialValue: rule.domain?.id)
}
```
Apply: `ClipEditorView(domain:)` / `ClipEditorView(clip:)`, fields `urlText`, `title`, `noteText`, `tagText`, `selectedDomainID`, plus a `titleWasManuallyEdited: Bool` flag (D-02 wiring — not present in Rule, new state specific to Clip's title-suggestion feature).

**Form body + toolbar + confirmationDialog shell** (`RuleEditorView.swift:64-101`) — copy verbatim shape: `NavigationStack { Form { ...sections... } }.scrollContentBackground(.hidden).background(theme.colors.background).navigationTitle(...).toolbar { cancellationAction / confirmationAction }.confirmationDialog(...)`.

**Title field + validation hint section** (`RuleEditorView.swift:105-119`):
```swift
private func titleSection(theme: Theme) -> some View {
    Section {
        TextField("Rule title", text: $title)
            .font(theme.typography.body)
        if trimmedTitle.isEmpty {
            Text("Give this a name to continue.")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
        }
    } header: {
        Text("Title").font(theme.typography.headline)
    }
}
```
Apply verbatim (copy "Give this a name to continue." per UI-SPEC copy contract), but wire `.onChange`/direct edit to set `titleWasManuallyEdited = true` (D-02).

**URL field section** (`RuleEditorView.swift:132-143`, `sourceURLSection`):
```swift
private func sourceURLSection(theme: Theme) -> some View {
    Section {
        TextField("https://example.com", text: $sourceURLText)
            .font(theme.typography.body)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    } header: {
        Text("Source URL").font(theme.typography.headline)
    }
}
```
Apply verbatim shape for the required `URL` field (header "URL" not "Source URL"); wire `.onChange(of: urlText)` to call `ClipTitleSuggestion.suggest(from:)` and populate `title` only when `!titleWasManuallyEdited` (D-02).

**Domain picker section** (`RuleEditorView.swift:145-158`):
```swift
private func domainSection(theme: Theme) -> some View {
    Section {
        Picker("Domain", selection: $selectedDomainID) {
            Text("None").tag(UUID?.none)
            ForEach(domains, id: \.id) { domain in
                Text(domain.name).tag(UUID?.some(domain.id))
            }
        }
        .font(theme.typography.body)
    } header: {
        Text("Domain").font(theme.typography.headline)
    }
}
```
Apply: if `Clip.domain` ends up non-optional (UI-SPEC Open Item 5), drop the `"None"` row and default-select the passed-in domain with no clear option — otherwise copy verbatim.

**Delete with confirmationDialog** (`RuleEditorView.swift:176-227`) — copy the `deleteSection`/`deleteDialogTitle`/`deleteDialogActions`/`deleteDialogMessage` shape; Clip's dialog message is always `"This can't be undone."` (no stem-count branch needed — D-11, no dependents) per UI-SPEC copy contract ("Delete this clip?" / "This can't be undone." / "Delete Clip" / "Cancel").

**Save function + disabled-until-valid CTA** (`RuleEditorView.swift:191-280`) — copy `saveCTAButton`/`saveRule()` shape; Clip's CTA disabled condition is `trimmedTitle.isEmpty || trimmedURL.isEmpty` (both required per UI-SPEC, vs. Rule's title-only gate).

---

### `HabitsTracker/Features/Hub/DomainDetailView.swift` (edit — append Clips section)

**Analog:** same file — the `buildCollectionsSection` / `collectionsSectionContent` / `collectionsSectionHeader` trio (`DomainDetailView.swift:140-186`), which is itself modeled on `buildRulesSection`/`rulesSectionContent`/`rulesSectionHeader` (`87-136`).

**Full trio to mirror** (`DomainDetailView.swift:140-186`):
```swift
private func buildCollectionsSection(theme: Theme) -> DomainSection? {
    let sorted = domain.collections.sorted { $0.sortIndex < $1.sortIndex }
    guard !domain.collections.isEmpty else { return nil }
    let content = AnyView(collectionsSectionContent(collections: sorted, theme: theme))
    return DomainSection(id: "collections", title: "Collections", content: content)
}

@ViewBuilder
private func collectionsSectionContent(collections: [Collection], theme: Theme) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.m) {
        collectionsSectionHeader(theme: theme)
        ForEach(collections, id: \.id) { collection in
            NavigationLink {
                CollectionDetailView(collection: collection)
            } label: {
                CollectionRow(collection: collection)
            }
            .buttonStyle(.plain)
        }
    }
}

private func collectionsSectionHeader(theme: Theme) -> some View {
    HStack(alignment: .center) {
        Text("Collections")
            .font(theme.typography.title)
            .foregroundStyle(theme.colors.textPrimary)
            .accessibilityAddTraits(.isHeader)
        Spacer()
        Button {
            creatingCollection = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.colors.accentPrimary)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("Add collection to \(domain.name)")
    }
}
```

**Apply for Clips** (insert at the `// Phase D–E: append Clips / Ideas sections here.` hook, `DomainDetailView.swift:81`):
1. Add `@State private var creatingClip = false` near `creatingCollection` (line 29).
2. Add `.sheet(isPresented: $creatingClip) { ClipEditorView(domain: domain) }` beside the existing `.sheet` modifiers (~line 58-60).
3. In `nonEmptySections(theme:)`, append:
   ```swift
   if let clipsSection = buildClipsSection(theme: theme) {
       sections.append(clipsSection)
   }
   ```
4. Add `buildClipsSection`/`clipsSectionContent`/`clipsSectionHeader`, filtering `domain.clips` to non-archived (D-10 — mirrors Rules' `.filter { !$0.isArchived }` at line 89, since Collections has no archive flag but Clips does), sorted by `createdAt` descending (UI-SPEC S1 ordering, matches `RuleRow`'s recency-first), `NavigationLink { ClipDetailView(clip: clip) } label: { ClipRow(clip: clip) }`, header title `"Clips"`, "+" button `accessibilityLabel("Add clip to \(domain.name)")`.

**Section-visibility filter analog** (`buildRulesSection`, line 87-96, closer match than Collections since it also filters `isArchived`):
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
Use this shape (isArchived filter + createdAt-descending sort) for `buildClipsSection`, not the Collections shape (which has no archive filter, sorts by `sortIndex`).

---

### `HabitsTracker/Utilities/ClipTitleSuggestion.swift` (new, D-02 pure helper)

**Analog:** `HabitsTracker/Services/CollectionRollupEngine.swift` — a pure `enum` namespace with a single `nonisolated static func`, no I/O, no SwiftData dependency beyond value types passed as arguments.

**Shape to mirror** (`CollectionRollupEngine.swift:1-14, 26`):
```swift
import Foundation

enum CollectionRollupEngine {
    enum Result: Equatable {
        case count(x: Int, y: Int)
        case costSum(total: Double)
        case none
    }

    nonisolated static func rollup(collection: Collection, items: [CollectionItem]) -> Result {
        ...
    }
}
```
Apply: `enum ClipTitleSuggestion { nonisolated static func suggest(from urlString: String) -> String { ... } }` — pure `URLComponents`/string parsing (host and/or last path slug per D-02), graceful fallback to `""` on malformed/no-scheme input (per the mandated test matrix). Lives in `Utilities/` (not `Services/`) since it has no SwiftData/model dependency at all — closer to `Utilities/AccentTokenColor.swift`'s pure-transform role than to the engine services, but the enum-namespace-with-static-func shape is identical to `CollectionRollupEngine`.

---

### `HabitsTracker/Services/ExportImportService.swift` (edit — schemaVersion 4→5, `ClipDTO`, round-trip)

**Analog:** same file, existing `Rule`/`RuleDTO` round-trip (closest — single-owner-relationship model, same shape as `Clip`).

**DTO shape to mirror** (`ExportImportService.swift:26-34`):
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
Apply: `struct ClipDTO: Codable { let id: UUID; let title: String; let url: String; let note: String?; let tag: String?; let status: String; let isArchived: Bool; let createdAt: Date; let domainID: UUID? }` (D-13 — `status` as raw `String`). Add `let clips: [ClipDTO]` to `HabitExportBundle` (line 4-13).

**Export mapping to mirror** (`ExportImportService.swift:171-181`):
```swift
rules: rules.map {
    RuleDTO(
        id: $0.id,
        title: $0.title,
        body: $0.body,
        sourceURL: $0.sourceURL,
        isArchived: $0.isArchived,
        createdAt: $0.createdAt,
        domainID: $0.domain?.id
    )
},
```
Apply the same `.map { ClipDTO(...) }` shape; add a `clips: [Clip]` parameter to `exportData(...)`'s signature (line 114-121) alongside `rules:`/`collections:`.

**Import/wiring mapping to mirror** (`ExportImportService.swift:244-258`):
```swift
var ruleIndex: [UUID: Rule] = [:]
for dto in bundle.rules {
    let rule = Rule(
        id: dto.id,
        title: dto.title,
        body: dto.body,
        sourceURL: dto.sourceURL,
        domain: dto.domainID.flatMap { categoryIndex[$0] },
        isArchived: dto.isArchived,
        createdAt: dto.createdAt
    )
    context.insert(rule)
    ruleIndex[dto.id] = rule
}
```
Apply the identical shape for `Clip` (no index map needed unless a future type references clips by id — none does today). Insert this block in `importReplace(...)` near the other leaf-owned-by-domain types (Rules/Collections), reconstructing `ClipStatus(rawValue: dto.status) ?? .saved` defensively (mirrors `HabitScheduleType(rawValue:) ?? .daily` fallback idiom at line 267).

**`deleteAll` ordering to mirror** (`ExportImportService.swift:350-359`):
```swift
private func deleteAll(context: ModelContext) throws {
    try context.delete(model: HabitState.self)
    try context.delete(model: DailyEntry.self)
    try context.delete(model: Habit.self)
    try context.delete(model: Rule.self)
    // Items before collections before domain (ownership order — T-03-10).
    try context.delete(model: CollectionItem.self)
    try context.delete(model: Collection.self)
    try context.delete(model: Domain.self)
    try context.save()
}
```
Apply: add `try context.delete(model: Clip.self)` alongside `Rule.self`/`CollectionItem.self` (before `Domain.self`, since `Clip.domain` is `.nullify` not owned by cascade — order relative to Domain matters, not relative to Rule/Collection).

**Bump `schemaVersion`** (`ExportImportService.swift:98`): `private let schemaVersion = 4` → `5` (D-13).

---

### `HabitsTracker/HabitsTrackerApp.swift` (edit — register `Clip.self`)

**Analog:** same file, `.modelContainer(for:[…])` list (`HabitsTrackerApp.swift:15-23`):
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
Apply: append `Clip.self` to the list (D-12 — plan-less container, no `migrationPlan:`).

---

### `HabitsTracker/Features/Settings/SettingsView.swift` (edit — pass `clips` to export call)

**Analog:** same file, existing export call site (`SettingsView.swift:60`):
```swift
let data = try exportImportService.exportData(categories: categories, habits: habits, entries: entries, rules: rules, collections: collections, collectionItems: collectionItems)
```
Apply: add a `@Query private var clips: [Clip]` (mirrors the existing `@Query` for `rules`/`collections` elsewhere in the file) and pass `clips: clips` into the call.

---

### `HabitsTrackerTests/ClipTitleSuggestionTests.swift` (test, transform — new)

**Analog:** `HabitsTrackerTests/CollectionRollupEngineTests.swift` (pure-function test shape, no ModelContainer — always runnable per §9.7).

**Shape to mirror** (`CollectionRollupEngineTests.swift:1-24`):
```swift
import XCTest
@testable import HabitsTracker

final class CollectionRollupEngineTests: XCTestCase {
    func testCompletionistHappyPath() {
        let collection = Collection(title: "Shows", statusSetID: "shows", showsAggregate: true)
        let items = [ ... ]
        let result = CollectionRollupEngine.rollup(collection: collection, items: items)
        XCTAssertEqual(result, .count(x: 2, y: 5))
    }
    ...
}
```
Apply: `ClipTitleSuggestionTests` with the 4 mandated cases from CONTEXT.md D-02 — normal URL, bare-host URL, URL with a slug, malformed/no-scheme string (graceful fallback). No `@testable import SwiftData`/ModelContext needed — pure string in, string out, exactly like `CollectionRollupEngineTests`.

---

### `HabitsTrackerTests/ClipModelTests.swift` (test, CRUD — new, build-verify only per §9.7)

**Analog:** `HabitsTrackerTests/RuleModelTests.swift` (in-memory `ModelContainer` + `FetchDescriptor` shape).

**Shape to mirror** (`RuleModelTests.swift:9-31`):
```swift
final class RuleModelTests: XCTestCase {
    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self, Rule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    @MainActor
    func testIsArchivedDefaultsFalse() throws {
        let context = try makeInMemoryContext()
        let rule = Rule(title: "No screens after 10pm")
        context.insert(rule)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<Rule>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.isArchived, false)
    }
}
```
Apply: `ClipModelTests` with `Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self, Clip.self])`, cover `isArchived` defaults false, `status` defaults `.saved`, and domain-nullify-on-delete (mirrors `Rule`'s stemmed-habit nullify test at line 33+). **Per CLAUDE.md §9.7, this suite crashes the test host at 0.000s on the iOS 26 simulator (SwiftData `@Model` persistence test) — build-verify only, do not chase through app code.** `ClipTitleSuggestionTests` (pure, no ModelContainer) is the one that must actually run and pass.

## Shared Patterns

### Nav template (domain section → "+" → editor → row → detail)
**Source:** `HabitsTracker/Features/Hub/DomainDetailView.swift` (Rules + Collections trios), locked by Phase 2 D-12 / Phase 3 D-09.
**Apply to:** `ClipRow.swift`, `ClipDetailView.swift`, `ClipEditorView.swift`, and the `DomainDetailView` Clips-section edit.

### DKBadge status chip (tokens-only, tap target)
**Source:** `HabitsTracker/Features/Collections/CollectionItemRow.swift:49-64` and `CollectionItemDetailView.swift:67-86`.
**Apply to:** `ClipRow.swift`'s trailing chip and `ClipDetailView.swift`'s status block AND tag pill (D-04 — same `DKBadge` styling for both status and tag per UI-SPEC).

### Soft-archive additive field
**Source:** `HabitsTracker/Models/Rule.swift:11` (`var isArchived: Bool = false`) + `RuleEditorView.swift:161-174` (`archiveSection`, toggle + save + dismiss).
**Apply to:** `Clip.isArchived` field and (if planner wants an archive action, not explicitly decided — D-11 focuses on delete) an equivalent editor section.

### Bordered/CTA link block (`Link(destination:)` + host/URL text)
**Source:** `HabitsTracker/Features/Rules/RuleDetailView.swift:117-170` (bordered variant + CTA button variant).
**Apply to:** `ClipDetailView.swift`'s Open Link block (CTA-button variant per D-08, see Pattern Assignments above).

### Export/import round-trip + schemaVersion bump
**Source:** `HabitsTracker/Services/ExportImportService.swift` (`RuleDTO` + export map + import loop + `deleteAll`).
**Apply to:** all `Clip` fields per D-13; bump `schemaVersion` 4→5.

### Domain picker in editor forms
**Source:** `HabitsTracker/Features/Rules/RuleEditorView.swift:145-158` (`domainSection`, `@Query(sort: \Domain.sortIndex) private var domains: [Domain]`).
**Apply to:** `ClipEditorView.swift`'s Domain field (S3 item 5) — confirm `"None"` row inclusion against final `Clip.domain` optionality (UI-SPEC Open Item 5).

### Pure helper + same-commit unit tests (§9.5)
**Source:** `HabitsTracker/Services/CollectionRollupEngine.swift` + `HabitsTrackerTests/CollectionRollupEngineTests.swift`.
**Apply to:** `ClipTitleSuggestion.swift` (D-02) + `ClipTitleSuggestionTests.swift`.

## No Analog Found

None — every Phase 4 file has a direct or composite analog in the Phase 2/3 codebase. This phase is explicitly scoped as a template-mirror of Rules/Collections (see CONTEXT.md "mirroring the ... nav template exactly").

## Metadata

**Analog search scope:** `HabitsTracker/Models/`, `HabitsTracker/Features/Rules/`, `HabitsTracker/Features/Collections/`, `HabitsTracker/Features/Hub/`, `HabitsTracker/Features/Settings/`, `HabitsTracker/Services/`, `HabitsTracker/Utilities/`, `HabitsTracker/HabitsTrackerApp.swift`, `HabitsTrackerTests/`
**Files scanned:** 12 analogs read in full or targeted excerpts (Rule.swift, Domain.swift, Collection.swift, CollectionItem.swift, RuleEditorView.swift, RuleDetailView.swift, RuleRow.swift, DomainDetailView.swift, CollectionItemRow.swift, CollectionItemDetailView.swift, CollectionRow.swift, CollectionItemEditorSheet.swift [partial], ExportImportService.swift, HabitsTrackerApp.swift, CollectionRollupEngine.swift [partial], CollectionRollupEngineTests.swift [partial], RuleModelTests.swift [partial], SettingsView.swift [grep only])
**Pattern extraction date:** 2026-07-08
