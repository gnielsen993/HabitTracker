---
phase: 03
phase_name: "collections-c"
project: "HabitsTracker — Lifestyle Hub"
generated: "2026-07-06"
counts:
  decisions: 12
  lessons: 6
  patterns: 6
  surprises: 4
missing_artifacts:
  - "RESEARCH.md"
  - "UAT.md"
  - "REVIEW.md"
---

# Phase 03 Learnings: collections-c

## Decisions

### StatusSets as code-only catalog, not a SwiftData @Model

Built-in StatusSet labels are non-editable in v1. Representing them as a pure code struct (`StatusSetCatalog`) — keyed by a stable `String` id, with no persistence — satisfies the COLL-01 "a StatusSet model exists" requirement as a typed value model. It costs nothing to make the labels non-editable: there is nothing persisted to edit.

**Rationale:** Avoids a migration surface and a persistence dependency for data that never changes at runtime; structural non-editability is a correctness guarantee, not a UI guard.
**Source:** 03-CONTEXT.md (D-01, D-03)

---

### Stop-at-terminal chip behavior (not wrap-around)

The tap-to-advance chip clamps at the terminal index — `min(statusIndex+1, terminal)` — rather than cycling back to 0. Tapping an already-terminal item does nothing to the value but still fires haptic feedback.

**Rationale:** A `watched`/`flown` item is precious completion signal. A stray tap must not silently reset it. Reset is an explicit, protected gesture (long-press contextMenu with a VoiceOver custom accessibility action), not the default path.
**Source:** 03-CONTEXT.md (D-06, D-07, D-08)

---

### Explicit Reset as a long-press contextMenu with VoiceOver custom action

Returning an item from terminal to initial state requires a distinct gesture (contextMenu `Button("Reset", role: .destructive)` + `.accessibilityAction(named: "Reset status")`). No confirm dialog is shown on forward advances; the reset gesture is the guarded one.

**Rationale:** Keeps the forward tap path fast and satisfies §9.15 accessibility without a modal confirm on every tap.
**Source:** 03-CONTEXT.md (D-07); 03-04-SUMMARY.md (decisions)

---

### Position controls live in CollectionItemDetailView, not the list row

Season/episode increments, counter "+1", and "Finished" are all in a dedicated detail view. The row shows only a compact position label (`S2 E4`).

**Rationale:** Mirrors the Phase 2 rule row→detail nav shape (D-12). Inline row steppers break at larger Dynamic Type sizes and crowd 44pt tap targets.
**Source:** 03-CONTEXT.md (D-09)

---

### Seed exactly ONE generic starter collection, not all 8 curated presets

`SeedDataService.defaultCollections` returns exactly one `Collection("My List", statusSetID: "generic", domain: mediaDomain)`. Upgraders receive it via the merge-add path only if missing (dedup key: `"<domain.name>::<title>"`).

**Rationale:** Seeding 8 empty lists across freshly-seeded unfocused domains recreates the project's named failure mode ("empty Notion folders") and complicates the upgrader merge-add path.
**Source:** 03-CONTEXT.md (D-14); 03-05-SUMMARY.md (decisions)

---

### X/Y rollup counts only terminal items — mid-step items excluded

`X = items where statusIndex == terminalIndex`. A `watching` show in a `to-watch → watching → watched` set is NOT counted in X regardless of how far along it is.

**Rationale:** "Completion" has a precise, non-ambiguous meaning. Partial progress must not inflate the count.
**Source:** 03-CONTEXT.md (D-16)

---

### Cost rollup is always plain text — never a DKProgressRing

`.costSum(total)` renders as `"$NNN"` monoNumber text in both the row trailing label and the detail header. A `DKProgressRing` is used only for completionist `.count(x, y)` results.

**Rationale:** A cost sum has no meaningful "progress toward a goal" framing — there is no denominator. Forcing a ring would require an upfront budget, which conflicts with the "no total ever required" principle (D-10).
**Source:** 03-CONTEXT.md (D-18); 03-VERIFICATION.md (behavioral spot-checks)

---

### "Money-flavored" is derived, not stored

Whether a collection is cost-flavored is computed at render time: `showsAggregate == true` AND at least one item has a non-nil `cost`. No stored boolean flag. The preset sets a sensible `showsAggregate` default; the user can flip it.

**Rationale:** Avoids a new stored field that would need migration and synchronization with actual item data. Keeps rollup logic centralized in `CollectionRollupEngine`.
**Source:** 03-CONTEXT.md (D-20)

---

### Schema expansion via plan-less inferred migration

`Collection` and `CollectionItem` are added to `.modelContainer(for:[…])` with no `migrationPlan:` argument. All new fields are optional or have defaults. The `Domain.collections` inverse uses `.nullify`; `Collection.items` uses `.cascade`.

