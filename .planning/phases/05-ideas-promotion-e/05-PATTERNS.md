# Phase 5: Ideas + Promotion (E) - Pattern Map

**Mapped:** 2026-07-10
**Files analyzed:** 15 (10 new, 5 modified)
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `HabitsTracker/Models/Idea.swift` (new) | model | CRUD | `HabitsTracker/Models/Clip.swift` (+ `Rule.swift`) | exact |
| `HabitsTracker/Models/Domain.swift` (edit — add `.ideas`) | model | CRUD | same file, `.rules`/`.collections`/`.clips` blocks | exact |
| `HabitsTracker/HabitsTrackerApp.swift` (edit) | config | CRUD | same file, `.modelContainer(for:)` list | exact |
| `HabitsTracker/Services/ExportImportService.swift` (edit) | service | batch (export/import) | same file, Clip export/import/delete blocks | exact |
| `HabitsTracker/Services/ExportImportDTOs.swift` (edit — add `IdeaDTO`) | model (DTO) | transform | same file, `ClipDTO`/`RuleDTO` structs | exact |
| `HabitsTracker/Services/PromoteService.swift` (new) | service | event-driven (consume/archive) | `HabitsTracker/Services/CollectionRollupEngine.swift` | role-match (pure static engine shape; PromoteService is stateful/mutating vs. rollup's pure-derive, but same "small testable `enum`/`final class` service, no view logic" idiom) |
| `HabitsTracker/Features/Today/TodayView.swift` (edit — add toolbar "+") | controller/view | request-response | same file (currently no toolbar; `RuleEditorView`'s toolbar block is the pattern for `.confirmationAction`/`.cancellationAction`, here just a bare `.topBarTrailing` plus button) | role-match |
| `HabitsTracker/Features/Ideas/IdeaCaptureSheet.swift` (new) | component (sheet) | CRUD | `HabitsTracker/Features/Rules/RuleEditorView.swift` (structure/mode) + `HabitsTracker/Features/Habits/HabitCreateSheet.swift` (fill-then-commit orphan-free discipline) | role-match (lighter: single field, no `Form` sections beyond one) |
| `HabitsTracker/Features/Hub/HubView.swift` (edit — inbox card) | component (view) | CRUD (read) | same file, `grid(theme:)` / `emptyState(theme:)` + `NavigationLink` to `DomainFocusPicker` | exact |
| `HabitsTracker/Features/Ideas/InboxView.swift` (new) | component (view) | CRUD (read) | `HabitsTracker/Features/Hub/DomainDetailView.swift` (data-driven list + minimal empty-state text pattern) | role-match |
| `HabitsTracker/Features/Hub/DomainDetailView.swift` (edit — Ideas section) | component (view) | CRUD | same file, `buildClipsSection` / `clipsSectionContent` / `clipsSectionHeader` trio (~lines 197–248) | exact |
| `HabitsTracker/Features/Ideas/IdeaRow.swift` (new) | component (row) | CRUD | `HabitsTracker/Features/Clips/ClipRow.swift` | exact |
| `HabitsTracker/Features/Ideas/PromoteToCollectionPicker.swift` (new) | component (sheet) | request-response | `HabitsTracker/Features/Settings/DomainFocusPicker.swift` (list-of-rows-that-navigate shape) — see note; also structurally close to a minimal `List`/`ScrollView` picker | role-match |
| `HabitsTracker/Features/Habits/HabitCreateSheet.swift` (edit — `.idea(Idea)` case) | component (sheet) | CRUD | same file, `HabitSource` enum (lines 7–10) + `seedDraftFromSource()` `.rule` case (lines 182–186) | exact |
| `HabitsTracker/Features/Rules/RuleEditorView.swift` (edit — promote prefill + domain-required gate) | component (sheet) | CRUD | same file, `init(domain:)` / `saveRule()` (lines 46–52, 254–280) | exact |
| `HabitsTracker/Features/Collections/CollectionItemEditorSheet.swift` (edit — promote prefill) | component (sheet) | CRUD | same file, `init(collection:)` / `saveItem()` (lines 42–48, 225–251) | exact |
| `HabitsTrackerTests/IdeaModelTests.swift` (new) | test | CRUD | `HabitsTrackerTests/ClipModelTests.swift` | exact |
| `HabitsTrackerTests/PromoteServiceTests.swift` (new) | test | event-driven | `HabitsTrackerTests/EngineTests.swift` (pure-logic, no `ModelContainer` needed if `PromoteService` is designed pure-friendly) | role-match |

---

## Pattern Assignments

### `HabitsTracker/Models/Idea.swift` (model, CRUD) — NEW

**Analogs:** `HabitsTracker/Models/Clip.swift` (shape) + `HabitsTracker/Models/Rule.swift` (simpler sibling)

**Full leaf-model shape to mirror** (`HabitsTracker/Models/Clip.swift:1-57`):
```swift
import Foundation
import SwiftData

@Model
final class Clip {
    @Attribute(.unique) var id: UUID
    var title: String
    var url: String
    var note: String?
    var tag: String?
    var statusRaw: String = ClipStatus.saved.rawValue
    var isArchived: Bool = false
    var createdAt: Date = Date.now

    @Relationship
    var domain: Domain?

    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        note: String? = nil,
        tag: String? = nil,
        status: ClipStatus = .saved,
        isArchived: Bool = false,
        createdAt: Date = .now,
        domain: Domain? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.note = note
        self.tag = tag
        self.statusRaw = status.rawValue
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.domain = domain
    }
}
```

**What to replicate:**
- `@Attribute(.unique) var id: UUID`, `init(id: UUID = UUID(), ...)`.
- Bare `@Relationship var domain: Domain?` on the leaf side (the `.nullify` + `inverse:` lives on `Domain.ideas`, not here — see `Rule.swift:13-14` / `Clip.swift:28-29`, both bare `@Relationship`).
- `isArchived: Bool = false` defaulted at both the stored-property declaration AND the init default (belt-and-suspenders — matches Clip exactly).
- `createdAt: Date = Date.now` at the **property declaration** — note the CONTEXT.md caveat: `@Model` default expressions need full qualification (`Date.now`, not `.now`); the init parameter default can still use `.now` (Clip does this: property `= Date.now`, init param `= .now`).
- `title: String` (non-optional, title-only minimum per D-08/D-11).

**What to change:**
- Add `note: String?` and `url: String?` (both optional — Rule/Clip precedent for optional `sourceURL`/`note`).
- Add forward-link fields (D-12, Claude's discretion on exact shape) — keep them a **lean value type**, no SwiftData relationship/backref. E.g. `promotedToTypeRaw: String?` + `promotedToID: UUID?`, mirroring how `Clip.statusRaw` is a raw-string-backed enum facade — a `PromotedKind: String, Codable` enum + computed facade property is the idiomatic house pattern (see `ClipStatus` at `Clip.swift:7-12`).
- No `stemmedHabits`-style owned relationship — Idea is a pure leaf (no cascade dependents), matching Clip more than Rule.

---

### `HabitsTracker/Models/Domain.swift` (model, CRUD) — EDIT

**Analog:** same file, existing `.rules`/`.collections`/`.clips` inverses (`Domain.swift:18-25`)

```swift
@Relationship(deleteRule: .nullify, inverse: \Rule.domain)
var rules: [Rule] = []

@Relationship(deleteRule: .nullify, inverse: \Collection.domain)
var collections: [Collection] = []

@Relationship(deleteRule: .nullify, inverse: \Clip.domain)
var clips: [Clip] = []
```

**What to replicate:** add a fourth block in the identical shape:
```swift
@Relationship(deleteRule: .nullify, inverse: \Idea.domain)
var ideas: [Idea] = []
```
Also add `ideas: [Idea] = []` to the memberwise `init(...)` parameter list and body assignment (mirror how `clips: [Clip] = []` was threaded through at `Domain.swift:39, 52`).

---

### `HabitsTracker/HabitsTrackerApp.swift` (config) — EDIT

**Analog:** same file (`HabitsTrackerApp.swift:15-24`)

```swift
.modelContainer(for: [
    Domain.self,
    Habit.self,
    DailyEntry.self,
    HabitState.self,
    Rule.self,
    Collection.self,
    CollectionItem.self,
    Clip.self
])
```

**What to change:** append `Idea.self` as the last entry (matches how `Clip.self` was appended in Phase 4 — order otherwise doesn't matter for `.modelContainer(for:)`).

---

### `HabitsTracker/Services/ExportImportService.swift` (service, batch) — EDIT

**Analog:** same file — Clip's three touch points: export map (`ExportImportService.swift:124-136`), import block (`186-200`), delete-all ordering (`292-304`).

**Export pattern to copy** (add a `ideas:` array + parameter, mirrors `clips:`):
```swift
clips: clips.map {
    ClipDTO(
        id: $0.id,
        title: $0.title,
        url: $0.url,
        note: $0.note,
        tag: $0.tag,
        status: $0.statusRaw,
        isArchived: $0.isArchived,
        createdAt: $0.createdAt,
        domainID: $0.domain?.id
    )
}
```
Also add `ideas: [Idea]` to `exportData(...)`'s signature (alongside `clips: [Clip]`, line 30) — every call site (`TodayView`? — actually the settings export screen; grep for `exportData(` call sites before editing) needs the new argument.

**Import pattern to copy** (`ExportImportService.swift:186-200`):
```swift
// 2b. Create Clips (wire to domain; no index map needed, nothing references clips by id)
for dto in bundle.clips {
    let clip = Clip(
        id: dto.id,
        title: dto.title,
        url: dto.url,
        note: dto.note,
        tag: dto.tag,
        status: ClipStatus(rawValue: dto.status) ?? .saved,
        isArchived: dto.isArchived,
        createdAt: dto.createdAt,
        domain: dto.domainID.flatMap { categoryIndex[$0] }
    )
    context.insert(clip)
}
```
Same shape for Idea — no index map needed (nothing else references an Idea by id via export/import; the forward-link fields are scalar, not a SwiftData relationship, so they round-trip as plain DTO fields, not an id-lookup wire-up).

**Delete-all ordering pattern** (`ExportImportService.swift:292-304`):
```swift
private func deleteAll(context: ModelContext) throws {
    try context.delete(model: HabitState.self)
    try context.delete(model: DailyEntry.self)
    try context.delete(model: Habit.self)
    try context.delete(model: Rule.self)
    try context.delete(model: CollectionItem.self)
    try context.delete(model: Collection.self)
    // Clip.domain is .nullify — clips must be deleted before their domain (T-04-09).
    try context.delete(model: Clip.self)
    try context.delete(model: Domain.self)
    try context.save()
}
```
**What to change:** insert `try context.delete(model: Idea.self)` **before** `try context.delete(model: Domain.self)` — same nullify-ordering rule the comment states for Clip (CONTEXT.md explicitly calls this out: "delete Idea before Domain in `deleteAll`").

**Schema version bump:** `private let schemaVersion = 5` (line 7) → `6` (D-14). Update the doc comment at top of `ExportImportTests.swift` (line 7 references "the current schemaVersion (5)") when tests are added/edited — not this service file, but flag for the planner.

---

### `HabitsTracker/Services/ExportImportDTOs.swift` (DTO, transform) — EDIT

**Analog:** same file, `RuleDTO` / `ClipDTO` (grep result, lines 75-95):
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

struct ClipDTO: Codable {
    let id: UUID
    let title: String
    let url: String
    let note: String?
    let tag: String?
    let status: String
    let isArchived: Bool
    let createdAt: Date
    let domainID: UUID?
}
```
**What to add:** `struct IdeaDTO: Codable` with `id`, `title`, `note: String?`, `url: String?`, `isArchived: Bool`, `createdAt: Date`, `domainID: UUID?`, plus scalar forward-link fields (e.g. `promotedToType: String?`, `promotedToID: UUID?`) — same flat/scalar-only DTO shape (no nested objects, matches every existing DTO in this file).

---

### `HabitsTracker/Services/PromoteService.swift` (service, event-driven) — NEW

**Closest analog:** `HabitsTracker/Services/CollectionRollupEngine.swift` (pure `enum` namespace, `nonisolated static` function, deterministic, testable, no view/`@Model`-mutation entanglement in its *signature* — though PromoteService legitimately DOES mutate `@Model` objects, unlike RollupEngine which is a pure derive).

```swift
enum CollectionRollupEngine {
    enum Result: Equatable {
        case count(x: Int, y: Int)
        case costSum(total: Double)
        case none
    }

    nonisolated static func rollup(collection: Collection, items: [CollectionItem]) -> Result {
        guard collection.showsAggregate else { return .none }
        // ...
    }
}
```

**What to replicate:**
- `enum PromoteService` namespace (or `final class` if it needs no static-only surface — CONTEXT.md leaves this discretionary) with `static` functions, one per target (`promoteToRule`, `promoteToHabit` [likely just returns the `.idea(Idea)` source, no mutation needed until the sheet saves], `promoteToCollectionItem`), plus a single **shared** `archiveAndForwardLink(idea:as:targetID:)` helper — this is the "one small testable core" §9.5 calls for, not scattered per-editor logic.
- Deterministic, no view/`DesignKit` imports — `import Foundation` (+`SwiftData` for `ModelContext`/`@Model` types) only, matching `CollectionRollupEngine`'s `import Foundation`-only header.
- Doc-comment block above the type explaining the derivation/consume contract, matching the RollupEngine's doc-comment style (lines 1-25 there).

**Error/edge-case shape to mirror** (`CollectionRollupEngine.swift:42-45` defensive fallback):
```swift
guard let statusSet = StatusSetCatalog.set(for: collection.statusSetID) else {
    return .count(x: 0, y: items.count)
}
```
PromoteService's analogous defensive case: an idea with `isArchived == true` already promoted — the service should be a safe no-op (skip) rather than double-archive/double-forward-link, per CONTEXT.md's "already-archived skip" test case (§9.5 list).

---

### `HabitsTracker/Features/Today/TodayView.swift` (view, request-response) — EDIT

**Analog:** same file — `NavigationStack` currently has zero `.toolbar` (`TodayView.swift:24-109`, no `.toolbar` modifier present). The nearest in-repo toolbar-button shape is `RuleEditorView`'s toolbar block (`RuleEditorView.swift:83-90`):
```swift
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
    }
    ToolbarItem(placement: .confirmationAction) {
        saveCTAButton(theme: theme)
    }
}
```
and the section-header "+" glyph styling used identically three times in `DomainDetailView.swift` (e.g. lines 135-142):
```swift
Button {
    creatingRule = true
} label: {
    Image(systemName: "plus")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(theme.colors.accentPrimary)
        .frame(minWidth: 44, minHeight: 44)
}
.accessibilityLabel("Add rule to \(domain.name)")
```

**What to build (S1, per UI-SPEC):**
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button {
            showingCapture = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.colors.accentPrimary)
        }
        .accessibilityLabel("Add idea")
        .accessibilityHint("Opens a quick capture sheet")
    }
}
.sheet(isPresented: $showingCapture) {
    IdeaCaptureSheet()
}
```
Add `@State private var showingCapture = false` alongside the existing `@State private var saveError: String?` (line 14). **Do not touch** any other part of `TodayView`'s body — the ScrollView/VStack content, the `.task` bootstrap, and `.alert` stay untouched (net-new chrome only, matches D-01/D-02's explicit "zero overlay/list pollution" framing).

---

### `HabitsTracker/Features/Ideas/IdeaCaptureSheet.swift` (sheet, CRUD) — NEW

**Analogs:** `RuleEditorView.swift` (mode enum + init-pair + save shape) and `HabitCreateSheet.swift` (orphan-free fill-then-commit discipline + `.presentationDetents`).

**Mode/init pattern to copy** (`RuleEditorView.swift:26-60`):
```swift
private enum EditorMode {
    case create(domain: Domain)
    case edit(rule: Rule)
}
private let editorMode: EditorMode

@State private var title: String
// ...

init(domain: Domain) {
    self.editorMode = .create(domain: domain)
    _title = State(initialValue: "")
    // ...
}

init(rule: Rule) {
    self.editorMode = .edit(rule: rule)
    _title = State(initialValue: rule.title)
    // ...
}
```
For `IdeaCaptureSheet`, per UI-SPEC S2: `IdeaCaptureSheet(domain: Domain? = nil)` for create (optional, unlike Rule's required `Domain`), `IdeaCaptureSheet(idea: Idea)` for edit.

**Single-field title section + validation hint** (`RuleEditorView.swift:105-119`, verbatim reusable copy):
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
        Text("Title")
            .font(theme.typography.headline)
    }
}
```
UI-SPEC wants placeholder **"What's the idea?"** instead of "Rule title", and per S2 this may be a plain `VStack`/single field rather than a full `Form` — "deliberately lighter than `RuleEditorView`/`ClipEditorView`" — but the validation-hint copy/token recipe is verbatim reuse.

**Save CTA + toolbar + delete-confirm pattern** (`RuleEditorView.swift:83-98, 176-227`) — copy the toolbar/CTA/`confirmationDialog` shape wholesale; title strings differ ("Add Idea"/"Save Changes"/"Delete Idea"/"Delete this idea?"/"This can't be undone." — all given verbatim in the UI-SPEC copy table).

**Orphan-free insert-only-on-save discipline** (`HabitCreateSheet.swift:66-70, 207-219`):
```swift
ToolbarItem(placement: .cancellationAction) {
    Button("Cancel") {
        dismiss()
        // Cancel inserts nothing — orphan-free (D-04, T-0203-01)
    }
}
// ...
let habit = Habit(...)
modelContext.insert(habit)
try? modelContext.save()
dismiss()
```
Mirror exactly for create-mode Idea: `Idea(title:, domain:)` inserted only inside the Save action, never earlier.

**Autofocus** (net-new, not in Rule/Clip editors — UI-SPEC S2 calls for `@FocusState` autofocus). Closest in-repo precedent for `@FocusState` usage is `ClipEditorView.swift:59, 152` (`@FocusState private var titleFieldIsFocused: Bool`, `.focused($titleFieldIsFocused)`) — reuse the mechanism, trigger it in `.onAppear` (`titleFieldIsFocused = true`) rather than Clip's manual-edit-detection use case.

**Sheet presentation sizing** (`HabitCreateSheet.swift:87-88`):
```swift
.presentationDetents([.medium, .large])
.presentationDragIndicator(.visible)
```
Reasonable default for `IdeaCaptureSheet` too, though UI-SPEC doesn't mandate detents explicitly — planner's call.

---

### `HabitsTracker/Features/Hub/HubView.swift` (view, CRUD read) — EDIT

**Analog:** same file — `grid(theme:)` (`HubView.swift:40-61`) and the "own the `@Query`, parent owns fetch" idiom already used for `focusedDomains` (line 15-16):
```swift
@Query(filter: #Predicate<Domain> { $0.isFocused }, sort: \Domain.sortIndex)
private var focusedDomains: [Domain]
```

**What to add:** a second `@Query` for unfiled/non-archived ideas:
```swift
@Query(filter: #Predicate<Idea> { $0.domain == nil && !$0.isArchived })
private var unfiledIdeas: [Idea]
```
placed above/inside the same `ScrollView`/`VStack` `grid(theme:)` renders into — **pinned above** (D-03), so it's a new `if !unfiledIdeas.isEmpty { inboxCard(theme:) }` block prepended before the grid's `LazyVGrid`, inside the same container per UI-SPEC S3 ("not a separate screen region").

**Card + `NavigationLink` shape to copy** — closest full-card component analog is the empty-state CTA card at `HubView.swift:75-85`:
```swift
NavigationLink {
    DomainFocusPicker()
} label: {
    Text("Choose Domains")
        .font(theme.typography.headline)
        .foregroundStyle(theme.colors.surfaceElevated)
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.vertical, theme.spacing.s)
        .background(theme.colors.accentPrimary)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.button, style: .continuous))
}
```
For the inbox card, wrap a `DKCard` (not a raw background/clipShape — UI-SPEC S3 specifies `DKCard` surface, `HStack` with icon/title/`Spacer()`/`DKBadge`/chevron) in a `NavigationLink { InboxView() } label: { ... }.buttonStyle(.plain)` — same `NavigationLink`-wraps-styled-content idiom as the grid's `DomainTile` (`HubView.swift:46-57`):
```swift
ForEach(focusedDomains) { domain in
    NavigationLink(value: domain) {
        DomainTile(...)
    }
    .buttonStyle(.plain)
}
```

---

### `HabitsTracker/Features/Ideas/InboxView.swift` (view, CRUD read) — NEW

**Analog:** `HabitsTracker/Features/Hub/DomainDetailView.swift` — data-driven, no owned `NavigationStack` (nests under caller's stack), `ScrollView`+`VStack` content shape (`DomainDetailView.swift:22-65`):
```swift
struct DomainDetailView: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let domain: Domain
    // ...
    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        // ...
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                header(theme: theme)
                if sections.isEmpty {
                    emptyState(theme: theme)
                } else {
                    ForEach(sections) { section in ... }
                }
            }
            .padding(theme.spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .navigationTitle(domain.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
```
**What to change:** `InboxView` owns its own `@Query` (per D-05, unlike `DomainDetailView` which takes `domain: Domain` as a prop and reads `domain.rules`/`.clips` directly) —
```swift
@Query(filter: #Predicate<Idea> { $0.domain == nil && !$0.isArchived }, sort: \Idea.createdAt, order: .reverse)
private var unfiledIdeas: [Idea]
```
Body renders `ForEach(unfiledIdeas) { IdeaRow(idea: $0) }` inside `VStack(spacing: theme.spacing.m)`, `navigationTitle("Inbox")`, no `NavigationStack` of its own (pushed from `HubView`'s stack via the S3 `NavigationLink`, exactly mirroring how `DomainDetailView` nests under `HubView`'s `navigationDestination`).

**Minimal empty-state text pattern** — closest is `DomainDetailView.emptyState(theme:)` (`DomainDetailView.swift:266-278`), but UI-SPEC S4 wants something even lighter (single centered line, no heading):
```swift
private func emptyState(theme: Theme) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.s) {
        Text("Nothing here yet")
            .font(theme.typography.title)
            .foregroundStyle(theme.colors.textPrimary)
        Text("Rules, collections, clips and ideas you file under this domain will show up here.")
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.textSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, theme.spacing.m)
}
```
Simplify to a single centered `Text("Nothing to file right now.")` styled `theme.typography.body`/`textSecondary`, `theme.spacing.xxl` top padding (per S4 copy contract) — do not carry over the two-line heading+body treatment.

---

### `HabitsTracker/Features/Hub/DomainDetailView.swift` (view, CRUD) — EDIT

**Analog:** same file, the Clips section trio verbatim (`DomainDetailView.swift:197-248`):
```swift
private func buildClipsSection(theme: Theme) -> DomainSection? {
    let activeClips = domain.clips
        .filter { !$0.isArchived }
        .sorted { $0.createdAt > $1.createdAt }

    guard !activeClips.isEmpty else { return nil }

    let content = AnyView(clipsSectionContent(clips: activeClips, theme: theme))
    return DomainSection(id: "clips", title: "Clips", content: content)
}

@ViewBuilder
private func clipsSectionContent(clips: [Clip], theme: Theme) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.m) {
        clipsSectionHeader(theme: theme)

        ForEach(clips, id: \.id) { clip in
            NavigationLink {
                ClipDetailView(clip: clip)
            } label: {
                ClipRow(clip: clip)
            }
            .buttonStyle(.plain)
        }
    }
}

