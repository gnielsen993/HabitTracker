import SwiftUI
import SwiftData
import DesignKit

struct CalendarMonthHeatmapView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Habit.name) private var habits: [Habit]
    @Query(sort: \DailyEntry.dateKey, order: .reverse) private var entries: [DailyEntry]

    @State private var monthAnchor = Date()
    @State private var selectedDay: Date?

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        let days = MonthGridBuilder.days(for: monthAnchor)

        NavigationStack {
            VStack(spacing: theme.spacing.m) {
                HStack {
                    Button {
                        monthAnchor = Calendar.current.date(byAdding: .month, value: -1, to: monthAnchor) ?? monthAnchor
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .foregroundStyle(theme.colors.accentPrimary)

                    Spacer()
                    Text(monthAnchor.formatted(.dateTime.month(.wide).year()))
                        .font(theme.typography.title)
                        .foregroundStyle(theme.colors.textPrimary)
                    Spacer()

                    Button {
                        monthAnchor = Calendar.current.date(byAdding: .month, value: 1, to: monthAnchor) ?? monthAnchor
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(theme.colors.accentPrimary)
                }
                .padding(.horizontal, theme.spacing.l)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: theme.spacing.xs), count: 7), spacing: theme.spacing.xs) {
                    ForEach(days, id: \.self) { day in
                        let completion = StatsEngine.dayCompletion(date: day, habits: habits, entries: entries)
                        DayCell(day: day, completion: completion, monthAnchor: monthAnchor, theme: theme)
                            .onTapGesture { selectedDay = day }
                    }
                }
                .padding(.horizontal, theme.spacing.l)

                Spacer()
            }
            .background(theme.colors.background.ignoresSafeArea())
            .navigationTitle("Calendar")
            .sheet(item: $selectedDay) { day in
                DayDetailSheet(date: day)
            }
        }
    }
}

private struct DayCell: View {
    let day: Date
    let completion: DayCompletion
    let monthAnchor: Date
    let theme: Theme

    var body: some View {
        let sameMonth = Calendar.current.isDate(day, equalTo: monthAnchor, toGranularity: .month)

        Text(day.formatted(.dateTime.day()))
            .font(theme.typography.caption)
            .foregroundStyle(sameMonth ? theme.colors.textPrimary : theme.colors.textTertiary)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous))
    }

    private var background: Color {
        guard completion.totalRequired > 0 else { return theme.colors.surfaceElevated }
        return theme.colors.accentPrimary.opacity(max(0.12, completion.ratio))
    }
}

enum MonthGridBuilder {
    static func days(for date: Date, calendar: Calendar = .current) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let start = monthInterval.start
        let startWeekday = DateUtilities.isoWeekday(for: start, calendar: calendar).rawValue
        let leading = startWeekday - 1

        let gridStart = calendar.date(byAdding: .day, value: -leading, to: start) ?? start
        return (0..<42).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: gridStart)
        }
    }
}

extension Date: @retroactive Identifiable {
    public var id: Date { self }
}
