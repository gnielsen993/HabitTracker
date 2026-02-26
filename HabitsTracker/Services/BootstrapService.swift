import Foundation
import SwiftData

final class BootstrapService {
    private let seedDataService = SeedDataService()

    func bootstrapIfNeeded(context: ModelContext) throws {
        try seedDataService.seedIfNeeded(context: context)
        _ = try ensureDailyEntryExists(for: .now, context: context)
    }

    @discardableResult
    func ensureDailyEntryExists(for date: Date, context: ModelContext) throws -> DailyEntry {
        let key = DateUtilities.startOfDay(date)
        var descriptor = FetchDescriptor<DailyEntry>(predicate: #Predicate { $0.dateKey == key })
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let entry = DailyEntry(dateKey: key)
        context.insert(entry)
        try context.save()
        return entry
    }
}
