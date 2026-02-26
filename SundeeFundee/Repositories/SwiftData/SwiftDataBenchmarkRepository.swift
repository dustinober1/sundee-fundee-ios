import Foundation
import SwiftData

final class SwiftDataBenchmarkRepository: BenchmarkRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ benchmark: Benchmark) throws {
        context.insert(benchmark)
        try context.save()
    }

    func fetchBenchmarks() throws -> [Benchmark] {
        let descriptor = FetchDescriptor<Benchmark>(
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchBenchmarks(named name: String) throws -> [Benchmark] {
        let descriptor = FetchDescriptor<Benchmark>(
            predicate: #Predicate { $0.name == name },
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func delete(_ benchmark: Benchmark) throws {
        context.delete(benchmark)
        try context.save()
    }
}
