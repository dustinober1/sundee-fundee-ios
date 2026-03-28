import Foundation
import SwiftData

final class SwiftDataCustomProgramRepository: CustomProgramRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ record: CustomProgramRecord) throws {
        context.insert(record)
        try context.save()
    }

    func fetchAll(userID: String) throws -> [CustomProgramRecord] {
        let descriptor = FetchDescriptor<CustomProgramRecord>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetch(id: String) throws -> CustomProgramRecord? {
        let descriptor = FetchDescriptor<CustomProgramRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    func update(_ record: CustomProgramRecord) throws {
        record.updatedAt = .now
        try context.save()
    }

    func delete(_ record: CustomProgramRecord) throws {
        context.delete(record)
        try context.save()
    }
}