**Rationale:** Inferred lightweight migration handles every additive change and dodges the Obj-C `NSException` the explicit plan throws on storage-equivalent adjacent versions. Required-no-default additions are the only failure mode and are prohibited.
**Source:** 03-CONTEXT.md (D-21, D-22); 03-01-SUMMARY.md (decisions)

---

### schemaVersion bumped 3→4 for Collection + CollectionItem round-trip

`ExportImportService.schemaVersion` moves from 3 to 4. `HabitExportBundle` gains `collections: [CollectionDTO]` and `collectionItems: [CollectionItemDTO]` as scalar-only Codable structs with `domainID?` / `collectionID?` foreign keys. Full multi-type completeness is Phase 6; this bump keeps the round-trip green for what Phase 3 adds.

**Rationale:** Data safety rule — never break existing export/import without bumping the version and extending the round-trip. Scalar-only DTOs with FK references are trivially round-trippable without an id-graph.
**Source:** 03-CONTEXT.md (D-23, D-05); 03-05-SUMMARY.md (decisions)

---

### deleteAll ordering: CollectionItem → Collection → Domain

`importReplace` deletes `CollectionItem.self` first, then `Collection.self`, then `Domain.self`. This respects the `.cascade` ownership chain and prevents FK constraint violations.

**Rationale:** Cascade relationships require owned children to be deleted before parents; reversing the order would either crash or leave orphaned rows.
**Source:** 03-05-SUMMARY.md (decisions, T-03-10 mitigation)

---

### Collections section visibility mirrors Rules: guard on `!domain.collections.isEmpty`

`buildCollectionsSection` in `DomainDetailView` only renders when `!domain.collections.isEmpty`. A 0-item collection is a real configured list and is a valid non-empty section entry.

**Rationale:** Mirrors the Phase 2 Rules contract and the DOM-03 "only non-empty sections" loop. Prevents phantom section headers for domains that have not yet created any collections.
**Source:** 03-CONTEXT.md (D-15); 03-03-SUMMARY.md (decisions)

---

## Lessons

### Removing `nonisolated` from a static func that accesses a `@MainActor` property

`StatusSetCatalog.set(for:)` was initially declared `nonisolated static func`. The compiler rejected it with "main actor-isolated static property 'all' can not be referenced from a nonisolated context." The fix was to remove `nonisolated` — the function is called from view code, which already runs on the main actor, so a plain `static func` is correct.

**Context:** The `nonisolated` keyword is only helpful at concurrency boundaries (e.g., actor methods that access non-isolated state). Static catalog lookups called from SwiftUI bodies do not need it.
**Source:** 03-02-SUMMARY.md (auto-fixed issues, Task 1)

---

### `Double?` vs `Double` blocks `XCTAssertEqual(accuracy:)`

`XCTAssertEqual(fetchedItem.cost, 12.99, accuracy: 0.001)` fails to compile because `CollectionItem.cost` is `Double?` and the `accuracy:` overload requires a non-optional `Double`. The fix is to unwrap first: `XCTAssertEqual(try XCTUnwrap(fetchedItem.cost), 12.99, accuracy: 0.001)`.

**Context:** Encountered during the TDD GREEN phase of 03-05. The `XCTUnwrap` approach is the idiomatic fix and also adds an implicit assertion that the value is non-nil.
**Source:** 03-05-SUMMARY.md (auto-fixed issues, Task 2)

---

### DKProgressRing requires a `y > 0` guard before computing `Double(x)/Double(y)`

`CollectionDetailView.rollupBlock` checks `if y == 0` before calling `DKProgressRing(progress: Double(x)/Double(y), ...)`. When `y == 0`, it renders `"0 items"` text with no ring instead.

**Context:** A newly created collection with no items would otherwise produce a divide-by-zero (NaN progress) passed to `DKProgressRing`, which had undefined visual behavior. The guard is a correctness requirement, not just a polish choice.
**Source:** 03-03-SUMMARY.md (decisions, T-03-05 mitigation)

---

### deleteAll ordering for owned relationships must follow the cascade chain

When `importReplace` wipes the store, deleting `Domain` before `Collection` or `Collection` before `CollectionItem` produces FK violations because cascade rules expect children to be removed first. Correct order: `CollectionItem → Collection → Domain`.

**Context:** Discovered during 03-05 planning. The lesson generalizes: whenever SwiftData models use `.cascade`, the deleteAll loop must walk the ownership tree from leaves to root.
**Source:** 03-05-SUMMARY.md (T-03-10 mitigation)

---

### A doc comment containing the literal string being grep-excluded trips acceptance criterion checks

