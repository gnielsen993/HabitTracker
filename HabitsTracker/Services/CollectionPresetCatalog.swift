import Foundation

struct CollectionPreset {
    let id: String
    let name: String
    let statusSetID: String
    let progressTemplate: String
    let showsAggregate: Bool
}

enum CollectionPresetCatalog {
    // Order matches UI-SPEC S2 preset picker order (D-12).
    // generic is first and is the default for user-created collections (COLL-02 / D-04).
    static let all: [CollectionPreset] = [
        CollectionPreset(
            id: "generic",
            name: "My List",
            statusSetID: "generic",
            progressTemplate: "none",
            showsAggregate: true
        ),
        CollectionPreset(
            id: "shows",
            name: "Shows",
            statusSetID: "shows",
            progressTemplate: "seasonEpisode",
            showsAggregate: true
        ),
        CollectionPreset(
            id: "movies",
            name: "Movies",
            statusSetID: "movies",
            progressTemplate: "none",
            showsAggregate: true
        ),
        CollectionPreset(
            id: "albums",
            name: "Albums",
            statusSetID: "albums",
            progressTemplate: "none",
            showsAggregate: true
        ),
        CollectionPreset(
            id: "concerts",
            name: "Concerts",
            statusSetID: "concerts",
            progressTemplate: "none",
            showsAggregate: true
        ),
        CollectionPreset(
            id: "books",
            name: "Books",
            statusSetID: "books",
            progressTemplate: "counter",
            showsAggregate: true
        ),
        CollectionPreset(
            id: "clothes",
            name: "Clothes to buy",
            statusSetID: "clothes",
            progressTemplate: "none",
            showsAggregate: true
        ),
        CollectionPreset(
            id: "spending",
            name: "Want to spend on",
            statusSetID: "spending",
            progressTemplate: "none",
            showsAggregate: true  // cost-flavored; rollup derives .costSum from item costs (D-20)
        ),
        CollectionPreset(
            id: "places",
            name: "Planes / places",
            statusSetID: "places",
            progressTemplate: "none",
            showsAggregate: true
        )
    ]
}
