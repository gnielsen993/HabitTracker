# HabitsTracker — Lifestyle Hub

## What This Is

HabitsTracker is a shipped (v1.0), local-first SwiftUI iPhone app for tracking binary daily habits with streaks, weekly goals, and a calendar heatmap. The **Lifestyle Hub** milestone evolves it from a pure habit app into a local-first lifestyle hub: habits stay the daily driver, with low-friction offshoots into Rules, Collections, Clips, and Ideas — all filed under user-chosen life **Domains** (a generalization of today's `Category`). It is for one person (the developer/owner) dogfooding their own lifestyle, not a multi-user product.

## Core Value

The daily habit loop keeps you opening the app, and every part of your lifestyle gets the *right kind of structure* (check / status / position / stem / promote) filed in one opinionated place — never the flat inert-text pile of a notes app. If everything else fails, Today/habits must still work and stay near-zero-friction.

## Requirements

### Validated

<!-- Shipped and confirmed valuable (HabitsTracker v1.0). -->

- ✓ Binary daily habits with required/optional modes and weekly targets — v1.0
- ✓ Streak / WeeklyGoal / Stats / Today engines (habit-only, pure, testable) — v1.0
- ✓ `Category`, `Habit`, `DailyEntry`, `HabitState` SwiftData models with seeding (`isSeeded`/`seedVersion`) — v1.0
- ✓ Today screen (hero), Progress charts + calendar heatmap, Settings management dashboard — v1.0
- ✓ Export/Import JSON (`Services/ExportImportService.swift`, `schemaVersion = 1`) — v1.0
- ✓ Plan-less SwiftData container, Balanced Luxury DesignKit theming — v1.0
- ✓ Domains generalize Categories: `isFocused`, Hub tab, focus picker, custom domains (`Category`→`Domain` rename via `@Attribute(originalName:)`, schemaVersion 2) — Validated in Phase A (2026-07-02)
- ✓ Rules as reference-first items + Stem-a-habit flow with shared `HabitCreateSheet` (`Rule` @Model, `.nullify` stem link, schemaVersion 3) — Validated in Phase B (2026-07-05)
- ✓ Collections: StatusSet model, tap-to-advance chips, fixed progress templates, aggregate/cost rollups, curated presets (`Collection`/`CollectionItem` @Models, schemaVersion 4) — Validated in Phase C (2026-07-06)
- ✓ Clips: offline-only saved links with tag + saved/acted status, filed by domain (`Clip` @Model, `ClipStatus`, zero-network title suggestion, schemaVersion 5) — Validated in Phase D (2026-07-10; schema upgrade auto-verified + full flow owner-approved)

### Active

<!-- Lifestyle Hub milestone scope (Phases A–F). -->

- [ ] Ideas: global capture-first quick-add, Hub inbox, File vs Promote graduations (Phase E)
- [ ] Polish: cross-domain search, empty states, full multi-type export/import, accessibility pass (Phase F)

### Out of Scope

<!-- Explicit boundaries for this milestone. -->

- Widgets — original-spec work, sequenced *after* the hub stabilizes (post-Phase F); does not block Phase A.
- Clip rich previews / on-demand link thumbnails — conflicts with offline-only v1; opt-in fetch deferred past Phase D.
- Cross-domain free tags — strict domain filing only in v1; revisit after Phase F.
- Rule active-resurfacing / daily nagging layer — v1 is opt-in stem only (locked DEC-rules-reference-first).
- User-definable progress templates beyond `none`/`counter`/`seasonEpisode` — fixed set is the scope guard against a generic spreadsheet builder.
- User-editable built-in StatusSet labels — preserves the opinionated feel; users wanting different words use the generic preset.
- Cloud / backend / sync — offline-only in v1 (constitution).
- DesignKit extraction of new components — only once proven in 2+ apps (constitution §4).
- Notifications / reminders — none planned in v1; revisit with widget work.

## Context

- **Brownfield milestone, not greenfield.** v1.0 is shipped and up to date with remote `main`. This roadmap covers the Lifestyle Hub milestone only; the habit core (engines, models, seeding, export/import, management dashboard) carries over unchanged. Domain is a *generalization* of `Category`, not a rewrite.
- **Solo developer + Claude.** No teams, sprints, analytics, or backend. Success is qualitative + dogfood-driven.
- **Five modes → five item types.** Do=Habit, Follow=Rule, Collect=Collection, Capture=Idea, Clip=Clip. Connective tissue: Rule→Habit (stem = copy), Idea→anything (promote = consume).
- **Plan status:** the SPEC (`Docs/LIFESTYLE_HUB_PLAN.md`, drafted 2026-06-21) is "planning only — not approved to build." Locked decisions below are **locked-intent** (settled product calls, preserved), not yet executed.
- **Pre-existing pending work** ("Next 3" from `Docs/STATUS.md`: accessibility pass, empty-state enhancements, schema/version visibility in Settings) folds into Phase F.
- **Success bar (SPEC §10):** hero loop survives; every built-in domain demonstrates ≥1 behavior Notes can't; all five modes have a real distinct home; stem & promote are ≤2 taps; a 4-week post-Phase-E dogfood shows continued daily use plus unprompted filing/stemming/promoting. Named failure mode: "it became empty Notion folders."

## Constraints

- **Tech stack**: Swift + SwiftUI, SwiftData persistence, lightweight MVVM, offline-only — constitution; no cloud/backends in v1.
- **Migration (plan-less)**: SwiftData container stays plan-less `.modelContainer(for: […])`. NEVER add `migrationPlan:` — proven to throw an uncatchable Obj-C NSException and crash the process (sibling FitnessTracker proved it).
- **Migration (additive-only)**: new `@Model` fields must be optional or defaulted; never required-no-default, never a type change. New `@Model` classes (Rule, Collection, CollectionItem, Idea, Clip) are additive and safe; register each in the container type list in `HabitsTrackerApp.swift`.
- **Migration (renames)**: only via `@Attribute(originalName:)`, never a bare rename (drop+add loses data). `Category`→`Domain` is the one risky move — decide relabel-only vs `@Attribute(originalName:)` before Phase A.
- **Upgrade test mandatory**: after every model change, build OLD app → create data → build NEW app over the store; must launch (PID > 0) with all prior data visible, or do NOT merge. Part of every phase's DoD.
- **Export/Import safety net**: bump `schemaVersion` and keep round-trip tests green whenever new types/fields are added. Never break existing local data without a migration path or export/import workaround.
- **Bundle ID frozen**: `gn.HabitsTracker` must NOT change, even if the product is renamed. Avoid bundle/App Group ID changes.
- **Design tokens only**: no hard-coded colors; all UI uses DesignKit semantic tokens (Balanced Luxury: warm cream light / charcoal dark; accents forest, navy, maroon/oxblood, walnut, stone). Custom domains pick a color *token*, not a raw color.
- **App structure + engine boundaries**: keep Models/, Services/, Features/, UIComponents/, Widgets/, Resources/, Docs/. Domain models and business engines stay in the app, not DesignKit. Habit engines (Streak/WeeklyGoal/Stats) apply ONLY to habits — not rules, collections, ideas, or clips. Reuse existing patterns; prefer the smallest change.

## Key Decisions

<!-- Locked-intent product/design decisions carried from the SPEC. Settled, not yet executed. -->

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Today/habits is the hero; offshoots reach from domains, never pile onto Today; capture must not pollute Today | Habits are the daily driver; keep friction near zero (DEC-today-is-hero) | — Pending |
| Rules are reference-first; the active layer is opt-in only via "stem a habit"; no auto daily resurfacing | A rule is a clean saved reference, not a nagging feed (DEC-rules-reference-first) | — Pending |
| Domains are a chosen catalog (built-ins + custom), each with SF Symbol + color token; generalizes `Category` | Generalization, not a rewrite — engines/seed/export carry over (DEC-domains-chosen-set) | — Pending |
| Stem (Rule→Habit) = copy: new habit, rule untouched, `originRuleID` backref, nullify-on-delete, one rule→many habits | Reference persists; habits are hero data and must survive rule deletion (DEC-stem-is-copy) | — Pending |
| Promote (Idea→anything) = consume: idea archived with forward-link, leaves inbox, result carries no backref; promote-to-habit reuses Stem's sheet | Staging is consumed; keeping the inbox clean is the whole point (DEC-promote-is-consume) | — Pending |
| `progressTemplate` is a FIXED set (`none`/`counter`/`seasonEpisode`), not user-definable in v1 | Scope guard against bloating into a generic spreadsheet builder (DEC-fixed-progress-templates) | — Pending |
| Status is a StatusSet template instance (ordered states + terminal), tap-to-advance chip; built-in labels not user-editable; generic preset must exist before user-created collections | Opinionated feel without bespoke per-type code (DEC-status-template-instances) | — Pending |
| Completionist lists roll up "X/Y"; trackers show no progress; money lists roll up a cost SUM, never a completion ring on spend | Progress toward spending feels wrong (DEC-cost-rollup-never-ring) | — Pending |
| Two entry points, one creation code path: global quick-add (capture-first → Idea → Hub inbox) + in-domain `+` (place-first); title-only minimum | Capture-first spine keeps offshoots near-zero friction (DEC-capture-first-spine) | — Pending |
| Keep 4 tabs (Today, Hub, Progress, Settings); Hub is the offshoot home; offshoots nest under Hub | No tab-bar growth; Today stays pure (DEC-four-tabs) | — Pending |
| All SwiftData changes are additive plan-less inferred migration; renames via `@Attribute(originalName:)` only | A `migrationPlan:` crashes the process; additive-only is the safe path (DEC-additive-migration-only) | — Pending |
| Offline-only in v1; constrains Clips to URL + manual title/note; bundle ID frozen | No backend in v1 (DEC-offline-only-v1) | — Pending |

## Open Questions

<!-- Unresolved product calls scoped to the phase where they must be decided. Not conflicts. -->

| # | Question | Decide by |
|---|----------|-----------|
| Q1 | Clip previews vs offline-only — store URL + manual title/note (fully offline, default) vs opt-in on-demand fetch | Phase D |
| Q2 | `Category`→`Domain`: relabel-only in UI (zero migration) vs `@Attribute(originalName: "Category")` rename (plan-less). Migration-plan path is struck. | Before Phase A |
| Q3 | Seed reconciliation for existing users: do existing Categories auto-become focused Domains or land unfocused? Push new seed into populated installs vs fresh-install-only? Re-seed policy vs `seedVersion`? | Before Phase A; revisit per phase as new seed types land |
| Q4 | Cross-domain tagging: strict domain filing only vs free tags (recommend strict in v1) | After Phase F |
| Q5 | Product naming/identity: keep "HabitTracker" or rename for the hub (bundle ID frozen regardless) | Any time; non-blocking |

---
*Last updated: 2026-07-10 after Phase D (Clips) completion*
