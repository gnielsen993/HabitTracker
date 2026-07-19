# My Life — Lifestyle Hub Product Direction

_Status: **Current experience implemented** 2026-07-18. The original capture-first proposal
below is retained only where it explains internal model decisions; the current user experience
is the calm personal daybook described here._

Evolution of HabitTracker from a pure habit app into a **local-first lifestyle hub**:
habits stay the daily driver, with low-friction offshoots into rules, lists, links, and
thoughts — organized within user-chosen life **Areas**.

User-facing vocabulary is intentionally human: My Life, Area, Principle, List, Saved Link,
Thought, Today, This Week, Show First, Move to Area, Turn into, Create Habit, and Inspired by.
The existing SwiftData names (`Domain`, `Rule`, `Collection`, `Clip`, `Idea`, and the
required/optional raw values) remain internal to preserve local data and avoid a needless
migration.

## Current experience

- **Today is action-only:** a calm greeting, one Up Next habit, a compact Today plan,
  flexible This Week goals, completed work tucked under Done today, and a collapsible note.
- **My Life owns creation:** Habit, Principle, List, Saved Link, and Thought can be created
  directly from My Life or within an Area. Creating a Thought first is never mandatory.
- **Thoughts are an optional scratchpad:** unplaced thoughts appear only when they exist and
  can be moved, turned into a Habit or Principle, added to a List, archived, or deleted.
- **Progress is workload-aware:** counts lead, percentages support them, Today opportunities
  and This Week targets are assessed separately, and individual habit patterns are primary.
- **History stays truthful:** effective-dated schedule revisions prevent current settings from
  rewriting the meaning of old days. Today and the current week remain in progress rather than
  being counted as failures.

---

## 0) The thesis

Apple Notes (and every notes app) treats **everything as inert text**. A grocery list, a
journal entry, a saved TikTok, and a personal rule all look identical and behave
identically — you type them, then they go stale. Notes is a graveyard.

Your lifestyle isn't inert. The things you want to track fall into distinct **modes of
engagement**, each wanting different behavior:

| Mode | Examples | What Notes can't do |
|------|----------|---------------------|
| **Do** | daily habits | check off, streaks, progress |
| **Follow** | style rules, "how to talk to people," money rules | hold as clean reference; spin a habit off it |
| **Collect** | clothes to buy, albums, concerts, shows | track status (want → owned, to-watch → watched) |
| **Capture** | ideas, things to spend on | quick in, promote later into a rule/habit/list |
| **Clip** | TikToks, links to keep | tag, file by domain, remember to act on it |

**Differentiator:** every part of your lifestyle gets the *right kind of structure*, filed
in one opinionated place, instead of one flat pile of text. The app is not "build my own
Notion" — it ships with opinionated domains and real starter content, and the daily habit
loop keeps you opening it.

---

## 1) Locked decisions (from discussion)

1. **Today/habits is the hero.** Habits are most-used; keep friction to start near zero.
   Rules / lists / links are *offshoots* reached from their domains, not piled onto Today.
2. **Rules are reference-first, not a nagging feed.** A rule is a clear saved spot for
   "how I want to dress / talk / spend." The *active* layer is **opt-in**: from a rule you
   can **stem a habit** (rule "talk to strangers" → habit "Talk to a stranger"). The rule
   stays as reference; the habit flows into Today. No automatic daily resurfacing in v1.
3. **Domains are a chosen set.** A listed catalog of built-in domains; user picks which to
   **focus**, can add their own. Each domain has an **icon** (SF Symbol) + color token for
   fast visual recognition.

---

## 2) The unifying model

Generalize the current `Category → Habit` into `Domain → Items of several types`.
This is a **generalization, not a rewrite** — the existing engines, seeding, export/import,
and management dashboard all carry over.

### Domain (generalizes today's `Category`)
Already has `name`, `iconName`, `colorToken`, `sortIndex`, `isSeeded`, `seedVersion`.
Add:
- `isFocused: Bool` — user chose to focus this domain (focused ones show in the Hub).

