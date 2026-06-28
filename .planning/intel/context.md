# Context

Running notes keyed by topic, appended verbatim-in-spirit with source attribution. These are
DOC-type background and SPEC framing that downstream planning should know but that are not
themselves decisions, requirements, or hard constraints.

---

## Product thesis / "why"
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§0, §4)
- Notes apps treat everything as inert text — a graveyard. A lifestyle has distinct modes of
  engagement (Do / Follow / Collect / Capture / Clip), each wanting different behavior. The
  differentiator: every part of your lifestyle gets the RIGHT kind of structure, filed in one
  opinionated place, with a daily habit loop that keeps you opening it. Explicitly NOT "build
  my own Notion" — it ships opinionated domains + real starter content.
- The five modes map to item types: Do=Habit, Follow=Rule, Collect=Collection,
  Capture=Idea, Clip=Clip/Link. Connective tissue = Rule->Habit (stem) and Idea->anything
  (promote).

## Current shipped state (v1.0)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/STATUS.md
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md (Current state)
- HabitsTracker v1.0 is shipped. Up to date with remote main. Startup hardening applied.
  Layout width pass applied for Today/Progress.
- Live `@Model` types: `Category`, `Habit`, `DailyEntry`, `HabitState` (in HabitsTracker/Models/).
  Container built plan-less via `.modelContainer(for:)`; no VersionedSchema scaffolding exists.
  Export/Import at `schemaVersion = 1`. Bundle id `gn.HabitsTracker`.
- BLOCKER (pre-existing, owner-side): local Xcode/TestFlight verification required on the
  user's side. Not a planning blocker for this ingest.
- Pre-existing pending "Next 3" (now folded into Phase F): accessibility pass (VoiceOver +
  Dynamic Type), empty-state enhancements, data schema/version visibility in Settings.

## Plan status
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (header, §6)
- The Lifestyle Hub plan is "planning only (not approved to build)," drafted 2026-06-21. The
  phased build order applies "when approved." Each phase is a shippable vertical slice; habits
  keep working throughout. The self-status "not approved to build" is why the classifier kept
  the SPEC's locked decisions at schema-level locked=false — they are locked-INTENT product
  decisions, preserved here, not yet executed.

## Seed strategy
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§5)
- Ship a domain catalog, pre-focus a sensible subset, seed each with light starter content
  (Style, Diet, Money, Social, Media, plus existing habit-heavy domains). All seeded content
  editable/archivable; reuse existing `isSeeded` / `seedVersion`. Curated collection presets
  are a content deliverable authored like seed habits (preset table in §5).

## Success bar / failure mode
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§9, §10)
- Offline-only, no analytics -> the bar is qualitative + dogfood-driven. Named failure mode:
  "it became empty Notion folders." Pass conditions: hero loop survives; every built-in domain
  demonstrates >=1 thing Notes can't; the five modes each have a real distinct home;
  connective tissue (stem/promote) is <=2 taps; dogfood signal = self-use 4 weeks post-Phase E
  with unprompted non-habit filing/stemming/promoting.

## Open questions still to resolve (per phase, not blockers for bootstrap)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§8)
- Q1 Clip previews vs offline-only -> decide at Phase D (default: fully offline).
- Q2 Category->Domain relabel vs @Attribute(originalName:) rename -> decide before Phase A.
- Q3 Seed reconciliation for existing users (auto-focus existing categories? push new seed
  into populated installs vs fresh-install-only? re-seed policy vs seedVersion) -> before Phase A.
- Q4 Cross-domain tagging: strict filing only vs free tags (recommend strict in v1) -> after Phase F.
- Q5 Product naming/identity: keep "HabitTracker" or rename (bundle ID frozen regardless).
- These are noted as open questions, NOT conflicts — they are unresolved product calls scoped
  to their phase, not contradictions between docs.

## Deferred / parked (not v1 scope)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§11)
- Widgets; Clip rich previews (opt-in on-demand); cross-domain free tags; rule
  active-resurfacing layer; product naming/identity; more progress templates (high bar —
  fixed set is the scope guard); DesignKit extraction (2+ app rule); notifications/reminders.
  None block Phase A.

## Cross-reference note (cycle, benign)
- The cross_refs form a mutual-reference cycle: LIFESTYLE_HUB_PLAN <-> SCHEMA_MIGRATION_PLAYBOOK,
  and SCHEMA_MIGRATION_PLAYBOOK <-> CLAUDE.md ("See also" links). These are documentation
  back-references, not derivation/precedence edges, so they do not drive a synthesis loop.
  Recorded as INFO in INGEST-CONFLICTS.md. Synthesis proceeded normally on all four docs.
