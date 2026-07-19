import Foundation
import SwiftData

@Model
final class HabitScheduleRevision {
    @Attribute(.unique) var id: UUID
    var effectiveDate: Date = Date.now
    var scheduleTypeRaw: String = HabitScheduleType.daily.rawValue
    var scheduledDaysRaw: [Int] = []
    var modeRaw: String = HabitMode.required.rawValue
    var weeklyTargetCount: Int?

    @Relationship
    var habit: Habit?

    var scheduleType: HabitScheduleType {
        get { HabitScheduleType(rawValue: scheduleTypeRaw) ?? .daily }
        set { scheduleTypeRaw = newValue.rawValue }
    }

    var mode: HabitMode {
        get { HabitMode(rawValue: modeRaw) ?? .required }
        set { modeRaw = newValue.rawValue }
    }

    var scheduledDays: [Weekday] {
        get { scheduledDaysRaw.compactMap(Weekday.init(rawValue:)) }
        set { scheduledDaysRaw = newValue.map(\.rawValue).sorted() }
    }

    init(
        id: UUID = UUID(),
        habit: Habit? = nil,
        effectiveDate: Date,
        scheduleType: HabitScheduleType,
        scheduledDays: [Weekday] = [],
        mode: HabitMode,
        weeklyTargetCount: Int? = nil
    ) {
        self.id = id
        self.habit = habit
        self.effectiveDate = DateUtilities.startOfDay(effectiveDate)
        self.scheduleTypeRaw = scheduleType.rawValue
        self.scheduledDaysRaw = scheduledDays.map(\.rawValue).sorted()
        self.modeRaw = mode.rawValue
        self.weeklyTargetCount = weeklyTargetCount
    }
}
