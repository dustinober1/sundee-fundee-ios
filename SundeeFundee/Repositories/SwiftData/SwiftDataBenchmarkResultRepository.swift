import Foundation
import SwiftData

final class SwiftDataBenchmarkResultRepository: BenchmarkResultRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ result: BenchmarkResult) throws {
        context.insert(result)
        try context.save()
    }

    func fetchResults(forDefinitionID definitionID: String) throws -> [BenchmarkResult] {
        let descriptor = FetchDescriptor<BenchmarkResult>(
            predicate: #Predicate { $0.definitionID == definitionID },
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func delete(_ result: BenchmarkResult) throws {
        context.delete(result)
        try context.save()
    }
}