private func clipsSectionHeader(theme: Theme) -> some View {
    HStack(alignment: .center) {
        Text("Clips")
            .font(theme.typography.title)
            .foregroundStyle(theme.colors.textPrimary)
            .accessibilityAddTraits(.isHeader)

        Spacer()

        Button {
            creatingClip = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.colors.accentPrimary)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("Add clip to \(domain.name)")
    }
}
```

**What to change for Ideas (D-09):**
- Replace `NavigationLink { ClipDetailView(clip:) } label: { ClipRow(clip:) }` with **just `IdeaRow(idea: idea)`, no `NavigationLink`** — D-08 deliberately has no `IdeaDetailView`; the row itself handles tap-to-edit internally via its own `.sheet` (S6). This is the one deviation from the Clips/Rules/Collections trio shape.
- `buildIdeasSection` filters `domain.ideas.filter { !$0.isArchived }.sorted { $0.createdAt > $1.createdAt }` (identical filter/sort to Clips).
- Register the call at the "Phase E: append Ideas section here" hook, **line 90**:
```swift
// Phase E: append Ideas section here.
```
becomes:
```swift
if let ideasSection = buildIdeasSection(theme: theme) {
    sections.append(ideasSection)
}
```
- Add `@State private var creatingIdea = false` alongside `creatingRule`/`creatingCollection`/`creatingClip` (line 28-30), and a `.sheet(isPresented: $creatingIdea) { IdeaCaptureSheet(domain: domain) }` alongside the other three `.sheet` modifiers (lines 56-64).
- Header button accessibility label: `"Add idea to \(domain.name)"` (matches the `"Add clip to \(domain.name)"` pattern exactly).

---

### `HabitsTracker/Features/Ideas/IdeaRow.swift` (row, CRUD) — NEW

**Analog:** `HabitsTracker/Features/Clips/ClipRow.swift` (full file, 85 lines) — data-driven, `DKCard` surface, combined-VoiceOver-element text block + separately-reachable trailing action `Button`(s).

```swift
struct ClipRow: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let clip: Clip
    @State private var tapCounter: Int = 0

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        DKCard(theme: theme) {
            HStack(alignment: .center, spacing: theme.spacing.m) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(clip.title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)

                    if let tag = clip.tag, !tag.isEmpty {
                        Text(tag)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel)

                statusChip(theme: theme)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
    }

    private func statusChip(theme: Theme) -> some View {
        Button {
            tapCounter += 1
            clip.status = clip.status == .saved ? .acted : .saved
        } label: {
            DKBadge(statusLabel, theme: theme)
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: tapCounter)
        .accessibilityLabel("Status: \(statusLabel), \(clip.title)")
        .accessibilityHint("Toggles between saved and acted")
    }
}
```

**What to replicate directly:**
- `DKCard(theme:)` surface, `let idea: Idea` sole data prop, `@EnvironmentObject`/`@Environment(\.colorScheme)` boilerplate.
- Title `Text` + optional caption line (`note` here instead of `tag`) — same `.lineLimit(2)`/`.minimumScaleFactor(0.9)`.
- `.accessibilityElement(children: .combine)` on the text `VStack`, with a **separate** trailing `Button`/`Menu` kept individually VoiceOver-reachable (never absorbed) — exactly the WR-01/WR-04 contract UI-SPEC S6 cites verbatim.
- `Button { ... } label: { DKBadge(...) .frame(minWidth: 44, minHeight: 44) }.buttonStyle(.plain)` recipe for pill-shaped tap targets — reuse this exact recipe for both File and Promote, swapping `DKBadge` text/icon per UI-SPEC's copy table, and swapping the single `Button` for a `Menu` (File → domain list, Promote → Rule/Habit/Collection item list) since both are choice-pickers, not toggles.

**What to change:**
- Two action affordances instead of one (`ClipRow` has one status chip; `IdeaRow` needs File + Promote in an `HStack(spacing: theme.spacing.s)`, per UI-SPEC S6 "Row 2").
- File pill conditional on `idea.domain == nil` (`ClipRow`'s chip is unconditional).
- Tap-to-edit on Row 1 opens `IdeaCaptureSheet(idea: idea)` — `ClipRow` has no such tap (its parent wraps it in `NavigationLink { ClipDetailView }`); `IdeaRow` must own this itself since D-08 forbids a `NavigationLink`/detail-view wrapper (`.onTapGesture` on the text `VStack`, or a `Button` with `.buttonStyle(.plain)` wrapping just Row 1 — planner's call per Claude's Discretion D-10).

---

### `HabitsTracker/Features/Ideas/PromoteToCollectionPicker.swift` (sheet, request-response) — NEW

No exact analog exists (no prior "pick one of N app-wide items across domains" picker). Closest structural precedent: `HabitsTracker/Features/Settings/DomainFocusPicker.swift` (a `List`/`ForEach` of toggleable rows with domain context) for the "flat list, tap a row, dismiss" shape, plus `RuleEditorView`'s toolbar `.cancellationAction` pattern for the Cancel button.

**What to build:** `NavigationStack` + `List`/`ScrollView` of `DKCard` rows, `@Query(sort: \Collection.title)` (or similar) for `[Collection]`, each row: collection name (`headline`) + `collection.domain?.name` sub-label (`caption`, textSecondary). Tapping dismisses the picker and opens `CollectionItemEditorSheet(collection:)` prefilled. Empty-collections edge case: single centered `Text("No lists yet. Create a collection first.")` — reuse the `InboxView` minimal-placeholder recipe.

**Toolbar Cancel** — copy verbatim from `RuleEditorView.swift:84-86`:
```swift
ToolbarItem(placement: .cancellationAction) {
    Button("Cancel") { dismiss() }
}
```

---

### `HabitsTracker/Features/Habits/HabitCreateSheet.swift` (sheet, CRUD) — EDIT

**Analog:** same file, `HabitSource` enum (`HabitCreateSheet.swift:7-10`, already reserving the case) and the `.rule` prefill arm in `seedDraftFromSource()` (`182-186`):

```swift
enum HabitSource {
    case manual
    case rule(Rule)
}
// ...
private func seedDraftFromSource() {
    switch source {
    case .manual:
        selectedDomain = domains.first
    case .rule(let rule):
        title = rule.title
        selectedDomain = rule.domain
    }
}
```

**What to change:**
```swift
enum HabitSource {
    case manual
    case rule(Rule)
    case idea(Idea)
}
```
and add a third `switch` arm:
```swift
case .idea(let idea):
    title = idea.title
    selectedDomain = idea.domain
