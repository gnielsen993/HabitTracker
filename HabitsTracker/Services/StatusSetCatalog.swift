import Foundation

struct StatusSet {
    let id: String
    let states: [String]
    let terminalIndex: Int
}

enum StatusSetCatalog {
    static let all: [StatusSet] = [
        StatusSet(id: "generic",   states: ["to-collect", "collected"],               terminalIndex: 1),
        StatusSet(id: "shows",     states: ["to-watch", "watching", "watched"],        terminalIndex: 2),
        StatusSet(id: "movies",    states: ["to-watch", "watching", "watched"],        terminalIndex: 2),
        StatusSet(id: "albums",    states: ["to-listen", "listening", "listened"],     terminalIndex: 2),
        StatusSet(id: "concerts",  states: ["to-attend", "attended"],                  terminalIndex: 1),
        StatusSet(id: "books",     states: ["to-read", "reading", "read"],             terminalIndex: 2),
        StatusSet(id: "clothes",   states: ["want", "bought"],                         terminalIndex: 1),
        StatusSet(id: "spending",  states: ["considering", "purchased"],               terminalIndex: 1),
        StatusSet(id: "places",    states: ["to-visit", "visited"],                    terminalIndex: 1)
    ]

    static var generic: StatusSet {
        // The generic set is guaranteed to exist — it is always the first entry.
        all.first { $0.id == "generic" }!
    }

    static func set(for id: String) -> StatusSet? {
        all.first { $0.id == id }
    }
}
