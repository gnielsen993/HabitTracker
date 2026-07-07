# CLAUDE.md
## Ecosystem Agent Rules (DesignKit + HabitsTracker + FitnessTracker + PantryPlanner)

**This is the single source of truth for agent rules.** `AGENTS.md` is a symlink to
this file, so Codex and Claude read identical rules — edit only this file, never a copy.
Claude Code reads this at the start of every session. Follow it as the project constitution.

> Mirrors the consolidated convention proven in the sibling `FitnessTracker` repo. The
> standalone `Architecture_Constitution.md` and `Design_Philosophy.md` are now thin pointers
> to this file — do not re-fork rules into them.

---

## 0) What you are building
A set of local-first SwiftUI apps that feel like one premium ecosystem, powered by a shared DesignKit Swift Package.

Projects:
- DesignKit (shared design system package)
- HabitsTracker (binary habits + optional weekly goals + widgets) — **this repo**
- FitnessTracker (split logging + muscle coverage + visuals)
- PantryPlanner (pantry forecasting + meal planner + cost awareness)

> **Active planning:** the in-flight evolution of this app into a local-first lifestyle hub
> is specified in `Docs/LIFESTYLE_HUB_PLAN.md` (planning-only until approved to build).

---

## 1) Absolute Constraints (Do Not Violate)
### Stack
- Swift + SwiftUI
- SwiftData for persistence (default)
- MVVM (lightweight) — state via `ObservableObject` / `@StateObject` / `@EnvironmentObject`. No TCA/Redux/heavy frameworks unless explicitly asked.
- Offline-only in v1 (no cloud/backends). CloudKit is a *future* option only; do not add it speculatively.

