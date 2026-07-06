import Foundation

enum CollectionRollupEngine {

    /// The rollup result returned for a given collection + its items.
    ///
    /// - count(x:y:)   — completionist: x items at terminal state, y total (D-16).
    /// - costSum(total:) — cost-flavored: sum of non-nil item costs only (D-19).
    /// - none           — tracker (showsAggregate == false) shows no aggregate (D-18).
    enum Result: Equatable {
        case count(x: Int, y: Int)
        case costSum(total: Double)
        case none
    }

    /// Derive the rollup for a collection and its items (D-20).
    ///
    /// Derivation order:
    /// 1. Guard showsAggregate — trackers always return .none.
    /// 2. Cost-flavored branch: if any item carries a non-nil cost, return .costSum
    ///    of the non-nil costs only (nil costs are excluded, not treated as 0).
    /// 3. Completionist branch: look up terminalIndex via StatusSetCatalog.
    ///    x = items where statusIndex == terminalIndex (strictly terminal — mid-step excluded, D-16).
    ///    y = total item count.
    ///    Defensive fallback: unknown statusSetID → .count(0, y) rather than crashing (T-03-03).
    nonisolated static func rollup(collection: Collection, items: [CollectionItem]) -> Result {
        // Step 1: tracker guard (D-18 — .none on showsAggregate == false)
        guard collection.showsAggregate else { return .none }

        // Step 2: cost-flavored branch (D-20)
        // Signal: any item has a non-nil cost value.
        let nonNilCosts = items.compactMap(\.cost)
        if !nonNilCosts.isEmpty {
            // Cost sum is ALWAYS plain text downstream; never a ring (D-18).
            return .costSum(total: nonNilCosts.reduce(0, +))
        }

        // Step 3: completionist branch (D-16, D-19)
        // Look up terminalIndex from the catalog. If the statusSetID is unknown
        // (e.g. imported/stale data — T-03-03), return .count(0, y) defensively
        // rather than force-unwrapping or crashing.
        guard let statusSet = StatusSetCatalog.set(for: collection.statusSetID) else {
            // Defensive path: unknown statusSetID — report all as incomplete.
            return .count(x: 0, y: items.count)
        }
        let terminalIndex = statusSet.terminalIndex
        let x = items.filter { $0.statusIndex == terminalIndex }.count  // strictly terminal only
        let y = items.count
        return .count(x: x, y: y)
    }
}
