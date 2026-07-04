---
phase: 2
slug: rules-b
status: approved
shadcn_initialized: false
preset: none
created: 2026-07-04
reviewed_at: 2026-07-04
---

# Phase 2 — UI Design Contract

> Visual and interaction contract for the Rules surfaces + the shared habit-create sheet. Generated in-session (gsd-ui-researcher timed out mid-run; authored directly from 02-CONTEXT.md decisions D-01…D-17 and verified against DesignKit source), to be verified by gsd-ui-checker.
>
> **Platform note:** This is a native **SwiftUI / iOS** app backed by the shared **DesignKit** Swift Package — NOT web/CSS. There is no shadcn, no registry, no hex. All values below are expressed as **DesignKit semantic tokens** and **SF Symbols**. "Hard rules" from `CLAUDE.md` are binding: no hard-coded colors, accents constrained to exactly 5 tokens (forest, navy, maroon/oxblood, walnut, stone), Balanced Luxury restraint, spacing/radii/typography come from DesignKit tokens only.
>
> **Continuity:** This contract reuses the Phase 1 token vocabulary and the `accentColor(forToken:)` resolver verbatim. The nav shape defined here (domain **section → detail view → section-header "+"**) is the **template Phases C–E mirror** for Collections / Clips / Ideas — design every pattern below to generalize.

---

## Surfaces in scope

| # | Surface | Requirement | New / edited file |
|---|---------|-------------|-------------------|
| S1 | Rules **section** inside `DomainDetailView` (list rows + header "+") | RULE-01 | `Features/Hub/DomainDetailView.swift` (edit — append to `nonEmptySections`) + `Features/Rules/RuleRow.swift` (new) |
| S2 | `RuleDetailView` — reference-first read surface (body, sourceURL, Stem, "Stemmed: N") | RULE-01, RULE-03, RULE-04 | `Features/Rules/RuleDetailView.swift` (new) |
| S3 | `RuleEditorView` — create/edit form sheet + archive + delete-with-stems | RULE-01, RULE-05 | `Features/Rules/RuleEditorView.swift` (new) |
| S4 | `HabitCreateSheet` — shared **fill-then-commit** habit create (source-agnostic) | RULE-02, RULE-03 | `Features/Habits/HabitCreateSheet.swift` (new) |
| S5 | Habit-side **"from rule" backref** row | RULE-04 | `Features/Settings/HabitEditorView.swift` (edit — add read-only row) |
| — | Today | — | **Untouched — visually unchanged. Do not edit.** |

> S4 is load-bearing: the same sheet is launched from S2's "Stem habit" action, from the migrated `HabitManagerView` "Add Habit" button (D-06), and — next milestone — from Phase 5 promote-to-habit. Its chrome must read identically regardless of launch source.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (native SwiftUI; no shadcn/registry) |
| Preset | not applicable — DesignKit `ThemePreset` is user-selected at runtime; this contract is preset-agnostic |
| Component library | DesignKit (`../DesignKit`, local path) — `DKCard`, `DKBadge`, `DKSectionHeader`, `DKButton`, `DKProgressRing` (verified present) |
| Icon library | **SF Symbols only** (Apple SDK). No third-party icon dependency. |
| Font | DesignKit `TypographyTokens` (verified). Dynamic Type respected (§9.15) |
| Color source | DesignKit `theme.colors.*` semantic tokens via `themeManager.theme(for: colorScheme)`; per-domain accent via the existing app-level `accentColor(forToken:)` resolver (Phase 1, app `Utilities/`, NOT DesignKit — §9.14). |

**Hard constraint (binding on every surface below):** No `Color(hex:)`, no `Color(red:…)`, no literal radii/spacing/opacity. Colors come only from `theme.colors.*` or `accentColor(forToken:)`. Spacing only from `theme.spacing.*`; radii only from `theme.radii.*`; type only from `theme.typography.*`.

---

## Spacing Scale

