import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorToken: String
    var sortIndex: Int
    var isSeeded: Bool
    var seedVersion: Int

    @Relationship(deleteRule: .nullify, inverse: \Habit.category)
    var habits: [Habit]

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorToken: String,
        sortIndex: Int,
        isSeeded: Bool = false,
        seedVersion: Int = 0,
        habits: [Habit] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorToken = colorToken
        self.sortIndex = sortIndex
        self.isSeeded = isSeeded
        self.seedVersion = seedVersion
        self.habits = habits
    }
}
