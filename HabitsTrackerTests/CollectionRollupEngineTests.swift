import XCTest
@testable import HabitsTracker

/// Unit tests for `CollectionRollupEngine` — all 5 required cases (§9.5, D-19).
/// `Collection` and `CollectionItem` instances are constructed in-memory and passed
/// directly to the pure engine; no SwiftData ModelContext is required.
final class CollectionRollupEngineTests: XCTestCase {

    // MARK: - Happy path: 2 of 5 items at terminal

    /// 3-state set (terminalIndex == 2). 5 items total, 2 at statusIndex == 2.
    /// Engine must return .count(x: 2, y: 5). (D-16)
    func testCompletionistHappyPath() {
        let collection = Collection(title: "Shows", statusSetID: "shows", showsAggregate: true)
        let items = [
            CollectionItem(title: "Succession",    statusIndex: 2),  // terminal = watched
            CollectionItem(title: "The Wire",      statusIndex: 2),  // terminal = watched
            CollectionItem(title: "Sopranos",      statusIndex: 1),  // watching (mid-step)
            CollectionItem(title: "Peaky Blinders",statusIndex: 0),  // to-watch
            CollectionItem(title: "Chernobyl",     statusIndex: 0)   // to-watch
        ]
        let result = CollectionRollupEngine.rollup(collection: collection, items: items)
        XCTAssertEqual(result, .count(x: 2, y: 5))
    }

    // MARK: - Empty list: showsAggregate true, zero items

    /// No items → .count(x: 0, y: 0). y == 0 is handled; no divide-by-zero (D-19).
    func testEmptyList() {
        let collection = Collection(title: "Movies", statusSetID: "movies", showsAggregate: true)
        let result = CollectionRollupEngine.rollup(collection: collection, items: [])
        XCTAssertEqual(result, .count(x: 0, y: 0))
    }

    // MARK: - Mid-step item is NOT counted in x

    /// 3-state set. One item at statusIndex 1 (watching) — NOT at terminal (2).
    /// Engine must count that item in y but NOT in x. (D-16)
    func testMidStepItemNotCounted() {
        let collection = Collection(title: "Books", statusSetID: "books", showsAggregate: true)
        let items = [
            CollectionItem(title: "Dune",       statusIndex: 2),  // terminal = read
            CollectionItem(title: "Foundation", statusIndex: 1),  // reading — mid-step, excluded from x
            CollectionItem(title: "1984",       statusIndex: 0)   // to-read
        ]
        let result = CollectionRollupEngine.rollup(collection: collection, items: items)
        XCTAssertEqual(result, .count(x: 1, y: 3),
                       "Mid-step (statusIndex 1) must not be counted in x")
    }

    // MARK: - Cost sum with mixed nil/non-nil costs

    /// Some items have nil cost, some have values. Engine returns .costSum of NON-NIL
    /// costs only — nil costs are excluded, not treated as 0. (D-19, D-20)
    func testCostSumWithMixedNilCosts() {
        let collection = Collection(title: "Want to spend on", statusSetID: "spending", showsAggregate: true)
        let items = [
            CollectionItem(title: "Camera",   cost: 800.0),
            CollectionItem(title: "Lens",     cost: 350.0),
            CollectionItem(title: "Tripod",   cost: nil),  // excluded from sum
            CollectionItem(title: "Bag",      cost: nil),  // excluded from sum
            CollectionItem(title: "Filter",   cost: 90.0)
        ]
        let result = CollectionRollupEngine.rollup(collection: collection, items: items)
        XCTAssertEqual(result, .costSum(total: 1240.0))
    }

    // MARK: - Tracker: showsAggregate == false → .none

    /// When showsAggregate is false the engine must return .none regardless of items. (D-18)
    func testTrackerShowsAggregateOff() {
        let collection = Collection(title: "Private List", statusSetID: "generic", showsAggregate: false)
        let items = [
            CollectionItem(title: "Item A", statusIndex: 1),
            CollectionItem(title: "Item B", statusIndex: 1)
        ]
        let result = CollectionRollupEngine.rollup(collection: collection, items: items)
        XCTAssertEqual(result, .none)
    }
}
