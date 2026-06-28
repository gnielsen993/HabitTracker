# Decisions

Synthesized from ingest docs. No ADR-type documents were present in this ingest set.
The decisions below are **locked product/design decisions** carried by the SPEC
(`Docs/LIFESTYLE_HUB_PLAN.md` §1, §2, §8-Resolved) plus standing **constraint decisions**
from the DOC-type constitution and migration playbook. They are treated as locked-intent
per the ingest prompt: preserve, do not re-derive. None are schema-level Accepted ADRs, so
none can hard-block another decision, but downstream planning must honor them as settled.

---

## DEC-today-is-hero
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§1.1)
- status: locked-intent
- scope: Information architecture / Today screen
- decision: Today/habits is the hero surface. Habits stay the daily driver with near-zero
  friction to start. Rules / lists / links are offshoots reached from their domains, never
  piled onto Today. Capture must not pollute Today's content list.

## DEC-rules-reference-first
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§1.2)
- status: locked-intent
- scope: Rule item type / activation model
- decision: Rules are reference-first, not a nagging feed. A rule is a clean saved reference.
  The active layer is opt-in only via "stem a habit." The rule persists as reference; the
  stemmed habit flows into Today. No automatic daily resurfacing of rules in v1.

## DEC-domains-chosen-set
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§1.3)
- status: locked-intent
- scope: Domain model (generalizes Category)
- decision: Domains are a chosen catalog of built-in domains; the user picks which to focus
  and can add their own. Each domain carries an SF Symbol icon + color token. Domain
  generalizes the existing `Category` model; this is a generalization, not a rewrite.

## DEC-stem-is-copy
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§2 Stem & Promote)
- status: locked-intent
- scope: Rule -> Habit connective tissue
- decision: Stem (Rule -> Habit) = copy. Creates a new Habit; the rule is untouched. Opens the
  shared habit-create sheet prefilled with title + the rule's domain (both editable); user
  sets schedule/required-optional. `originRuleID` links habit -> rule. Bidirectional backref.
  One rule -> many habits allowed. Deleting a rule = nullify (`originRuleID` -> nil), NEVER
  cascade; habits are the hero data and must survive rule deletion (SwiftData nullify delete rule).

## DEC-promote-is-consume
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§2 Stem & Promote)
- status: locked-intent
- scope: Idea -> Rule/Habit/Collection-item connective tissue
- decision: Promote (Idea -> anything) = consume. The idea is archived with a forward-link to
  what it became and leaves the active inbox. Result carries no backref to the idea (lean model).
  Promote-to-habit reuses the SAME habit-create sheet as Stem (one shared code path). File
  (stays an Idea, gains a domain) vs Promote (becomes another type, consumed) are the two
  one-tap inbox graduations. Asymmetry rule: reference persists, staging is consumed.

## DEC-fixed-progress-templates
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§2, §5, §9)
- status: locked-intent
- scope: Collection progress model
- decision: `progressTemplate` is a FIXED set (`none` / `counter` / `seasonEpisode`), NOT
  user-definable in v1. This is the explicit scope guard against the model bloating into a
  generic spreadsheet builder. Do not reopen the fixed set mid-phase.

## DEC-status-template-instances
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§2 Collection behavior model)
- status: locked-intent
- scope: Collection StatusSet model
- decision: Status is a StatusSet template instance (ordered states with a terminal "done"),
  not free text and not a hard per-type enum. Rendered as a tap-to-advance chip (binary is N=2).
  Built-in StatusSet labels are NOT user-editable in v1 (preserves the opinionated feel);
  users wanting different words create a list with the generic set. The generic preset
  (`to-collect -> collected`) must exist before any user-created collection can be saved.

## DEC-cost-rollup-never-ring
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§2 Aggregate, §8 Resolved)
- status: locked-intent
- scope: Collection aggregate / money lists
- decision: `showsAggregate` completionist lists roll up "X/Y"; tracker lists show no progress.
  Money-flavored lists roll up as a cost SUM ("$340 of wishlist"), NEVER a completion ring on
  spend. Presets set a sensible default; user can flip the flag per collection.

## DEC-capture-first-spine
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§3 Creation model)
- status: locked-intent
- scope: Creation model / quick-add
- decision: Two converging entry points, one creation code path. Global quick-add (capture-first)
  defaults to Idea and drops into the Hub inbox; domain optional at save. In-domain `+`
  (place-first) files directly to that domain with type picker. Minimum field set = title only
  for every type (plus URL for Clip). Inbox lives in the Hub, never on Today.

## DEC-four-tabs
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§3 Navigation)
- status: locked-intent
- scope: Navigation / tab bar
- decision: Keep 4 tabs (Today, Hub, Progress, Settings); do not grow the tab bar. Hub is the
  new offshoot home (grid of focused domains). Progress folds the Calendar heatmap inside
  (habit history only). Offshoots nest under Hub.

## DEC-additive-migration-only (constraint decision)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/SCHEMA_MIGRATION_PLAYBOOK.md (TL;DR, Forbidden Moves)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§7)
- status: locked-intent (constitution-backed)
- scope: SwiftData persistence / migration strategy
- decision: All SwiftData changes are plan-less inferred lightweight migration. NEVER add a
  `migrationPlan:` argument (proven to throw an uncatchable Obj-C NSException and crash the
  process). New fields optional-or-defaulted only. Renames only via `@Attribute(originalName:)`.
  `Category` -> `Domain` rename is the one risky move: decide relabel-only (a) vs
  `@Attribute(originalName:)` (b) before Phase A. See constraints.md for full detail.

## DEC-offline-only-v1 (constraint decision)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/CLAUDE.md (§1 Stack)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§8 Q1, §11)
- status: locked-intent (constitution-backed)
- scope: Networking / Clips
- decision: Offline-only in v1 (no cloud/backends). This constrains Clip rich previews:
  v1 default is store URL + manual title/note only (fully offline). Opt-in on-demand fetch
  is deferred (§11). Bundle ID `gn.HabitsTracker` must NOT change regardless of any product
  rename.
