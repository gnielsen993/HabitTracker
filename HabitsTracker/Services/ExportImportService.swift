import Foundation
import SwiftData

struct HabitExportBundle: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let categories: [DomainDTO]
    let habits: [HabitDTO]
    let dailyEntries: [DailyEntryDTO]
    let rules: [RuleDTO]
}

struct DomainDTO: Codable {
    let id: UUID
    let name: String
    let iconName: String
    let colorToken: String
    let sortIndex: Int
    let isSeeded: Bool
    let seedVersion: Int
    let isFocused: Bool
}

struct RuleDTO: Codable {
    let id: UUID
    let title: String
    let body: String
    let sourceURL: String?
    let isArchived: Bool
    let createdAt: Date
    let domainID: UUID?
}

struct HabitDTO: Codable {
    let id: UUID
    let name: String
    let categoryId: UUID?
    let scheduleTypeRaw: String
    let scheduledDaysRaw: [Int]
    let modeRaw: String
    let weeklyTargetCount: Int?
    let isPinned: Bool
    let isArchived: Bool
    let isSeeded: Bool
    let seedVersion: Int
    let createdAt: Date
    let originRuleID: UUID?
}

struct DailyEntryDTO: Codable {
    let id: UUID
    let dateKey: Date
    let note: String
    let mood: String
    let states: [HabitStateDTO]
}

struct HabitStateDTO: Codable {
    let id: UUID
    let habitId: UUID
    let isCompleted: Bool
    let completedAt: Date?
}

final class ExportImportService {
    private let schemaVersion = 3
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = encoder
        self.decoder = decoder
    }

    func exportData(categories: [Domain], habits: [Habit], entries: [DailyEntry], rules: [Rule]) throws -> Data {
        let payload = HabitExportBundle(
            schemaVersion: schemaVersion,
            exportedAt: .now,
            categories: categories.map {
                DomainDTO(
                    id: $0.id,
                    name: $0.name,
                    iconName: $0.iconName,
                    colorToken: $0.colorToken,
                    sortIndex: $0.sortIndex,
                    isSeeded: $0.isSeeded,
                    seedVersion: $0.seedVersion,
                    isFocused: $0.isFocused
                )
            },
            habits: habits.map {
                HabitDTO(
                    id: $0.id,
                    name: $0.name,
                    categoryId: $0.category?.id,
                    scheduleTypeRaw: $0.scheduleTypeRaw,
                    scheduledDaysRaw: $0.scheduledDaysRaw,
                    modeRaw: $0.modeRaw,
                    weeklyTargetCount: $0.weeklyTargetCount,
                    isPinned: $0.isPinned,
                    isArchived: $0.isArchived,
                    isSeeded: $0.isSeeded,
                    seedVersion: $0.seedVersion,
                    createdAt: $0.createdAt,
                    originRuleID: $0.originRule?.id
                )
            },
            dailyEntries: entries.map { entry in
                DailyEntryDTO(
                    id: entry.id,
                    dateKey: entry.dateKey,
                    note: entry.note,
                    mood: entry.mood,
                    states: entry.habitStates.compactMap { state in
                        guard let habitId = state.habit?.id else { return nil }
                        return HabitStateDTO(
                            id: state.id,
                            habitId: habitId,
                            isCompleted: state.isCompleted,
                            completedAt: state.completedAt
                        )
                    }
                )
            },
            rules: rules.map {
                RuleDTO(
                    id: $0.id,
                    title: $0.title,
                    body: $0.body,
                    sourceURL: $0.sourceURL,
                    isArchived: $0.isArchived,
                    createdAt: $0.createdAt,
                    domainID: $0.domain?.id
                )
            }
        )

        return try encoder.encode(payload)
    }

    func importReplace(data: Data, context: ModelContext) throws {
        let bundle = try decoder.decode(HabitExportBundle.self, from: data)
        guard bundle.schemaVersion == schemaVersion else {
            throw ImportError.unsupportedSchema(bundle.schemaVersion)
        }

        try deleteAll(context: context)

        // 1. Create Domains (build id->Domain map)
        var categoryIndex: [UUID: Domain] = [:]
        for dto in bundle.categories {
            let category = Domain(
                id: dto.id,
                name: dto.name,
                iconName: dto.iconName,
                colorToken: dto.colorToken,
                sortIndex: dto.sortIndex,
                isSeeded: dto.isSeeded,
                seedVersion: dto.seedVersion,
                isFocused: dto.isFocused
            )
            context.insert(category)
            categoryIndex[dto.id] = category
        }

        // 2. Create Rules (build id->Rule map, wire rule.domain)
        var ruleIndex: [UUID: Rule] = [:]
        for dto in bundle.rules {
            let rule = Rule(
                id: dto.id,
                title: dto.title,
                body: dto.body,
                sourceURL: dto.sourceURL,
                domain: dto.domainID.flatMap { categoryIndex[$0] },
                isArchived: dto.isArchived,
                createdAt: dto.createdAt
            )
            context.insert(rule)
            ruleIndex[dto.id] = rule
        }

        // 3. Create Habits (wire category + originRule)
        var habitIndex: [UUID: Habit] = [:]
        for dto in bundle.habits {
            let habit = Habit(
                id: dto.id,
                name: dto.name,
                category: dto.categoryId.flatMap { categoryIndex[$0] },
                scheduleType: HabitScheduleType(rawValue: dto.scheduleTypeRaw) ?? .daily,
                scheduledDays: dto.scheduledDaysRaw.compactMap(Weekday.init(rawValue:)),
                mode: HabitMode(rawValue: dto.modeRaw) ?? .required,
                weeklyTargetCount: dto.weeklyTargetCount,
                isPinned: dto.isPinned,
                isArchived: dto.isArchived,
                isSeeded: dto.isSeeded,
                seedVersion: dto.seedVersion,
                createdAt: dto.createdAt,
                originRule: dto.originRuleID.flatMap { ruleIndex[$0] }
            )
            context.insert(habit)
            habitIndex[dto.id] = habit
        }

        // 4. Create DailyEntries + HabitStates
        for dto in bundle.dailyEntries {
            let entry = DailyEntry(
                id: dto.id,
                dateKey: dto.dateKey,
                note: dto.note,
                mood: dto.mood
            )
            context.insert(entry)

            for stateDTO in dto.states {
                guard let habit = habitIndex[stateDTO.habitId] else { continue }
                let state = HabitState(
                    id: stateDTO.id,
                    isCompleted: stateDTO.isCompleted,
                    completedAt: stateDTO.completedAt,
                    dailyEntry: entry,
                    habit: habit
                )
                context.insert(state)
                entry.habitStates.append(state)
                habit.states.append(state)
            }
        }

        try context.save()
    }

    private func deleteAll(context: ModelContext) throws {
        try context.delete(model: HabitState.self)
        try context.delete(model: DailyEntry.self)
        try context.delete(model: Habit.self)
        try context.delete(model: Rule.self)
        try context.delete(model: Domain.self)
        try context.save()
    }
}

enum ImportError: Error {
    case unsupportedSchema(Int)
}
