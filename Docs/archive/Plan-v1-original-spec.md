# Project 2: Local-Only Habit Tracker (Swift)
## Version 1 Spec — Binary Habits + Optional Habits + Widgets (Quick Entry)

---

# 0) Goal

Build a personal habit tracker that:
- is 100% offline (no cloud, no accounts)
- supports user-defined categories (Productivity / Lifestyle / Learning / etc.)
- tracks **binary** habits (done / not done)
- supports **optional habits** that don’t count against you daily but can count weekly
- provides premium visuals: rings, calendars/heatmaps, charts, streaks
- includes **widgets + Lock Screen widgets** for ultra-fast check-ins

---

# 1) Core Concepts

## 1.1 Categories
User-defined buckets:
- Productivity
- Lifestyle
- Learning
- Fitness
- Social
- etc.

Fields:
- name
- SF Symbol icon
- color token
- sort order

## 1.2 Habits (Binary)
Each habit is either completed or not completed for a given day.

Each habit belongs to a category and has:
- schedule (daily or custom weekdays)
- **mode**: Required vs Optional
- optional weekly goal behavior (for Optional habits)

---

# 2) Habit Modes & Scheduling (Key v1 Behavior)

## 2.1 Required Habits
- Expected on scheduled days
- Included in daily progress rings and “Today completion %”
- Affect streaks normally

## 2.2 Optional Habits
For habits you *don’t* expect daily but want to track toward a weekly goal.
Examples:
- Deep clean (1x/week)
- Long run (1–2x/week)
- Social outreach (2x/week)

Optional habits:
- Are shown in Today under an “Optional” section
- Do **not** reduce daily completion % if left undone
- Can contribute to **weekly progress** (e.g., “2 / 3 this week”)

## 2.3 Schedule Types (v1)
- Daily
- Custom days (Mon/Wed/Fri etc.)
Presets (UI convenience):
- Weekdays
- Weekends

## 2.4 Weekly Goals (for Optional Habits)
Optional habits can have:
- showWeeklyGoal = true
- weeklyTargetCount (Int) — e.g., 2 times/week

Weekly progress:
- `completedThisWeek / weeklyTargetCount`

Note: Weekly target does NOT imply specific days—just counts.

---

# 3) Primary User Flow

## 3.1 Today Screen (Main)
Top:
- Date + mini summary
- Overall progress ring: `Completed Required / Total Required scheduled today`
- Category mini-rings (Required only)

Sections (grouped by category):
### Required (Scheduled Today)
- checklist items with one-tap toggle
- quick “undo” ability

### Optional (Always available)
- list of optional habits (can be filtered)
- each shows weekly progress badge: `1/2 this week`

Bottom:
- Daily note / journal (optional)
- Quick reflection prompt (optional)

---

# 4) Visuals & Progress Tracking (Premium UI)

## 4.1 Daily Rings
- Overall ring (Required only): completed / required scheduled today
- Category rings (Required only) per category

Optional habits do not impact these rings.

## 4.2 Calendar Heatmap (History)
Monthly calendar shading by Required completion %:
- 0% → light
- 100% → dark
- days with no required habits scheduled show a neutral style

Tap a day:
- shows that day’s required + optional completion and notes

Filters:
- All
- By category
- By habit (switch to habit heatmap mode)

## 4.3 Habit Detail View (Binary)
For each habit:
- current streak (for scheduled/required habits)
- best streak
- last completed date
- habit-specific heatmap calendar
- completion rate over last 30/90 scheduled days

For Optional habits:
- weekly completion chart (bar: weeks vs count)
- weekly target progress indicator

## 4.4 Progress Dashboard (Swift Charts)
Charts:
- Required completion % over time (line)
- Required habits completed per day (bar)
- Category consistency (stacked bar per week)
- Optional weekly targets met (bar / list)

Leaderboard lists:
- Most consistent required habits (last 30 days)
- Optional habits with best weekly follow-through

---

# 5) Widgets & Quick Entry (Required for v1)

## 5.1 Home Screen Widgets
### Small widget
- shows overall Required ring + “X/Y”
- tap opens Today

### Medium widget (Quick Toggles)
- shows 4–6 pinned habits (mix required/optional)
- tap a habit to toggle completion via App Intent

