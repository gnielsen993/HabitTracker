# Milestones

## v1.0 Lifestyle Hub (Shipped: 2026-07-12)

**Phases completed:** 6 phases, 33 plans, 60 tasks

**Key accomplishments:**

- RED-by-design XCTest scaffold (Domain shape + isFocused default, version-gated focus backfill idempotency, custom-domain persistence, schemaVersion-2 Export/Import round-trip) plus a committed DOM-01 upgrade-test merge-gate runbook.
- Plan-less `@Model` rename of `Category` to `Domain` with the additive defaulted `isFocused: Bool = false` field, `Habit.category` retyped to `Domain?`, all ~10 reference sites updated compile-clean, and Export/Import bumped to schemaVersion 2 with `DomainDTO` + `isFocused` — app target builds green on iPhone 17. The DOM-01 manual upgrade-test merge gate is surfaced as a PENDING owner-side checkpoint (not satisfied by this agent).
- Version-gated, idempotent seed reconciliation (persisted `lastSeededVersion` marker; once-only `previous>0`-guarded focus backfill flipping pre-existing Domains to focused; name-keyed merge-add of Style/Diet/Money/Media as unfocused) wired into `BootstrapService` with an injectable `UserDefaults`, plus the app-level `accentColor(forToken:scheme:)` resolver over the 5 DesignKit accents.
- Task 1 — Fold calendar into Progress behind a segmented control
- 1. [Rule 3 - Blocking] `accentColor` free function shadowed by SwiftUI `View.accentColor`
- 1. [Rule 1 - Bug] `accentColor` free function shadowed by SwiftUI `View.accentColor`
- Rule @Model + bidirectional Rule↔Habit .nullify stem link + Domain.rules inverse, all additive under plan-less inferred migration, with Export/Import bumped to schemaVersion 3.
- RuleRow, RuleDetailView, RuleEditorView, and the Rules section in DomainDetailView — full CRUD + archive + delete-with-stems, all token-only with VoiceOver labels and explicit empty states.
- Shared fill-then-commit HabitCreateSheet wired to three call sites — Stem in RuleDetailView, Add Habit in HabitManagerView, plus a read-only "Stemmed from" backref in HabitEditorView — closing the bidirectional Rule↔Habit link.
- One-liner:
- One-liner:
- One-liner:
- One-liner:
- One-liner:
- Clip @Model (title/url/note?/tag?/status/isArchived) with a String-backed ClipStatus facade and a Domain.clips `.nullify` inverse, registered plan-less — the schema foundation every later Clips plan builds on.
- Pure `URLComponents`-only URL-to-title suggestion helper (host/slug humanization, zero network) with 4 green XCTest cases, embodying the D-02 offline-friction-reduction decision.
- Three new SwiftUI surfaces under `Features/Clips/` — a create/edit Form sheet with a zero-network title-suggestion helper, a data-driven row card, and a detail view with a prominent full-width Open Link CTA — all mirroring the Phase 2 Rule surfaces exactly, token-only, and fully offline.
- ExportImportService bumped to schemaVersion 5 with a ClipDTO that round-trips title/url/note/tag/status(raw)/isArchived plus the domain FK, mirroring the existing RuleDTO block exactly.
- A Clips section appended to `DomainDetailView` — reachable "+" → `ClipEditorView(domain:)` create, non-archived clips listed recency-first, each row pushing `ClipDetailView` — mirroring the locked Rules/Collections nav template exactly and rendering only when the domain has clips (D-10, CLIP-03).
- Idea @Model with nested Idea.PromotedKind raw-string facade, Domain.ideas .nullify inverse, and plan-less container registration — the schema-expansion foundation every later Phase 5 plan builds on.
- ExportImportService schemaVersion bumped 5→6 with a full Idea round-trip (IdeaDTO, export map, import loop, nullify-ordered deleteAll) and SettingsView wired to supply the ideas @Query.
- PromoteService — a pure, save-free enum namespace centralizing the promote-is-consume logic (archive + scalar forward-link + domain-required predicate), proven by a 4/4 green runnable-tier test suite with zero ModelContainer.
- Automated simctl migration test proves the Idea @Model + Domain.ideas nullify inverse migrates a real Phase-4 store (16 domains/10 habits/2 collections/1 dailyEntry) with zero data loss, no crash, and ZIDEA added empty — reusing the CLIP-01 sentinel-injection precedent.
- Title-only IdeaCaptureSheet (dual create/edit init, orphan-free save, hard-delete escape hatch) wired to a net-new top-trailing "+" on Today that captures unfiled ideas straight into the Hub inbox without touching Today's existing content.
- The three existing target editors (Rule/Habit/CollectionItem) now accept an idea prefill and self-consume (or hand off) via PromoteService on Save, plus a new app-wide PromoteToCollectionPicker — no bespoke PromoteSheet, maximal reuse (D-06/D-07).
- IdeaRow: a data-driven row (§9.2) with tap-to-edit (opens IdeaCaptureSheet), an unfiled-only File domain-Menu, and an always-on Promote Menu that routes into the three prefilled target editors from 05-06 and consumes the idea via PromoteService — the surface where the inbox actually empties.
- A count-gated "N to file" DKCard pinned above HubView's domain grid opens InboxView, a self-querying list of unfiled ideas rendered as IdeaRows — the surface where captured ideas land until filed or promoted.
- DomainDetailView gains a fourth offshoot section — filed Ideas, rendered via the reusable IdeaRow with no detail-view wrapper (D-08) — plus an in-domain "+" that captures a new idea pre-filed under that domain (D-09).
- Gate 1 — Build.
- Cross-domain search on the Hub tab (`.searchable` + iOS 26 `.searchToolbarBehavior(.minimize)`) with type-grouped results (Habits/Rules/Collections/Clips/Ideas) that reuse each item's existing detail/editor surface, plus confirmation that all pre-existing empty states satisfy §9.3.
- Fixed the silent-VoiceOver Collections tap-to-advance chip (converted to a reachable Button with label+hint, mirroring ClipRow) and added a read-only Settings "About" section surfacing app version + data schema version from a single source of truth.
- Added `testAllTypesSurviveRoundTripV6` (all 7 persisted types + cross-type relationships in one bundle) and `testMalformedAndUnsupportedImportPreservesStore` (invalid JSON + schemaVersion-7 both throw and never destroy the existing store) to `ExportImportTests.swift`; `ExportImportService.swift` and `schemaVersion` (6) are unchanged.

---
