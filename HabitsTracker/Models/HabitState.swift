import Foundation
import SwiftData

@Model
final class HabitState {
    @Attribute(.unique) var id: UUID
    var isCompleted: Bool
    var completedAt: Date?

    @Relationship
    var dailyEntry: DailyEntry?

    @Relationship
    var habit: Habit?

    init(
        id: UUID = UUID(),
        isCompleted: Bool,
        completedAt: Date? = nil,
        dailyEntry: DailyEntry? = nil,
        habit: Habit? = nil
    ) {
        self.id = id
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.dailyEntry = dailyEntry
        self.habit = habit
    }
}
