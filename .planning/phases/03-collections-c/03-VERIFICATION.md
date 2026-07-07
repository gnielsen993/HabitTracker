---
phase: 03-collections-c
verified: 2026-07-06T21:15:00Z
status: human_needed
score: 5/5
overrides_applied: 0
human_verification:
  - test: "Create a collection from a preset in DomainDetailView"
    expected: "Tap '+' in a domain's Collections section header -> CollectionPresetPickerSheet appears with 9 presets (generic first) -> selecting one creates and saves the collection, which immediately appears in the section row; tapping the row navigates to CollectionDetailView"
    why_human: "Full nav-stack push, sheet presentation, and SwiftData live-query update require on-device confirmation; grep confirms all wiring is present but cannot verify UIKit/SwiftUI rendering behavior"
  - test: "Tap-to-advance chip stops at terminal; explicit long-press Reset works"
    expected: "Tapping chip on 'watched' item does nothing visually (stays at terminal, haptic still fires); long-press shows Reset destructive option; after Reset, chip returns to first state (e.g. 'to-watch')"
    why_human: "D-06/D-07/D-08: min() clamp + sensoryFeedback + contextMenu verified in code but stop-at-terminal feel and haptic need physical-device confirmation — this was cleared by Gabe in the 03-04 checkpoint (2026-07-06) and is documented in 03-04-SUMMARY as approved"
  - test: "seasonEpisode controls show 'S2 E4' after +Episode and +Season operations; counter '+1' increments label"
    expected: "Start at S1 E1 -> tap +Episode three times -> shows 'S1 E4'; tap +Season -> shows 'S2 E1'; tap +Episode three more times -> 'S2 E4'; Books counter '+Chapter' increments from 'Chapter 0' to 'Chapter 1'"
    why_human: "D-10 position-mutation logic verified in code (item.episode += 1; item.season += 1; item.episode = 1; item.counterValue += 1) but multi-tap progression and label update need on-device confirmation — cleared by Gabe's 03-04 checkpoint approval"
  - test: "Rollup row label and detail header render correctly for completionist vs cost vs tracker"
    expected: "Shows list with 2/5 watched: row trailing label '2/5', header shows DKProgressRing; Wishlist with item costs: row shows '$1,240', header shows '$1,240' (no ring); tracker (showsAggregate off): no trailing label, no header rollup"
    why_human: "D-17/D-18: trailing-label path in CollectionRow and DKProgressRing in CollectionDetailView header verified in code but rendering output (font, ring size, label placement) needs visual confirmation"
---

# Phase 3: Collections (C) — Verification Report

**Phase Goal:** Domains can hold opinionated lists whose items carry behavior — a tap-to-advance status chip, an optional position, and aggregate/cost rollups — so a Shows list or a wishlist feels considered, not like inert text.
**Verified:** 2026-07-06T21:15:00Z
**Status:** human_needed (all code truths VERIFIED; 4 items require on-device confirmation per the note below)
**Re-verification:** No — initial verification