Source of truth: `DesignKit/Layout/SpacingTokens.swift` (verified: `xs, s, m, l, xl, xxl`). **Do not invent values — use these tokens by name.**

| Token | Value | Usage in this phase |
|-------|-------|---------------------|
| `theme.spacing.xs` | 4 | Rule-row title↔subtitle gap; "Stemmed: N" badge inner padding; icon↔label gap |
| `theme.spacing.s` | 8 | Between form field label and control; sourceURL glyph↔text gap; stemmed-row inset |
| `theme.spacing.m` | 12 | Between stacked rule rows; between form fields; RuleDetail header block gaps |
| `theme.spacing.l` | 16 | `DKCard` / section content padding; sheet horizontal padding; screen padding |
| `theme.spacing.xl` | 24 | Between `RuleDetailView` blocks (header → body → source → stem → stemmed list); empty-state vertical rhythm |
| `theme.spacing.xxl` | 32 | Empty-state top inset / major breaks |

Radii — source `DesignKit/Layout/RadiusTokens.swift` (verified: `card, button, chip, sheet`):

| Token | Value | Usage |
|-------|-------|-------|
| `theme.radii.card` | 16 | Rule rows / detail cards (`DKCard` surfaces) |
| `theme.radii.button` | 14 | "Stem habit" CTA, "Save" buttons |
| `theme.radii.chip` | 12 | "Stemmed: N" `DKBadge`, "from rule" backref pill, "Archived" badge |
| `theme.radii.sheet` | 22 | `RuleEditorView` + `HabitCreateSheet` sheet surfaces |

**Exceptions:** All tap targets (rule rows, stemmed-habit rows, sourceURL affordance, "+" header button, Stem CTA) must be **≥ 44×44 pt** (HIG / §9.15) via `.frame(minHeight:44)` — the only allowed non-token dimension, an accessibility floor not a style choice. Matches Phase 1.

---

## Typography

Source of truth: `DesignKit/Typography/TypographyTokens.swift` (verified — the same 6 token roles as Phase 1). Do not introduce new `.font(.system(size:))` calls.

| Role | Token | Underlying | Usage in this phase |
|------|-------|-----------|---------------------|
| Display | `theme.typography.titleLarge` | 32 / bold / rounded | Empty-state heading (Rules section) |
| Heading | `theme.typography.title` | title2 / semibold | `RuleDetailView` rule title; section headers via `DKSectionHeader` ("Rules", "Stemmed habits") |
| Label | `theme.typography.headline` | headline | Rule-row title; form field labels; stemmed-habit row name; "Stem habit" button label |
| Body | `theme.typography.body` | body / regular | Rule **body** long-form text; form field values; empty-state body; sourceURL text |
| Caption | `theme.typography.caption` | caption | Rule-row secondary line (domain / archived); backref caption; sourceURL host hint; delete-dialog message |
| Mono | `theme.typography.monoNumber` | monospaced body | Optional: the count digit in "Stemmed: **N**" if rendered as a standalone numeral. Default is the `DKBadge` label (headline/caption); mono is reserved, not required. |

- Dynamic Type: all text scales; the rule **body** wraps freely (no fixed-height container, no `.lineLimit` on the detail body). Rule rows cap the title at 1–2 lines with `.minimumScaleFactor` only where truncation would break the row.
- Line height: SwiftUI defaults per token; do not override.

---

## Color

DesignKit applies a **60/30/10 split structurally** via semantic tokens — this contract maps each role to the existing token. Verified against `DesignKit/Theme/Tokens.swift` (`ThemeColors`: `background, surface, surfaceElevated, border, textPrimary, textSecondary, textTertiary, danger, success, fillSelected, accentPrimary`).

