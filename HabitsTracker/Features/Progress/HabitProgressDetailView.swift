import SwiftUI
import SwiftData
import DesignKit

struct HabitProgressDetailView: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Habit.name) private var habits: [Habit]

    let habitID: UUID
    @State private var range: HabitProgressEngine.Range

    init(habitID: UUID, initialRange: HabitProgressEngine.Range) {
        self.habitID = habitID
        _range = State(initialValue: initialRange)
    }

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        Group {
            if let habit = habits.first(where: { $0.id == habitID }) {
                detail(snapshot: HabitProgressEngine.snapshot(from: habit), theme: theme)
            } else {
                ContentUnavailableView("Habit unavailable", systemImage: "questionmark.circle", description: Text("This habit may have been deleted."))
            }
        }
        .background(theme.colors.background.ignoresSafeArea())
    }

    private func detail(snapshot: HabitProgressEngine.HabitSnapshot, theme: Theme) -> some View {
        let dates = rangeDates
        let currentRevision = HabitProgressEngine.revision(for: snapshot, on: .now)

        return ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(snapshot.name).font(theme.typography.titleLarge).foregroundStyle(theme.colors.textPrimary)
                    Text(snapshot.areaName ?? "No area").font(theme.typography.body).foregroundStyle(theme.colors.textSecondary)
                }

                Picker("Range", selection: $range) {
                    ForEach(HabitProgressEngine.Range.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                totals(snapshot: snapshot, revision: currentRevision, theme: theme)

                VStack(alignment: .leading, spacing: theme.spacing.m) {
                    DKSectionHeader("Completion history", subtitle: "Check = completed · Minus = missed · Circle = not scheduled · Ellipsis = in progress", theme: theme)
                    ProgressTileGrid(snapshot: snapshot, dates: dates, theme: theme)
                }

                if currentRevision?.mode == .required {
                    streaks(snapshot: snapshot, theme: theme)
                    weekdayBreakdown(snapshot: snapshot, theme: theme)
                } else {
                    weeklyHistory(snapshot: snapshot, theme: theme)
                }

                if let insight = HabitProgressEngine.hardestWeekdayInsight(
                    for: snapshot,
                    from: dates.first ?? .now,
                    through: .now
                ) {
                    insightCard(insight.text, theme: theme)
                }
            }
            .padding(theme.spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Habit Progress")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func totals(
        snapshot: HabitProgressEngine.HabitSnapshot,
        revision: HabitProgressEngine.Revision?,
        theme: Theme
    ) -> some View {
        DKCard(theme: theme) {
            if revision?.mode == .optional {
                let weekly = HabitProgressEngine.weeklySummary(habits: [snapshot], from: rangeDates.first ?? .now, through: .now, includeArchived: true)
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("\(weekly.achievedTargets) of \(weekly.eligibleTargets) weekly targets")
                        .font(theme.typography.title)
                        .foregroundStyle(theme.colors.textPrimary)
                    Text("\(Int(weekly.percentage * 100))% of completed weeks")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            } else {
                let summary = HabitProgressEngine.opportunitySummary(habits: [snapshot], from: rangeDates.first ?? .now, through: .now, includeArchived: true)
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("\(summary.completed) of \(summary.scheduled) expected")
                        .font(theme.typography.title)
                        .foregroundStyle(theme.colors.textPrimary)
                    Text("\(Int(summary.percentage * 100))% of scheduled opportunities")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func streaks(snapshot: HabitProgressEngine.HabitSnapshot, theme: Theme) -> some View {
        let current = HabitProgressEngine.currentStreak(for: snapshot)
        let best = HabitProgressEngine.bestStreak(for: snapshot, through: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now)
        return VStack(alignment: .leading, spacing: theme.spacing.m) {
            DKSectionHeader("Streaks", theme: theme)
            HStack(spacing: theme.spacing.m) {
                metric("Current", value: "\(current)", theme: theme)
                metric("Best", value: "\(best)", theme: theme)
            }
        }
    }

    private func metric(_ title: String, value: String, theme: Theme) -> some View {
        DKCard(theme: theme) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(value).font(theme.typography.title).foregroundStyle(theme.colors.accentPrimary)
                Text(title).font(theme.typography.caption).foregroundStyle(theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func weekdayBreakdown(snapshot: HabitProgressEngine.HabitSnapshot, theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            DKSectionHeader("Weekdays", subtitle: "Completed versus eligible", theme: theme)
            DKCard(theme: theme) {
                VStack(spacing: theme.spacing.s) {
                    ForEach(Weekday.allCases) { weekday in
                        let count = weekdayCount(weekday, snapshot: snapshot)
                        HStack {
                            Text(weekday.shortLabel).foregroundStyle(theme.colors.textPrimary)
                            Spacer()
                            Text("\(count.completed) of \(count.eligible)").foregroundStyle(theme.colors.textSecondary)
                        }
                        .font(theme.typography.body)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private func weeklyHistory(snapshot: HabitProgressEngine.HabitSnapshot, theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            DKSectionHeader("Weekly target history", subtitle: "The current week stays live", theme: theme)
            DKCard(theme: theme) {
                VStack(spacing: theme.spacing.s) {
                    ForEach(weekStarts, id: \.self) { week in
                        if let progress = HabitProgressEngine.weekProgress(for: snapshot, weekStarting: week) {
                            HStack {
                                Text(week.formatted(.dateTime.month(.abbreviated).day()))
                                Spacer()
                                Image(systemName: progress.achieved ? "checkmark.circle.fill" : "circle")
                                    .accessibilityHidden(true)
                                Text("\(progress.completed) of \(progress.target)")
                            }
                            .font(theme.typography.body)
                            .foregroundStyle(progress.achieved ? theme.colors.success : theme.colors.textSecondary)
                            .accessibilityLabel("Week of \(week.formatted(date: .abbreviated, time: .omitted)), \(progress.completed) of \(progress.target), \(progress.achieved ? "target met" : "target not met")")
                        }
                    }
                }
            }
        }
    }

    private func insightCard(_ text: String, theme: Theme) -> some View {
        DKCard(theme: theme) {
            Label {
                Text(text).font(theme.typography.body).foregroundStyle(theme.colors.textPrimary)
            } icon: {
                Image(systemName: "sparkles").foregroundStyle(theme.colors.accentPrimary)
            }
        }
    }

    private var rangeDates: [Date] {
        (0..<range.rawValue).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: .now) }
    }

    private var weekStarts: [Date] {
        let current = DateUtilities.startOfWeek(for: .now)
        let count = max(1, range.rawValue / 7)
        return (0..<count).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -($0 * 7), to: current) }
    }

    private func weekdayCount(
        _ weekday: Weekday,
        snapshot: HabitProgressEngine.HabitSnapshot
    ) -> (completed: Int, eligible: Int) {
        var completed = 0
        var eligible = 0
        for date in rangeDates.dropLast() where DateUtilities.isoWeekday(for: date) == weekday {
            let status = HabitProgressEngine.status(for: snapshot, on: date)
            if status == .completed || status == .missed {
                eligible += 1
                if status == .completed { completed += 1 }
            }
        }
        return (completed, eligible)
    }
}