```
Also thread `originRule`'s sibling — `saveHabit(theme:)` (`HabitCreateSheet.swift:191-220`) currently only sets `originRule` for `.rule`; for `.idea` **no equivalent `originIdea` link is set** (D-07: "the result carries no backref to the idea") — the Idea→Habit forward link lives on the `Idea` side only (via `PromoteService`'s archive-with-forward-link call, invoked from wherever promote triggers the sheet — likely the presenting view's `.sheet(isPresented:)` completion, or a small wrapper that calls `PromoteService` right after `HabitCreateSheet` dismisses via a successful save). **Chrome and every other line of this file stay untouched** per D-07's explicit instruction — this is the smallest possible diff.

---

### `HabitsTracker/Features/Rules/RuleEditorView.swift` (sheet, CRUD) — EDIT

**Analog:** same file — `init(domain:)` (lines 46-52) and `saveRule()` (lines 254-280).

**What to add:** an idea-prefill init path and a domain-required save-gate active only in that path. Pattern to extend (mirrors the existing two-init-shape):
```swift
init(domain: Domain) {
    self.editorMode = .create(domain: domain)
    _title = State(initialValue: "")
    _bodyText = State(initialValue: "")
    _sourceURLText = State(initialValue: "")
    _selectedDomainID = State(initialValue: domain.id)
}
```
Add e.g. `init(promotingIdea idea: Idea)` that sets `_title = State(initialValue: idea.title)`, `_bodyText = State(initialValue: idea.note ?? "")`, `_sourceURLText = State(initialValue: idea.url ?? "")`, `_selectedDomainID = State(initialValue: idea.domain?.id)`, plus an internal flag (`isPromoteFlow`/`sourceIdea: Idea?` — UI-SPEC Open Item #5 leaves the exact mechanism to the planner) that the `saveCTAButton`'s `.disabled(...)` (line 195, currently `trimmedTitle.isEmpty`) extends to also require `selectedDomainID != nil` when that flag is set and the idea was unfiled. On successful save reached via this path, call into `PromoteService` to archive+forward-link the source idea (mirrors how `saveRule()`'s `.create`/`.edit` branches at lines 261-276 are the single insert/mutate point — the promote-consume call belongs right after `try? modelContext.save()`, line 278).

---

### `HabitsTracker/Features/Collections/CollectionItemEditorSheet.swift` (sheet, CRUD) — EDIT

**Analog:** same file — `init(collection:)` (lines 42-48) and `saveItem()` (lines 225-251).

```swift
init(collection: Collection) {
    self.editorMode = .create(collection)
    _title = State(initialValue: "")
    _noteText = State(initialValue: "")
    _urlText = State(initialValue: "")
    _costText = State(initialValue: "")
}
```
**What to add:** prefill `_title`/`_urlText` from the promoted idea when reached via `PromoteToCollectionPicker` (the `collection` is already resolved by that point — picking the collection *is* the domain selection per UI-SPEC S7, so **no additional domain-required gate is needed here**, unlike `RuleEditorView`). Same "call `PromoteService` right after `try? modelContext.save()`" hook as the Rule case (line 249 in `saveItem()`).

---

## Shared Patterns

### Data-driven view / row (§9.2)
**Source:** `HabitsTracker/Features/Clips/ClipRow.swift` (whole file) — takes only its model value as a prop, owns no `@Query`, mutates only via `@Environment(\.modelContext)` + direct property writes + `try? modelContext.save()`.
**Apply to:** `IdeaRow`, `InboxView` (query owned by the view itself, not passed in — matches D-05's explicit instruction), `PromoteToCollectionPicker`.

### Section-loop-with-per-section-"+" (DOM-03 house idiom)
**Source:** `HabitsTracker/Features/Hub/DomainDetailView.swift:69-248` (the `nonEmptySections` builder + three `build*Section`/`*SectionContent`/`*SectionHeader` trios).
**Apply to:** the new Ideas section in the same file — reuse the trio shape verbatim, with the one deviation noted above (no `NavigationLink`/detail-view wrapper on the row).

### Fill-then-commit / orphan-free save (D-04 habit precedent, extended to Idea/Rule/CollectionItem editors)
**Source:** `HabitsTracker/Features/Habits/HabitCreateSheet.swift:65-89, 189-220` — Cancel inserts nothing; the model object is constructed and `context.insert`-ed only inside the Save action.
**Apply to:** `IdeaCaptureSheet` create mode; all three promote target editors already follow this (Rule/Clip/CollectionItem editors share the identical `.create`/`.edit` `switch` + single-insert-point shape).

### Two-mode `EditorMode` enum + dual-init sheet
**Source:** `HabitsTracker/Features/Rules/RuleEditorView.swift:26-60` (`private enum EditorMode { case create(domain: Domain); case edit(rule: Rule) }` + matching `init(domain:)`/`init(rule:)` pair). Reused verbatim in `CollectionItemEditorSheet.swift:22-56` and `ClipEditorView.swift:34-86`.
**Apply to:** `IdeaCaptureSheet` (`.create(domain: Domain?)` / `.edit(idea: Idea)`), and the promote-prefill inits added to `RuleEditorView`/`CollectionItemEditorSheet`.

### Validation-hint copy + disabled-Save gate
**Source:** `RuleEditorView.swift:110-114` (`if trimmedTitle.isEmpty { Text("Give this a name to continue.") ... }`) + `saveCTAButton` `.disabled(trimmedTitle.isEmpty)` (line 195). Verbatim string, verbatim token recipe, reused in `ClipEditorView`, `CollectionItemEditorSheet`, `HabitCreateSheet`.
**Apply to:** `IdeaCaptureSheet`, and the domain-required-gate extension on `RuleEditorView`'s promote path (extend the `.disabled(...)` predicate, don't replace the copy).

### Destructive delete with `confirmationDialog`
**Source:** `RuleEditorView.swift:91-100, 176-227` — `showDeleteConfirm: Bool` state, `Button(role: .destructive) { showDeleteConfirm = true }`, `.confirmationDialog(title, isPresented:, titleVisibility: .visible) { actions } message: { ... }`. Identical shape in `ClipEditorView.swift` and `CollectionItemEditorSheet.swift`.
**Apply to:** `IdeaCaptureSheet`'s edit-mode "Delete Idea" row (UI-SPEC S2) — copy title "Delete this idea?" / message "This can't be undone." / confirm "Delete Idea" / cancel "Cancel" verbatim per the Copywriting Contract.

### Soft-archive scalar field + `.nullify` domain relationship
**Source:** `Clip.swift` (`isArchived: Bool = false`, bare `@Relationship var domain: Domain?`) + `Domain.swift`'s `.nullify`/`inverse:` block for `\Clip.domain`.
**Apply to:** `Idea.swift` + `Domain.ideas`.

### Additive-only schema change + plan-less `.modelContainer`
**Source:** `HabitsTrackerApp.swift:15-24` (no `migrationPlan:` argument) + `Docs/SCHEMA_MIGRATION_PLAYBOOK.md`.
**Apply to:** `Idea` model registration; run the mandatory upgrade test per D-13 before merging.

### `os.Logger`, never `print()`
**Source:** `HabitsTracker/Features/Clips/ClipEditorView.swift:4-6`:
```swift
import os.log
private let logger = Logger(subsystem: "lauterstar.HabitsTracker", category: "ClipEditorView")
```
**Apply to:** `PromoteService` if it needs diagnostics (e.g. logging a defensive skip on already-archived idea), `IdeaCaptureSheet` if any error path needs it.

### Pure-service unit tests, no `ModelContainer` where avoidable (§9.5, §9.7)
**Source:** `HabitsTrackerTests/EngineTests.swift` (whole file) — plain `XCTestCase`, constructs `@Model` objects in-memory (not persisted) and calls a `static` engine function directly; runs and passes on the iOS 26 simulator (unlike `@Model`-persistence suites).
**Apply to:** `PromoteServiceTests` — if `PromoteService`'s core consume/archive/forward-link logic can be expressed against in-memory (unsaved) `@Model` instances without a `ModelContainer`/`ModelContext.save()`, it inherits the "runs and passes" tier, not the "build-verify only" tier. Design the service's testable core to accept already-constructed model objects and mutate their properties directly (as `CollectionRollupEngine.rollup` does with `Collection`/`[CollectionItem]`), reserving any `ModelContext.save()` call for a thin caller-side wrapper.

---

## No Analog Found

None — every file in scope has at least a role-match analog (see table above). The one file with the weakest match is `PromoteToCollectionPicker.swift` (no prior "flat cross-domain picker" screen exists); it should compose `DomainFocusPicker`'s row-list shape with `RuleEditorView`'s toolbar Cancel rather than following one single strong analog.

## Metadata

**Analog search scope:** `HabitsTracker/Models/`, `HabitsTracker/Services/`, `HabitsTracker/Features/{Hub,Clips,Rules,Collections,Habits,Today,Settings}/`, `HabitsTracker/HabitsTrackerApp.swift`, `HabitsTrackerTests/`
**Files scanned:** 24 (12 read in full, 12 grepped/partially read)
**Pattern extraction date:** 2026-07-10
