import Foundation
import CloudKit

// MARK: - BenchmarkDefinitionDTO

/// Lightweight Codable struct for decoding benchmarks.json and CloudKit records.
/// Mapped to BenchmarkDefinition (SwiftData @Model) at the call site.
private struct BenchmarkDefinitionDTO: Codable {
    let id: String
    let name: String
    let category: String
    let workoutDescription: String
    let scoringTypeRaw: String
    let sortOrder: Int

    func toBenchmarkDefinition() -> BenchmarkDefinition {
        BenchmarkDefinition(
            id: id,
            userID: "",
            name: name,
            category: category,
            workoutDescription: workoutDescription,
            scoringType: BenchmarkScoringType(rawValue: scoringTypeRaw) ?? .time,
            isPredefined: true,
            sortOrder: sortOrder
        )
    }
}

// MARK: - BundledBenchmarkDefinitionRepository

/// Loads benchmark definitions from the bundled benchmarks.json file.
/// Caches the raw DTOs (not @Model instances) to avoid SwiftData data races.
final class BundledBenchmarkDefinitionRepository: RemoteBenchmarkDefinitionRepository {
    private let bundle: Bundle
    private let resourceName: String
    private var dtoCache: [BenchmarkDefinitionDTO]?

    init(bundle: Bundle = .main, resourceName: String = "benchmarks") {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    func fetchBenchmarkDefinitions() async throws -> [BenchmarkDefinition] {
        if let dtoCache { return dtoCache.map { $0.toBenchmarkDefinition() } }
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            return []
        }
        let data = try Data(contentsOf: url)
        let dtos = try JSONDecoder().decode([BenchmarkDefinitionDTO].self, from: data)
        dtoCache = dtos
        return dtos.map { $0.toBenchmarkDefinition() }
    }
}
