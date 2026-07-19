import SwiftUI
import SwiftData
import Charts
import DesignKit

private enum ProgressTab { case overview, days }

struct ProgressDashboardView: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Habit.name) private var habits: [Habit]

    @State private var progressTab: ProgressTab = .overview
    @State private var range: HabitProgressEngine.Range = .twelveWeeks
    @State private var showsArchived = false

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        NavigationStack {
            VStack(spacing: theme.spacing.m) {
                Picker("Progress view", selection: $progressTab) {
                    Text("Overview").tag(ProgressTab.overview)
                    Text("Days").tag(ProgressTab.days)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, theme.spacing.l)

                if progressTab == .overview { overview(theme: theme) }
                else { CalendarMonthHeatmapView() }
            }
            .background(theme.colors.background.ignoresSafeArea())
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Toggle("Archived", isOn: $showsArchived)
                    } label: {
                        Label("Filters", systemImage: showsArchived ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel(showsArchived ? "Filters, archived shown" : "Filters, archived hidden")
                }
            }
        }
    }

    private func overview(theme: Theme) -> some View {
        let snapshots = habits.map { HabitProgressEngine.snapshot(from: $0) }
        let visible = snapshots.filter { showsArchived || !$0.isArchived }
        let start = rangeStart
        let todaySummary = HabitProgressEngine.opportunitySummary(habits: visible, from: start, through: .now)
        let weeklySummary = HabitProgressEngine.weeklySummary(habits: visible, from: start, through: .now)
        let workload = HabitProgressEngine.dailyWorkload(habits: visible, from: start, through: .now)

        return ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                Picker("Range", selection: $range) {
                    ForEach(HabitProgressEngine.Range.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                summaryCards(today: todaySummary, weekly: weeklySummary, snapshots: visible, theme: theme)
                workloadChart(workload, theme: theme)

                DKSectionHeader("Habits", subtitle: showsArchived ? "Including archived" : "Active habits", theme: theme)
                if visible.isEmpty {
                    emptyState(theme: theme)
                } else {
                    ForEach(visible) { snapshot in
                        NavigationLink {
                            HabitProgressDetailView(habitID: snapshot.id, initialRange: range)
                        } label: {
                            HabitProgressCard(snapshot: snapshot, rangeStart: start, theme: theme)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(theme.spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func summaryCards(
        today: HabitProgressEngine.OpportunitySummary,
        weekly: HabitProgressEngine.WeeklySummary,
        snapshots: [HabitProgressEngine.HabitSnapshot],
        theme: Theme
    ) -> some View {
        let currentWeek = snapshots.compactMap {
            HabitProgressEngine.weekProgress(for: $0, weekStarting: DateUtilities.startOfWeek(for: .now))
        }
        let liveCompleted = currentWeek.reduce(0) { $0 + min($1.completed, $1.target) }
        let liveTarget = currentWeek.reduce(0) { $0 + $1.target }

        return VStack(spacing: theme.spacing.m) {
            metricCard(
                title: "Today habits",
                count: "\(today.completed) of \(today.scheduled)",
                context: today.scheduled == 0 ? "No scheduled opportunities" : "\(Int(today.percentage * 100))% across scheduled opportunities",
                theme: theme
            )
            metricCard(
                title: "This Week goals",
                count: "\(weekly.achievedTargets) of \(weekly.eligibleTargets)",
                context: "Completed weeks · Current week \(liveCompleted) of \(liveTarget)",
                theme: theme
            )
        }
    }

    private func metricCard(title: String, count: String, context: String, theme: Theme) -> some View {
        DKCard(theme: theme) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(title).font(theme.typography.headline).foregroundStyle(theme.colors.textPrimary)
                    Text(context).font(theme.typography.caption).foregroundStyle(theme.colors.textSecondary)
                }
                Spacer()
                Text(count).font(theme.typography.title).foregroundStyle(theme.colors.accentPrimary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func workloadChart(_ workload: [HabitProgressEngine.DayWorkload], theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            DKSectionHeader("Daily workload", subtitle: "Completed versus scheduled", theme: theme)
            DKCard(theme: theme) {
                if workload.allSatisfy({ $0.scheduled == 0 }) {
                    Text("No Today opportunities in this range.")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    Chart(workload) { point in
                        BarMark(x: .value("Day", point.date), y: .value("Scheduled", point.scheduled))
                            .foregroundStyle(theme.charts.chart2)
                        BarMark(x: .value("Day", point.date), y: .value("Completed", point.completed))
                            .foregroundStyle(theme.charts.chart1)
                    }
                    .chartLegend(.hidden)
                    .frame(height: 200)
                    .accessibilityLabel("Daily completed versus scheduled opportunities chart")
                }
            }
        }
    }

    private func emptyState(theme: Theme) -> some View {
        DKCard(theme: theme) {
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                Text(showsArchived ? "No habits yet" : "No active habits")
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.textPrimary)
                Text(showsArchived ? "Create a habit in My Life to begin seeing patterns." : "Archived habits stay out of view until you turn on the Archived filter.")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
    }

    private var rangeStart: Date {
        Calendar.current.date(byAdding: .day, value: -(range.rawValue - 1), to: DateUtilities.startOfDay(.now)) ?? .now
    }
}

private struct HabitProgressCard: View {
    let snapshot: HabitProgressEngine.HabitSnapshot
    let rangeStart: Date
    let theme: Theme

    var body: some View {
        let revision = HabitProgressEngine.revision(for: snapshot, on: .now)
        let summary = HabitProgressEngine.opportunitySummary(habits: [snapshot], from: rangeStart, through: .now, includeArchived: true)

        DKCard(theme: theme) {
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                HStack {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(snapshot.name).font(theme.typography.headline).foregroundStyle(theme.colors.textPrimary)
                        Text(snapshot.areaName ?? "No area").font(theme.typography.caption).foregroundStyle(theme.colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(theme.colors.textTertiary)
                }

                ProgressTileGrid(snapshot: snapshot, dates: trailingDays(28), theme: theme, compact: true)

                HStack {
                    if revision?.mode == .optional,
                       let week = HabitProgressEngine.weekProgress(for: snapshot, weekStarting: .now) {
                        Text("\(week.completed) of \(week.target) this week")
                    } else {
                        Text("\(summary.completed) of \(summary.scheduled) expected")
                        Spacer()
                        Text("Streak \(HabitProgressEngine.currentStreak(for: snapshot))")
                    }
                }
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary(revision: revision, summary: summary))
    }

    private func trailingDays(_ count: Int) -> [Date] {
        (0..<count).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: .now) }
    }

    private func accessibilitySummary(
        revision: HabitProgressEngine.Revision?,
        summary: HabitProgressEngine.OpportunitySummary
    ) -> String {
        if revision?.mode == .optional, let week = HabitProgressEngine.weekProgress(for: snapshot, weekStarting: .now) {
            return "\(snapshot.name), \(snapshot.areaName ?? "no area"), \(week.completed) of \(week.target) this week"
        }
        return "\(snapshot.name), \(snapshot.areaName ?? "no area"), \(summary.completed) of \(summary.scheduled) expected, \(Int(summary.percentage * 100)) percent"
    }
}