| Role | Token | Usage |
|------|-------|-------|
| Dominant (60%) | `theme.colors.background` | Screen background for `RuleDetailView`, editor + create sheets |
| Secondary (30%) | `theme.colors.surface` / `theme.colors.surfaceElevated` | Rule rows, detail cards, stemmed-habit rows, sheet surfaces |
| Border | `theme.colors.border` | Row / card stroke (1pt), sourceURL affordance outline |
| Text | `theme.colors.textPrimary` / `textSecondary` / `textTertiary` | Titles + body / supporting captions / placeholder + disabled hints |
| Accent (10%) | `accentColor(forToken:)` → the **rule's domain** color | **Reserved list below — never "all interactive elements"** |
| Primary action | `theme.colors.accentPrimary` | "Stem habit" and "Save" CTAs (generic theme accent, NOT a domain color — keeps the 5 domain accents meaningful) |
| Destructive | `theme.colors.danger` | "Delete rule" affordance + delete-with-stems confirmation confirm button |

**Accent (`accentColor(forToken:)`) reserved for (exhaustive):**
1. The rule's domain glyph in the `RuleDetailView` header (tinted from the owning `domain.colorToken`).
2. The small domain glyph/dot on a `RuleRow` (S1), if shown — resolved from the domain's token.

**Accent is NOT used for:** the "Stem habit" CTA (uses `accentPrimary`), body text, section chrome, form controls, the sourceURL link text, or badges — those use `textPrimary` / `surface` / `accentPrimary` / `danger` so the 5 domain accents stay identity-only (one color = one domain).

**Resolver reuse (no new resolver):** consume the Phase 1 `accentColor(forToken: domain.colorToken, theme:)`. Unknown/legacy token → `theme.colors.accentPrimary` fallback (never crash, never off-palette). Do not duplicate the mapping.

---

## Component Inventory & Interaction Contract

