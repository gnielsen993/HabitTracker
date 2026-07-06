import Foundation
import SwiftData

final class SeedDataService {
    private let seedVersion = 2

    func seedIfNeeded(context: ModelContext) throws {
        let existingCategories = try context.fetch(FetchDescriptor<Domain>())
        guard existingCategories.isEmpty else { return }

        let categories = defaultDomains()
        categories.forEach { context.insert($0) }

        let categoryByName = Dictionary(uniqueKeysWithValues: categories.map { ($0.name, $0) })
        for habit in defaultHabits(categoryByName: categoryByName) {
            context.insert(habit)
        }

        // Seed ONE generic starter collection (D-14).
        for collection in defaultCollections(domainByName: categoryByName) {
            context.insert(collection)
        }

        try context.save()
    }

    func restoreMissingDefaults(context: ModelContext) throws {
        let existingCategories = try context.fetch(FetchDescriptor<Domain>())
        let byName = Dictionary(uniqueKeysWithValues: existingCategories.map { ($0.name, $0) })

        var resolved = byName
        for template in defaultDomains() where resolved[template.name] == nil {
            // Merge-add (D-08): newly introduced defaults arrive unfocused so an
            // upgrader's Hub is not flooded — the user opts in via the focus picker.
            template.isFocused = false
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

        // Merge-add the generic starter collection (D-14): insert only if missing.
        let existingCollections = try context.fetch(FetchDescriptor<Collection>())
        let collectionKey = Set(existingCollections.map { "\($0.domain?.name ?? "None")::\($0.title)" })

        for collection in defaultCollections(domainByName: resolved) {
            let key = "\(collection.domain?.name ?? "None")::\(collection.title)"
            if !collectionKey.contains(key) {
                context.insert(collection)
            }
        }

        try context.save()
    }

    private func defaultDomains() -> [Domain] {
        [
            // Opinionated subset (D-09): the carried-over v1 defaults seed PRE-FOCUSED
            // on a fresh install — they are the curated Hub the user opens to.
            Domain(name: "Productivity", iconName: "checklist", colorToken: "forest", sortIndex: 0, isSeeded: true, seedVersion: seedVersion, isFocused: true),
            Domain(name: "Learning", iconName: "book", colorToken: "navy", sortIndex: 1, isSeeded: true, seedVersion: seedVersion, isFocused: true),
            Domain(name: "Lifestyle", iconName: "sun.max", colorToken: "stone", sortIndex: 2, isSeeded: true, seedVersion: seedVersion, isFocused: true),
            Domain(name: "Health", iconName: "heart", colorToken: "forest", sortIndex: 3, isSeeded: true, seedVersion: seedVersion, isFocused: true),
            Domain(name: "Fitness", iconName: "figure.run", colorToken: "navy", sortIndex: 4, isSeeded: true, seedVersion: seedVersion, isFocused: true),
            Domain(name: "Social", iconName: "person.2", colorToken: "maroon", sortIndex: 5, isSeeded: true, seedVersion: seedVersion, isFocused: true),
            Domain(name: "Mindfulness", iconName: "brain", colorToken: "walnut", sortIndex: 6, isSeeded: true, seedVersion: seedVersion, isFocused: true),
            Domain(name: "House / Chores", iconName: "house", colorToken: "walnut", sortIndex: 7, isSeeded: true, seedVersion: seedVersion, isFocused: true),
            Domain(name: "Finance", iconName: "dollarsign.circle", colorToken: "stone", sortIndex: 8, isSeeded: true, seedVersion: seedVersion, isFocused: true),
            Domain(name: "Creativity", iconName: "paintbrush", colorToken: "maroon", sortIndex: 9, isSeeded: true, seedVersion: seedVersion, isFocused: true),
            Domain(name: "Career", iconName: "briefcase", colorToken: "navy", sortIndex: 10, isSeeded: true, seedVersion: seedVersion, isFocused: true),
            Domain(name: "Admin / Life Ops", iconName: "tray.full", colorToken: "stone", sortIndex: 11, isSeeded: true, seedVersion: seedVersion, isFocused: true),
            // New hub seed domains (D-08): seed UNFOCUSED so a fresh curated install is
            // not flooded (Pitfall 3). On an upgrade they merge-add unfocused too.
            Domain(name: "Style", iconName: "tshirt", colorToken: "maroon", sortIndex: 12, isSeeded: true, seedVersion: seedVersion, isFocused: false),
            Domain(name: "Diet", iconName: "fork.knife", colorToken: "forest", sortIndex: 13, isSeeded: true, seedVersion: seedVersion, isFocused: false),
            Domain(name: "Money", iconName: "banknote", colorToken: "walnut", sortIndex: 14, isSeeded: true, seedVersion: seedVersion, isFocused: false),
            Domain(name: "Media", iconName: "play.rectangle", colorToken: "navy", sortIndex: 15, isSeeded: true, seedVersion: seedVersion, isFocused: false)
        ]
    }

    /// Returns exactly ONE generic starter collection seeded under the "Media" domain (D-14).
    /// Claude's Discretion: name "My List", domain "Media" — an existing seed domain.
    /// Returns an empty array if the Media domain is absent so the insert path is always
    /// safe (the upgrader path guards on the dedup key anyway).
    private func defaultCollections(domainByName: [String: Domain]) -> [Collection] {
        guard let mediaDomain = domainByName["Media"] else { return [] }
        return [
            Collection(
                title: "My List",
                statusSetID: "generic",
                progressTemplate: "none",
                showsAggregate: true,
                sortIndex: 0,
                isSeeded: true,
                seedVersion: seedVersion,
                domain: mediaDomain
            )
        ]
    }

    private func defaultHabits(categoryByName: [String: Domain]) -> [Habit] {
        func c(_ name: String) -> Domain? { categoryByName[name] }

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
