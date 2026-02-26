import Foundation
import SwiftData

final class SeedDataService {
    private let seedVersion = 1

    func seedIfNeeded(context: ModelContext) throws {
        let existingCategories = try context.fetch(FetchDescriptor<Category>())
        guard existingCategories.isEmpty else { return }

        let categories = defaultCategories()
        categories.forEach { context.insert($0) }

        let categoryByName = Dictionary(uniqueKeysWithValues: categories.map { ($0.name, $0) })
        for habit in defaultHabits(categoryByName: categoryByName) {
            context.insert(habit)
        }

        try context.save()
    }

    func restoreMissingDefaults(context: ModelContext) throws {
        let existingCategories = try context.fetch(FetchDescriptor<Category>())
        let byName = Dictionary(uniqueKeysWithValues: existingCategories.map { ($0.name, $0) })

        var resolved = byName
        for template in defaultCategories() where resolved[template.name] == nil {
            context.insert(template)
            resolved[template.name] = template
        }

        let existingHabits = try context.fetch(FetchDescriptor<Habit>())
        let habitKey = Set(existingHabits.map { "\(($0.category?.name ?? "None"))::\($0.name)" })

        for habit in defaultHabits(categoryByName: resolved) {
            let key = "\((habit.category?.name ?? "None"))::\(habit.name)"
            if !habitKey.contains(key) {
                context.insert(habit)
            }
        }

        try context.save()
    }

    private func defaultCategories() -> [Category] {
        [
            Category(name: "Productivity", iconName: "checklist", colorToken: "forest", sortIndex: 0, isSeeded: true, seedVersion: seedVersion),
            Category(name: "Learning", iconName: "book", colorToken: "navy", sortIndex: 1, isSeeded: true, seedVersion: seedVersion),
            Category(name: "Lifestyle", iconName: "sun.max", colorToken: "stone", sortIndex: 2, isSeeded: true, seedVersion: seedVersion),
            Category(name: "Health", iconName: "heart", colorToken: "forest", sortIndex: 3, isSeeded: true, seedVersion: seedVersion),
            Category(name: "Fitness", iconName: "figure.run", colorToken: "navy", sortIndex: 4, isSeeded: true, seedVersion: seedVersion),
            Category(name: "Social", iconName: "person.2", colorToken: "maroon", sortIndex: 5, isSeeded: true, seedVersion: seedVersion),
            Category(name: "Mindfulness", iconName: "brain", colorToken: "walnut", sortIndex: 6, isSeeded: true, seedVersion: seedVersion),
            Category(name: "House / Chores", iconName: "house", colorToken: "walnut", sortIndex: 7, isSeeded: true, seedVersion: seedVersion),
            Category(name: "Finance", iconName: "dollarsign.circle", colorToken: "stone", sortIndex: 8, isSeeded: true, seedVersion: seedVersion),
            Category(name: "Creativity", iconName: "paintbrush", colorToken: "maroon", sortIndex: 9, isSeeded: true, seedVersion: seedVersion),
            Category(name: "Career", iconName: "briefcase", colorToken: "navy", sortIndex: 10, isSeeded: true, seedVersion: seedVersion),
            Category(name: "Admin / Life Ops", iconName: "tray.full", colorToken: "stone", sortIndex: 11, isSeeded: true, seedVersion: seedVersion)
        ]
    }

    private func defaultHabits(categoryByName: [String: Category]) -> [Habit] {
        func c(_ name: String) -> Category? { categoryByName[name] }

        return [
            Habit(name: "Deep Work", category: c("Productivity"), scheduleType: .customDays, scheduledDays: [.monday, .tuesday, .wednesday, .thursday, .friday], mode: .required, isSeeded: true, seedVersion: seedVersion),
            Habit(name: "Plan Tomorrow", category: c("Productivity"), scheduleType: .daily, mode: .optional, weeklyTargetCount: 3, isSeeded: true, seedVersion: seedVersion),
            Habit(name: "Read", category: c("Learning"), scheduleType: .daily, mode: .required, isSeeded: true, seedVersion: seedVersion),
            Habit(name: "LeetCode", category: c("Learning"), scheduleType: .daily, mode: .optional, weeklyTargetCount: 3, isSeeded: true, seedVersion: seedVersion),
            Habit(name: "Workout", category: c("Fitness"), scheduleType: .daily, mode: .optional, weeklyTargetCount: 4, isSeeded: true, seedVersion: seedVersion),
            Habit(name: "Walk", category: c("Fitness"), scheduleType: .daily, mode: .optional, weeklyTargetCount: 5, isSeeded: true, seedVersion: seedVersion),
            Habit(name: "Reach Out", category: c("Social"), scheduleType: .daily, mode: .optional, weeklyTargetCount: 2, isSeeded: true, seedVersion: seedVersion),
            Habit(name: "Meditate", category: c("Mindfulness"), scheduleType: .daily, mode: .optional, weeklyTargetCount: 5, isSeeded: true, seedVersion: seedVersion),
            Habit(name: "Track Spending", category: c("Finance"), scheduleType: .daily, mode: .optional, weeklyTargetCount: 2, isSeeded: true, seedVersion: seedVersion),
            Habit(name: "Calendar Review", category: c("Admin / Life Ops"), scheduleType: .daily, mode: .optional, weeklyTargetCount: 1, isSeeded: true, seedVersion: seedVersion)
        ]
    }
}
