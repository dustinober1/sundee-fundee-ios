import Foundation
import SwiftData

final class SwiftDataPainLogRepository: PainLogRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ log: PainLog) throws {
        context.insert(log)
        try context.save()
    }

    func fetchLogs(injuryProfileID: String) throws -> [PainLog] {
        let descriptor = FetchDescriptor<PainLog>(
            predicate: #Predicate { $0.injuryProfileID == injuryProfileID },
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchAllLogs() throws -> [PainLog] {
        let descriptor = FetchDescriptor<PainLog>(
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
