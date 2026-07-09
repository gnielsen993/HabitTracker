# Release Process — HabitsTracker

Triggered when Gabe says: **"wrap up x.x.x"**, **"shipping x.x.x"**,
**"prepare release x.x.x"**, or **"release process"** (see `CLAUDE.md` §10).

Do not start this process speculatively. Wait for the trigger phrase.

---

## Step 0 — Sync

Per `CLAUDE.md` §7/§9.10: `git fetch --prune` + `git pull --ff-only` for
HabitsTracker (and `../DesignKit` if it was touched), preserving any dirty
local work before pulling.

## Step 1 — Internal release log

1. Confirm `Docs/releases/v{x.x.x}.md` exists and every section is current.
   - Create it from `Docs/releases/TEMPLATE.md` if this is a fresh bump.
   - Status moves from "pending QA" to "shipped" only when actually submitting.
   - Tick the QA checklist before submission.
2. Verify `MARKETING_VERSION` in `HabitsTracker.xcodeproj/project.pbxproj`
   matches the release filename.

## Step 2 — Schema gate (if any @Model changed this version)

Run the `Docs/SCHEMA_MIGRATION_PLAYBOOK.md` upgrade test via
`Docs/UPGRADE_TEST_RUNBOOK.md`: install the prior shipped build, log data,
install the new build over it, confirm launch + data intact. A schema change
without this gate does not ship.

## Step 3 — App Store copy

Update `Docs/AppStoreListing.md`:
- Add a new **What's New** entry (short + medium variants, plain human voice
  — no AI phrasing, no em-dashes, no "we"/"seamless"/"powerful").
- Review **Description**, **Subtitle**, **Promotional Text**, and **Keywords**.
  If new features change the value proposition or search relevance, update them
  and flag the change to Gabe.

## Step 4 — What's New text for Gabe

Pull the **short variant** (~300–450 chars) from `Docs/AppStoreListing.md` and
hand it to Gabe as plain text, ready to paste into App Store Connect under
"What's New in This Version".

## Step 5 — Final push

```bash
cd ~/Desktop/HabitsTracker
git status --short --branch
git push
```

Push before wrap-up is considered done. If `../DesignKit` changed, push it too
(separate commit in that repo — see `CLAUDE.md` §9.14).

---

## Writing What's New copy

- Lead with what changed for the *user*, not what changed in code.
- No bullet soup for minor polish — fold it into one sentence at the end.
- No "we", no "you'll love", no "powerful", no "seamless", no em-dashes.
- Short variant target: 300–450 characters. Medium: 600–800.
- Read existing entries in `Docs/AppStoreListing.md` for tone calibration.
