---
phase: 02-rules-b
verified: 2026-07-05T00:00:00Z
status: human_needed
score: 5/5 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Create a rule under a domain, then tap 'Stem habit'. The sheet opens prefilled with the rule's title and domain — both editable. Save the habit and confirm it appears on Today."
    expected: "The new habit appears on Today's list without reloading the app. The rule is unchanged. The rule's 'Stemmed: N' count reflects the new habit after returning to RuleDetailView."
    why_human: "Today's data flow (TodayView rendering newly inserted Habit) is runtime-only. The insert path is statically correct but the appearance on Today requires a live SwiftData context update cycle that cannot be confirmed by static analysis."
  - test: "Stem the same rule a second time, creating a second habit. Open RuleDetailView and verify 'Stemmed: 2' badge and two rows in the stemmed list. Each row opens its habit editor."
    expected: "Badge shows 'Stemmed: 2'; both stemmed habits are listed; tapping each opens HabitEditorView showing that habit."
    why_human: "The relationship is structurally correct (stemmedHabits inverse wired) but the count-reflects-live-data check requires a running SwiftData context."
  - test: "Open HabitEditorView for a stemmed habit. Verify a read-only 'Stemmed from: {rule title}' backref row appears. Tap it and confirm it navigates to RuleDetailView for the correct rule."
    expected: "The backref row is visible and tappable; tapping pushes RuleDetailView within HabitEditorView's NavigationStack."
    why_human: "NavigationLink push behavior from inside a sheet-presented NavigationStack requires runtime verification."
  - test: "Delete a rule that has at least one stemmed habit. Verify the confirmation dialog appears with the exact copy 'This rule has N stemmed habit(s). They'll be kept — only the rule is deleted.' Confirm deletion. Open the formerly-stemmed habit and confirm it still exists with originRule nil (no backref row visible)."
    expected: "Rule is deleted; its previously-stemmed habit survives; the habit's editor shows no 'Stemmed from' row."
    why_human: "The .nullify delete rule is correctly modeled but the actual SwiftData cascade behavior must be confirmed in a live context."
  - test: "Run xcodebuild test (-scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test) and confirm RuleModelTests + ExportImportTests pass."
    expected: "testIsArchivedDefaultsFalse, testDeleteRuleNullifiesStemmedHabits, testStemmedHabitsInverse, testDomainRulesInverse, testExportImportRoundTripV3 all green."
    why_human: "Unit test execution was blocked by account spend limit during 02-01 and was not re-run. The test code is substantive and structurally correct. A full test run is required before milestone RC."
  - test: "Upgrade test: install the Phase-1 build over an existing store, then install the Phase-2 build over that same store (no uninstall between builds). Confirm app launches and all prior domains/habits/history are intact."
    expected: "App launches without crash (PID > 0); all pre-Phase-2 data is visible."
    why_human: "Accepted by developer on low-risk basis (all new fields are optional/defaulted, migration plan-less). Must be validated before milestone RC per CLAUDE.md §6 and Docs/SCHEMA_MIGRATION_PLAYBOOK.md."
---

# Phase 02: Rules (Phase B) Verification Report

