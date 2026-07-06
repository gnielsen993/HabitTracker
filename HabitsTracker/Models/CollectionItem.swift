import Foundation
import SwiftData

@Model
final class CollectionItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var statusIndex: Int = 0
    var sortIndex: Int = 0
    var note: String? = nil
    var sourceURL: String? = nil
    var cost: Double? = nil
    var season: Int = 1
    var episode: Int = 1
    var counterValue: Int = 0
    var counterLabel: String? = nil
    var isSeeded: Bool = false
    var seedVersion: Int = 0

    @Relationship
    var collection: Collection?

    init(
        id: UUID = UUID(),
        title: String,
        statusIndex: Int = 0,
        sortIndex: Int = 0,
        note: String? = nil,
        sourceURL: String? = nil,
        cost: Double? = nil,
        season: Int = 1,
        episode: Int = 1,
        counterValue: Int = 0,
        counterLabel: String? = nil,
        isSeeded: Bool = false,
        seedVersion: Int = 0,
        collection: Collection? = nil
    ) {
        self.id = id
        self.title = title
        self.statusIndex = statusIndex
        self.sortIndex = sortIndex
        self.note = note
        self.sourceURL = sourceURL
        self.cost = cost
        self.season = season
        self.episode = episode
        self.counterValue = counterValue
        self.counterLabel = counterLabel
        self.isSeeded = isSeeded
        self.seedVersion = seedVersion
        self.collection = collection
    }
}
