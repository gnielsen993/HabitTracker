# Requirements

Synthesized from ingest docs. No PRD-type documents were present. The SPEC
(`Docs/LIFESTYLE_HUB_PLAN.md`) is the source of truth; its phased build order (§6) and
per-phase acceptance criteria (§6 "Acceptance criteria") are extracted here as requirements
with success criteria. The A-F phase structure and cross-phase dependencies are preserved.

Each phase ALSO inherits the baseline Definition of Done (CLAUDE.md §7 + SPEC §6): compiles;
behavior verified with what-was-run stated; token + structure rules held; upgrade test green;
export/import round-trip green for any type touched; no new drift. See constraints.md.

---

## REQ-phase-a-domain-generalization
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§6 Phase A, §6 Acceptance A)
- scope: Domain model, Hub tab, focus picker, custom-domain creation
- dependencies: none (Phase A is the foundation). Migration decision (Category->Domain) must
  be made before this phase per §7 / §8 Q2.
- description: Generalize `Category` into `Domain`. Add `isFocused: Bool`. Build the Hub tab,
  the domain focus picker, and custom-domain creation with an SF Symbol icon picker.
- success criteria:
  - Upgrade leaves all habits/categories intact (upgrade test green).
  - Hub shows focused domains as an icon+color grid; tapping opens DomainDetailView showing
    only non-empty sections.
  - Focus picker adds/removes a Hub tile; unfocus HIDES the tile but NEVER deletes content.
  - Custom domain (name + SF Symbol + color token) persists and appears in the catalog.
  - Today is visually unchanged.

## REQ-phase-b-rules
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§6 Phase B, §6 Acceptance B, §2 Stem & Promote)
- scope: Rule model, RuleDetailView, Stem-habit flow, shared habit-create-from-source sheet
- dependencies: Phase A (Domain model). PROVIDES the shared habit-create-from-source sheet
  that Phase E reuses for promote-to-habit — this dependency is load-bearing.
- description: Add the Rule model (`title`, `body`, optional `sourceURL`, `createdAt`).
  Build RuleDetailView and the Stem-habit flow (`originRuleID`, copy-not-move, prefilled
  habit sheet, nullify-on-delete, bidirectional backref). Ship the shared
  habit-create-from-source sheet.
- success criteria:
  - Create/edit/archive a Rule (title + body + optional `sourceURL`).
  - Stem opens a prefilled habit sheet (title + rule's domain, editable schedule); the new
    habit appears on Today.
  - Rule shows "Stemmed: N habits" -> jumps to habit; habit shows "from rule" -> jumps to rule.
  - One rule stems >=2 habits.
  - Deleting a rule with stemmed habits soft-confirms; habits SURVIVE; `originRuleID` nulled.

## REQ-phase-c-collections
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§6 Phase C, §6 Acceptance C, §2 Collection behavior, §5 presets)
- scope: StatusSet model, status chips, progress templates, aggregate rollups, curated presets
- dependencies: Phase A (Domain). The generic StatusSet preset (`to-collect -> collected`)
  is a prerequisite and must exist before any user-created collection can be saved.
- description: Add the StatusSet model + tap-to-advance status chips + `showsAggregate` rollups
  (count and cost-sum) as the spine. Ship the `seasonEpisode` and `counter` progress templates
  (Shows is the compelling case). Author curated presets from §5; generic preset is a
  prerequisite. Scope guard: do not reopen the fixed `progressTemplate` set mid-phase.
- success criteria:
  - Create from a preset; items carry status from its StatusSet; the tap-to-advance chip
    cycles through states including terminal.
  - `seasonEpisode` (+episode / +season resets ep->1 / finished->terminal) shows "S2 E4".
  - `counter` +1 increments its label.
  - `showsAggregate` ON -> "X/Y"; tracker mode -> no ring; money lists -> cost sum.
  - Generic preset exists and is the default for user-created lists.
  - Built-in labels not editable.

## REQ-phase-d-clips
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§6 Phase D, §6 Acceptance D, §8 Q1)
- scope: Clip/Link model, tag/status, offline preview decision
- dependencies: Phase A (Domain). Requires resolving the Clip-preview-vs-offline open question
  (§8 Q1) first.
- description: Add saved links with tag/status. Resolve the preview question first
  (default: store URL + manual title/note, fully offline).
- success criteria:
  - Save a URL (title + note + tag + status) FULLY OFFLINE (per the resolved preview decision).
  - Clip is filed by domain and found in the domain's Clips section.
  - Status toggles saved -> acted.

## REQ-phase-e-ideas-promotion
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§6 Phase E, §6 Acceptance E, §2 Stem & Promote, §3 Creation model)
- scope: Idea model, global quick-add, Hub inbox, File vs Promote, promote flows
- dependencies: Phase A (Domain), Phase B (REUSES Phase B's shared habit-create sheet for
  promote-to-habit), Phase C (promote-to-collection-item target), Phase D (in-domain + per type).
  This phase adds the global capture surface that ties the in-domain + entry points together.
- description: Add the Idea model. Build global quick-add (capture-first), the Hub inbox for
  unfiled items, File vs Promote graduations, and promote to rule/habit/collection item
  (consume + archive-with-link; reuses Phase B's habit sheet).
- success criteria:
  - Global quick-add reachable WITHOUT leaving Today and WITHOUT adding a row to Today's list;
    defaults to Idea; lands in the Hub inbox.
  - File assigns a domain (stays an Idea); Promote converts to rule/habit/collection item per
    §2, carrying the right fields, and the idea is archived with a forward-link and leaves the
    active list.
  - Unfiled-idea promote prompts for a domain; promote-to-collection prompts for the target list.

## REQ-phase-f-polish
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§6 Phase F, §6 Acceptance F)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/STATUS.md (Next 3 — pre-existing accessibility/empty-state work folds in here)
- scope: Cross-domain search, Hub layout, empty states, full export/import, accessibility
- dependencies: Phases A-E (operates across all new types).
- description: Cross-domain search, Hub layout, empty states, export/import for all new types,
  accessibility pass. Absorbs the pre-existing pending "Next 3" (accessibility, empty states,
  schema visibility in Settings) from STATUS.md.
- success criteria:
  - Cross-domain search returns items across types and navigates to a tapped result.
  - Every section / inbox / Hub has an empty state.
  - Full export/import round-trips ALL types under the bumped `schemaVersion`.
  - Accessibility: Dynamic Type, VoiceOver labels on chips/buttons/grid, tokens-only colors.

## REQ-deferred-widgets (parked — not v1 scope)
- source: /Users/gabrielnielsen/Desktop/HabitsTracker/Docs/LIFESTYLE_HUB_PLAN.md (§6 Later, §11)
- scope: WidgetKit
- dependencies: sequence AFTER the hub stabilizes (post Phase F).
- description: Widgets, still unbuilt from the original v1 spec. Deferred deliberately; does not
  block Phase A. Listed for traceability only — downstream planning should not schedule into v1.