Both `CollectionDetailView.swift` (03-03) and `CollectionItemDetailView.swift` (03-04) had doc comments written as `"declares NO NavigationStack"`. The plan's acceptance criterion was `grep -c "NavigationStack" <file> returns 0`, which the comment itself violated. Fix: change comment text to `"declares no nav container of its own"`.

**Context:** Plan acceptance criteria that grep for the absence of a token should be written against code tokens, not English prose. Doc comments that use a banned term as an example will always fail the check.
**Source:** 03-03-SUMMARY.md (auto-fixed issues); 03-04-SUMMARY.md (auto-fixed issues)

---

### Xcode 26.3 / iOS 26 CoreSimulator XCTest host-launch crash blocks all SwiftData test execution on this machine

`xcodebuild test` aborts during host-app launch with `EXC_BREAKPOINT` in SwiftData before any test method runs. This is a pre-existing machine-wide environment blocker — identical behavior appears on `RuleModelTests` from Phase 2, which were known-good. It is not caused by any Phase 3 code. Tests are therefore build-verified only, not execution-verified, across all five plans.

**Context:** The blocker recurred on 03-01, 03-02, 03-03, 03-04, and 03-05. The two human-gated checkpoints (03-01 upgrade test, 03-04 UX device pass) were resolved by owner reasoning and physical-device confirmation respectively — not by fixing the simulator environment.
**Source:** 03-01-SUMMARY.md, 03-02-SUMMARY.md, 03-05-SUMMARY.md (known issues); 03-VERIFICATION.md (environment note)

---

## Patterns

### Mirror the DomainDetailView Rules section shape for Collections

The Collections section in `DomainDetailView` is a structural copy of the Rules section: same `DomainSection(id:)` construction, same section header with "+" button + `accessibilityAddTraits(.isHeader)`, same `NavigationLink { DetailView } label: { RowView }.buttonStyle(.plain)` pattern, same `!domain.<relationship>.isEmpty` guard.

**When to use:** Whenever a new entity type is added to `DomainDetailView` as a section (e.g., Clips in Phase 4, Ideas in Phase 5). Copy the Rules section structure and adjust the entity type, detail view, and row view.
**Source:** 03-CONTEXT.md (code_context, D-15); 03-03-SUMMARY.md (Task 2)

---

### Code-only catalog structs as the single source of truth the UI renders from

`StatusSetCatalog` (9 StatusSets keyed by stable `String` id) and `CollectionPresetCatalog` (9 presets with `statusSetID`, `progressTemplate`, `showsAggregate` defaults) are pure enums with no persistence, no DesignKit dependency, no SwiftData. The UI derives everything — chip labels, preset picker rows, rollup semantics — from these catalogs at render time.

**When to use:** When built-in configuration options are non-editable in v1 and their shape is stable. Avoids a migration surface and an in-app editor while keeping the UI fully data-driven. Extend the catalog (not the UI) when new presets or status sets are needed.
**Source:** 03-CONTEXT.md (D-01, D-12); 03-02-SUMMARY.md (Task 1)

---

### Pure engine with same-commit unit tests (§9.5)

`CollectionRollupEngine` is a `Foundation`-only enum with a single `static func rollup(collection:items:) -> Result`. Its 5 unit tests (happy path, empty list, mid-step exclusion, mixed-nil cost, `showsAggregate` off) land in the same commit. The engine has no DesignKit, no SwiftData, no `print()`.

**When to use:** Any deterministic computation over domain models that can be expressed as a pure function. Test the engine independently before wiring it to UI. The same pattern is established for `StreakEngine`, `WeeklyGoalEngine`, and `StatsEngine`.
**Source:** 03-CONTEXT.md (D-19); 03-02-SUMMARY.md (Task 2); CLAUDE.md §9.5

---

### tapCounter @State to keep .sensoryFeedback firing at terminal

The chip uses a separate `@State var tapCounter: Int` as the trigger for `.sensoryFeedback(.impact(weight:.light), trigger: tapCounter)`. On every tap, `tapCounter += 1` and `statusIndex = min(statusIndex+1, terminal)`. Because the trigger is the tap count — not `statusIndex` — the haptic fires even when clamped at terminal, making the no-op feel intentional rather than broken.

**When to use:** Any `.sensoryFeedback` that must fire on user gesture even when the underlying value is clamped or unchanged. Using the mutable value directly as a trigger silently suppresses feedback when the value doesn't change.
**Source:** 03-CONTEXT.md (D-08); 03-04-SUMMARY.md (Task 1, CollectionItemRow.swift)

---

### Scalar-only DTO Codable structs for export round-trip with FK references

