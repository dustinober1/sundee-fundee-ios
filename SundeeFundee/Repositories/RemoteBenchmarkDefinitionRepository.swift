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
final class BundledBenchmarkDefinitionRepository: RemoteBenchmarkDefinitionRepository, @unchecked Sendable {
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

// MARK: - CloudKitBenchmarkDefinitionRepository

/// Fetches benchmark definitions from CloudKit Public Database.
/// Falls back to the bundled repository if CloudKit is unavailable or returns empty.
final class CloudKitBenchmarkDefinitionRepository: RemoteBenchmarkDefinitionRepository {
    typealias CloudRecordFetcher = @Sendable (CKQuery) async throws -> [(CKRecord.ID, Result<CKRecord, Error>)]

    private let cloudFetcher: @Sendable () async throws -> [BenchmarkDefinition]
    private let fallback: any RemoteBenchmarkDefinitionRepository

    init(
        containerID: String = "iCloud.com.sundeefundee.app",
        fallback: any RemoteBenchmarkDefinitionRepository = BundledBenchmarkDefinitionRepository(),
        cloudQueryExecutor: CloudRecordFetcher? = nil
    ) {
        self.fallback = fallback
        self.cloudFetcher = {
            if let cloudQueryExecutor {
                return try await Self.fetchFromCloudKit(cloudQueryExecutor)
            }
            guard CloudKitWODRepository.hasCloudKitEntitlement else {
                throw CKError(.notAuthenticated)
            }
            return try await Self.fetchFromCloudKit { query in
                return try await CKContainer(identifier: containerID).publicCloudDatabase.records(matching: query).matchResults
            }
        }
    }

    init(
        fallback: any RemoteBenchmarkDefinitionRepository,
        cloudRecordFetcher: @escaping CloudRecordFetcher
    ) {
        self.fallback = fallback
        self.cloudFetcher = {
            try await Self.fetchFromCloudKit(cloudRecordFetcher)
        }
    }

    init(
        fallback: any RemoteBenchmarkDefinitionRepository,
        cloudFetcher: @escaping @Sendable () async throws -> [BenchmarkDefinition]
    ) {
        self.fallback = fallback
        self.cloudFetcher = cloudFetcher
    }

    func fetchBenchmarkDefinitions() async throws -> [BenchmarkDefinition] {
        do {
            let defs = try await cloudFetcher()
            if defs.isEmpty {
                return try await fallback.fetchBenchmarkDefinitions()
            }
            return defs
        } catch {
            return try await fallback.fetchBenchmarkDefinitions()
        }
    }

    private static func fetchFromCloudKit(_ cloudRecordFetcher: CloudRecordFetcher) async throws -> [BenchmarkDefinition] {
        let query = CKQuery(recordType: "BenchmarkDefinition", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

        let matchResults = try await cloudRecordFetcher(query)
        return matchResults.compactMap { _, recordResult -> BenchmarkDefinition? in
            guard let record = try? recordResult.get(),
                  let id = record["id"] as? String,
                  let name = record["name"] as? String,
                  let category = record["category"] as? String,
                  let workoutDescription = record["workoutDescription"] as? String,
                  let scoringTypeRaw = record["scoringTypeRaw"] as? String,
                  let sortOrder = (record["sortOrder"] as? Int64).map(Int.init)
            else { return nil }
            return BenchmarkDefinition(
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
}
