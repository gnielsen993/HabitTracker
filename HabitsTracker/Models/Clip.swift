import Foundation
import SwiftData

/// Two-state status for a saved `Clip`: `saved` (default) -> `acted` (D-03).
/// A dedicated fixed-2-case enum, NOT the Phase 3 StatusSet catalog — a Clip's
/// states are inherent, not template-driven.
enum ClipStatus: String, Codable, CaseIterable, Identifiable {
    case saved
    case acted

    var id: String { rawValue }
}

/// An offline-only saved link filed under a `Domain` (CLIP-02...CLIP-04).
/// Leaf model: no owned dependents, so `domain` is a bare relationship with
/// `.nullify` declared on the `Domain.clips` inverse (never cascade, D-11).
@Model
final class Clip {
    @Attribute(.unique) var id: UUID
    var title: String
    var url: String
    var note: String?
    var tag: String?
    var statusRaw: String = ClipStatus.saved.rawValue
    var isArchived: Bool = false
    var createdAt: Date = Date.now

    @Relationship
    var domain: Domain?

    var status: ClipStatus {
        get { ClipStatus(rawValue: statusRaw) ?? .saved }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        note: String? = nil,
        tag: String? = nil,
        status: ClipStatus = .saved,
        isArchived: Bool = false,
        createdAt: Date = .now,
        domain: Domain? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.note = note
        self.tag = tag
        self.statusRaw = status.rawValue
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.domain = domain
    }
}