**Environment note:** The Xcode 26.3 / iOS 26 CoreSimulator test-runner crashes host-launch on this machine (documented in STATE.md as a pre-existing machine-wide blocker — identical behavior on all existing test suites including RuleModelTests). Tests are therefore build-verified only, not execution-verified. The 03-01 upgrade-test gate was approved by Gabe on additive-migration reasoning (2026-07-05); the 03-04 on-device UX gate was cleared by Gabe's physical-device pass (2026-07-06). Both are reflected below.

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can create a collection from a preset (DomainDetailView Collections section → preset picker → filed collection with its StatusSet) | VERIFIED | `DomainDetailView.buildCollectionsSection` wired; `CollectionPresetPickerSheet(domain:)` sheet from `+` button; `createCollection(from:)` inserts + saves; `CollectionRow` + `NavigationLink` → `CollectionDetailView` present |
| 2 | Tap-to-advance chip advances `statusIndex`, stops at terminal, and produces haptic; explicit Reset (contextMenu + VoiceOver action) returns to 0 | VERIFIED (code) | `CollectionItemRow`: `min(item.statusIndex + 1, terminalIndex)` (no modulo); `.sensoryFeedback(.impact(weight:.light), trigger: tapCounter)`; `.contextMenu { Button("Reset", role: .destructive) }`; `.accessibilityAction(named: "Reset status")`; on-device approved 2026-07-06 by Gabe |
| 3 | `seasonEpisode` template shows "S2 E4"; +Season resets episode→1; +Episode increments; "Finished" sets terminal; `counter` +1 increments | VERIFIED (code) | `CollectionItemDetailView`: `item.episode += 1`; `item.season += 1; item.episode = 1`; `item.statusIndex = terminalIndex`; `item.counterValue += 1`; `positionDisplayText` returns `"S\(item.season) E\(item.episode)"` and `"\(label) \(item.counterValue)"`; on-device approved 2026-07-06 by Gabe |
| 4 | `showsAggregate` ON → "X/Y" trailing label + DKProgressRing in detail header for completionist; cost items → "$NNN" (never a ring); tracker OFF → no rollup | VERIFIED | `CollectionRow.trailingRollup`: `.count(x,y) where y>0 → "\(x)/\(y)"`, `.costSum(total) → "$NNN"`, else `EmptyView()`; `CollectionDetailView.rollupBlock`: `.count` with y>0 → `DKProgressRing`, `.costSum` → monoNumber text (never ring), `.none` → `EmptyView()` |
| 5 | Generic preset exists as catalog default; built-in StatusSet labels are not user-editable | VERIFIED | `StatusSetCatalog.all[0]` = `StatusSet(id:"generic", states:["to-collect","collected"], terminalIndex:1)`; `CollectionPresetCatalog.all.first?.id == "generic"`; no SwiftData `@Model` for StatusSet — labels live in code only (structural non-editability, D-03) |

