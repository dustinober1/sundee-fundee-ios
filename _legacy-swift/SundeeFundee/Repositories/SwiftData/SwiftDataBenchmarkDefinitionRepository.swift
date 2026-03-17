import Foundation
import SwiftData

final class SwiftDataBenchmarkDefinitionRepository: BenchmarkDefinitionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ definition: BenchmarkDefinition) throws {
        context.insert(definition)
        try context.save()
    }

    func fetchAll() throws -> [BenchmarkDefinition] {
        let descriptor = FetchDescriptor<BenchmarkDefinition>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func fetchUserCreated(userID: String) throws -> [BenchmarkDefinition] {
        let descriptor = FetchDescriptor<BenchmarkDefinition>(
            predicate: #Predicate { $0.isPredefined == false && $0.userID == userID },
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func delete(_ definition: BenchmarkDefinition) throws {
        context.delete(definition)
        try context.save()
    }
}