### S1 — Rules section in `DomainDetailView` (RULE-01)
- **Integration:** append a `DomainSection(id:"rules", title:"Rules", …)` to `nonEmptySections` (Phase 1 built this loop hook). The section renders **only when the domain has ≥1 non-archived rule** — otherwise the whole section is absent (DOM-03 "only non-empty sections" contract still holds; the domain's own Phase-1 empty state covers a fully-empty domain).
- **Section header:** `DKSectionHeader("Rules")` with a trailing **"+"** button (`Image(systemName:"plus")`, ≥44pt, `accentPrimary` tint) that presents `RuleEditorView` in create mode, pre-filed under this domain.
- **Row (`RuleRow`, data-driven per §9.2 — takes a `Rule`, owns no query):** `DKCard` surface; title in `theme.typography.headline` (textPrimary, 1–2 lines); optional second line in `theme.typography.caption` (textSecondary) showing a stemmed count (`"Stemmed: N"`) and/or `"· has link"` when `sourceURL != nil`. Whole row is one ≥44pt tap target → push `RuleDetailView(rule:)`. No swipe-delete on the row (delete lives in the editor, S3, so the confirmation copy is always shown).
- **Ordering:** rules sorted by `createdAt` descending (newest first). Archived rules are excluded from this section.
- **Empty state (§9.3):** not a separate blank screen — when the domain has zero rules the section simply does not appear; the "+" to create the first rule is reachable via the Phase 5 in-domain add and, this phase, via the `HabitManager`-style entry / the section header once one exists. **First-rule affordance:** if the domain has other non-empty sections but zero rules, no Rules section shows (correct). Copy for the domain-level empty state is Phase 1's ("Nothing here yet…") — unchanged.

### S2 — `RuleDetailView` (RULE-01 / RULE-03 / RULE-04)
Data-driven: takes a `Rule` value; declares **no `NavigationStack` of its own** (nests under the Hub stack, mirrors `DomainDetailView`). Vertical `ScrollView` of blocks separated by `theme.spacing.xl`:
1. **Header block:** owning-domain glyph (accent-tinted via `accentColor(forToken:)`) + rule **title** in `theme.typography.title` (textPrimary). If archived, an `"Archived"` `DKBadge` (chip radius, textSecondary/surface — not danger) sits inline.
2. **Body block:** the rule's `body` in `theme.typography.body` (textPrimary), full-wrap, selectable, no line limit. If body is empty, omit the block (do not show an empty card).
3. **Source block (conditional):** shown only when `sourceURL != nil`. A bordered `DKCard`-style affordance: leading `Image(systemName:"link")`, the URL **host** (e.g. `apple.com`) in `theme.typography.body` (textPrimary) with the full URL in `theme.typography.caption` (textSecondary) beneath. Tapping opens the link via `Link`/`openURL` (offline-safe: this only *stores + opens* a URL, no fetch — honors the offline-only constraint). ≥44pt.
4. **Primary action:** **"Stem habit"** — `DKButton` (or styled button) full-width, `accentPrimary`, `theme.radii.button`, ≥44pt. Presents `HabitCreateSheet` (S4) prefilled from this rule.
5. **Stemmed block (conditional, RULE-04):** shown only when `rule.stemmedHabits` is non-empty. `DKSectionHeader("Stemmed habits")` + a list of rows (one per stemmed habit), each: habit name in `theme.typography.headline`, ≥44pt, tap → navigate to that habit (push a habit detail / open `HabitEditorView` for it). A `"Stemmed: N"` `DKBadge` (chip radius) may sit in the section header.
- **Toolbar:** trailing **"Edit"** button → presents `RuleEditorView` in edit mode.

### S3 — `RuleEditorView` (RULE-01 / RULE-05)
- Presented as a **sheet** (`theme.radii.sheet`), shaped like the existing `HabitEditorView` `Form` idiom (§4 reuse). Fields: **Title** (`TextField`, trim + non-empty guard), **Body** (`TextEditor`, multi-line, optional), **Source URL** (`TextField`, `.keyboardType(.URL)`, `.textInputAutocapitalization(.never)`, optional), **Domain** (`Picker` over domains, defaults to the section/rule's domain).
- Field labels `theme.typography.headline`; values `theme.typography.body`.
- **Save CTA:** **"Add Rule"** in create mode / **"Save Changes"** in edit mode (`accentPrimary`), disabled until a non-empty trimmed title exists → inline validation copy (below). On save: create-mode inserts the `Rule` + `try modelContext.save()`; edit-mode mutates in place + saves. (Verb + noun, matching Phase 1's "Add Domain" — never a bare "Save".)
- **Archive:** a row/toggle **"Archive rule"** flipping `isArchived` (D-13). Archiving returns to the list and drops the rule from the S1 section (never deletes). An archived rule shown in edit mode offers **"Unarchive Rule"**.
- **Delete (RULE-05):** a destructive **"Delete Rule"** row (`theme.colors.danger`). If the rule has stemmed habits, tapping presents a `confirmationDialog` (copy below); confirming lets the `.nullify` rule (D-01) null each `Habit.originRule` automatically — habits survive. If the rule has zero stems, a lighter confirm is still shown for consistency.

### S4 — `HabitCreateSheet` (shared, load-bearing) (RULE-02 / RULE-03)
- **Lifecycle: fill-then-commit (D-04).** The sheet edits an in-memory draft; the `Habit` is inserted into `modelContext` **only on Save**. **Cancel creates nothing** (orphan-free). This replaces the old insert-then-edit "New Habit" placeholder path (D-06) — the migrated `HabitManagerView` "Add Habit" now presents this sheet too.
- **Source-agnostic chrome (D-07):** identical layout whether launched from a rule (Stem), manual add, or later an idea. The **only** source-dependent behavior is prefill: title + domain seed from the source and remain **editable**. No "stemmed from X" banner inside the create sheet — the link is recorded on save, not surfaced here.
- Presented as a **sheet** (`theme.radii.sheet`). Fields mirror `HabitEditorView`: **Title** (`TextField`, prefilled + editable, non-empty guard), **Domain** (`Picker`, prefilled from source), **Schedule** (the existing schedule control — daily / specific days), **Required/Optional** (the existing `HabitMode` control). Field labels `theme.typography.headline`, values `theme.typography.body`.
- **Save CTA:** **"Add Habit"** (`accentPrimary`, `theme.radii.button`, ≥44pt), disabled until a non-empty trimmed title exists. On save: insert `Habit`, set `originRule` when launched from a rule (D-01), `try modelContext.save()`; the new habit appears on Today (RULE-03). Dismiss.
- **Cancel:** **"Cancel"** — dismisses, inserts nothing.

### S5 — Habit-side "from rule" backref (RULE-04)
- A **read-only** row added to `HabitEditorView`, shown only when `habit.originRule != nil`: caption **"Stemmed from"** (`theme.typography.caption`, textSecondary) + the rule's title as a tappable pill/row (`theme.typography.headline`, `theme.radii.chip`) → navigates to `RuleDetailView(rule: habit.originRule!)`. ≥44pt. Editing/removing the habit never touches the rule.

### Accessibility (§9.15 — part of "done", applies to all surfaces)
- VoiceOver labels: rule row → `"<title>, rule"` (+ `", stemmed <N> habits"` / `", has link"` when present); "+" header button → `"Add rule to <domain>"`; Stem CTA → `"Stem habit from this rule"`; sourceURL affordance → `"Open source link, <host>"`; stemmed-habit row → `"<habit name>, stemmed habit"`; backref row → `"Stemmed from <rule title>, opens rule"`; archive toggle → `"Archive rule"` with on/off value.
- Dynamic Type: rule **body** and all labels reflow; no clipped text; no fixed-height text containers.
- Contrast: rely on DesignKit token pairings (textPrimary/secondary on surface/background); no accent-on-accent text; the sourceURL link uses textPrimary, not accent.
- Tap targets ≥ 44pt on every interactive element listed above.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Rules section header (S1) | **"Rules"** — trailing "+" opens the create sheet |
| Rule-row secondary line (S1) | **"Stemmed: {N}"** and/or **"· has link"** (omit when zero / no url) |
| Create/edit rule save CTA (S3) | **"Add Rule"** (create mode) / **"Save Changes"** (edit mode) — never a bare "Save" |
| RuleDetail primary action (S2) | **"Stem habit"** |
| Stemmed section header (S2) | **"Stemmed habits"** with **"Stemmed: {N}"** badge |
| Source affordance (S2) | Leading link glyph + host line; VoiceOver **"Open source link, {host}"** |
| Archived indicator (S2) | **"Archived"** badge |
| HabitCreateSheet save CTA (S4) | **"Add Habit"** (primary); **"Cancel"** dismisses without creating |
| Backref row (S5) | Caption **"Stemmed from"** + rule title (tap → rule) |
| Title validation error (S3, S4) | **"Give this a name to continue."** (inline; Save/Add Habit stays disabled until a non-empty trimmed title exists — mirrors the Phase 1 `Add Domain` guard) |
| Archive action (S3) | **"Archive rule"** / when archived: **"Unarchive Rule"** |
| Destructive confirmation — delete rule **with** stems (S3, RULE-05) | Title: **"Delete this rule?"** Message: **"This rule has {N} stemmed habit(s). They'll be kept — only the rule is deleted."** Confirm **"Delete Rule"** (`theme.colors.danger`), cancel **"Cancel"**. |
| Destructive confirmation — delete rule with **no** stems (S3) | Title: **"Delete this rule?"** Message: **"This can't be undone."** Confirm **"Delete Rule"** (`danger`), cancel **"Cancel"**. |

Voice: concise, plain, reassuring about data safety (matches the constitution's "never destroy user data" posture, and Phase 1's copy voice). Sentence case; no exclamation marks.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none (native SwiftUI app) | none | not applicable — no shadcn, no component registry, no external package added this phase |

No new third-party dependency. `sourceURL` is **stored and opened only** — no network fetch, no link preview, no metadata scraping (offline-only constraint, §1). All UI is DesignKit tokens + Apple SF Symbols + Apple `Link`/`openURL`.

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
