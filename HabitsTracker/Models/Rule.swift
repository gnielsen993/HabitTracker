import Foundation
import SwiftData

@Model
final class Rule {
    @Attribute(.unique) var id: UUID
    var title: String
    var body: String
    var sourceURL: String?
    var createdAt: Date
    var isArchived: Bool = false

    @Relationship
    var domain: Domain?

    @Relationship(deleteRule: .nullify, inverse: \Habit.originRule)
    var stemmedHabits: [Habit] = []

    init(
        id: UUID = UUID(),
        title: String,
        body: String = "",
        sourceURL: String? = nil,
        domain: Domain? = nil,
        isArchived: Bool = false,
        createdAt: Date = .now,
        stemmedHabits: [Habit] = []
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.sourceURL = sourceURL
        self.domain = domain
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.stemmedHabits = stemmedHabits
    }
}
