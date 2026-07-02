import SwiftUI
import SwiftData
import Charts
import DesignKit

private enum ProgressTab {
    case charts
    case calendar
}

struct ProgressDashboardView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Habit.name) private var habits: [Habit]
    @Query(sort: \DailyEntry.dateKey) private var entries: [DailyEntry]

    @State private var progressTab: ProgressTab = .charts

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        NavigationStack {
            VStack(spacing: theme.spacing.l) {
                Picker("", selection: $progressTab) {
                    Text("Charts").tag(ProgressTab.charts)
                    Text("Calendar").tag(ProgressTab.calendar)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, theme.spacing.l)

                switch progressTab {
                case .charts:
                    chartsBody(theme: theme)
                case .calendar:
                    CalendarMonthHeatmapView()
                }
            }
            .background(theme.colors.background.ignoresSafeArea())
            .navigationTitle("Progress")
        }
    }

    @ViewBuilder
    private func chartsBody(theme: Theme) -> some View {
        let trend = StatsEngine.dailyTrend(habits: habits, entries: entries, daysBack: 30)

        ScrollView {
            VStack(spacing: theme.spacing.l) {
                DKSectionHeader("Required Completion", subtitle: "Last 30 days", theme: theme)

                DKCard(theme: theme) {
                    Chart(trend) { point in
                        LineMark(
                            x: .value("Day", point.date),
                            y: .value("Completion", point.ratio)
                        )
                        .foregroundStyle(theme.charts.chart1)

                        AreaMark(
                            x: .value("Day", point.date),
                            y: .value("Completion", point.ratio)
                        )
                        .foregroundStyle(theme.charts.chart1.opacity(0.2))
                    }
                    .chartYScale(domain: 0...1)
                    .frame(height: 200)
                }

                DKSectionHeader("Optional Weekly Targets", theme: theme)
                DKCard(theme: theme) {
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        ForEach(TodayEngine.optionalHabits(from: habits), id: \.id) { habit in
                            if let target = habit.weeklyTargetCount {
                                let completed = WeeklyGoalEngine.completedCountThisWeek(habit: habit, entries: entries)
                                HStack {
                                    Text(habit.name)
                                        .foregroundStyle(theme.colors.textPrimary)
                                    Spacer()
                                    DKBadge("\(completed)/\(target)", theme: theme)
                                }
                            }
                        }
                    }
                }
            }
            .padding(theme.spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