**Score:** 5/5 truths verified (code level). 4 items routed to human verification (visual rendering + on-device behavior).

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `HabitsTracker/Models/Collection.swift` | `@Model` with `statusSetID`, `progressTemplate`, `showsAggregate`, cascade items | VERIFIED | All fields present with correct defaults; `@Relationship(deleteRule: .cascade, inverse: \CollectionItem.collection) var items` |
| `HabitsTracker/Models/CollectionItem.swift` | `@Model` with `statusIndex`, `season`, `episode`, `counterValue`, `cost?` | VERIFIED | All fields present; bare `@Relationship var collection: Collection?` |
| `HabitsTracker/Models/Domain.swift` | `@Relationship(deleteRule: .nullify, inverse: \Collection.domain) var collections` | VERIFIED | Line 21; init extended with `collections: [Collection] = []` |
| `HabitsTracker/HabitsTrackerApp.swift` | `Collection.self, CollectionItem.self` in plan-less container; no `migrationPlan:` | VERIFIED | Both types registered; `grep migrationPlan` returns 0 |
| `HabitsTracker/Services/StatusSetCatalog.swift` | 9 StatusSets; generic first; Foundation-only | VERIFIED | 9 entries; no SwiftData/@Model/DesignKit |
| `HabitsTracker/Services/CollectionPresetCatalog.swift` | 9 presets; generic first; SPEC §5 order | VERIFIED | 9 presets in spec order; `generic` first |
| `HabitsTracker/Services/CollectionRollupEngine.swift` | Pure engine; `.count/.costSum/.none`; terminal-only X; nil-excluded cost | VERIFIED | `nonisolated static func rollup`; Step 1 tracker guard; Step 2 `compactMap(\.cost)`; Step 3 terminal filter; Foundation-only |
| `HabitsTracker/Features/Collections/CollectionRow.swift` | DKCard + trailing rollup; token-only; no `@Query` | VERIFIED | DKCard; `trailingRollup`; no `@Query`; DesignKit tokens only |
| `HabitsTracker/Features/Collections/CollectionPresetPickerSheet.swift` | 9-preset picker; creates + files collection; `modelContext.insert` + `save` | VERIFIED | `CollectionPresetCatalog.all` forEach; `createCollection(from:)` inserts + saves + dismisses |
| `HabitsTracker/Features/Collections/CollectionDetailView.swift` | Header rollup (ring+text / cost text / none); item list; empty state; `CollectionItemEditorSheet` wired | VERIFIED | `rollupBlock` switch; `DKProgressRing` for count; empty-state copy present; `CollectionItemEditorSheet(collection:)` sheet; `CollectionItemRow` + `NavigationLink` → `CollectionItemDetailView` |
| `HabitsTracker/Features/Collections/CollectionItemRow.swift` | Chip with `min()` clamp; `sensoryFeedback`; contextMenu Reset; position label; no `@Query` | VERIFIED | All present; `Array[safe:]` bounds guard |
| `HabitsTracker/Features/Collections/CollectionItemDetailView.swift` | Position controls (+Episode/+Season/Finished/+counter); status chip; metadata blocks | VERIFIED | All controls present; `item.episode = 1` on +Season; `item.statusIndex = terminalIndex` on Finished |
| `HabitsTracker/Features/Collections/CollectionItemEditorSheet.swift` | Create/edit EditorMode; title validation; cost parse; delete confirm; `modelContext.insert` | VERIFIED | `EditorMode { case create(Collection); case edit(CollectionItem) }`; trim guard; `Double(trimmed)` cost; `confirmationDialog`; `modelContext.insert` + `delete` |
| `HabitsTracker/Features/Hub/DomainDetailView.swift` | `buildCollectionsSection` guard; `CollectionPresetPickerSheet` sheet; `CollectionRow` + `NavigationLink` | VERIFIED | `!domain.collections.isEmpty` guard; `creatingCollection` state + sheet; rows wired |
| `HabitsTracker/Services/SeedDataService.swift` | Exactly ONE generic starter collection; merge-add dedup key | VERIFIED | `defaultCollections` returns 1 `Collection`; dedup key `"\(domain.name)::\(title)"` in `restoreMissingDefaults` |
| `HabitsTracker/Services/ExportImportService.swift` | `schemaVersion = 4`; `CollectionDTO`/`CollectionItemDTO`; `collectionIndex` wiring; deleteAll ownership order | VERIFIED | All present; `CollectionItem → Collection → Domain` deletion order |
| `HabitsTrackerTests/CollectionModelTests.swift` | 5 model tests: defaults, inverse, cascade, nullify | VERIFIED | All 5 test methods present; `makeInMemoryContext` schema includes both types; builds clean |
| `HabitsTrackerTests/CollectionRollupEngineTests.swift` | 5 unit tests; all required cases | VERIFIED | All 5 methods present; no ModelContext needed (pure engine) |
| `HabitsTrackerTests/ExportImportTests.swift` | `testExportImportRoundTripV4` with scalar + wiring assertions | VERIFIED | Test present; asserts `statusIndex`, `season`, `episode`, `cost`, `statusSetID`, `progressTemplate`, `showsAggregate`, `item.collection?.id == fetchedCollection.id`; builds clean |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `DomainDetailView.swift` | `CollectionPresetPickerSheet` | `.sheet(isPresented: $creatingCollection)` | WIRED | Line 58–60 |
| `DomainDetailView.swift` | `CollectionDetailView` | `NavigationLink { CollectionDetailView(collection:) }` | WIRED | Lines 155–162 |
| `CollectionDetailView.swift` | `CollectionItemEditorSheet` | `.sheet(isPresented: $addingItem) { CollectionItemEditorSheet(collection:) }` | WIRED | Lines 50–52 |
| `CollectionDetailView.swift` | `CollectionItemDetailView` | `NavigationLink { CollectionItemDetailView(item:) }` | WIRED | Lines 164–168 |
| `CollectionRow.swift` | `CollectionRollupEngine` | `CollectionRollupEngine.rollup(collection:items:)` | WIRED | Line 20 |
| `CollectionRollupEngine.swift` | `StatusSetCatalog` | `StatusSetCatalog.set(for: collection.statusSetID)` | WIRED | Line 43 |
| `CollectionPresetPickerSheet.swift` | `CollectionPresetCatalog` | `CollectionPresetCatalog.all` | WIRED | Line 24 |
| `HabitsTrackerApp.swift` | `Collection.self, CollectionItem.self` | `.modelContainer(for: [..., Collection.self, CollectionItem.self])` | WIRED | Lines 21–22 |
| `SettingsView.swift` | `ExportImportService.exportData` | `exportData(..., collections: collections, collectionItems: collectionItems)` | WIRED | Line 60; `@Query` for both types at lines 15–16 |
| `Domain.swift` | `Collection` | `@Relationship(deleteRule: .nullify, inverse: \Collection.domain) var collections` | WIRED | Line 21 |
| `Collection.swift` | `CollectionItem` | `@Relationship(deleteRule: .cascade, inverse: \CollectionItem.collection) var items` | WIRED | Line 19 |

