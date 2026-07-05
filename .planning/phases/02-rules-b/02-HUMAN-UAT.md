---
status: partial
phase: 02-rules-b
source: [02-VERIFICATION.md]
started: 2026-07-05T00:00:00Z
updated: 2026-07-05T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Stem a habit → appears on Today
expected: Create a rule under a domain, tap "Stem habit". The sheet opens prefilled with the rule's title and domain (both editable). Save — the new habit appears on Today's list without reloading the app, the rule is unchanged, and its "Stemmed: N" count reflects the new habit after returning to RuleDetailView.
result: [pending]

### 2. One rule stems ≥2 habits → "Stemmed: 2" + list
expected: Stem the same rule a second time. RuleDetailView shows a "Stemmed: 2" badge and two rows in the stemmed list; tapping each row opens that habit's editor.
result: [pending]

### 3. Habit → rule backref navigation
expected: Open a stemmed habit's editor. A read-only "Stemmed from: {rule title}" row is visible and tappable; tapping pushes RuleDetailView for the correct rule within the editor's NavigationStack.
result: [pending]

### 4. Delete rule with stems → soft-confirm + nullify (never cascade)
expected: Delete a rule with ≥1 stemmed habit. The confirmation dialog reads "This rule has N stemmed habit(s). They'll be kept — only the rule is deleted." Confirm. The formerly-stemmed habit survives with originRule nil (no "Stemmed from" row).
result: [pending]

### 5. Unit suite green (deferred from 02-01)
expected: `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test` — testIsArchivedDefaultsFalse, testDeleteRuleNullifiesStemmedHabits, testStemmedHabitsInverse, testDomainRulesInverse, and the ExportImport v3 round-trip all green. (Blocked by account spend limit during 02-01; code is substantive — run before milestone RC.)
result: [pending]

### 6. Schema upgrade / data-survival test (deferred from 02-01)
expected: Install the Phase-1 build, then the Phase-2 build over the same store (no uninstall between). App launches (PID > 0) with all prior domains/habits/history intact. (Accepted low-risk: all new fields optional/defaulted, plan-less migration. Required before milestone RC per CLAUDE.md §6 + Docs/SCHEMA_MIGRATION_PLAYBOOK.md.)
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
