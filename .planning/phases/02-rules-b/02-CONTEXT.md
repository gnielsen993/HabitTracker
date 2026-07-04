# Phase 2: Rules (B) - Context

**Gathered:** 2026-07-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Rules become clean, **reference-first** items (`title`, `body`, optional `sourceURL`,
`createdAt`) filed under a `Domain`. The phase also ships the **shared, reusable
habit-create-from-source sheet** (RULE-02) and the **Stem** flow: from a rule the user spins
off a new `Habit` (copy — rule left untouched) that flows into Today, with a **bidirectional
link** between rule and habit. This clarifies HOW to implement RULE-01…RULE-05. It does NOT
add Collections/Clips/Ideas (later phases), and it does NOT build the global Idea capture
surface — but the create sheet it delivers is **load-bearing**: Phase 5 promote-to-habit
reuses it verbatim.

</domain>

<decisions>
## Implementation Decisions

### Rule↔Habit link storage (RULE-04 / RULE-05)
- **D-01:** Model the stem link as a **SwiftData relationship**, not a raw UUID field:
  `Habit.originRule: Rule?` with `@Relationship(deleteRule: .nullify, inverse: \Rule.stemmedHabits)`.
  Rationale: the requirement's `originRuleID` names the *intent* ("nulled on delete, never
  cascade") — a `.nullify` relationship delivers exactly that semantic idiomatically, gives
  the backref (`habit.originRule`) and the count (`rule.stemmedHabits.count`, RULE-04) for
  free, and **mirrors the existing `Habit.category ↔ Domain.habits` `.nullify` pattern**. No
  manual nullify sweep, no hand-rolled two-direction fetches.
- **D-02:** `Rule.stemmedHabits` is the inverse array; a single rule stemming ≥2 habits
  (RULE-04) is just multiple `Habit.originRule` pointers — no extra modeling.
- **D-03:** Export/import (Phase 6) serializes the link as the habit's `originRule` **id
  reference** in JSON, consistent with how relationships are flattened for export.

### Shared habit-create sheet lifecycle (RULE-02 — load-bearing for Phase 5)
- **D-04:** Build a **new fill-then-commit sheet** (`HabitCreateSheet` over an in-memory
  draft/struct) that inserts the `Habit` into the `modelContext` **only on Save**. Cancel
  creates nothing. Rationale: RULE-02 is explicitly a "create-from-source" sheet reused by
  promote; a source-driven entry (a rule / an idea) must not litter Today with an orphan
  "New Habit" on cancel — the current insert-then-edit pattern would.