**Phase Goal:** Rules exist as clean, reference-first items filed by domain, and the user can spin a habit off a rule via a shared, reusable habit-create sheet that flows the new habit into Today.
**Verified:** 2026-07-05
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can create, edit, and archive a Rule (title + body + optional sourceURL), filed under a domain | VERIFIED | `RuleEditorView` has dual create/edit init, Form with title/body/sourceURL fields, archive toggle ("Archive rule"/"Unarchive Rule"), save CTA "Add Rule"/"Save Changes", `modelContext.insert` in create path; domain picker backed by `@Query(sort: \Domain.sortIndex)` |
| 2 | "Stem habit" opens a prefilled sheet (title + rule's domain, editable schedule); the new habit appears on Today and the rule is left untouched | VERIFIED (code); human_needed (Today render) | `RuleDetailView` presents `HabitCreateSheet(source: .rule(rule))`; sheet's `seedDraftFromSource()` sets `title = rule.title`, `selectedDomain = rule.domain`; schedule fields are editable; `originRule` set on Habit, rule never mutated; Today runtime appearance is human-only |
| 3 | The rule shows "Stemmed: N habits" that jumps to a habit; the habit shows a "from rule" backref that jumps to the rule | VERIFIED (code); human_needed (navigation) | `RuleDetailView` `stemmedBlock` renders `DKBadge("Stemmed: \(rule.stemmedHabits.count)")` + per-habit button → `editingHabit` sheet; `HabitEditorView` has `if let originRule = habit.originRule { ... NavigationLink { RuleDetailView(rule: originRule) } }` |
| 4 | One rule can stem >= 2 habits | VERIFIED | `Rule.stemmedHabits: [Habit]` with `.nullify` inverse; `HabitCreateSheet` creates each habit with `originRule: rule`; `RuleModelTests.testStemmedHabitsInverse` and `testStemmedHabitsCount` cover this structurally |
| 5 | Deleting a rule with stemmed habits soft-confirms; the habits survive and originRule is nulled (never cascade) | VERIFIED (code); human_needed (live delete) | `RuleEditorView.deleteDialogMessage` shows "This rule has N stemmed habit(s). They'll be kept — only the rule is deleted."; `confirmationDialog` with "Delete Rule" / "Cancel"; `.nullify` on `Rule.stemmedHabits` inverse via `@Relationship(deleteRule: .nullify, inverse: \Habit.originRule)`; `RuleModelTests.testDeleteRuleNullifiesStemmedHabits` tests the nullify behavior |

**Score:** 5/5 truths verified in code; 4 truths also require human runtime confirmation

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `HabitsTracker/Models/Rule.swift` | @Model with title/body/sourceURL/createdAt/isArchived/domain/stemmedHabits | VERIFIED | 39 lines; `@Attribute(.unique) var id`; `isArchived: Bool = false`; `@Relationship(deleteRule: .nullify, inverse: \Habit.originRule) var stemmedHabits: [Habit]`; plain `@Relationship var domain: Domain?` |
| `HabitsTracker/Models/Habit.swift` | originRule: Rule? plain relationship | VERIFIED | `@Relationship var originRule: Rule?` present; init includes `originRule: Rule? = nil` |
| `HabitsTracker/Models/Domain.swift` | rules: [Rule] owning inverse | VERIFIED | `@Relationship(deleteRule: .nullify, inverse: \Rule.domain) var rules: [Rule] = []` |
| `HabitsTracker/HabitsTrackerApp.swift` | Rule.self in plan-less container | VERIFIED | `Rule.self` in type list; no `migrationPlan` argument |
| `HabitsTracker/Services/ExportImportService.swift` | schemaVersion 3 + RuleDTO + originRuleID | VERIFIED | `private let schemaVersion = 3`; `struct RuleDTO`; `let originRuleID: UUID?` on `HabitDTO`; `rules: [RuleDTO]` on `HabitExportBundle`; delete order: HabitState → DailyEntry → Habit → Rule → Domain |
| `HabitsTracker/Features/Settings/SettingsView.swift` | @Query Rule.createdAt + rules: arg to exportData | VERIFIED | `@Query(sort: \Rule.createdAt) private var rules: [Rule]`; `exportData(categories: categories, habits: habits, entries: entries, rules: rules)` |
| `HabitsTracker/Features/Rules/RuleRow.swift` | Data-driven card row, no @Query | VERIFIED | 62 lines; `let rule: Rule`; no `@Query` or `modelContext`; `secondaryLine` builds "Stemmed: N" / "· has link"; `≥44pt` via `frame(maxWidth: .infinity, minHeight: 44)` |
| `HabitsTracker/Features/Rules/RuleDetailView.swift` | Reference-first detail, no own NavigationStack | VERIFIED | 208 lines; no `NavigationStack` in code (only in doc comment); 5 conditional blocks; `stemming` @State presents `HabitCreateSheet(source: .rule(rule))`; toolbar Edit → `RuleEditorView` |
| `HabitsTracker/Features/Rules/RuleEditorView.swift` | Create/edit form + archive + delete confirm | VERIFIED | 281 lines; dual init; "Add Rule"/"Save Changes" CTA; `confirmationDialog` with stem-aware copy; archive toggle; delete with `.nullify` |
| `HabitsTracker/Features/Hub/DomainDetailView.swift` | Rules section in nonEmptySections | VERIFIED | 158 lines; `buildRulesSection` filters `!$0.isArchived`, sorts newest-first; section header with "+" → `RuleEditorView(domain:)`; NavigationLink rows → `RuleDetailView` |
| `HabitsTracker/Features/Habits/HabitCreateSheet.swift` | Shared fill-then-commit sheet | VERIFIED | 221 lines; `HabitSource` enum; single `modelContext.insert` in `saveHabit()`; Cancel inserts nothing; `seedDraftFromSource()` prefills title + domain from rule; `originRule` set in save path |
| `HabitsTracker/Features/Settings/HabitManagerView.swift` | Add Habit via HabitCreateSheet, no "New Habit" insert | VERIFIED | 74 lines; `@State private var creatingHabit`; `.sheet(isPresented: $creatingHabit) { HabitCreateSheet(source: .manual) }`; no "New Habit" string; no pre-insert |
| `HabitsTracker/Features/Settings/HabitEditorView.swift` | "Stemmed from" backref row | VERIFIED | 125 lines; `if let originRule = habit.originRule { NavigationLink { RuleDetailView(rule: originRule) } ... }`; no `originRule!`; no write path to originRule |
| `HabitsTrackerTests/RuleModelTests.swift` | 4 tests covering default, nullify, inverses | VERIFIED | 94 lines; `testIsArchivedDefaultsFalse`, `testDeleteRuleNullifiesStemmedHabits`, `testStemmedHabitsInverse`, `testDomainRulesInverse` |
| `HabitsTrackerTests/ExportImportTests.swift` | V3 round-trip asserting stem link + isArchived | VERIFIED | 62 lines; `testExportImportRoundTripV3` asserts `fetchedHabit?.originRule?.id == fetchedRule?.id` and `isArchived == false` |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `HabitsTrackerApp.swift` | `Rule` | `modelContainer` type list | WIRED | `Rule.self` present; no `migrationPlan` |
| `Habit.swift` | `Rule` | `originRule` plain relationship | WIRED | `@Relationship var originRule: Rule?` |
| `Rule.swift` | `Habit` (nullify inverse) | `stemmedHabits` | WIRED | `@Relationship(deleteRule: .nullify, inverse: \Habit.originRule) var stemmedHabits: [Habit]` |
| `Domain.swift` | `Rule` (nullify inverse) | `rules` | WIRED | `@Relationship(deleteRule: .nullify, inverse: \Rule.domain) var rules: [Rule]` |
| `DomainDetailView.swift` | `RuleDetailView` | NavigationLink per RuleRow | WIRED | `NavigationLink { RuleDetailView(rule: rule) }` in `rulesSectionContent` |
| `DomainDetailView.swift` | `RuleEditorView` | "+" button → sheet | WIRED | `sheet(isPresented: $creatingRule) { RuleEditorView(domain: domain) }` |
| `RuleDetailView.swift` | `HabitCreateSheet` | Stem button → `stemming` @State → sheet | WIRED | `.sheet(isPresented: $stemming) { HabitCreateSheet(source: .rule(rule)) }`; button sets `stemming = true` |
| `HabitManagerView.swift` | `HabitCreateSheet` | Add Habit → `creatingHabit` @State → sheet | WIRED | `.sheet(isPresented: $creatingHabit) { HabitCreateSheet(source: .manual) }` |
| `HabitEditorView.swift` | `RuleDetailView` | backref NavigationLink | WIRED | `NavigationLink { RuleDetailView(rule: originRule) }` guarded by `if let` |
| `RuleEditorView.swift` | `Rule` | `modelContext.insert` on create / mutate on edit | WIRED | `modelContext.insert(rule)` in create branch; `rule.title = trimmed` etc. in edit branch |
| `SettingsView.swift` | `ExportImportService.exportData` | `rules:` argument | WIRED | `exportData(categories:habits:entries:rules:)` call includes `rules: rules` |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `RuleDetailView` | `rule.stemmedHabits` | SwiftData relationship inverse | Yes — live inverse populated by `Rule.stemmedHabits` via `.nullify` relationship | FLOWING |
| `DomainDetailView` | `domain.rules` | SwiftData relationship inverse `Domain.rules` | Yes — filtered + sorted in `buildRulesSection` | FLOWING |
| `HabitCreateSheet` | `title`, `selectedDomain` | `seedDraftFromSource()` on `.onAppear` | Yes — seeded from `rule.title`/`rule.domain` for rule source; domains from `@Query` | FLOWING |
| `HabitEditorView` | `habit.originRule` | SwiftData model property | Yes — set at creation in `HabitCreateSheet.saveHabit()` | FLOWING |
| `ExportImportService` | `rules` array | `@Query(sort: \Rule.createdAt)` in SettingsView | Yes — live query result passed as parameter | FLOWING |

---

### Behavioral Spot-Checks

Static verification only (no simulator available). Structural checks performed:

| Behavior | Check | Result | Status |
|----------|-------|--------|--------|
| Single insert on Save in HabitCreateSheet | `grep modelContext.insert HabitCreateSheet.swift` | 1 occurrence at line 217 (save path only) | PASS |
| No "New Habit" pre-insert in HabitManagerView | `grep "New Habit" HabitManagerView.swift` | 0 matches | PASS |
| No force-unwrap of originRule in HabitEditorView | `grep "originRule!" HabitEditorView.swift` | 0 matches | PASS |
| Delete Rule before Domain in deleteAll | Line order in ExportImportService.deleteAll | Rule.self at line 243, Domain.self at line 244 | PASS |
| No TODO(02-03) remaining in RuleDetailView | `grep "TODO(02-03)" RuleDetailView.swift` | 0 matches | PASS |
| No .disabled(true) on Stem button | `grep ".disabled(true)" RuleDetailView.swift` | 0 matches | PASS |
| No NavigationStack in RuleDetailView struct | Code-only grep (excluding comments) | 0 code occurrences | PASS |

---

### Probe Execution

Step 7c: SKIPPED — no probe scripts found under `scripts/*/tests/probe-*.sh`. No probes declared in PLAN files.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| RULE-01 | 02-01, 02-02 | Create/edit/archive Rule (title, body, sourceURL, createdAt) filed under domain | SATISFIED | `Rule.swift` @Model complete; `RuleEditorView` CRUD; `DomainDetailView` Rules section |
| RULE-02 | 02-03 | Shared habit-create-from-source sheet (prefilled title + domain, editable; user sets schedule + required/optional) | SATISFIED | `HabitCreateSheet.swift` with `HabitSource` enum; both fields editable; reusable path |
| RULE-03 | 02-03 | "Stem habit" creates Habit, leaves rule untouched, prefilled sheet, new habit appears on Today | SATISFIED (code) / human_needed (Today render) | `RuleDetailView` Stem → `HabitCreateSheet(source: .rule(rule))`; rule never mutated; Today runtime appearance is human-only |
| RULE-04 | 02-02, 02-03 | Bidirectional link: rule shows "Stemmed: N" (tap → habit), habit shows "from rule" backref (tap → rule); one rule can stem ≥2 habits | SATISFIED | `RuleDetailView.stemmedBlock`; `HabitEditorView` backref row; `Rule.stemmedHabits: [Habit]` relationship |
| RULE-05 | 02-01, 02-02 | Delete rule with stemmed habits: soft-confirm; habits survive; originRule nulled (never cascade) | SATISFIED (code) / human_needed (live delete) | `.nullify` on `Rule.stemmedHabits`; `confirmationDialog` with correct copy; `RuleModelTests.testDeleteRuleNullifiesStemmedHabits` |

All 5 requirement IDs (RULE-01 through RULE-05) are accounted for. No orphaned requirements for this phase.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `RuleDetailView.swift` | 24 | Comment reads "02-03 wires the real sheet here" (stale after 02-03 completed) | Info | Stale comment only; the actual sheet is wired on line 63. No behavioral impact. |

No TBD, FIXME, or XXX debt markers in any phase-modified file. No `print()` calls. No duplicate `* 2.swift` files. All stub indicators are absent from production code paths.

---

### Human Verification Required

The following items require a running simulator or device. All supporting code is present and structurally correct — these are runtime-behavior confirmations only.

#### 1. New habit appears on Today after Stem

**Test:** Open a domain's DomainDetailView, tap a rule, tap "Stem habit". Edit the prefilled title if desired. Tap "Add Habit". Navigate to Today.
**Expected:** The newly created habit appears in Today's list for the current day.
**Why human:** TodayView's data pipeline (SwiftData query + display of a newly inserted Habit) is a live rendering concern. The insert path in HabitCreateSheet is structurally correct but Today's appearance requires a running app.

#### 2. "Stemmed: N" count updates live after stemming

**Test:** Open a rule that has 0 stemmed habits. Stem one habit. Return to RuleDetailView. Stem a second habit. Verify the badge shows "Stemmed: 2" and two rows are listed.
**Expected:** "Stemmed: 2" DKBadge; two habit rows each tappable to open HabitEditorView.
**Why human:** SwiftData relationship inverse (`stemmedHabits`) count updating within a live session requires runtime confirmation.

#### 3. "Stemmed from" backref navigates correctly inside a sheet-presented NavigationStack

**Test:** In HabitManagerView, tap Edit on a stemmed habit. Verify the "Stemmed from: {rule title}" row is present. Tap it.
**Expected:** RuleDetailView for the correct rule is pushed within HabitEditorView's NavigationStack (no doubled nav chrome).
**Why human:** NavigationLink push behavior from within a sheet-presented NavigationStack has historically had nested-nav failure modes in SwiftUI.

#### 4. Delete-with-stems dialog + nullify behavior

**Test:** Create a rule with two stemmed habits. Open RuleEditorView. Tap Delete Rule. Verify the dialog reads "This rule has 2 stemmed habit(s). They'll be kept — only the rule is deleted." Confirm. Verify both habits still exist in HabitManagerView with no "Stemmed from" row.
**Expected:** Rule deleted; both habits survive; `originRule` is nil on both (no backref row).
**Why human:** SwiftData `.nullify` delete rule behavior is tested in `RuleModelTests` but in-memory only; live store behavior needs confirmation.

#### 5. Unit test suite execution (RuleModelTests + ExportImportTests)

**Test:** `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test`
**Expected:** All 5 tests green (testIsArchivedDefaultsFalse, testDeleteRuleNullifiesStemmedHabits, testStemmedHabitsInverse, testDomainRulesInverse, testExportImportRoundTripV3).
**Why human:** Test execution was blocked by account spend limit during 02-01; no test run has been confirmed. The test code is substantive and structurally correct.

#### 6. Upgrade test (Phase-1 store → Phase-2 build, data integrity)

**Test:** Per `Docs/UPGRADE_TEST_RUNBOOK.md` — install Phase-1 build, create data, install Phase-2 build over the same store (no uninstall), confirm data intact.
**Expected:** App launches without crash; all prior domains/habits/history are visible.
**Why human:** Explicitly deferred in 02-01-SUMMARY.md with developer approval (low-risk basis). All new fields are optional/defaulted; migration is plan-less per playbook. Must be confirmed before milestone RC per CLAUDE.md §6.

---

### Gaps Summary

No code gaps. All 5 success criteria are statically verified in the codebase. All artifacts exist, are substantive (no stubs), and are correctly wired. Data flows are connected. The 6 human verification items above are runtime-behavior confirmations — they cannot be resolved by static analysis and are not code defects.

The one carry-forward item from 02-01-SUMMARY.md (upgrade test + unit suite execution) is included as human verification items 5 and 6 above.

---

_Verified: 2026-07-05_
_Verifier: Claude (gsd-verifier)_
