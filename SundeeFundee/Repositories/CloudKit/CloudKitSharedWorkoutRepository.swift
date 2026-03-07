import Foundation
import CloudKit
import SwiftData

/// Fetches shared workouts from CloudKit Public DB and caches locally.
/// Falls back to cached results if CloudKit is unavailable.
final class CloudKitSharedWorkoutRepository: SharedWorkoutRepository, @unchecked Sendable {
    private let containerID: String
    private let modelContext: ModelContext

    init(containerID: String = "iCloud.com.sundeefundee.app", modelContext: ModelContext) {
        self.containerID = containerID
        self.modelContext = modelContext
    }

    /// Fetch shared workouts from CloudKit, with local cache fallback.
    func fetchShared(focus: String?, maxDuration: Int?) async throws -> [SharedWorkoutTemplate] {
        do {
            // Try CloudKit first
            return try await fetchFromCloudKit(focus: focus, maxDuration: maxDuration)
        } catch {
            // Fall back to cached results
            return fetchCached(focus: focus, maxDuration: maxDuration)
        }
    }

    /// Contribute a completed workout to CloudKit Public DB (anonymously).
    func contribute(_ workout: GeneratedWorkout, userID: String) async throws {
        let container = CKContainer(identifier: containerID)
        let publicDB = container.publicCloudDatabase

        guard let workoutJSON = try? JSONEncoder().encode(workout),
              let jsonString = String(data: workoutJSON, encoding: .utf8) else {
            throw RepositoryError.encodingFailed
        }

        let record = CKRecord(recordType: "SharedWorkoutTemplate")
        record["userID"] = ""  // Anonymous
        record["workoutJSON"] = jsonString
        record["focusRaw"] = workout.questionnaire.focus.rawValue
        record["durationMinutes"] = workout.totalEstimatedMinutes
        record["equipmentRaw"] = workout.questionnaire.equipment.rawValue
        record["createdAt"] = Date.now

        try await publicDB.save(record)

        // Cache locally
        let cached = SharedWorkoutTemplateRecord(
            id: record.recordID.recordName,
            userID: "",
            createdAt: Date.now,
            downloadedAt: Date.now,
            workoutJSON: jsonString,
            focusRaw: workout.questionnaire.focus.rawValue,
            durationMinutes: workout.totalEstimatedMinutes,
            equipmentRaw: workout.questionnaire.equipment.rawValue
        )
        modelContext.insert(cached)
        try? modelContext.save()
    }

    // MARK: - Private

    private func fetchFromCloudKit(focus: String?, maxDuration: Int?) async throws -> [SharedWorkoutTemplate] {
        let container = CKContainer(identifier: containerID)
        let publicDB = container.publicCloudDatabase

        var predicate = NSPredicate(value: true)
        if let focus = focus {
            predicate = NSPredicate(format: "focusRaw = %@", focus)
        }

        let query = CKQuery(recordType: "SharedWorkoutTemplate", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let matchResults = try await publicDB.records(matching: query)
        var templates: [SharedWorkoutTemplate] = []

        for (_, recordResult) in matchResults.matchResults {
            guard let record = try? recordResult.get() else { continue }

            guard let workoutJSON = record["workoutJSON"] as? String,
                  let jsonData = workoutJSON.data(using: .utf8),
                  let workout = try? JSONDecoder().decode(GeneratedWorkout.self, from: jsonData) else {
                continue
            }

            let duration = (record["durationMinutes"] as? Int) ?? workout.totalEstimatedMinutes
            if let maxDuration = maxDuration, duration > maxDuration { continue }

            let template = SharedWorkoutTemplate(
                id: record.recordID.recordName,
                workout: workout,
                durationMinutes: duration,
                downloadedAt: Date.now
            )
            templates.append(template)

            // Cache locally
            let cached = SharedWorkoutTemplateRecord(
                id: record.recordID.recordName,
                userID: record["userID"] as? String ?? "",
                createdAt: record["createdAt"] as? Date ?? Date.now,
                downloadedAt: Date.now,
                workoutJSON: workoutJSON,
                focusRaw: record["focusRaw"] as? String ?? "",
                durationMinutes: duration,
                equipmentRaw: record["equipmentRaw"] as? String ?? ""
            )
            modelContext.insert(cached)
        }

        try? modelContext.save()
        return templates
    }

    private func fetchCached(focus: String?, maxDuration: Int?) -> [SharedWorkoutTemplate] {
        let descriptor = FetchDescriptor<SharedWorkoutTemplateRecord>()
        let cached = (try? modelContext.fetch(descriptor)) ?? []

        return cached.compactMap { record in
            if let focus = focus, record.focusRaw != focus { return nil }
            if let maxDuration = maxDuration, record.durationMinutes > maxDuration { return nil }

            guard let jsonData = record.workoutJSON.data(using: .utf8),
                  let workout = try? JSONDecoder().decode(GeneratedWorkout.self, from: jsonData) else {
                return nil
            }

            return SharedWorkoutTemplate(
                id: record.id,
                workout: workout,
                durationMinutes: record.durationMinutes,
                downloadedAt: record.downloadedAt
            )
        }
    }
}

// MARK: - RepositoryError

enum RepositoryError: Error {
    case encodingFailed
    case decodingFailed
    case notFound
}
