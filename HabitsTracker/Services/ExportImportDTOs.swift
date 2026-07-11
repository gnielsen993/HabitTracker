import Foundation

/// Codable transfer objects for the Export/Import backup round-trip.
///
/// Split out of `ExportImportService.swift` to keep that file focused on the
/// export/import logic (§9.1). Each `*DTO` mirrors one `@Model` type's persisted
/// fields; `HabitExportBundle` is the top-level payload.
///
/// Backward tolerance: `HabitExportBundle` decodes any type array that a given
/// `schemaVersion` predates as an empty list, so a backup exported on an earlier
/// build (which lacks `rules`/`collections`/`collectionItems`/`clips`) still
/// imports instead of throwing. Full cross-version *field-level* fidelity for the
/// oldest schemas is Phase F (Polish) territory — this covers the common
/// "restore a recent backup after a version bump" case.
struct HabitExportBundle: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let categories: [DomainDTO]
    let habits: [HabitDTO]
    let dailyEntries: [DailyEntryDTO]
    let rules: [RuleDTO]
    let collections: [CollectionDTO]
    let collectionItems: [CollectionItemDTO]
    let clips: [ClipDTO]
    let ideas: [IdeaDTO]

    init(
        schemaVersion: Int,
        exportedAt: Date,
        categories: [DomainDTO],
        habits: [HabitDTO],
        dailyEntries: [DailyEntryDTO],
        rules: [RuleDTO],
        collections: [CollectionDTO],
        collectionItems: [CollectionItemDTO],
        clips: [ClipDTO],
        ideas: [IdeaDTO]
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.categories = categories
        self.habits = habits
        self.dailyEntries = dailyEntries
        self.rules = rules
        self.collections = collections
        self.collectionItems = collectionItems
        self.clips = clips
        self.ideas = ideas
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        // Type arrays introduced in later schema versions are absent in older
        // backups — decode-if-present so restoring a pre-bump backup does not throw.
        categories = try container.decodeIfPresent([DomainDTO].self, forKey: .categories) ?? []
        habits = try container.decodeIfPresent([HabitDTO].self, forKey: .habits) ?? []
        dailyEntries = try container.decodeIfPresent([DailyEntryDTO].self, forKey: .dailyEntries) ?? []
        rules = try container.decodeIfPresent([RuleDTO].self, forKey: .rules) ?? []
        collections = try container.decodeIfPresent([CollectionDTO].self, forKey: .collections) ?? []
        collectionItems = try container.decodeIfPresent([CollectionItemDTO].self, forKey: .collectionItems) ?? []
        clips = try container.decodeIfPresent([ClipDTO].self, forKey: .clips) ?? []
        ideas = try container.decodeIfPresent([IdeaDTO].self, forKey: .ideas) ?? []
    }
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

struct ClipDTO: Codable {
    let id: UUID
    let title: String
    let url: String
    let note: String?
    let tag: String?
    let status: String
    let isArchived: Bool
    let createdAt: Date
    let domainID: UUID?
}

struct IdeaDTO: Codable {
    let id: UUID
    let title: String
    let note: String?
    let url: String?
    let isArchived: Bool
    let createdAt: Date
    let promotedToKind: String?
    let promotedToID: UUID?
    let domainID: UUID?
}

struct CollectionDTO: Codable {
    let id: UUID
    let title: String
    let statusSetID: String
    let progressTemplate: String
    let showsAggregate: Bool
    let sortIndex: Int
    let note: String?
    let isSeeded: Bool
    let seedVersion: Int
    let domainID: UUID?
}

struct CollectionItemDTO: Codable {
    let id: UUID
    let title: String
    let statusIndex: Int
    let sortIndex: Int
    let note: String?
    let sourceURL: String?
    let cost: Double?
    let season: Int
    let episode: Int
    let counterValue: Int
    let counterLabel: String?
    let isSeeded: Bool
    let seedVersion: Int
    let collectionID: UUID?
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
