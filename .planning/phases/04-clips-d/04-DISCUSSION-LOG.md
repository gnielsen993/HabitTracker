# Phase 4: Clips (D) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-08
**Phase:** 4-Clips (D)
**Areas discussed:** Q1 offline/preview, Status modeling, Tag modeling, Clip surface shape

Mode: advisor (minimal-decisive calibration; technical-owner framing). These are
codebase-internal consistency decisions grounded in the Phase 2/3 patterns, so trade-off
tables were authored directly from the codebase scout rather than farmed to web-research
agents. All four areas landed on the recommended option.

---

## Q1 offline/preview (mandatory record — Success Criterion 1)

| Option | Description | Selected |
|--------|-------------|----------|
| Offline + host-suggested title | Zero network; a pure string helper prefills an editable title from the URL host/slug. Ships with a unit test. | ✓ |
| Fully offline, purely manual | No parsing; user types the title. Simplest; empty title field each paste. | |

**User's choice:** Offline + host-suggested title
**Notes:** Top-level offline-only (no network fetch, ever) is locked by the constitution and
recorded as the SC1 gate regardless of sub-choice. The zero-network title suggestion is a
friction win that stays inside the offline constraint.

---

## Status modeling (CLIP-04, saved→acted)

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated enum + shared chip visual | `enum ClipStatus {saved, acted}`; tap toggles; rendered with the same DesignKit chip styling as Collections. No StatusSetCatalog coupling. | ✓ |
| Reuse Phase 3 StatusSet catalog | Add a saved→acted StatusSet entry, drive the existing tap-to-advance chip. Max consistency, more coupling. | |

**User's choice:** Dedicated enum + shared chip visual
**Notes:** A Clip's two states are fixed/inherent, not template-driven — coupling to the
StatusSet abstraction would be over-abstraction (mirrors Phase 3 D-01 reasoning). Same look,
no coupling.

---

## Tag modeling (CLIP-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Single optional free-text String | `tag: String?` — optional, honors title-only-minimum, scope-guarded. | ✓ |
| Optional string + in-domain autocomplete | Same field plus suggestions from tags used in this domain. Edges toward the deferred tag system. | |

**User's choice:** Single optional free-text String
**Notes:** Per-clip label, not a taxonomy. Cross-domain tag systems are deferred past Phase F
(PROJECT.md Out of Scope).

---

## Clip surface shape (CLIP-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated ClipDetailView, template-consistent | Tap row → detail (Open Link, note, status, edit); chip also on row. Follows Phase 2/3 nav template; note stays visible. | ✓ |
| Row-primary, tap-opens-URL | No detail view; row tap opens link in Safari; editor sheet hosts note/tag/status. Fewest taps, breaks template, hides note. | |

**User's choice:** Dedicated ClipDetailView, template-consistent
**Notes:** A Clip is action-oriented (URL is the payload), which argued for the row-primary
shape — but template consistency + keeping the note visible won. The "Open Link" action is
made prominent in the detail view to preserve the act-on-it feel; the minor extra tap is
accepted.

---

## Claude's Discretion

- Exact host/slug extraction rule for the title suggestion (within pure/zero-network/tested).
- Whether tapping an `acted` chip toggles back to `saved` or needs an explicit reset.
- Whether a hard delete needs a confirm dialog.
- URL normalization (prepend `https://`) and invalid-URL handling.
- `Clip` field set beyond the decided ones; `ClipDetailView`/`ClipEditorView`/row layout;
  Clips-section empty-state copy — within tokens, file cap, data-driven-view, accessibility.

## Deferred Ideas

- Clip rich previews / link thumbnails / on-demand fetch — offline-only v1; revisit past Phase D.
- Cross-domain free tags / tag taxonomy — strict domain filing in v1; revisit after Phase F.
- In-domain tag autocomplete — considered, not taken (edges toward the deferred tag system).
- Full multi-type export/import completeness — Phase 6.
- Ideas + promote-to-anything — Phase 5.