`CollectionDTO` and `CollectionItemDTO` carry only scalar fields plus nullable `domainID: UUID?` / `collectionID: UUID?` foreign keys. `importReplace` rebuilds the id graph in dependency order: domain index first, then collection index, then items wired via `collectionIndex[dto.collectionID]`. Dangling FK lookups resolve to `nil` (never force-unwrapped) and the item is inserted anyway.

**When to use:** Whenever exporting a new entity type in a `HabitExportBundle`. Scalars + FK UUIDs keep the JSON human-readable and the import safe against forward/backward version skew. Always build the index for the parent type before iterating child DTOs.
**Source:** 03-CONTEXT.md (D-05); 03-05-SUMMARY.md (Task 2)

---

### TDD RED-then-GREEN for export/import tests

The v4 round-trip test (`testExportImportRoundTripV4`) was committed RED (test file + `build-for-testing` failure) before the `ExportImportService` changes landed (GREEN). The existing `testExportImportRoundTripV3` was updated in the same GREEN commit to pass the extended `exportData` signature.

**When to use:** Export/import extensions that change a public function signature. The RED commit proves the test is genuinely testing the new behavior; the GREEN commit proves the implementation satisfies it. Regression guard: always update the prior-version test call site to keep it compiling and passing.
**Source:** 03-05-SUMMARY.md (TDD gate compliance)

---

## Surprises

### The 03-01 upgrade-test gate was cleared by additive-migration reasoning, not by running it

The SCHEMA_MIGRATION_PLAYBOOK's mandatory upgrade test (install prior build → log data → install over → confirm intact) could not be run automatically due to the CoreSimulator blocker. Gabe approved clearing the gate on the argument that the change is purely additive (two brand-new `@Model` tables, every field optional/defaulted) — the exact shape inferred lightweight migration is guaranteed to handle. The playbook's documented failure mode (required-no-default fields) does not apply.

**Impact:** Establishes a precedent: purely additive schema expansions with no optional-field violations can be approved via reasoning when the automated path is blocked, without waiting for a manual over-install. Non-additive changes still require the physical upgrade test.
**Source:** 03-01-SUMMARY.md (upgrade test gate checkpoint resolution)

---

### The 03-04 first execution attempt dropped on an API connection error with zero committed work

The first agent run for 03-04 (Collection Item Interaction Surface) terminated mid-execution due to an API connection error before producing any code or commits. The plan was re-run cleanly from the beginning as a fresh execution; the second run completed in ~5 minutes and produced all three files and two commits.

**Impact:** Confirms that gsd-executor's atomic-commit discipline (each task committed before moving to the next) is the correct guard for connection interruptions — but only if the commit happens before the connection drops. When a full plan re-run is needed, a clean start is preferable to attempting to resume from a partially-applied state.
**Source:** 03-04-SUMMARY.md (plan context, metrics note "5 min" for a 3-file + 4-file plan)

---

### The CoreSimulator XCTest blocker recurred across all five plans — blocking both human-gate checkpoints

The pre-existing Xcode 26.3 / iOS 26 CoreSimulator host-launch crash (documented in STATE.md since Phase 1) surfaced in every single plan of Phase 3. Both blocking human-verify gates (03-01 schema migration, 03-04 UX device pass) were un-runnable via the automated path and had to be resolved by owner reasoning (03-01) and physical-device confirmation (03-04).

**Impact:** Any phase that includes SwiftData tests or a schema-expansion gate on this machine is build-verified only. The verification baseline must be stated explicitly in SUMMARY and VERIFICATION artifacts; "tests pass" cannot mean "tests executed" in this environment.
**Source:** 03-01-SUMMARY.md, 03-02-SUMMARY.md, 03-05-SUMMARY.md (known issues); 03-VERIFICATION.md (environment note)

---

### The 03-04 on-device human checkpoint was the only gate cleared by physical-device confirmation from Gabe

Gabe ran the 7-step on-device pass on an iPhone 17 and confirmed: chip stop-at-terminal + haptic, "+Season resets episode to 1", counter "+1", Dynamic Type scaling, and VoiceOver "Reset status" custom action. This was the only interactive behavior verification in the phase — all other truths were verified by grep and build.

**Impact:** Physical-device gates for chip/haptic/VoiceOver behavior are non-negotiable; they cannot be replaced by simulator testing even when the simulator is operational. Plan these checkpoints explicitly as blocking human-verify tasks with a clear 7-step checklist so the owner knows exactly what to confirm.
**Source:** 03-04-SUMMARY.md (checkpoint gate section); 03-VERIFICATION.md (human verification items 2 and 3)

---

*Phase: 03-Collections (C)*
*Extracted: 2026-07-06*
