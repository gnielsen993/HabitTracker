import Foundation
import SwiftData

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var scheduleTypeRaw: String
    var scheduledDaysRaw: [Int]
    var modeRaw: String
    var weeklyTargetCount: Int?
    var isPinned: Bool
    var isArchived: Bool
    var isSeeded: Bool
    var seedVersion: Int
    var createdAt: Date

    @Relationship
    var category: Domain?

    @Relationship
    var originRule: Rule?

    @Relationship(deleteRule: .cascade, inverse: \HabitState.habit)
    var states: [HabitState]

    @Relationship(deleteRule: .cascade, inverse: \HabitScheduleRevision.habit)
    var scheduleRevisions: [HabitScheduleRevision] = []

    var scheduleType: HabitScheduleType {
        get { HabitScheduleType(rawValue: scheduleTypeRaw) ?? .daily }
        set { scheduleTypeRaw = newValue.rawValue }
    }

    var mode: HabitMode {
        get { HabitMode(rawValue: modeRaw) ?? .required }
        set { modeRaw = newValue.rawValue }
    }

    var scheduledDays: [Weekday] {
        get { scheduledDaysRaw.compactMap(Weekday.init(rawValue:)).sorted { $0.rawValue < $1.rawValue } }
        set { scheduledDaysRaw = newValue.map { $0.rawValue }.sorted() }
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: Domain? = nil,
        scheduleType: HabitScheduleType,
        scheduledDays: [Weekday] = [],
        mode: HabitMode,
        weeklyTargetCount: Int? = nil,
        isPinned: Bool = false,
        isArchived: Bool = false,
        isSeeded: Bool = false,
        seedVersion: Int = 0,
        createdAt: Date = .now,
        originRule: Rule? = nil,
        states: [HabitState] = [],
        scheduleRevisions: [HabitScheduleRevision] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.scheduleTypeRaw = scheduleType.rawValue
        self.scheduledDaysRaw = scheduledDays.map { $0.rawValue }.sorted()
        self.modeRaw = mode.rawValue
        self.weeklyTargetCount = weeklyTargetCount
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.isSeeded = isSeeded
        self.seedVersion = seedVersion
        self.createdAt = createdAt
        self.originRule = originRule
        self.states = states
        self.scheduleRevisions = scheduleRevisions
    }
}
