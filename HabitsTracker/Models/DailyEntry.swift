import Foundation
import SwiftData

@Model
final class DailyEntry {
    @Attribute(.unique) var id: UUID
    var dateKey: Date
    var note: String
    var mood: String

    @Relationship(deleteRule: .cascade, inverse: \HabitState.dailyEntry)
    var habitStates: [HabitState]

    init(
        id: UUID = UUID(),
        dateKey: Date,
        note: String = "",
        mood: String = "",
        habitStates: [HabitState] = []
    ) {
        self.id = id
        self.dateKey = dateKey
        self.note = note
        self.mood = mood
        self.habitStates = habitStates
    }
}
