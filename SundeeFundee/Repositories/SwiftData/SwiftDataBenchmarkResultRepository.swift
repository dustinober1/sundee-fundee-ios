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
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )
        let all = try context.fetch(descriptor)
        return all.filter { $0.definitionID == definitionID }
    }

    func delete(_ result: BenchmarkResult) throws {
        context.delete(result)
        try context.save()
    }
}
