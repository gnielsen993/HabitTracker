---
phase: 1
slug: domain-generalization-a
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-28
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (HabitsTrackerTests target) |
| **Config file** | none — existing test target |
| **Quick run command** | `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:HabitsTrackerTests test -quiet` |
| **Full suite command** | `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' test -quiet` |
| **Estimated runtime** | ~60–120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick run command for the touched test file.
- **After every plan wave:** Run the full suite.
- **Before `/gsd:verify-work`:** Full suite green AND the manual upgrade test passed.
- **Max feedback latency:** ~120 seconds (automated); upgrade test is manual (see below).

---

## Per-Task Verification Map

| Task | Wave | Requirement | Test Type | Automated Command | File (Wave 0) | Status |
|------|------|-------------|-----------|-------------------|---------------|--------|
| Domain rename loss-free (rows + `habits` inverse survive) | 0 | DOM-01 | unit + manual upgrade | `DomainMigrationTests` | ❌ W0 | ⬜ pending |
| `isFocused` additive defaulted field | 1 | DOM-02 | unit | `DomainMigrationTests.testIsFocusedDefault` | ❌ W0 | ⬜ pending |
| Focus backfill idempotent (two-run, `previous>0` guard) | 1 | DOM-04 | unit | `BootstrapBackfillTests.testBackfillRunsOnce` | ❌ W0 | ⬜ pending |
| Merge-add new domains unfocused, name-keyed dedupe | 1 | DOM-04 | unit | `BootstrapBackfillTests.testMergeAddUnfocused` | ❌ W0 | ⬜ pending |
| Export/Import round-trip at schemaVersion 2 | 2 | DOM-01/02 | unit | `ExportImportTests.testRoundTripV2` | ❌ W0 | ⬜ pending |
| Custom domain persists (name+icon+colorToken) | 2 | DOM-05 | unit | `DomainCreateTests.testPersist` | ❌ W0 | ⬜ pending |
| 4-tab invariant (Today/Hub/Progress/Settings) | 2 | DOM-06 | manual | UI inspection | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `HabitsTrackerTests/DomainMigrationTests.swift` — `isFocused` default + (where automatable) post-rename row presence
- [ ] `HabitsTrackerTests/BootstrapBackfillTests.swift` — two-run idempotency + `previous>0` guard + merge-add-unfocused
- [ ] `HabitsTrackerTests/ExportImportTests.swift` — round-trip at `schemaVersion = 2` (extend existing if present)
- [ ] `HabitsTrackerTests/DomainCreateTests.swift` — custom domain persistence

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| **Upgrade test (data integrity across the class rename)** | DOM-01 | Requires installing the prior shipped build, creating data, then installing the new build over the same on-device store — cannot be expressed as an in-process unit test. THE merge gate for DOM-01. | Per `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` Step 4 with `gn.HabitsTracker` / iPhone 17: build OLD → create categories + toggle habits → build NEW over store → app launches (PID>0) with all prior data visible. **If rows do NOT survive → pivot D-01 to relabel-only before building Hub UI.** |
| 4-tab structure + Today unchanged | DOM-06 | Visual/layout invariant | Launch app: confirm tabs are Today / Hub / Progress / Settings (no Calendar tab, no 5th tab); Today visually identical to v1.0. |
| Calendar reachable via Charts ⇄ Calendar segmented control | DOM-03 | Visual/interaction | In Progress, toggle segmented control; calendar heatmap + day-detail sheet work as before. |

---

## Validation Sign-Off

- [ ] All tasks have an automated verify or a Wave 0 dependency (except the inherently-manual upgrade test + visual invariants)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
