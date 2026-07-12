import Foundation
import SwiftData

// DTOs live in `ExportImportDTOs.swift` (§9.1 file-size split).

final class ExportImportService {
    /// Single source of truth for the export/import schema version (currently 6).
    /// Readable so callers like `SettingsView`'s About row never carry a divergent
    /// literal (POL-04 D-13).
    static let currentSchemaVersion = 6
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

    func exportData(
        categories: [Domain],
        habits: [Habit],
        entries: [DailyEntry],
        rules: [Rule],
        collections: [Collection],
        collectionItems: [CollectionItem],
        clips: [Clip],
        ideas: [Idea]
    ) throws -> Data {
        let payload = HabitExportBundle(
            schemaVersion: Self.currentSchemaVersion,
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
            },
            collections: collections.map {
                CollectionDTO(
                    id: $0.id,
                    title: $0.title,
                    statusSetID: $0.statusSetID,
                    progressTemplate: $0.progressTemplate,
                    showsAggregate: $0.showsAggregate,
                    sortIndex: $0.sortIndex,
                    note: $0.note,
                    isSeeded: $0.isSeeded,
                    seedVersion: $0.seedVersion,
                    domainID: $0.domain?.id
                )
            },
            collectionItems: collectionItems.map {
                CollectionItemDTO(
                    id: $0.id,
                    title: $0.title,
                    statusIndex: $0.statusIndex,
                    sortIndex: $0.sortIndex,
                    note: $0.note,
                    sourceURL: $0.sourceURL,
                    cost: $0.cost,
                    season: $0.season,
                    episode: $0.episode,
                    counterValue: $0.counterValue,
                    counterLabel: $0.counterLabel,
                    isSeeded: $0.isSeeded,
                    seedVersion: $0.seedVersion,
                    collectionID: $0.collection?.id
                )
            },
            clips: clips.map {
                ClipDTO(
                    id: $0.id,
                    title: $0.title,
                    url: $0.url,
                    note: $0.note,
                    tag: $0.tag,
                    status: $0.statusRaw,
                    isArchived: $0.isArchived,
                    createdAt: $0.createdAt,
                    domainID: $0.domain?.id
                )
            },
            ideas: ideas.map {
                IdeaDTO(
                    id: $0.id,
                    title: $0.title,
                    note: $0.note,
                    url: $0.url,
                    isArchived: $0.isArchived,
                    createdAt: $0.createdAt,
                    promotedToKind: $0.promotedToKindRaw,
                    promotedToID: $0.promotedToID,
                    domainID: $0.domain?.id
                )
            }
        )

        return try encoder.encode(payload)
    }

    func importReplace(data: Data, context: ModelContext) throws {
        let bundle = try decoder.decode(HabitExportBundle.self, from: data)
        // Accept this version or older (older backups decode missing type arrays
        // as empty via HabitExportBundle's tolerant decoder). Reject only backups
        // from a *newer* build we can't understand, so we never silently drop data.
        guard bundle.schemaVersion <= Self.currentSchemaVersion else {
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

        // 2b. Create Clips (wire to domain; no index map needed, nothing references clips by id)
        for dto in bundle.clips {
            let clip = Clip(
                id: dto.id,
                title: dto.title,
                url: dto.url,
                note: dto.note,
                tag: dto.tag,
                status: ClipStatus(rawValue: dto.status) ?? .saved,
                isArchived: dto.isArchived,
                createdAt: dto.createdAt,
                domain: dto.domainID.flatMap { categoryIndex[$0] }
            )
            context.insert(clip)
        }

        // 2c. Create Ideas (wire to domain; no index map needed — nothing
        // references an Idea by id, the promotedTo* fields are plain scalars)
        for dto in bundle.ideas {
            let idea = Idea(
                id: dto.id,
                title: dto.title,
                note: dto.note,
                url: dto.url,
                isArchived: dto.isArchived,
                createdAt: dto.createdAt,
                promotedToKindRaw: dto.promotedToKind,
                promotedToID: dto.promotedToID,
                domain: dto.domainID.flatMap { categoryIndex[$0] }
            )
            context.insert(idea)
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

        // 4. Create Collections (build id->Collection index, wire to domain)
        var collectionIndex: [UUID: Collection] = [:]
        for dto in bundle.collections {
            let collection = Collection(
                id: dto.id,
                title: dto.title,
                statusSetID: dto.statusSetID,
                progressTemplate: dto.progressTemplate,
                showsAggregate: dto.showsAggregate,
                sortIndex: dto.sortIndex,
                note: dto.note,
                isSeeded: dto.isSeeded,
                seedVersion: dto.seedVersion,
                domain: dto.domainID.flatMap { categoryIndex[$0] }
            )
            context.insert(collection)
            collectionIndex[dto.id] = collection
        }

        // 5. Create CollectionItems (wire to collection via index)
        for dto in bundle.collectionItems {
            let item = CollectionItem(
                id: dto.id,
                title: dto.title,
                statusIndex: dto.statusIndex,
                sortIndex: dto.sortIndex,
                note: dto.note,
                sourceURL: dto.sourceURL,
                cost: dto.cost,
                season: dto.season,
                episode: dto.episode,
                counterValue: dto.counterValue,
                counterLabel: dto.counterLabel,
                isSeeded: dto.isSeeded,
                seedVersion: dto.seedVersion,
                collection: dto.collectionID.flatMap { collectionIndex[$0] }
            )
            context.insert(item)
        }

        // 6. Create DailyEntries + HabitStates
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
        // Items before collections before domain (ownership order — T-03-10).
        try context.delete(model: CollectionItem.self)
        try context.delete(model: Collection.self)
        // Clip.domain is .nullify — clips must be deleted before their domain (T-04-09).
        try context.delete(model: Clip.self)
        // Idea.domain is .nullify — ideas must be deleted before their domain (T-05-03).
        try context.delete(model: Idea.self)
        try context.delete(model: Domain.self)
        try context.save()
    }
}

enum ImportError: Error {
    case unsupportedSchema(Int)
}
