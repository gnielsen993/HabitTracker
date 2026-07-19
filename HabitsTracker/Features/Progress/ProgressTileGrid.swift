import SwiftUI
import DesignKit

struct ProgressTileGrid: View {
    let snapshot: HabitProgressEngine.HabitSnapshot
    let dates: [Date]
    let theme: Theme
    var compact = false

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: theme.spacing.xs), count: compact ? 14 : 7),
            spacing: theme.spacing.xs
        ) {
            ForEach(dates, id: \.self) { date in
                let status = HabitProgressEngine.status(for: snapshot, on: date)
                ZStack {
                    RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
                        .fill(background(for: status))
                    Image(systemName: symbol(for: status))
                        .font(theme.typography.caption)
                        .foregroundStyle(foreground(for: status))
                        .accessibilityHidden(true)
                }
                .aspectRatio(1, contentMode: .fit)
                .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted)), \(label(for: status))")
            }
        }
    }

    private func symbol(for status: HabitProgressEngine.DayStatus) -> String {
        switch status {
        case .completed: "checkmark"
        case .missed: "minus"
        case .notScheduled: "circle"
        case .inProgress: "ellipsis"
        }
    }

    private func label(for status: HabitProgressEngine.DayStatus) -> String {
        switch status {
        case .completed: "completed"
        case .missed: "missed"
        case .notScheduled: "not scheduled"
        case .inProgress: "in progress"
        }
    }

    private func background(for status: HabitProgressEngine.DayStatus) -> Color {
        switch status {
        case .completed: theme.colors.success
        case .missed: theme.colors.surfaceElevated
        case .notScheduled: theme.colors.surface
        case .inProgress: theme.colors.highlight
        }
    }

    private func foreground(for status: HabitProgressEngine.DayStatus) -> Color {
        switch status {
        case .completed: theme.colors.surfaceElevated
        case .missed, .notScheduled: theme.colors.textTertiary
        case .inProgress: theme.colors.accentPrimary
        }
    }
}