### Large widget
- shows ring + grouped list of pinned habits + weekly optional progress

## 5.2 Lock Screen Widgets (Quick Entry)
Lock Screen widgets should be “glance + tap” fast:
- Circular: Required ring
- Rectangular: 2–3 pinned habits with checkmarks
- Inline: `Habits: X/Y`

Tapping a Lock Screen widget:
- toggles a habit (if Apple allows direct toggle via intent)
- or deep links into the app’s Today screen / specific habit sheet

## 5.3 Widget Interactions (Implementation Strategy)
Use:
- **WidgetKit**
- **App Intents** for toggling completion without opening full UI (best effort)
- Deep links fallback when direct toggle isn’t allowed in context

Pinned habits:
- user selects up to N habits to show in widgets
- pinned list stored locally

---

# 6) Data Model (SwiftData)

## Category
- id
- name
- iconName (SF Symbol)
- colorToken
- sortIndex

## Habit
- id
- name
- categoryId
- scheduleType (enum) — daily | customDays
- scheduledDays ([weekday]) optional
- mode (enum) — required | optional
- weeklyTargetCount (Int?)  // only for optional
- isPinned (Bool)
- isArchived (Bool)
- createdAt

## DailyEntry
- id
- dateKey (startOfDay)
- note (String optional)
- mood (optional)
- habitStates: [HabitState]

## HabitState
- id
- dailyEntryId
- habitId
- isCompleted (Bool)
- completedAt (Date optional)

Notes:
- Create DailyEntry lazily for today when app opens
- HabitState created on-demand when toggled (or pre-generated for scheduled habits)

---

# 7) Business Rules (Deterministic + Testable)

## 7.1 “Today Required List”
Include habits where:
- habit.mode == required
- habit is scheduled today (daily or today in customDays)

## 7.2 “Today Optional List”
Include habits where:
- habit.mode == optional
- regardless of day
Show weekly progress badge if weeklyTargetCount exists.

## 7.3 Daily Progress Calculations
Daily Required completion:
- completedRequiredToday / totalRequiredScheduledToday

Optional completion:
- tracked separately, not part of the ring

## 7.4 Weekly Progress (Optional)
Week boundary: Monday–Sunday (or user setting later)
- completedThisWeek = count of days in week where isCompleted == true for that habit
- weeklyTargetMet = completedThisWeek >= weeklyTargetCount

---

# 8) Offline-First & Export/Import

Persistence:
- SwiftData local store

Export:
- JSON file to Files app
- versioned schema

Import:
- merge strategy:
  - by IDs (preferred)
  - optionally by name if IDs missing (later)

---

# 9) UX Screens (SwiftUI)

Tabs:
1. Today
2. Calendar
3. Progress
4. Settings

Screens:
- TodayView (Required + Optional sections, rings)
- CategoryManagerView
- HabitEditorView
- CalendarMonthHeatmapView
- DayDetailSheet
- HabitDetailView (heatmap + streaks/weekly bars)
- ProgressDashboardView (charts)
- SettingsView (export/import, widget pins, week start)

---

# 10) Architecture (GitHub-Friendly)

Folders:
Models/
Services/
  StatsEngine.swift
  StreakEngine.swift
  WeeklyGoalEngine.swift
  ExportImportService.swift
  WidgetDataProvider.swift
Features/
  Today/
  Calendar/
  Progress/
  Settings/
Widgets/
  HabitsWidget.swift
  AppIntents/
UIComponents/
Utilities/
Docs/

Key services:
- StatsEngine: daily % + trends
- StreakEngine: streak logic for required habits
- WeeklyGoalEngine: optional weekly completion tracking
- WidgetDataProvider: fast snapshot data for widgets/lock screen

Tests:
- schedule logic
- required vs optional counting rules
- weekly goal counting
- streak edge cases
- JSON export/import round-trip

---

# 11) Milestones (Build Order)

## Phase 1 — Foundation
- SwiftData models
- Category + Habit CRUD
- TodayView rendering grouped by category

## Phase 2 — Required vs Optional
- enforce mode rules
- required ring progress
- optional weekly badges

## Phase 3 — Calendar Heatmap + Day Detail
- month heatmap (required completion %)
- day detail sheet with required + optional

## Phase 4 — Habit Detail
- habit heatmap
- streaks for required
- weekly bars for optional

