---
phase: 04-clips-d
plan: 02
subsystem: utility
tags: [swift, urlcomponents, pure-function, tdd, xctest]

# Dependency graph
requires:
  - phase: 04-clips-d (plan 01)
    provides: Clip @Model + ClipStatus enum, registered plan-less in the container
provides:
  - "ClipTitleSuggestion.suggest(from:) — pure, zero-network URL-to-title suggestion helper"
  - "ClipTitleSuggestionTests — 4 mandated invariant-based test cases, runnable/green on iPhone 17"
affects: [04-clips-d plan 03+ (ClipEditorView consumes suggest(from:) to prefill Title on URL entry, D-09)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure enum namespace + nonisolated static func for model-free transforms (mirrors CollectionRollupEngine)"
    - "TDD RED/GREEN for a §9.5 pure helper: failing invariant-based tests first, then minimal implementation"

key-files:
  created:
    - HabitsTracker/Utilities/ClipTitleSuggestion.swift
    - HabitsTrackerTests/ClipTitleSuggestionTests.swift
  modified: []

key-decisions:
  - "Humanization rule (Claude's Discretion within D-02): prefer the last non-empty path slug (strip trailing extension, hyphens/underscores -> spaces, title-cased); fall back to host with leading www. stripped; empty/malformed input returns \"\" gracefully."
  - "Scheme normalization is parse-local only: a bare host string like example.com is retried with https:// prepended purely for URLComponents parsing, never mutating the caller's string or touching the network."

patterns-established:
  - "Utilities/ is the home for pure, model-free transforms (ClipTitleSuggestion joins AccentTokenColor)."

requirements-completed: [CLIP-01, CLIP-02]

# Metrics
duration: 5min
completed: 2026-07-08
---

# Phase 4 Plan 2: ClipTitleSuggestion Zero-Network Title Helper Summary

**Pure `URLComponents`-only URL-to-title suggestion helper (host/slug humanization, zero network) with 4 green XCTest cases, embodying the D-02 offline-friction-reduction decision.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-08T22:49:00-05:00
- **Completed:** 2026-07-08T22:52:06-05:00
- **Tasks:** 2
- **Files modified:** 2 (both new)

## Accomplishments
- `ClipTitleSuggestion.suggest(from:)` — a pure enum namespace with a single `nonisolated static func`, no SwiftData/model/network dependency, mirroring `CollectionRollupEngine`'s shape.
- Zero network APIs anywhere in the file (`URLSession`/`dataTask`/`.load`/`URLRequest` all absent, grep-verified) — the offline gate (SC1/D-01) holds.
- 4 mandated test cases (`testBareHost`, `testUrlWithSlug`, `testNormalUrlNonEmpty`, `testMalformedFallback`) written as invariant assertions (non-empty, substring-contains, no-hyphen, no-crash) rather than exact-string equality, keeping the precise humanization rule as executor discretion per D-02.
- Full TDD RED -> GREEN cycle: tests committed first against a non-existent helper (compile-fails as expected RED), then the implementation committed to make all 4 pass.
- Suite runs GREEN on the iPhone 17 simulator (pure suite, no `ModelContainer`, always runnable per CLAUDE.md §9.7) — confirmed via `-only-testing:HabitsTrackerTests/ClipTitleSuggestionTests -parallel-testing-enabled NO`, exit 0, all 4 `passed`.
- Full `HabitsTracker` scheme build verified clean after the addition.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write failing ClipTitleSuggestionTests for the 4 mandated cases (RED)** - `6a5c2b3` (test)
2. **Task 2: Implement ClipTitleSuggestion pure helper to green (GREEN)** - `2dee26a` (feat)

_TDD task: RED (test) -> GREEN (feat). No REFACTOR commit needed — the GREEN implementation was clean on first pass._

## Files Created/Modified
- `HabitsTracker/Utilities/ClipTitleSuggestion.swift` - pure zero-network URL -> suggested-title helper (slug-preferred, host-fallback, `""` graceful fallback)
- `HabitsTrackerTests/ClipTitleSuggestionTests.swift` - 4 invariant-based XCTest cases against the helper, no `ModelContainer`

## Decisions Made
- Humanization order: last-path-slug preferred (extension stripped, `-`/`_` -> spaces, title-cased) over host, because a slug is more descriptive than a bare domain when present.
- `www.` prefix stripped from the host fallback for readability (`www.nytimes.com` -> `nytimes.com`).
- Malformed/no-scheme garbage and empty input both resolve to `""` (not the raw string) — the `ClipEditorView` Title field is simply left empty for the user to fill, which is the simpler and more predictable of the two documented fallback options.
- Scheme-less bare-host input (e.g. `example.com`) gets a parse-local `https://` prepend so `URLComponents` can still resolve a host — this normalization never touches the stored `url` value or the network.

## Deviations from Plan

None — plan executed exactly as written. Two minor in-flight self-corrections during Task 1/2 (not deviations from plan intent, just fixing the executor's own draft before commit):
- Reworded a doc comment in the test file that literally contained the string `ModelContainer` (in a "no ModelContainer needed" note) so the acceptance-criteria grep (`grep -c "ModelContainer"` returns 0) passes literally, not just in spirit.
- Reworded a doc comment in the helper that named the forbidden network APIs (`URLSession`/`dataTask`/etc.) for documentation purposes, which tripped the acceptance-criteria grep for those same literal strings; reworded to describe the constraint without naming the APIs verbatim.
- Marked the private `humanize(slug:)` helper `nonisolated` to silence a main-actor-isolation compiler warning surfaced during the first green test run, keeping the whole helper consistently non-isolated as a pure function.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `ClipTitleSuggestion.suggest(from:)` is ready for `ClipEditorView` (D-09, a later 04-clips-d plan) to call on URL entry and prefill the editable Title field.
- No blockers introduced by this plan. The pre-existing CLIP-01 upgrade-test checkpoint from 04-01 (owner verification on iPhone 17 against a Phase-3 store) remains open and is unaffected by this plan's pure-utility scope.

## Self-Check: PASSED

- FOUND: HabitsTracker/Utilities/ClipTitleSuggestion.swift
- FOUND: HabitsTrackerTests/ClipTitleSuggestionTests.swift
- FOUND commit: 6a5c2b3 (test RED)
- FOUND commit: 2dee26a (feat GREEN)

---
*Phase: 04-clips-d*
*Completed: 2026-07-08*
