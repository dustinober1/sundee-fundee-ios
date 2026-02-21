import Foundation
import CloudKit

/// Fetches admin-pushed workout programs from the CloudKit public database.
///
/// **CloudKit record schema (set up in CloudKit Dashboard):**
/// - Record type: `Program`
/// - Fields:
///   - `programId`   (String)  — unique identifier, maps to ProgramV2.id
///   - `name`        (String)
///   - `category`    (String)  — e.g. "strength", "conditioning"
///   - `description` (String)
///   - `durationWeeks`    (Int64)
///   - `sessionsPerWeek`  (Int64)
///   - `difficulty`  (String)  — "beginner" / "intermediate" / "advanced"
///   - `programJSON` (String)  — full ProgramV2-compatible JSON, must include
///                              `phases` and `weeks` arrays matching ProgramV2 schema
///
/// The admin creates / updates these records in the CloudKit Dashboard
/// (https://icloud.developer.apple.com) under the app's public database.
final class CloudKitProgramService {
    static let shared = CloudKitProgramService()

    private let container = CKContainer(identifier: "iCloud.com.sundeefundee.app")
    private let cacheKey = "cached_public_programs"
    private let cacheExpiryKey = "cached_public_programs_expiry"
    /// Cache TTL: 6 hours
    private let cacheTTL: TimeInterval = 6 * 60 * 60

    private init() {}

    // MARK: - Public API

    /// Fetches programs from the CloudKit public database.
    /// Returns cached results if cache is fresh; falls back to cache on network errors.
    func fetchPublicPrograms() async throws -> [ProgramV2] {
        if let cached = loadCache(), !isCacheExpired() {
            return cached
        }

        do {
            let programs = try await fetchFromCloudKit()
            saveCache(programs)
            return programs
        } catch {
            if let cached = loadCache() {
                return cached
            }
            throw error
        }
    }

    // MARK: - CloudKit Fetch

    private func fetchFromCloudKit() async throws -> [ProgramV2] {
        let db = container.publicCloudDatabase
        let query = CKQuery(recordType: "Program", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let result = try await db.records(matching: query, resultsLimit: 200)
        var programs: [ProgramV2] = []

        for (_, recordResult) in result.matchResults {
            if let record = try? recordResult.get(),
               let program = programV2(from: record) {
                programs.append(program)
            }
        }
        return programs
    }

    private func programV2(from record: CKRecord) -> ProgramV2? {
        guard
            let jsonString = record["programJSON"] as? String,
            let data = jsonString.data(using: .utf8)
        else { return nil }

        return try? JSONDecoder().decode(ProgramV2.self, from: data)
    }

    // MARK: - Cache

    private func loadCache() -> [ProgramV2]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode([ProgramV2].self, from: data)
    }

    private func saveCache(_ programs: [ProgramV2]) {
        if let data = try? JSONEncoder().encode(programs) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970 + cacheTTL, forKey: cacheExpiryKey)
        }
    }

    private func isCacheExpired() -> Bool {
        let expiry = UserDefaults.standard.double(forKey: cacheExpiryKey)
        return Date().timeIntervalSince1970 > expiry
    }
}
