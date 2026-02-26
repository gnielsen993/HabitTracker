import Foundation
import SwiftData

struct HabitExportBundle: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let categories: [CategoryDTO]
    let habits: [HabitDTO]
    let dailyEntries: [DailyEntryDTO]
}

struct CategoryDTO: Codable {
    let id: UUID
    let name: String
    let iconName: String
    let colorToken: String
    let sortIndex: Int
    let isSeeded: Bool
    let seedVersion: Int
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
    private let schemaVersion = 1
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

    func exportData(categories: [Category], habits: [Habit], entries: [DailyEntry]) throws -> Data {
        let payload = HabitExportBundle(
            schemaVersion: schemaVersion,
            exportedAt: .now,
            categories: categories.map {
                CategoryDTO(
                    id: $0.id,
                    name: $0.name,
                    iconName: $0.iconName,
                    colorToken: $0.colorToken,
                    sortIndex: $0.sortIndex,
                    isSeeded: $0.isSeeded,
                    seedVersion: $0.seedVersion
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
                    createdAt: $0.createdAt
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

        var categoryIndex: [UUID: Category] = [:]
        for dto in bundle.categories {
            let category = Category(
                id: dto.id,
                name: dto.name,
                iconName: dto.iconName,
                colorToken: dto.colorToken,
                sortIndex: dto.sortIndex,
                isSeeded: dto.isSeeded,
                seedVersion: dto.seedVersion
            )
            context.insert(category)
            categoryIndex[dto.id] = category
        }

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
                createdAt: dto.createdAt
            )
            context.insert(habit)
            habitIndex[dto.id] = habit
        }

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
        try context.delete(model: Category.self)
        try context.save()
    }
}

enum ImportError: Error {
    case unsupportedSchema(Int)
}