## Phase 5 — Progress Dashboard
- charts for trends and category consistency

## Phase 6 — Widgets + Lock Screen Widgets
- pinned habits selection UI
- widgets (small/medium/large)
- lock screen widgets
- App Intent toggles + deep link fallback

## Phase 7 — Export/Import + Polish
- JSON versioning
- animations, haptics
- dark mode polish

---

# 12) iOS Target
iOS 17+
- SwiftData
- Swift Charts
- App Intents + modern WidgetKit

---

# 13) Future Expansion (Optional)
- Multiple profiles (still local)
- “Rocks” (top 3 daily priorities)
- Habit templates (school day / weekend)
- Numeric habits (minutes/pages)
- Smart prompts (non-AI): “you usually do LeetCode at 8pm”
- Curator-like suggestions: “You’re 1/2 on Deep Clean this week”

## 2.5 Built-In Defaults + Management Dashboard (Planned for Habit v1)

### Why this exists
Even if this is a personal project, a “real” habit app should not open to an empty screen.
So we ship with an **expansive built-in set** of Categories + optional starter Habits, BUT:
- everything is editable
- everything is deletable/archivable
- user can disable defaults they don’t want
- no cloud, no accounts

This keeps v1 instantly usable and “ship-ready” if you ever decide to publish.

---

## 2.6 Seed Strategy (Local-Only)
On first launch:
1. If database is empty:
   - Insert default Categories
   - Insert default Habits (lightweight set, but broad coverage)
2. Mark seeded records with:
   - `isSeeded = true`
   - `seedVersion = 1`
3. Future expansions:
   - If app ships later, you can add new defaults by bumping seedVersion and offering:
     - “Add new defaults” button (manual, user-consented)
   - Never silently overwrite user changes.

---

## 2.7 Default Categories (Expansive)
Suggested built-in Categories (editable):
- Productivity
- Learning
- Lifestyle
- Health
- Fitness
- Social
- Mindfulness
- House / Chores
- Finance
- Creativity
- Career
- Admin / Life Ops

Each category includes:
- name
- SF Symbol icon
- color token
- sort order

---

## 2.8 Default Habits (Starter Library)
Seeded habits should feel “real app”, but not overwhelming.
Rule: most habits default to Optional unless they’re universally daily.

Examples (you can adjust later):

### Productivity
- Deep Work (Required: custom weekdays)
- Plan Tomorrow (Optional: weekly target 3)
- No Phone First Hour (Optional)

### Learning
- Read (Required: daily)
- LeetCode (Optional: weekly target 3)
- Review Notes (Optional)

### Lifestyle
- Journal (Optional or Required depending on preference)
- Clean Space (Optional: weekly target 2)
- Cook at Home (Optional)

### Health / Fitness
- Workout (Optional: weekly target 4)
- Walk (Optional: weekly target 5)
- Stretch (Optional: weekly target 3)
- Water Goal (Optional)

### Social
- Reach Out (Optional: weekly target 2)
- Social Effort (Optional: weekly target 3)

### Mindfulness
- Meditate (Optional: weekly target 5)
- Breathwork (Optional)

### House / Chores
- Laundry (Optional: weekly target 1)
- Dishes Reset (Optional: weekly target 4)

### Finance
- Track Spending (Optional: weekly target 2)
- Check Accounts (Optional: weekly target 1)

### Creativity
- Build/Ship (Optional: weekly target 3)
- Write (Optional)

### Career
- Apply/Network (Optional: weekly target 2)
- Portfolio Work (Optional)

### Admin / Life Ops
- Inbox Zero (Optional)
- Calendar Review (Optional: weekly target 1)

All seeded habits:
- editable name/category/schedule/mode
- can be archived if unused
- can be pinned for widgets

---

# 9.5 “Dashboard” Management Screens (Required for Real-App Readiness)

## Settings → Management Dashboard (one place to control everything)

### A) Manage Categories
- reorder categories (drag)
- edit name/icon/color
- archive category (moves habits to “Uncategorized” or asks what to do)
- add new category

### B) Manage Habits
- search habits
- filter by category, Required/Optional, Pinned, Archived
- bulk actions:
  - move category
  - set Required/Optional
  - pin/unpin
  - archive/unarchive
