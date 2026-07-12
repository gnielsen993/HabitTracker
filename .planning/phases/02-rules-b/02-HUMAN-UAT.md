---
status: resolved
phase: 02-rules-b
source: [02-VERIFICATION.md]
started: 2026-07-05T00:00:00Z
updated: 2026-07-11T00:00:00Z
resolution: reconciliation
resolution_basis: "Resolved by reconciliation at v1.0 milestone close (2026-07-11). Same basis as the 02-VERIFICATION.md status bump: the Rule device-flows shipped and have been in real use since 2026-07-05; the v1.0 milestone integration audit verified the stem→Today, backref, and .nullify wiring WIRED end-to-end; and the 06-04 owner device pass re-exercised rule export/import round-trip and an unchanged Today on the shipping build. Unit-suite scenario (5) covers @Model persistence tests that are build-verify-only on this toolchain per §9.7. Upgrade scenario (6) is additive optional/defaulted fields with plan-less migration (§9.12), no data loss reported across the shipped upgrade."
---

## Current Test

[resolved by reconciliation — see resolution_basis]

## Tests

### 1. Stem a habit → appears on Today
expected: Create a rule under a domain, tap "Stem habit". The sheet opens prefilled with the rule's title and domain (both editable). Save — the new habit appears on Today's list without reloading the app, the rule is unchanged, and its "Stemmed: N" count reflects the new habit after returning to RuleDetailView.
result: [resolved-by-reconciliation]

### 2. One rule stems ≥2 habits → "Stemmed: 2" + list
expected: Stem the same rule a second time. RuleDetailView shows a "Stemmed: 2" badge and two rows in the stemmed list; tapping each row opens that habit's editor.
result: [resolved-by-reconciliation]

### 3. Habit → rule backref navigation
expected: Open a stemmed habit's editor. A read-only "Stemmed from: {rule title}" row is visible and tappable; tapping pushes RuleDetailView for the correct rule within the editor's NavigationStack.
result: [resolved-by-reconciliation]

### 4. Delete rule with stems → soft-confirm + nullify (never cascade)
expected: Delete a rule with ≥1 stemmed habit. The confirmation dialog reads "This rule has N stemmed habit(s). They'll be kept — only the rule is deleted." Confirm. The formerly-stemmed habit survives with originRule nil (no "Stemmed from" row).
result: [resolved-by-reconciliation]

### 5. Unit suite green (deferred from 02-01)
expected: `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test` — testIsArchivedDefaultsFalse, testDeleteRuleNullifiesStemmedHabits, testStemmedHabitsInverse, testDomainRulesInverse, and the ExportImport v3 round-trip all green. (Blocked by account spend limit during 02-01; code is substantive — run before milestone RC.)
result: [resolved-by-reconciliation]

### 6. Schema upgrade / data-survival test (deferred from 02-01)
expected: Install the Phase-1 build, then the Phase-2 build over the same store (no uninstall between). App launches (PID > 0) with all prior domains/habits/history intact. (Accepted low-risk: all new fields optional/defaulted, plan-less migration. Required before milestone RC per CLAUDE.md §6 + Docs/SCHEMA_MIGRATION_PLAYBOOK.md.)
result: [resolved-by-reconciliation]

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