---

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `CollectionRow` | `collection.items` (for rollup) | SwiftData live relationship from `Collection` passed by parent | Yes — items fetched by SwiftData relationship | FLOWING |
| `CollectionDetailView` | `collection.items` (items list + rollup) | SwiftData relationship on `Collection` param | Yes — same relationship, sorted by `sortIndex` | FLOWING |
| `CollectionPresetPickerSheet` | `CollectionPresetCatalog.all` | Code-only enum — always 9 entries | Yes — static catalog, not empty | FLOWING |
| `CollectionRollupEngine` | `items: [CollectionItem]` param | Caller passes `collection.items` | Yes — live relationship data | FLOWING |
| `SeedDataService.defaultCollections` | returns `[Collection]` | In-memory construction, filed to `mediaDomain` | Yes — exactly 1 item | FLOWING |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Build succeeds | `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' build` | `** BUILD SUCCEEDED **` | PASS |
| No `migrationPlan:` in container | `grep migrationPlan HabitsTracker/HabitsTrackerApp.swift` | 0 matches | PASS |
| Generic set is first preset | `CollectionPresetCatalog.all.first?.id` | `"generic"` (verified in source) | PASS |
| Exactly 1 seeded Collection | `defaultCollections` helper count | 1 `Collection(` call | PASS |
| Cost rollup never uses ring | `grep DKProgressRing CollectionDetailView.swift` context | Only in `.count` branch, not in `.costSum` branch | PASS |
| No `print()` in new services | `grep print(` in all new service files | 0 matches | PASS |
| No hardcoded colors in Collection views | `grep Color.` in Features/Collections/ | 0 matches (all via `theme.colors.*`) | PASS |
| All committed hashes exist | `git cat-file -t <hash>` for all 11 hashes | All return `commit` | PASS |

---

## Probe Execution

No probe scripts declared or exist for this phase. `Step 7c: SKIPPED (no probe-*.sh files for phase 03)`.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| COLL-01 | 03-01, 03-02 | StatusSet model with ordered states + terminal index | SATISFIED | `StatusSet` struct in `StatusSetCatalog.swift`; `statusSetID: String` stored on `Collection`; `statusIndex: Int` on `CollectionItem` |
| COLL-02 | 03-02, 03-05 | Generic StatusSet preset is default; prerequisite for user-created lists | SATISFIED | `statusSetID = "generic"` default on `Collection`; `CollectionPresetCatalog.all.first?.id == "generic"`; seeded in `SeedDataService` |
| COLL-03 | 03-04 | Tap-to-advance status chip cycles through states including terminal | SATISFIED | `min(item.statusIndex + 1, terminalIndex)` clamp; stop-at-terminal; contextMenu Reset; on-device approved 2026-07-06 |
| COLL-04 | 03-01, 03-04 | `seasonEpisode` position template: +episode, +season resets episode→1, Finished→terminal | SATISFIED | Fields `season: Int = 1`, `episode: Int = 1` on `CollectionItem`; controls in `CollectionItemDetailView` |
| COLL-05 | 03-01, 03-04 | `counter` template with +1 increment and label | SATISFIED | Fields `counterValue: Int = 0`, `counterLabel: String?` on `CollectionItem`; `+\(counterLabel)` button in `CollectionItemDetailView` |
| COLL-06 | 03-02, 03-03 | Aggregate/cost rollups (X/Y vs cost-sum vs none) via `CollectionRollupEngine` | SATISFIED | Pure engine with 5 pinned unit tests; trailing label on `CollectionRow`; header in `CollectionDetailView` |
| COLL-07 | 03-02, 03-05 | 9 curated presets ship as code catalog; ONE generic starter seeded | SATISFIED | `CollectionPresetCatalog.all` — 9 presets; `SeedDataService.defaultCollections` — exactly 1 starter |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | — |

