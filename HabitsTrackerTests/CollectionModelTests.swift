import XCTest
import SwiftData
@testable import HabitsTracker

/// Tests for `Collection` + `CollectionItem` @Models, the Domain.collections inverse,
/// cascade delete on Collection.items, and nullify on Domain.collections (COLL-01, D-21, D-22).
final class CollectionModelTests: XCTestCase {

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([
            Domain.self, Habit.self, DailyEntry.self, HabitState.self, Rule.self,
            Collection.self, CollectionItem.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    /// A CollectionItem built with only a title must default statusIndex to 0 (D-06).
    @MainActor
    func testStatusIndexDefaultsZero() throws {
        let context = try makeInMemoryContext()

        let item = CollectionItem(title: "Inception")
        context.insert(item)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CollectionItem>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.statusIndex, 0)
    }

    /// A Collection built with only a title must default statusSetID, progressTemplate, showsAggregate (D-02, D-21).
    @MainActor
    func testCollectionDefaults() throws {
        let context = try makeInMemoryContext()

        let collection = Collection(title: "My List")
        context.insert(collection)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Collection>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.statusSetID, "generic")
        XCTAssertEqual(fetched.first?.progressTemplate, "none")
        XCTAssertEqual(fetched.first?.showsAggregate, true)
    }

    /// Setting collection.domain = domain makes domain.collections contain that collection (D-22 inverse).
    @MainActor
    func testDomainCollectionsInverse() throws {
        let context = try makeInMemoryContext()

        let domain = Domain(name: "Media", iconName: "film", colorToken: "navy", sortIndex: 0)
        let collection = Collection(title: "Shows", domain: domain)
        context.insert(domain)
        context.insert(collection)
        try context.save()

        let domains = try context.fetch(FetchDescriptor<Domain>())
        XCTAssertEqual(domains.first?.collections.count, 1)
        XCTAssertEqual(domains.first?.collections.first?.title, "Shows")
    }

    /// Deleting a Collection cascade-deletes its CollectionItems (D-22).
    @MainActor
    func testDeleteCollectionCascadesItems() throws {
        let context = try makeInMemoryContext()

        let collection = Collection(title: "Books")
        let itemA = CollectionItem(title: "Dune", collection: collection)
        let itemB = CollectionItem(title: "Foundation", collection: collection)
        context.insert(collection)
        context.insert(itemA)
        context.insert(itemB)
        try context.save()

        context.delete(collection)
        try context.save()

        let items = try context.fetch(FetchDescriptor<CollectionItem>())
        XCTAssertEqual(items.count, 0, "Cascade delete must remove all items when collection is deleted")
    }

    /// Deleting a Domain nullifies its collections (domain.collections shrinks) — the collections survive (D-22).
    @MainActor
    func testDeleteDomainNullifiesCollections() throws {
        let context = try makeInMemoryContext()

        let domain = Domain(name: "Media", iconName: "film", colorToken: "navy", sortIndex: 0)
        let collection = Collection(title: "Albums", domain: domain)
        context.insert(domain)
        context.insert(collection)
        try context.save()

        context.delete(domain)
        try context.save()

        let collections = try context.fetch(FetchDescriptor<Collection>())
        XCTAssertEqual(collections.count, 1, "Collection must survive domain deletion")
        XCTAssertNil(collections.first?.domain, "Collection.domain must be nullified after domain deletion")
    }
}
