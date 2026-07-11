import Foundation
import SwiftData

/// A freeform, title-only-minimum capture item filed under a `Domain` (IDEA-01).
/// Leaf model: no owned dependents, so `domain` is a bare relationship with
/// `.nullify` declared on the `Domain.ideas` inverse (never cascade, D-11).
///
/// Promote (Idea->anything, D-12) is consume: the idea is archived and carries a
/// scalar forward-link (`promotedToKindRaw`/`promotedToID`) to whatever it became.
/// There is deliberately no SwiftData relationship/backref for the forward-link —
/// it is a lean value pair, mirroring how `Clip.statusRaw` is a raw-string-backed
/// enum facade (`ClipStatus`/`Clip.status`).
@Model
final class Idea {
    @Attribute(.unique) var id: UUID
    var title: String
    var note: String?
    var url: String?
    var isArchived: Bool = false
    var createdAt: Date = Date.now

    var promotedToKindRaw: String?
    var promotedToID: UUID?

    @Relationship
    var domain: Domain?

    /// Nested single source of truth (D-12) — referenced elsewhere as `Idea.PromotedKind`.
    /// Do NOT introduce a top-level `PromotedKind`; 05-03/05-06/05-07 all reference this
    /// nested type.
    enum PromotedKind: String, Codable {
        case rule
        case habit
        case collectionItem
    }

    /// Computed facade over `promotedToKindRaw`, mirroring `Clip.status` over `statusRaw`.
    var promotedTo: PromotedKind? {
        get { promotedToKindRaw.flatMap(PromotedKind.init(rawValue:)) }
        set { promotedToKindRaw = newValue?.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        note: String? = nil,
        url: String? = nil,
        isArchived: Bool = false,
        createdAt: Date = .now,
        promotedToKindRaw: String? = nil,
        promotedToID: UUID? = nil,
        domain: Domain? = nil
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.url = url
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.promotedToKindRaw = promotedToKindRaw
        self.promotedToID = promotedToID
        self.domain = domain
    }
}