- **D-05:** The sheet is **prefilled + editable**: title (seeded from the source), domain
  (seeded from the rule's domain), plus user-set schedule and required/optional. It flows the
  saved habit into Today (RULE-03).
- **D-06:** **Migrate the existing "Add Habit" button** (`HabitManagerView:49`) to this same
  sheet — one create path everywhere. Kills the current orphan-on-cancel behavior in the
  manager too. Retire the insert-then-edit `Habit(name: "New Habit")` placeholder pattern.
- **D-07:** Design the sheet as **source-agnostic** (takes a prefill payload / optional origin)
  so Phase 5 promote-to-habit passes an idea as the source with zero sheet changes.

### Rule surface & entry points (RULE-01 / RULE-03 / RULE-04)
- **D-08:** Add a **"Rules" section inside `DomainDetailView`** — it slots into the already-
  scaffolded `nonEmptySections` loop (Phase 1 built this hook), filtered to non-empty and
  shown only when the domain has rules.
- **D-09:** A **"+" in the Rules section header** opens the rule editor to create a rule filed
  under that domain.
- **D-10:** A **dedicated `RuleDetailView`** (reached by tapping a rule) shows body, a tappable
  `sourceURL`, a **"Stem habit"** action (opens the D-04 sheet prefilled), and the
  **"Stemmed: N habits"** list; tapping a stemmed entry jumps to that habit (RULE-04).
- **D-11:** The **habit-side "from rule" backref** lives as a read-only row in
  `HabitEditorView` ("Stemmed from: [rule]") that navigates to the `RuleDetailView` (RULE-04).
- **D-12:** This nav shape (domain section → detail view → "+" in section header) is the
  **template Phases C–E mirror** for Collections/Clips/Ideas.

### Rule edit & archive pattern (RULE-01 / RULE-05)
- **D-13:** Mirror `Habit`: `Rule` gets an additive **`isArchived: Bool = false`** soft-archive
  field (SwiftData lightweight migration; §9.12 additive-defaulted rule). Archive hides, never
  deletes.
- **D-14:** A **`RuleEditorView` form sheet** (title, body, sourceURL, domain picker) shaped
  like `HabitEditorView` handles create + edit. Reuse the existing editor idiom (§4).
- **D-15:** **Delete a rule with stemmed habits → soft-confirm** via `confirmationDialog`:
  "This rule has N stemmed habit(s). They'll be kept — only the rule is deleted." On confirm,
  the `.nullify` rule (D-01) nulls each `Habit.originRule` automatically; habits survive
  (RULE-05, never cascade).

### Schema / migration (playbook territory)
- **D-16:** Adding `Rule` (`@Model`) + `Rule.stemmedHabits`/`Habit.originRule` + `Rule.isArchived`
  is **schema-expansion** — follow `Docs/SCHEMA_MIGRATION_PLAYBOOK.md`: plan-less inferred
  migration, new fields optional/defaulted, run the upgrade test, register `Rule` in the
  `.modelContainer(for:[…])` type list in `HabitsTrackerApp.swift`.
- **D-17:** Bump `ExportImportService.schemaVersion` (2 → 3) and extend the round-trip to cover
  `Rule` + the stem link. (Full multi-type export/import completeness is Phase 6; Phase 2 keeps
  the round-trip green for the types it adds.)

### Claude's Discretion
- Whether `HabitCreateSheet` takes an enum `HabitSource { .manual, .rule(Rule), .idea(Idea) }`
  or a lighter prefill struct — planner/executor choose, so long as it's source-agnostic (D-07).
- Exact `RuleDetailView` / `RuleEditorView` layout within DesignKit tokens (§9.4), file-split
  per §9.1 (~400-line cap), and data-driven-view rule (§9.2).
- Copy for the Rules-section empty state (§9.3) and the sourceURL affordance styling.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Plan & requirements
- `Docs/LIFESTYLE_HUB_PLAN.md` — Phase B (Rules) spec, the Rule→Habit stem semantics, and the
  shared habit-create-from-source sheet contract reused by Phase E.
- `.planning/ROADMAP.md` — Phase 2 goal, success criteria (5), and the "PROVIDES the shared
  habit-create sheet that Phase 5 reuses — load-bearing" dependency note.
- `.planning/REQUIREMENTS.md` — RULE-01…RULE-05 + shared baseline DoD.
- `.planning/PROJECT.md` — locked-intent decisions, constraints, open questions.
- `.planning/phases/01-domain-generalization-a/01-CONTEXT.md` — Phase 1 decisions this phase
  builds on (Domain model, DomainDetailView section-loop hook, plan-less migration stance).

### Migration (mandatory before any @Model change)
- `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` — plan-less inferred migration, additive-defaulted field
  rule, the mandatory upgrade test (install prior build → log data → install over → verify),
  Forbidden Moves.
- `CLAUDE.md` §9.12 (schema changes), §9.5 (new pure services ship with tests), §9.1/§9.2/§9.3/
  §9.15 (file cap, data-driven views, empty states, accessibility), §8 (commands, bundle id
  `gn.HabitsTracker`), §1 (design constraints, tokens-only).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HabitsTracker/Models/Habit.swift` — gains `originRule: Rule?` (`.nullify`); already has the
  `category: Domain?` relationship as the exact pattern to copy (D-01).
- `HabitsTracker/Models/Domain.swift` — `Rule` files under a domain (add `Domain.rules` inverse
  or `Rule.domain` with the same `.nullify` idiom as `Domain.habits`).
- `HabitsTracker/Features/Hub/DomainDetailView.swift` — `nonEmptySections(theme:)` is the
  Phase-1 hook: append a filtered "Rules" section here (D-08). Empty-state pattern already present.
- `HabitsTracker/Features/Settings/HabitEditorView.swift` (100 lines) — the form idiom to mirror
  for `RuleEditorView` (D-14); also gains the "Stemmed from" backref row (D-11).
- `HabitsTracker/Features/Settings/HabitManagerView.swift` — the insert-then-edit "Add Habit"
  button (line 49) migrates to the new `HabitCreateSheet` (D-06).
- `HabitsTracker/Services/ExportImportService.swift` — `schemaVersion` 2→3; extend for `Rule`
  + stem link (D-17).
- `HabitsTrackerApp.swift` — register `Rule` in `.modelContainer(for:[…])` (D-16).

### Established Patterns
- ModelContainer is **plan-less** (`.modelContainer(for:[…])`, no `migrationPlan:`) — inferred
  lightweight migration; new fields must be optional/defaulted.
- `.nullify` relationships with `inverse:` are the house pattern (`Habit.category ↔ Domain.habits`).
- DesignKit tokens only; Xcode synchronized root groups (objectVersion 77) auto-register new
  `.swift` files — never hand-edit `project.pbxproj` (§9.8), no Finder-dupe files (§9.6).
- Pure engines/services ship with unit tests in the same commit (§9.5) — the stem-link nullify
  behavior and export round-trip are the testable cores here.

### Integration Points
- New `Rule` `@Model` + `Habit.originRule`/`Rule.stemmedHabits` + `Rule.isArchived` → container
  type list + inferred migration + upgrade test.
- `HabitCreateSheet` is the shared surface consumed by (a) HabitManager "Add Habit", (b) Rule
  Stem, and (c) — next milestone — Phase 5 promote-to-habit. Keep it source-agnostic (D-07).

</code_context>

<specifics>
## Specific Ideas

- Rules are **reference-first**: the body (and a tappable source link) is the point — give it
  room in a dedicated detail view rather than cramming it into a list row.
- Cancelling a Stem must leave **zero trace** on Today — this drove fill-then-commit (D-04)
  over the existing insert-then-edit flow.
- One create path everywhere (D-06): the manager "Add Habit", Stem, and future Promote should
  all funnel through the same sheet so the flow only has to be right once.

</specifics>

<deferred>
## Deferred Ideas

- **Global Idea capture surface + Hub inbox + Promote** — Phase 5 (E). Phase 2 only delivers
  the reusable sheet that promote-to-habit will consume; it does not build the capture UI.
- **Full multi-type export/import completeness** (all 8 types under one bumped schemaVersion)
  — Phase 6 (F). Phase 2 keeps the round-trip green for the `Rule` + stem-link it adds.
- **Collections / Clips sections** in DomainDetailView — Phases 3/4; they mirror the Rules
  section pattern D-08/D-12 established here.

None outside phase scope — discussion stayed within the Rules domain.

</deferred>

---

*Phase: 2-Rules (B)*
*Context gathered: 2026-07-04*
