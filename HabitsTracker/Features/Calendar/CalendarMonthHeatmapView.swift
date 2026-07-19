import SwiftUI
import SwiftData
import DesignKit

struct CalendarMonthHeatmapView: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Habit.name) private var habits: [Habit]
    @Query(sort: \DailyEntry.dateKey, order: .reverse) private var entries: [DailyEntry]

    @State private var monthAnchor = Date()
    @State private var selectedDay: Date?

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        let days = MonthGridBuilder.days(for: monthAnchor)
        let snapshots = habits.filter { !$0.isArchived }.map { HabitProgressEngine.snapshot(from: $0) }

        // Folded into ProgressDashboardView behind a Charts ⇄ Calendar segmented
        // control (D-13/D-14). No inner NavigationStack / navigationTitle here —
        // Progress owns the single stack; this view nests under it.
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
                    DayCell(day: day, snapshots: snapshots, monthAnchor: monthAnchor, theme: theme)
                        .onTapGesture { selectedDay = day }
                }
            }
            .padding(.horizontal, theme.spacing.l)

            Spacer()
        }
        .background(theme.colors.background.ignoresSafeArea())
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(date: day)
        }
    }
}

private struct DayCell: View {
    let day: Date
    let snapshots: [HabitProgressEngine.HabitSnapshot]
    let monthAnchor: Date
    let theme: Theme

    var body: some View {
        let sameMonth = Calendar.current.isDate(day, equalTo: monthAnchor, toGranularity: .month)

        VStack(spacing: theme.spacing.xs) {
            Text(day.formatted(.dateTime.day()))
            Image(systemName: symbol)
                .accessibilityHidden(true)
        }
        .font(theme.typography.caption)
        .foregroundStyle(sameMonth ? theme.colors.textPrimary : theme.colors.textTertiary)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)), \(statusLabel)")
    }

    private var background: Color {
        if Calendar.current.isDateInToday(day) { return theme.colors.highlight }
        if completed > 0 && completed == scheduled { return theme.colors.success }
        return scheduled > 0 ? theme.colors.surfaceElevated : theme.colors.surface
    }

    private var historicalStatuses: [HabitProgressEngine.DayStatus] {
        snapshots.map { HabitProgressEngine.status(for: $0, on: day) }
    }

    private var completed: Int { historicalStatuses.filter { $0 == .completed }.count }
    private var scheduled: Int { historicalStatuses.filter { $0 == .completed || $0 == .missed || $0 == .inProgress }.count }

    private var symbol: String {
        if DateUtilities.startOfDay(day) > DateUtilities.startOfDay(.now) { return "lock" }
        if Calendar.current.isDateInToday(day) { return "ellipsis" }
        if scheduled == 0 { return "circle" }
        return completed == scheduled ? "checkmark" : "minus"
    }

    private var statusLabel: String {
        if DateUtilities.startOfDay(day) > DateUtilities.startOfDay(.now) { return "future day, read-only" }
        if Calendar.current.isDateInToday(day) { return "in progress" }
        if scheduled == 0 { return "nothing scheduled" }
        return "\(completed) of \(scheduled) completed"
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