### Data safety
- Implement Export/Import JSON in every app (schemaVersion + replace import at minimum). HabitsTracker has this in `Services/ExportImportService.swift` (currently `schemaVersion = 1`) — extend it, don't replace it.
- Never break existing local data without a migration path or export/import workaround.
- HabitsTracker bundle id: `lauterstar.HabitsTracker` (shipped under Gabe's company account, team `JCWX4BK8GW`; migrated from the original `gn.HabitsTracker` on 2026-07-06 — this rename is intentional and approved). Avoid *further* bundle ID / App Group ID changes from here — a change relocates the on-disk SwiftData store and looks like data loss on existing installs.

### Design
- No hard-coded colors in UI.
- All UI uses DesignKit semantic tokens.
- Theme identity (default / shipping brand): Balanced Luxury
  - Light: warm cream background (not pure white); cards/surfaces use slightly darker warm neutrals for depth
  - Dark: charcoal background (not pure black)
  - Core luxury accents: forest, navy, maroon/oxblood, walnut, stone — these define the out-of-the-box feel.
- Charts use the theme chart palette — no rainbow / high-saturation chaos in the *default* palette.
- “Personality” is achieved by presets and layout emphasis, not random styling.
- Theme behavior: default follows System; in-app picker overrides System/Light/Dark.
- **Preset exposure (decision 2026-07-06): the in-app theme picker uses DesignKit's `DKThemePicker` and exposes the FULL `PresetCatalog.all` catalog — including the loud/showcase presets (voltage, bubblegum, vaporwave, etc.) — plus custom themes.** This is a deliberate, user-facing relaxation of the earlier "accents constrained to the luxury 5 / no neon" rule: Balanced Luxury remains the default identity, but users may opt into any catalog preset. Do NOT re-restrict the picker to the luxury 5 or strip loud presets — that would revert an approved decision.

---

## 2) DesignKit: How it should work
### What goes into DesignKit
- Theme tokens: colors, typography, spacing, radii, motion
- ThemeManager: mode (system/light/dark) + preset (Forest/Navy/Maroon/Walnut/Stone)
- Components: DKCard, DKButton, DKProgressRing, DKBadge, DKSectionHeader
- Charts: DKChartStyle helper for Swift Charts

### What does NOT go into DesignKit
- App domain models (Habit, Category/Domain, WorkoutSession, PantryItem, etc.)
- App business logic engines (streaks, coverage, forecasting)
- Domain-specific icon libraries (exercise drawings, food illustrations)

### Future (explicitly allowed but not required now)
- Design Dashboard hooks:
  - Category color/icon overrides (constrained palette)
  - Export/import theme JSON
- Implement only when requested. Any future dashboard must preserve the luxury constraint (no neon / no high-saturation chaos).

---

## 3) Shared App Structure (Keep Consistent)
Apps must use:
- Models/
- Services/
- Features/
- UIComponents/ (app-specific only)
- Settings/ (if present; in HabitsTracker today this lives under `Features/Settings/`)
- Widgets/ (if present)
- Resources/
- Docs/

DesignKit uses:
- Theme/
- Typography/
- Layout/
- Motion/
- Components/
- Charts/
- Storage/
- Utilities/

---

## 4) Coding standards & AI-assisted changes (avoid ecosystem drift)
- Reuse existing patterns in the repo. Do not invent new architectures.
- Prefer the smallest change that satisfies the requirement; clarity over abstraction.
- Favor explicit, readable Swift over clever generics. Use `final` where appropriate.
- Validate at boundaries (user input, import/export, startup bootstrap); fail gracefully with a user-facing recovery path.
- Keep domain logic in services/view models, never in view bodies. View models stay small and testable.
- Extract to DesignKit ONLY when repetition is proven (used in 2+ apps).
- **Architect for extension, not prediction.** No premature abstraction; do not build unused layers "just in case." Keep future hooks as TODOs rather than building systems now.
- Engines are pure/testable modules with deterministic behavior. Keep naming consistent:
  - Habit: StreakEngine, WeeklyGoalEngine, StatsEngine (TodayEngine for Today assembly)
  - Fitness: CoverageEngine, ProgressionEngine, StatsEngine
  - Pantry: ForecastEngine, MealAggregationEngine, CostEngine

---

## 5) Widgets guidance (when present)
- Use WidgetKit + App Intents for quick toggles where possible.
- Keep widget data minimal (snapshot/cache) and refresh timelines intentionally.
- If sharing theme across widgets/apps is needed later, use stable App Group storage.
- (HabitsTracker widgets are still unbuilt from the original v1 spec — sequence intentionally.)

---

## 6) Testing expectations
- Add unit tests for core engines (streak/weekly-goal/stats math).
- Verify export/import round-trip where feasible.
- For UI: keep tests minimal unless explicitly requested.

### RC smoke test (every release candidate)
1. Fresh-install launch works.
2. Core flow: open Today → toggle a required habit → award an optional weekly badge → review Progress.
3. Settings: theme change, export/import backup round-trip.
4. Empty states and errors are user-friendly.
5. No debug artifacts or placeholder strings remain.

---

## 7) Definition of done (for any task)
A task is done when:
- repo state was synchronized first (`git fetch --prune` + `git pull --ff-only` for every touched repo, preserving dirty local work before pull)
- code compiles
- behavior is verified (explain what was run / checked — see §8)
- structure + token rules are followed
- no new drift introduced
- verified commits were pushed to GitHub at the end (`git status --short --branch`, then `git push` for every changed repo) unless Gabe explicitly says not to push

---

## 8) Commands (HabitsTracker)
- **Build:** `xcodebuild -scheme HabitsTracker -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build`
- **Test:** same as above with `test` instead of `build`.
- **Bundle id:** `lauterstar.HabitsTracker` (used for `xcrun simctl uninstall` — see §9.7 and the schema playbook).
- **Marketing version:** `1.0` (in `HabitsTracker.xcodeproj/project.pbxproj`).
- Prefer `-quiet`; drop it only when diagnosing a failure. Don’t claim “verified” without stating which of {build, test, simulator run} you actually ran (see §9.18).

---

## 9) Session-derived rules (avoid repeating past pain)

> Ported from the FitnessTracker constitution — these are ecosystem-wide lessons. Verified to
> apply to HabitsTracker: `objectVersion = 77` with synchronized root groups (§9.6, §9.8),
> `../DesignKit` consumed as a local sibling (§9.14), zero `print()` calls today (§9.13).

### 9.1 File size cap (~400 lines)
If a view or service crosses ~400 lines, split by concern into sibling files. Smells that trigger a split: multiple MARKs for unrelated sub-features, several `@State` groups each driving a distinct sub-section, or a single view owning more than two independent data-load paths.

### 9.2 Reusable views are data-driven, not data-fetching
A view used in 2+ places takes props only — the parent owns the SwiftData query. A reusable card gets its data + `isLoading`, never touches `modelContext`. Keeps fetch logic in one place and makes SwiftUI previews trivial. (Directly governs the Lifestyle Hub's new shared views: status chip, position stepper, Hub tile, DomainDetailView sections.)

### 9.3 Every data-driven view ships with an explicit empty state
No blank screens on first launch or empty filters. Write the copy ("No rules in this domain yet.", "Nothing in your inbox.") before the chart or list is considered done.

### 9.4 Verify theme tokens exist before using them
Use semantic tokens only — no hardcoded radii/spacing/opacities. When reaching for a token, check `DesignKit/Layout/*.swift` or `DesignKit/Theme/Tokens.swift` first rather than inventing a value.

### 9.5 New pure services ship with unit tests in the same commit
At minimum cover: happy path, empty input, and one edge case (tie-break / variant demotion / soft-delete skip). Tests go in `HabitsTrackerTests/` (one file per engine unless a shared file is clearly warranted).

### 9.6 Never tolerate Finder-dupe files (`X 2.swift`)
This Xcode project (`objectVersion = 77`) uses `PBXFileSystemSynchronizedRootGroup` — every `.swift` in the folder is compiled. Byte-identical `X 2.swift` dupes cause "invalid redeclaration" and block the whole target. If one appears in `git status` as `??`, confirm with `diff` then delete before doing anything else.

### 9.7 Test runner crashes in `NSStagedMigrationManager` → uninstall, don't debug
If `xcodebuild test` aborts during host-app launch with `_findCurrentMigrationStageFromModelChecksum:` in the crash report, the simulator has a stale SwiftData store from a prior schema version. Fix: `xcrun simctl uninstall <device-id> lauterstar.HabitsTracker`, then retry. Not a code bug — don't chase it through a migration plan.

### 9.8 New `.swift` files in existing folders auto-register
Do not hand-patch `project.pbxproj` to add a file. Dropping the file into `Features/<area>/`, `Services/`, or `Models/` is enough — the synchronized root group picks it up on next build. Only edit `project.pbxproj` when adding a new top-level folder or changing target membership.

### 9.9 Commit discipline — one feature or one grouped batch per commit
Each large feature lands in its own commit; small unrelated changes get grouped into a single coherent commit. Never bundle a large feature with unrelated fixes. Reason: regressions are bisectable only when commits are atomic. Prefixes: `fix:` (reliability/bug), `feat:` (user-visible capability), `chore:` (infra/docs). **Branching:** work directly on `main` for normal changes; use a `feature/` or `fix/` branch only for risky/large or PR-reviewed work. **Triage buckets:** P0 = crashes / data loss / broken critical flow; P1 = high-friction UX & accessibility blockers; P2 = enhancements & polish. Always prompt Gabe to commit after a feature is verified — don't let uncommitted work pile up.

### 9.10 Split-machine sync discipline
Work happens across multiple machines. Every agent/human workflow pulls at the beginning and pushes at the end. Do not start from stale local state, and do not leave verified work only on one machine unless Gabe explicitly says not to push.

### 9.11 Release Log — `Docs/releases/v{current}.md`
Per-version release notes live in `Docs/releases/`, keyed off `MARKETING_VERSION` in `HabitsTracker.xcodeproj/project.pbxproj`. For every significant feature/fix: check the current version, create `Docs/releases/v{version}.md` if absent, append the change under the right section (Summary, User-facing, Internal, Fixes, Risks/notes), keep entries brief, land the update in the same commit as the code. Never mutate a shipped version's file. Skip the log for self-explanatory or doc-only commits. (HabitsTracker has no `Docs/releases/` yet — create it from the FitnessTracker convention when the first post-1.0 release is prepared.)

### 9.12 SwiftData schema changes go through the playbook
Any change to a `@Model` class (add/remove/rename a field, change a type, alter a relationship) follows `Docs/SCHEMA_MIGRATION_PLAYBOOK.md`. The short rules:
- The container is constructed plan-less — today via the `.modelContainer(for:[Category, Habit, DailyEntry, HabitState])` modifier in `HabitsTrackerApp.swift`, **without** a `migrationPlan:` argument. Inferred lightweight migration handles every additive change and dodges the Obj-C NSException the explicit plan throws on storage-equivalent adjacent versions.
- New fields must be optional or have a default value. Required-no-default additions break inferred migration.
- Renames go through `@Attribute(originalName:)`, **never** a `SchemaMigrationPlan`.
- Run the upgrade test in the playbook before merging any model change (install prior shipped build, log data, install over with new build, confirm launch + data intact).
- The Lifestyle Hub build (`Docs/LIFESTYLE_HUB_PLAN.md` §7) is schema-expansion work — it is playbook territory by definition.

### 9.13 Logging — `os.Logger`, never `print()`
Diagnostics go through `os.Logger` with a subsystem/category, never `print()` / `debugPrint()` in committed code. (The codebase is at zero raw `print()` calls — keep it there.)

### 9.14 DesignKit is a separate sibling repo (`../DesignKit`)
DesignKit is consumed by **local path**, not a pinned remote package, and is shared by all sibling apps. Therefore:
- Changes to DesignKit are a separate commit + push *in that repo* (pull it first, per §9.10).
- A DesignKit change affects HabitsTracker / FitnessTracker / PantryPlanner — confirm the need is real (2+ apps, §4) before editing it.
- After a DesignKit change, verify HabitsTracker still builds against it (§8).
- Never make an app-only tweak inside DesignKit.

### 9.15 Accessibility is part of “done”
New UI supports Dynamic Type, carries meaningful accessibility labels, and meets contrast. Pairs with the §9.3 empty-state requirement — both are gates, not polish.

### 9.16 Do not hand-edit these
- Any frozen versioned-schema snapshot, once introduced (§9.12).
- Bundled seed JSON except through the seed-merge path (`Services/SeedDataService.swift` — merge missing items, never destroy user data).
- Shipped `Docs/releases/v*.md` files (§9.11) — open a new version file instead.
- `project.pbxproj`, except per §9.8.

### 9.17 Propose rules/tools when redundancy proves itself
When you hit the *same* friction a 2nd time, repeat a multi-step manual sequence that could be one command, or notice a rule that's now stale/contradicted — surface it before moving on.
- **Bar:** suggest only on recurrence (≥2×) or demonstrated redundancy, not first encounter. One good rule beats five speculative ones.
- **Pick the lightest form:** a new rule in §9, a Claude skill, a tool/script, or a settings/permission entry.
- **Propose, don't auto-apply.** State the trigger you observed, the proposed text, and where it'd live. Gabe approves before it lands.

### 9.18 You are the implementer — don't hand back work you can do
If a step is doable with your own tools (editing files, `xcodebuild` / `xcrun` / git, search), **do it** — never hand Gabe a list of manual steps and call that done. Only delegate steps that genuinely require the human: interactive auth, physical-device actions, App Store Connect / web UI, or a decision that is his to make. When you delegate, say *why* it needs him and give exact steps (for shell he can run in-session, suggest the `! <command>` prefix). Don't end a turn at “you should now run/build/commit…” when you could have done it.

---

## 10) Release wrap-up
**Trigger phrases:** "wrap up x.x.x", "shipping x.x.x", "prepare release x.x.x", "release process"

When you hear one of these, follow `Docs/RELEASE_PROCESS.md` in full (create it from the FitnessTracker template the first time). Do not start speculatively. App Store listing copy lives in `Docs/AppStoreListing.md` — update it as part of every wrap-up, not separately.

---

## 11) Auto-loaded skills (Claude only)
- None registered for HabitsTracker yet. (FitnessTracker carries a `sketch-findings` design skill; add an equivalent here only when a reusable design-decision corpus exists.)

> Codex note: skills are a Claude Code feature. When working under Codex, treat any
> referenced skill material as docs to read rather than a skill to invoke.

<!-- GSD:profile-start -->
## Developer Profile

> Generated by GSD from session_analysis. Run `/gsd-profile-user --refresh` to update.

| Dimension | Rating | Confidence |
|-----------|--------|------------|
| Communication | conversational | HIGH |
| Decisions | deliberate-informed | HIGH |
| Explanations | concise | MEDIUM |
| Debugging | diagnostic | HIGH |
| UX Philosophy | design-conscious | HIGH |
| Vendor Choices | opinionated | MEDIUM |
| Frustrations | instruction-adherence | MEDIUM |
| Learning | guided | MEDIUM |

**Directives:**
- **Communication:** Match a conversational, collaborative tone. Engage with the developer's reasoning and respond to thinking-aloud as dialogue rather than treating every message as a discrete command. Mirror their lightweight numbered-list structure in multi-part replies.
- **Decisions:** Before implementing, surface gaps, trade-offs, and open questions for the developer to react to. Do not jump straight to code on ambiguous requests. Once they approve, execute decisively without re-litigating.
- **Explanations:** Provide brief, focused explanations of approach and key decisions alongside the work. Explain concepts at a practical level when asked; avoid exhaustive theory unless requested. Lead with the decision, then justify concisely.
- **Debugging:** When debugging, diagnose and explain the root cause before applying a fix. The developer cares about why something happens, not just making it stop. Confirm the cause matches their observed symptoms before implementing.
- **UX Philosophy:** Treat UI/UX quality as equal in priority to functionality. Respect the DesignKit semantic token system, never hard-code colors or ship generic iOS-default styling. Surface visual polish issues proactively and treat them as real bugs.
- **Vendor Choices:** Defer to the developer's established stack and project rules (SwiftUI, SwiftData, MVVM, DesignKit, offline-only). Do not introduce new frameworks or dependencies without explicit approval. Prefer reusing existing patterns and consolidating to a single source of truth.
- **Frustrations:** Follow documented CLAUDE.md rules precisely. Do not ask permission for actions the rules already authorize (e.g., commit/push on wrap-up). Perform actions yourself rather than instructing the developer. Trust stated facts about their codebase over your own assumptions.
- **Learning:** When introducing new concepts or orienting the developer, explain through guided dialogue -- how the mechanism works generally, then connect it to their situation. Offer to investigate and summarize project state rather than assuming they will read the code themselves.
<!-- GSD:profile-end -->