### Item types living inside a Domain
- **Habit** *(exists today)* — recurring, checkable. Schedule, required/optional mode,
  weekly target, streaks. Engines: Streak / WeeklyGoal / Stats apply **only** to habits.
  Add `originRuleID: UUID?` — set when stemmed from a rule.
- **Rule** *(new)* — a reference principle. `title`, `body`, optional `sourceURL`
  (where you saw it), `createdAt`. Action: **Stem habit** (prefilled, linked).
- **Collection + CollectionItem** *(new)* — a named list (e.g. "Albums to listen to") of
  entries. Covers shopping, wishlist, albums, concerts, shows, places, etc. The Collection
  model carries three properties that make built-ins *feel* domain-aware while keeping
  user-created lists generic (see "Collection behavior model" below):
  - `statusSetID` — which vocabulary its items move through.
  - `progressTemplate` — `none` · `counter` · `seasonEpisode` (a small **fixed** set; not
    user-definable in v1).
  - `showsAggregate: Bool` — whether the collection rolls up progress, or is a plain
    tracker/log.

  Each **CollectionItem**: `title`, `status` (a state from the collection's StatusSet),
  optional `position` (driven by `progressTemplate` — e.g. season/episode or a counter),
  optional `note`, optional `url`, optional `cost`, `sortIndex`, `isSeeded`.

#### Collection behavior model (status vs. position vs. aggregate)
Three independent axes, so built-in lists feel considered without bespoke code per type:

- **StatusSet** — an ordered list of states with a terminal "done" state. A Collection
  references one `statusSetID`. Built-ins use curated sets (`to-fly → flown`,
  `to-watch → watching → watched`); user-created lists default to the generic
  `to-collect → collected` (alternates: `to-complete → completed`, `to-do → done`). Same
  code path, different seed data. **Status is not free text and not a hard enum per type** —
  it's a template instance. Rendered as a **tap-to-advance chip** (binary is just N=2).
  Built-in labels are **not** user-editable in v1 (keeps the opinionated feel); users who
  want different words create their own list with the generic set.
- **Position** — an optional running counter you *advance*, with **no required total**
  (avoids an upfront "how many episodes?" cost). Driven by `progressTemplate`:
  - `none` — no position (most lists).
  - `counter` — a single `+1` bump with a label (e.g. "Fast 6", "Chapter 12").
  - `seasonEpisode` — buttons **+episode** (episode += 1), **+season** (season += 1,
    episode → 1), and **finished** (sets status to the terminal state). Item shows "S2 E4".
  Position is an *add-on to* status, not a separate mode: a show is `watching` **and**
  `S2 E4`, then `watched` when finished.
- **Aggregate** (`showsAggregate`) — completionist lists (planes, albums, places) roll up
  "**23/50 flown**"; tracker lists (bought, want-to-spend) show no progress (progress toward
  spending feels wrong). For money-flavored lists the rollup, when shown, is a **cost sum**
  ("$340 of wishlist"), **not** a completion ring. Presets set a sensible default; the user
  can flip the flag per collection. *(This resolves the earlier open cost-rollup question:
  cost sums in tracker-mode; never a progress ring on spend.)*
- **Idea** *(new)* — freeform capture. Can be **promoted** into a rule, habit, or
  collection item later.
- **Clip / Link** *(new)* — a saved URL (TikTok/article). `title`, `url`, `note`,
  `tag`, `status` (saved/acted). See open question on previews (offline constraint).

> Connective tissue: **Rule → Habit** ("stem"), and **Idea → anything** ("promote").
> These two flows are what make it a *system* rather than typed folders.

#### Stem & Promote (the connective tissue, spec'd)
The governing rule is a deliberate **asymmetry**: *reference persists, staging is consumed.*

- **Stem (Rule → Habit) = copy.** Creates a new Habit; the rule is untouched (locked
  decision §1.2). Opens the normal habit-create sheet **prefilled** with title (from the
  rule, editable) and `domain = the rule's domain` (editable); the user sets
  schedule / required-optional themselves (the rule has none to inherit). `originRuleID` links
  habit → rule. **Bidirectional:** the rule shows "Stemmed: N habits" (tap to jump), the habit
  shows a subtle "from rule: …" backref. **One rule → many habits** allowed.
  - **Orphan rule on delete = nullify, never cascade.** Deleting a rule must *never* delete a
    habit (habits are the hero data). The habit survives; `originRuleID` → nil; the backref
    quietly disappears. Soft-confirm when habits reference the rule: "This rule has N stemmed
    habits — they'll stay, but lose their link." (SwiftData relationship: nullify delete rule.)

- **Promote (Idea → Rule / Habit / Collection item) = consume.** On success the idea is
  **archived with a forward-link** to what it became (auditable) and leaves the active
  inbox/idea list — keeping the inbox clean is the whole point (else: Notes graveyard). The
  result carries **no** backref to the idea (lean model).
  - **Carries per target:** → Rule: text → body/title, idea URL → `sourceURL`. → Habit: text →
    title, then the **same habit-create sheet as Stem** (one shared code path). → Collection
    item: text → title, **user picks the target collection**; URL/cost carry if present.
  - **Domain at promote time:** an **unfiled** inbox idea must capture a domain (Rules &
    Collections live in domains); a filed idea defaults to its own domain.
  - **Two graduations for an inbox idea:** **File** (stays an Idea, just gains a domain) vs
    **Promote** (becomes another type, idea consumed) — both one-tap from the inbox.

---

## 3) Navigation & screens

Keep 4 tabs (don't grow the tab bar):

1. **Today** — the daily driver. Required habits + optional weekly badges, daily note.
   Habits stemmed from rules look like any other habit here. *No rules/lists clutter.*
2. **Hub** *(new — replaces nothing; this is the offshoot home)* — grid of **focused
   domains** with their icons. Tap a domain → its sections: Habits · Rules · Lists ·
   Clips · Ideas (only sections with content/relevance shown).
3. **Progress** — existing charts; fold the Calendar heatmap inside (habit history only).
4. **Settings** — existing management dashboard + **Domain focus picker** + export/import.

Key sub-screens:
- **DomainDetailView** — sections per item type within one domain.
- **RuleDetailView** — reference text + "Stem habit" button.
- **CollectionView** — list entries with status toggles.
- **Domain focus/catalog** — pick which domains to focus, add custom (name + icon + color).

### Creation model (current)

Creation is direct and place-oriented, without a mandatory staging workflow:

- **My Life `+`:** creates a Habit or Thought immediately, or creates a Principle, List,
  or Saved Link after choosing its Area.
- **Area `+`:** creates any of the five item types already scoped to that Area.
- **Today:** has no creation affordance while work exists. A genuinely empty day offers
  only a contextual **Set up a habit** route into My Life.
- **Thoughts:** title is required; note and reference link are optional. A Thought may stay
  a Thought forever. The internal promotion service remains an implementation detail for
  outcome-based actions such as **Turn into Habit**.

The retired global Idea inbox, Today toolbar `+`, File/Promote wording, and mandatory
Idea → File → Promote mental model are not part of the intended experience.

> The global capture feeds the inbox; the in-domain `+` files directly. Both routes converge
> on the same item types, so there's one creation code path, two surfaces.

---

## 4) What Notes does poorly → how we answer it (design principles)

- Inert text → items have **behavior** (check, status, stem, promote).
- No "do vs reference vs principle" separation → **typed items**, distinct UI per type.
- Rules get buried → rules are first-class, filed by domain, and can **become habits**.
- Saved links rot → clips carry **status + domain tag**, found where you'd look.
- No progress → habits keep streaks/weekly targets (existing engines).
- Shallow folders → **opinionated domains** with real seeded starter content.

---

## 5) Seed strategy (keeps it "real app," never an empty screen)

Ship a domain catalog; pre-focus a sensible subset. Seed each with light starter content.
Examples:
- **Style** — rules ("neutral base + one accent," "no logos"), a "Clothes to buy" list.
- **Diet** — rules, a habits set (Water, Cook at home).
- **Money** — rules ("48h before any >$X buy"), a "Want to spend on" list.
- **Social** — rule "talk to a stranger" (good stem-a-habit demo).
- **Media** — lists: albums, concerts, shows.
- Plus the existing habit-heavy domains (Productivity, Health, Mindfulness, etc.).

All seeded content editable/archivable; reuse existing `isSeeded` / `seedVersion`.

### Curated collection presets (a content deliverable, authored like seed habits)
Built-in collections ship with curated StatusSets, progress templates, and aggregate
defaults so they *feel* different — not just a different title. The **generic** preset must
exist before any user-created collection can be saved.

| Collection (built-in) | StatusSet | Progress template | Aggregate default |
|---|---|---|---|
| Shows | to-watch → watching → watched | `seasonEpisode` | off (log) |
| Movies / franchises | to-watch → watched | `counter` (+1) | count |
| Albums | to-listen → listened | `none` | "X/Y" |
| Concerts | want-to-go → went | `none` | tracker |
| Books | to-read → reading → read | `counter` (chapter, optional) | count |
| Clothes to buy | want → owned | `none` | tracker + cost sum |
| Want to spend on | want → bought | `none` | tracker + cost sum |
| Planes / places | to-fly → flown · to-go → been | `none` | "X/Y" (completionist) |
| **Generic (user-created)** | to-collect → collected | `none` | user choice |

Notes:
- `progressTemplate` is a **fixed set** (`none` · `counter` · `seasonEpisode`) — *not*
  user-definable in v1. This is the explicit guard against the StatusSet/counter model
  bloating into a generic spreadsheet builder (see §9 scope-creep risk).
- `seasonEpisode` button semantics: **+episode** (episode += 1), **+season** (season += 1,
  episode → 1), **finished** (status → terminal). No total is ever required.

---

## 6) Build order (when approved)

Each phase is a shippable vertical slice; habits keep working throughout.

- **Phase A — Domain generalization.** Add `isFocused`; build Hub tab + domain focus
  picker + custom-domain creation with icon picker. (Mostly relabel + one field.)
- **Phase B — Rules.** Rule model, RuleDetailView, **Stem habit** flow (`originRuleID`,
  copy-not-move, prefilled habit sheet, nullify-on-delete, bidirectional backref — see §2
  Stem & Promote). This phase ships the shared habit-create-from-source sheet that Phase E
  reuses for promote-to-habit.
- **Phase C — Collections.** StatusSet model + tap-to-advance status chips + `showsAggregate`
  rollups (count and cost-sum) as the spine. Ship the `seasonEpisode` and `counter` progress
  templates (Shows is the compelling case). Curated presets from §5; generic preset is a
  prerequisite. *Scope guard: do not reopen the fixed `progressTemplate` set mid-phase.*
- **Phase D — Clips.** Saved links with tag/status (resolve preview question first).
- **Phase E — Ideas + promotion.** Global quick-add (capture-first), the **Hub inbox** for
  unfiled items, **File vs Promote** graduations, and **promote** to rule/habit/collection
  item (consume + archive-with-link; reuses Phase B's habit sheet — see §2 Stem & Promote).
  In-domain `+` (place-first) is delivered per type in B–D; this phase adds the global surface
  that ties them together. (See §3 Creation model.)
- **Phase F — Polish.** Cross-domain search, Hub layout, empty states, export/import for
  all new types, accessibility pass (was already the pending "Next 3").
- **Later — Widgets.** Still unbuilt from the original v1 spec; sequence after the hub
  stabilizes.

### Acceptance criteria (the checkable "done" per phase)
Every phase also inherits the **baseline DoD** (constitution §7): compiles; behavior verified
with what-was-run stated; token + structure rules held; **upgrade test green** (existing
habit user updates over their store, app launches, all prior data visible — per
`Docs/SCHEMA_MIGRATION_PLAYBOOK.md`); export/import round-trip green for any
type touched; no new drift. On top of that, each phase is done when:

- **A — Domain generalization.** Upgrade leaves all habits/categories intact. Hub shows
  focused domains as an icon+color grid; tapping opens DomainDetailView showing only
  non-empty sections. Focus picker adds/removes a Hub tile; **unfocus hides the tile but
  never deletes content**. Custom domain (name + SF Symbol + color token) persists and
  appears in the catalog. Today is visually unchanged.
- **B — Rules.** Create/edit/archive a Rule (title + body + optional `sourceURL`). **Stem**
  opens a prefilled habit sheet (title + rule's domain, editable schedule); the new habit
  appears on Today. Rule shows "Stemmed: N habits" → jumps to habit; habit shows "from rule"
  → jumps to rule. One rule stems ≥2 habits. Deleting a rule with stemmed habits soft-confirms,
  habits **survive**, `originRuleID` nulled.
- **C — Collections.** Create from a preset; items carry status from its StatusSet; the
  tap-to-advance chip cycles through states incl. terminal. `seasonEpisode` (+episode /
  +season resets ep→1 / finished→terminal) shows "S2 E4". `counter` +1 increments its label.
  `showsAggregate` ON → "X/Y"; tracker mode → no ring; money lists → cost sum. Generic preset
  exists and is the default for user-created lists. Built-in labels not editable.
- **D — Clips.** Save a URL (title + note + tag + status) **fully offline** (per the resolved
  preview decision). Clip is filed by domain and found in the domain's Clips section; status
  toggles saved → acted.
- **E — Ideas + promotion.** Global quick-add reachable **without leaving Today and without
  adding a row to Today's list**; defaults to Idea; lands in the Hub inbox. **File** assigns a
  domain (stays an Idea); **Promote** converts to rule/habit/collection item per §2, carrying
  the right fields, and the idea is archived with a forward-link and leaves the active list.
  Unfiled-idea promote prompts for a domain; promote-to-collection prompts for the target list.
- **F — Polish.** Cross-domain search returns items across types and navigates to a tapped
  result. Every section / inbox / Hub has an empty state. Full export/import round-trips **all**
  types under the bumped `schemaVersion`. Accessibility: Dynamic Type, VoiceOver labels on
  chips/buttons/grid, tokens-only colors.

---

## 7) Data safety & migration (must respect constitution)

- All additions are **additive**: new `@Model` classes + optional fields with defaults →
  SwiftData lightweight migration, no data loss for existing habit users.
- **`Category` → `Domain` rename:** renaming the `@Model` class is the one risky move (a
  store-incompatible change). Two safe options — decide before Phase A:
  - (a) keep the Swift class `Category`, just relabel as "Domain" in UI (zero migration), or
  - (b) rename the class using **`@Attribute(originalName: "Category")`**, kept **plan-less**.
  - ❌ **Do NOT** use a `SchemaMigrationPlan` / `ModelContainer(for:migrationPlan:…)` for this.
    The ecosystem already proved it throws an uncatchable Obj-C `NSException` and crashes the
    process — see `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` (Forbidden Moves). All
    SwiftData changes here follow that playbook: additive optional/defaulted fields, inferred
    lightweight migration, no explicit plan; renames only via `@Attribute(originalName:)`.
  Export/Import already exists as the fallback safety net either way.
- Extend `schemaVersion` in export to cover the new types; keep round-trip tests.

---

## 8) Open questions (need a call before the relevant phase)

> **Resolved (now spec'd in §2 / §3 / §5):**
> - **Collection status model** — curated StatusSets for built-ins, generic
>   `to-collect → collected` for user-created. Status vs. position vs. aggregate are three
>   axes; `progressTemplate` is a fixed set (`none`/`counter`/`seasonEpisode`), not
>   user-definable in v1. Built-in labels not user-editable. Cost rolls up as a sum in
>   tracker-mode, never a progress ring on spend. (§2 / §5)
> - **Creation model** — capture-first global quick-add → Hub inbox, plus place-first
>   in-domain `+`; title-only minimum; capture must not pollute Today. (§3)
> - **Stem & Promote** — stem = copy (rule persists, nullify-on-delete), promote = consume
>   (idea archived with forward-link). Shared habit-create sheet. (§2)

1. **Clip previews vs offline-only.** Rich link/TikTok thumbnails need a network fetch,
   which conflicts with the v1 offline-only rule. Options: store URL + manual title/note
   only (fully offline), or allow an *opt-in, on-demand* fetch. → decide at Phase D.
2. **`Category` → `Domain`:** relabel-only (a) vs `@Attribute(originalName:)` rename (b) —
   see §7. The migration-plan path is **struck** (proven to crash; playbook Forbidden Moves).
   → Phase A.
3. **Seed reconciliation for existing users** *(product, not schema)*. On update, an existing
   habit user already has Categories and a `seedVersion`. Decide:
   - Do their existing Categories auto-become **focused Domains**, or land unfocused (empty
     Hub until they pick)?
   - Are the new seeded domains/collection presets **pushed into an already-populated install**
     (risk: dumping starter content into a curated app) or **fresh-install-only** (risk:
     upgraders never discover the new domains)?
   - Re-seed policy against `seedVersion` for the above.
   → decide before Phase A (Hub) and revisit per phase as new seed types land.
4. **Cross-domain tagging:** strict domain filing only, or also free tags across domains?
   (Recommend: strict filing in v1; tags later if needed.)
5. **Naming/identity:** still "HabitTracker," or rename the product to reflect the hub?
   (Repo remote is `HabitTracker`; bundle ID must NOT change regardless.)

---

## 9) Risks

- **Scope creep into a generic everything-bucket.** Defense: opinionated seeded domains +
  the habit loop + the stem/promote flows. If it becomes empty typed folders, it's Notion.
- **Tab/IA bloat.** Defense: 4 tabs, offshoots nested under Hub, Today stays pure.
- **Migration mistakes.** Defense: additive-only changes + export/import safety net.

---

## 10) Success bar (how we know it worked — and how we'd catch the failure mode)

Offline-only, no analytics, so the bar is **qualitative + dogfood-driven**, not a metric
dashboard. The named failure mode (§9) is "it became empty Notion folders." We pass when:

- **The hero loop survives.** Today/habits is still the reason the app opens daily; the new
  surfaces *feed* it (stem → habit on Today) rather than competing for the home screen.
- **Every built-in domain demonstrates ≥1 thing Notes can't.** Each focused domain shows real
  *behavior* — a check, a status chip, a position, a stem, a promote — not just typed text.
  A domain that's only inert text **fails the bar** and should be cut or reworked, not shipped.
- **The five modes each have a real home.** Do / Follow / Collect / Capture / Clip are each
  reachable and behave distinctly (per §0). If two modes feel identical in use, the
  differentiation failed.
- **Connective tissue is cheap to reach.** Stem (from a rule) and Promote (from the inbox) are
  ≤2 taps from where you'd naturally be standing.
- **Dogfood signal (the real test).** Self-use for **4 weeks** post-Phase E. Pass = you still
  open it daily *and* you've filed/stemmed/promoted at least a handful of non-habit items
  unprompted. Fail signal = it drifts into a place you only open for habits, or the offshoots
  feel like folders you forget. Treat that as a design defect, not a content problem.

---

## 11) Deferred / open-ended (revisit later — not v1 scope)

Parked deliberately so they're not lost. None block Phase A.

- **Widgets** — from the original v1 spec; sequence after the hub stabilizes (§6 "Later").
- **Clip rich previews** — opt-in, on-demand fetch that respects offline-only; revisit after
  Phase D once the manual-title baseline ships (§8 Q1).
- **Cross-domain free tags** — beyond strict domain filing; revisit after Phase F (§8 Q4).
- **Rule active-resurfacing layer** — v1 has *opt-in* stem only and no daily resurfacing of
  rules (locked §1.2). A gentle resurfacing/review mode could come later if reference rules
  feel too passive.
- **Product naming/identity** — keep "HabitTracker" or rename for the hub; bundle ID frozen
  regardless (§8 Q5).
- **More progress templates** — beyond the fixed `none`/`counter`/`seasonEpisode`. Add only on
  *proven* repeated need; the fixed set is the scope guard (§2 / §9), so this bar is high.
- **DesignKit extraction** — promote any new component (status chip, position stepper, Hub
  grid tile) into DesignKit **only** once it's proven in 2+ apps (constitution §4).
- **Notifications/reminders** — none planned in v1 beyond eventual widgets; revisit with the
  widget work.
