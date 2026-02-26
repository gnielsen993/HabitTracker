import Foundation

enum HabitMode: String, Codable, CaseIterable, Identifiable {
    case required
    case optional

    var id: String { rawValue }
}

enum HabitScheduleType: String, Codable, CaseIterable, Identifiable {
    case daily
    case customDays

    var id: String { rawValue }
}

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7

    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        case .sunday: "Sun"
        }
    }
}
