import Foundation
import SwiftData

@Model
final class Collection {
    @Attribute(.unique) var id: UUID
    var title: String
    var statusSetID: String = "generic"
    var progressTemplate: String = "none"
    var showsAggregate: Bool = true
    var sortIndex: Int = 0
    var note: String? = nil
    var isSeeded: Bool = false
    var seedVersion: Int = 0

    @Relationship
    var domain: Domain?

    @Relationship(deleteRule: .cascade, inverse: \CollectionItem.collection)
    var items: [CollectionItem] = []

    init(
        id: UUID = UUID(),
        title: String,
        statusSetID: String = "generic",
        progressTemplate: String = "none",
        showsAggregate: Bool = true,
        sortIndex: Int = 0,
        note: String? = nil,
        isSeeded: Bool = false,
        seedVersion: Int = 0,
        domain: Domain? = nil,
        items: [CollectionItem] = []
    ) {
        self.id = id
        self.title = title
        self.statusSetID = statusSetID
        self.progressTemplate = progressTemplate
        self.showsAggregate = showsAggregate
        self.sortIndex = sortIndex
        self.note = note
        self.isSeeded = isSeeded
        self.seedVersion = seedVersion
        self.domain = domain
        self.items = items
    }
}