- edit habit schedule + weekly target (optional habits)

### C) Defaults Control (seed management)
- “Restore defaults” (re-adds missing seeded categories/habits)
- “Add new defaults” (only if seedVersion increased in future builds)
- “Reset to fresh install (local)” (danger zone; wipes DB)

---

# 10.5 Widgets + Lock Screen Widgets tie-in (Quick Entry is primary)
The dashboard controls widget content:
- user selects “Pinned Habits”
- widgets display pinned habits for 1-tap toggles
- lock screen widgets show:
  - required ring
  - 1–3 pinned habits quick toggles
  - optional weekly goal progress for a chosen habit

If a habit is archived/unpinned, widgets update automatically.

---

## Data Model Additions (for seed + dashboard)
Category:
- isSeeded (Bool)
- seedVersion (Int)

Habit:
- isSeeded (Bool)
- seedVersion (Int)
- isPinned (Bool)  // widget selection

## Persistence, Updates, and Data Safety (Local-Only)

This project is designed to be **installed directly from Xcode** (personal use) and may never ship to the App Store. This section documents how local data behaves over time and how to avoid losing it.

### 1) Reality Check: What can cause data loss
Local data is typically preserved across normal rebuilds/updates, but it can be lost if:

- **The app is uninstalled** (iOS deletes the app’s sandbox/container)
- **The Bundle Identifier changes** (iOS treats it as a different app with a fresh container)
- **The storage location changes** (e.g., changing App Group ID or moving the database file path without migration)
- **A breaking database schema change occurs** (no migration path for SwiftData/Core Data)
- **A “reset data” debug action is triggered** (developer-only behavior)

> Important: App signing/provisioning expiring does **not** automatically delete data.
> Data loss typically happens only if you must uninstall to recover.

---

### 2) Updates and rebuilding in the future
Normal development updates (Xcode “Run” installing over the same app with the same Bundle ID) should:

- ✅ keep local database records (SwiftData/Core Data)
- ✅ keep UserDefaults values
- ✅ keep cached files in the app container
- ✅ keep App Group–shared widget cache (if App Group ID stays the same)

As long as you **do not uninstall** and **do not change identifiers**, local data persists.

---

### 3) Manual Backup: Export/Import (recommended for all local-first apps)
Add a simple, versioned **Export / Import** flow to protect against uninstall or migration issues.

#### Export
- Generates a single file (preferably JSON) containing:
  - user-created data (habits/workouts/etc.)
  - user settings (units, pins, schedules, etc.)
  - schemaVersion
  - createdAt timestamp
- Saves to the Files app using a document picker.

#### Import
- Reads the export file
- Validates `schemaVersion`
- Imports with one of two strategies:
  - **Replace**: wipe local store then import everything
  - **Merge**: match by stable IDs and merge updates

> Minimum viable safety: Export + Replace Import.

---

### 4) Schema changes: “Don’t brick your store”
Even personal apps evolve. Prevent accidental wipes:

- Maintain a `schemaVersion` constant in code
- When adding fields:
  - prefer optional fields with sensible defaults
- When renaming/removing fields:
  - plan a migration step or deprecate gradually
- If migration is complex:
  - fall back to export → reinstall → import

---

### 5) Widgets and shared data (if widgets exist)
Widgets are separate extensions, so shared access requires stable identifiers.

#### App Group (recommended)
- Use a single, stable App Group ID, e.g. `group.com.yourname.project`
- Store only a **lightweight widget offer cache** in the App Group:
  - pinned item IDs
  - “today state” snapshot
  - last refresh time
- Keep the main database in the app container unless you explicitly need DB sharing.

#### Refresh behavior
- Widgets are not real-time; they refresh on iOS schedules.
- After in-app changes, request a refresh:
  - `WidgetCenter.shared.reloadTimelines(...)`

---

### 6) Stability checklist (do these and you’re safe)
- [ ] Never change Bundle ID once you start using the app daily
- [ ] Never change App Group ID once widgets ship
- [ ] Implement Export/Import early
- [ ] Add a “Backup Reminder” (optional)
- [ ] Keep schema evolution incremental and versioned
- [ ] Add a Settings “Danger Zone”:
  - Reset local data (explicit user confirmation)
  - Show last backup date/time


