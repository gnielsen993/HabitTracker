import Foundation
import SwiftData
import os.log

// `Logger` is a thread-safe value type over os_log; safe to share across the
// `nonisolated static` functions below without actor isolation.
nonisolated(unsafe) private let logger = Logger(subsystem: "lauterstar.HabitsTracker", category: "PromoteService")

/// The single small, pure, testable core for Idea promote (D-07, D-12, IDEA-04).
///
/// Promote (Idea->anything) is a CONSUME operation: the idea is archived and left
/// with a scalar forward-link (`promotedTo`/`promotedToID`) to whatever it became.
/// There is deliberately no SwiftData relationship/backref from the result
/// (Rule/Habit/CollectionItem) back to the idea — the forward link is a lean value
/// pair, matching how `Clip.statusRaw` backs the `ClipStatus` facade.
///
/// This core mutates the passed-in `Idea` directly and never calls
/// `ModelContext.save()` — the caller (one of the three target editors, 05-06) owns
/// the save. Keeping the core save-free lets `PromoteServiceTests` construct plain
/// in-memory `@Model` objects with no `ModelContainer`, so the suite runs in the
/// runnable engine tier that actually executes on the iOS 26 simulator (§9.7),
/// unlike `@Model`-persistence suites.
///
/// This service does NOT construct the target Rule/Habit/CollectionItem — the
/// editors already own that insert; this service only performs the idea-side
/// consume plus the precondition predicates the editors' Save-gate consults.
enum PromoteService {

    /// Archives `idea` and sets its forward link to the promoted target (D-07).
    ///
    /// Safe no-op (logged skip) when `idea.isArchived` is already true — a second
    /// promote of the same idea must never double-archive or overwrite an existing
    /// forward-link (T-05-04).
    nonisolated static func archiveAndForwardLink(idea: Idea, as kind: Idea.PromotedKind, targetID: UUID) {
        guard !idea.isArchived else {
            logger.notice("archiveAndForwardLink skipped — idea \(idea.id, privacy: .public) is already archived")
            return
        }
        idea.isArchived = true
        idea.promotedTo = kind
        idea.promotedToID = targetID
    }

    /// The unfiled-idea-needs-domain precondition (IDEA-05): promoting an idea with
    /// no domain must be gated until the editor's domain picker resolves one.
    nonisolated static func requiresDomainBeforePromote(idea: Idea) -> Bool {
        idea.domain == nil
    }
}
