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
        let descriptor = FetchDescriptor<BenchmarkDefinition>()
        return try context.fetch(descriptor)
    }

    func fetchUserCreated(userID: String) throws -> [BenchmarkDefinition] {
        let descriptor = FetchDescriptor<BenchmarkDefinition>(
            sortBy: [SortDescriptor(\.name)]
        )
        let all = try context.fetch(descriptor)
        return all.filter { !$0.isPredefined && $0.userID == userID }
    }

    func delete(_ definition: BenchmarkDefinition) throws {
        context.delete(definition)
        try context.save()
    }
}
