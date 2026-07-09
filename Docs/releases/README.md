# Internal Release Logs

Per-version release notes for the **HabitsTracker** iOS app. Scope =
anything that ships in a `MARKETING_VERSION` bump.

Mirrors the convention proven in the sibling repos (FitnessTracker,
ParkedUp, DesignKit) so any AI session crossing repos sees the same shape.
See `CLAUDE.md` §9.11.

## How to use

- Version source: `MARKETING_VERSION` in
  `HabitsTracker.xcodeproj/project.pbxproj` (currently `1.0`).
- Create one file per release: `vX.Y.Z.md` (or `vX.Y.md` if the patch
  digit is unused).
- Use [`TEMPLATE.md`](TEMPLATE.md) as the starting point.
- Keep entries factual, brief, bullet-pointed.
- For every significant change (feature, fix, behavior shift) during
  a version, append to that version's file in the same commit as the
  code change.
- A new release file is opened when `MARKETING_VERSION` is bumped.
- Never mutate a shipped version's file — open a new one instead.

## Sections in each file

- **Summary** — one or two sentences on the release theme
- **User-facing changes** — what a user notices
- **Internal changes** — engine / structure / refactors
- **Fixes** — bug fixes (with root cause when non-obvious)
- **Risks / notes** — schema changes, migration concerns, manual steps
- **QA checklist** — pre-ship verification steps (see `CLAUDE.md` §6 RC smoke test)

## What NOT to put here

- Self-explanatory commits, comment tweaks, doc-only changes
- Per-file modification lists (commit history covers that)
- Anything that didn't actually ship in this `MARKETING_VERSION`

## Related artifacts

- Live status: `.planning/STATE.md`
- Schema changes: `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` + `Docs/UPGRADE_TEST_RUNBOOK.md`
- App Store copy: `Docs/AppStoreListing.md`
- Recent commits: `git log --oneline -20`

## Entries

- _(none yet — v1.0 shipped before this log existed; the first entry is
  opened when the next `MARKETING_VERSION` is bumped.)_