No debt markers (TODO/FIXME/TBD/XXX), no `print()` calls, no hardcoded colors, no empty stubs. The `EmptyView()` at `CollectionDetailView.swift:129` is the `.none` case of a switch on `CollectionRollupEngine.Result` — correct, not a stub.

---

## Human Verification Required

### 1. Preset picker creates and files a collection

**Test:** Open a focused domain in DomainDetailView → tap "+" in the Collections section header → verify CollectionPresetPickerSheet appears with 9 presets (generic "My List" first) → tap "Shows" → verify a "Shows" collection appears in the domain's Collections section row with "Shows — watched" sub-label → tap the row → verify CollectionDetailView opens with the Shows header and empty state.
**Expected:** Collection persists; appears in the section row immediately after sheet dismiss; full nav works.
**Why human:** Sheet presentation, live SwiftData query update, and NavigationLink push cannot be verified without rendering.

### 2. Chip stop-at-terminal + haptic + explicit Reset

**Test (cleared 2026-07-06 by Gabe):** In a Shows collection, add a show item → tap the "to-watch" chip twice to reach "watched" → tap once more → confirm chip stays at "watched" and a haptic still fires → long-press chip → tap "Reset" → confirm chip returns to "to-watch".
**Expected:** Terminal is sticky; taps at terminal do not wrap; haptic fires on every tap; Reset is explicit and destructive.
**Why human:** `.sensoryFeedback`, contextMenu behavior, and stop-at-terminal UX require physical device. Cleared in 03-04 checkpoint by Gabe.

### 3. seasonEpisode progression display and counter increment

**Test (cleared 2026-07-06 by Gabe):** Open a show item → tap "+Episode" three times → verify display shows "S1 E4" → tap "+Season" → verify "S2 E1" → tap "+Episode" three more times → verify "S2 E4". In a Books collection, create a book item → open it → tap "+Chapter" → verify "Chapter 1".
**Expected:** Correct position-display text after each mutation; +Season resets episode to 1.
**Why human:** Multi-step mutation and label rendering require on-device confirmation. Cleared in 03-04 checkpoint by Gabe.

### 4. Rollup rendering: ring vs text vs absent

**Test:** Create a Shows collection with 5 items; mark 2 as "watched" → verify CollectionRow shows "2/5" trailing caption; open CollectionDetailView → verify DKProgressRing appears at 56pt with "2 of 5 watched" below. Create a "Want to spend on" collection; add items with costs → verify row shows "$NNN" (no ring). Create a collection with `showsAggregate` toggled off → verify no trailing label on row, no rollup in header.
**Expected:** Rollup mode is derived by engine; cost is always plain text, never a ring; tracker shows nothing.
**Why human:** DKProgressRing rendering, layout and font-size of trailing labels, and the visual absence of rollup elements need visual confirmation.

---

## Gaps Summary

No gaps. All 5 roadmap success criteria and all 7 COLL-0x requirements are satisfied by substantive, wired, data-flowing implementations. The 4 human-verification items are confirmations of already-passing code behaviors — 2 of them (03-04 chip and position controls) were already cleared by Gabe's on-device checkpoint approval on 2026-07-06. The remaining 2 (preset picker create-flow and rollup rendering) require a visual pass only.

---

*Verified: 2026-07-06T21:15:00Z*
*Verifier: Claude (gsd-verifier)*
