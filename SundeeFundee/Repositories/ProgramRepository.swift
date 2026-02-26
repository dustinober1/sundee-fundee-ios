import Foundation
import CloudKit

// MARK: - BundledProgramRepository

/// Loads programs bundled as JSON in the app target.
/// Used as the primary source when CloudKit is unavailable.
final class BundledProgramRepository: ProgramRepository, @unchecked Sendable {
    private var cache: [Program]?

    func fetchPrograms() async throws -> [Program] {
        if let cache { return cache }
        guard let url = Bundle.main.url(forResource: "programs", withExtension: "json") else {
            return []
        }
        let data = try Data(contentsOf: url)
        let programs = try JSONDecoder().decode([Program].self, from: data)
        cache = programs
        return programs
    }

    func fetchProgram(id: String) async throws -> Program? {
        let all = try await fetchPrograms()
        return all.first { $0.id == id }
    }
}

// MARK: - CloudKitProgramRepository

/// Fetches programs from CloudKit Public Database.
/// Falls back to the bundled repository if CloudKit is unavailable.
final class CloudKitProgramRepository: ProgramRepository, @unchecked Sendable {
    private let container: CKContainer
    private let fallback: BundledProgramRepository

    init(containerID: String = "iCloud.com.sundeefundee.app") {
        container = CKContainer(identifier: containerID)
        fallback = BundledProgramRepository()
    }

    func fetchPrograms() async throws -> [Program] {
        do {
            return try await fetchFromCloudKit()
        } catch {
            // Fall back to bundled programs when CloudKit is unavailable
            return try await fallback.fetchPrograms()
        }
    }

    func fetchProgram(id: String) async throws -> Program? {
        let all = try await fetchPrograms()
        return all.first { $0.id == id }
    }

    private func fetchFromCloudKit() async throws -> [Program] {
        let publicDB = container.publicCloudDatabase
        let query = CKQuery(recordType: "Program", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let result = try await publicDB.records(matching: query)
        return try result.matchResults.compactMap { _, recordResult -> Program? in
            let record = try recordResult.get()
            return try Program(from: record)
        }
    }
}

// MARK: - CKRecord → Program decoding

extension Program {
    init(from record: CKRecord) throws {
        guard
            let id = record["id"] as? String,
            let name = record["name"] as? String,
            let category = record["category"] as? String,
            let description = record["description"] as? String,
            let durationWeeks = record["durationWeeks"] as? Int,
            let sessionsPerWeek = record["sessionsPerWeek"] as? Int,
            let difficulty = record["difficulty"] as? String,
            let weeksJSON = record["weeksJSON"] as? String,
            let weeksData = weeksJSON.data(using: .utf8)
        else {
            throw ProgramDecodingError.missingFields
        }

        let weeks = try JSONDecoder().decode([ProgramWeek].self, from: weeksData)

        var adjustmentProfile: ProgramCycleAdjustmentProfile?
        if let profileJSON = record["cycleAdjustmentProfileJSON"] as? String,
           let profileData = profileJSON.data(using: .utf8) {
            adjustmentProfile = try? JSONDecoder().decode(ProgramCycleAdjustmentProfile.self, from: profileData)
        }

        var phases: [ProgramPhase] = []
        if let phasesJSON = record["phasesJSON"] as? String,
           let phasesData = phasesJSON.data(using: .utf8) {
            phases = (try? JSONDecoder().decode([ProgramPhase].self, from: phasesData)) ?? []
        }

        self.init(
            id: id,
            name: name,
            category: category,
            description: description,
            durationWeeks: durationWeeks,
            sessionsPerWeek: sessionsPerWeek,
            difficulty: difficulty,
            phases: phases,
            weeks: weeks,
            cycleAdjustmentProfile: adjustmentProfile
        )
    }
}

enum ProgramDecodingError: Error {
    case missingFields
}
