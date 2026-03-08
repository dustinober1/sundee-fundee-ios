import Foundation
import CloudKit

// MARK: - BundledWODRepository

/// Loads WODs bundled as JSON in the app target.
/// Used as the primary source when CloudKit is unavailable.
final class BundledWODRepository: WODRepository, @unchecked Sendable {
    private let bundle: Bundle
    private let resourceName: String
    private var cache: [WOD]?

    init(bundle: Bundle = .main, resourceName: String = "wods") {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    func fetchWODs() async throws -> [WOD] {
        if let cache { return cache }
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            return []
        }
        let data = try Data(contentsOf: url)
        let wods = try JSONDecoder().decode([WOD].self, from: data)
        cache = wods
        return wods
    }
}

// MARK: - CloudKitWODRepository

/// Fetches WODs from CloudKit Public Database.
/// Falls back to the bundled repository if CloudKit is unavailable.
final class CloudKitWODRepository: WODRepository, @unchecked Sendable {
    typealias CloudRecordFetcher = @Sendable (CKQuery) async throws -> [(CKRecord.ID, Result<CKRecord, Error>)]

    private let cloudFetcher: () async throws -> [WOD]
    private let fallback: WODRepository

    init(
        containerID: String = "iCloud.com.sundeefundee.app",
        fallback: WODRepository = BundledWODRepository(),
        cloudQueryExecutor: CloudRecordFetcher? = nil
    ) {
        self.fallback = fallback
        self.cloudFetcher = {
            try await Self.fetchFromCloudKit { query in
                if let cloudQueryExecutor {
                    return try await cloudQueryExecutor(query)
                }
                guard FileManager.default.ubiquityIdentityToken != nil else {
                    throw CKError(.notAuthenticated)
                }
                return try await CKContainer(identifier: containerID).publicCloudDatabase.records(matching: query).matchResults
            }
        }
    }

    init(
        fallback: WODRepository,
        cloudRecordFetcher: @escaping CloudRecordFetcher
    ) {
        self.fallback = fallback
        self.cloudFetcher = {
            try await Self.fetchFromCloudKit(cloudRecordFetcher)
        }
    }

    init(
        fallback: WODRepository,
        cloudFetcher: @escaping () async throws -> [WOD]
    ) {
        self.fallback = fallback
        self.cloudFetcher = cloudFetcher
    }

    func fetchWODs() async throws -> [WOD] {
        do {
            let wods = try await cloudFetcher()
            return Self.filterPublished(wods)
        } catch {
            let wods = try await fallback.fetchWODs()
            return Self.filterPublished(wods)
        }
    }

    static func filterPublished(_ wods: [WOD], now: Date = Date()) -> [WOD] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: now)
        return wods.filter { $0.status == "published" && $0.publishDate <= todayString }
    }

    private static func fetchFromCloudKit(_ cloudRecordFetcher: CloudRecordFetcher) async throws -> [WOD] {
        let query = CKQuery(recordType: "WOD", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let matchResults = try await cloudRecordFetcher(query)
        return try matchResults.compactMap { _, recordResult -> WOD? in
            let record = try recordResult.get()
            return try WOD(record: record)
        }
    }
}

// CKRecord → WOD decoding is now provided by SundeeFundeeShared
