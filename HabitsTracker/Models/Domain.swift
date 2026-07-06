import Foundation
import SwiftData

@Model
final class Domain {
    @Attribute(.unique) var id: UUID
    @Attribute(originalName: "name") var name: String
    @Attribute(originalName: "iconName") var iconName: String
    @Attribute(originalName: "colorToken") var colorToken: String
    @Attribute(originalName: "sortIndex") var sortIndex: Int
    @Attribute(originalName: "isSeeded") var isSeeded: Bool
    @Attribute(originalName: "seedVersion") var seedVersion: Int
    var isFocused: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \Habit.category)
    var habits: [Habit]

    @Relationship(deleteRule: .nullify, inverse: \Rule.domain)
    var rules: [Rule] = []

    @Relationship(deleteRule: .nullify, inverse: \Collection.domain)
    var collections: [Collection] = []

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorToken: String,
        sortIndex: Int,
        isSeeded: Bool = false,
        seedVersion: Int = 0,
        isFocused: Bool = false,
        habits: [Habit] = [],
        rules: [Rule] = [],
        collections: [Collection] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorToken = colorToken
        self.sortIndex = sortIndex
        self.isSeeded = isSeeded
        self.seedVersion = seedVersion
        self.isFocused = isFocused
        self.habits = habits
        self.rules = rules
        self.collections = collections
    }
}
