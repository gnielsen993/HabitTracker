import Foundation

enum DateUtilities {
    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func isoWeekday(for date: Date, calendar: Calendar = .current) -> Weekday {
        let weekday = calendar.component(.weekday, from: date)
        let iso = weekday == 1 ? 7 : weekday - 1
        return Weekday(rawValue: iso) ?? .monday
    }

    static func startOfWeek(for date: Date, calendar: Calendar = .current) -> Date {
        let startDay = startOfDay(date, calendar: calendar)
        let weekday = isoWeekday(for: startDay, calendar: calendar).rawValue
        return calendar.date(byAdding: .day, value: -(weekday - 1), to: startDay) ?? startDay
    }
}
