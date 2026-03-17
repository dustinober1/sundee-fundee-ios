import Foundation
import SwiftData

// MARK: - AIWorkoutServiceError

enum AIWorkoutServiceError: Error {
    case notAuthenticated
    case encodingFailed
    case decodingFailed
}

// MARK: - SwiftDataAIWorkoutService

/// AI workout service backed by SwiftData + CloudKit.
///
/// Generates workouts via `GeminiWorkoutService` when online, falling back
/// to `OfflineWorkoutGenerator` on any error. Persists results to the user's
/// CloudKit private database via SwiftData.
final class SwiftDataAIWorkoutService: AIWorkoutServiceProtocol, @unchecked Sendable {

    private let modelContext: ModelContext
    private let geminiService: GeminiWorkoutService
    private let sharedRepository: (any SharedWorkoutRepository)?

    init(
        modelContext: ModelContext,
        geminiService: GeminiWorkoutService = GeminiWorkoutService(),
        sharedRepository: (any SharedWorkoutRepository)? = nil
    ) {
        self.modelContext = modelContext
        self.geminiService = geminiService
        self.sharedRepository = sharedRepository
    }

    /// Builds the stripped workout for public contribution. Static for testability.
    static func buildContribution(from workout: GeneratedWorkout) -> GeneratedWorkout? {
        return workout.strippedForSharing()
    }

    static func generateWithFallback(
        context: WorkoutGenerationContext,
        geminiService: GeminiWorkoutService
    ) async -> GeneratedWorkout {
        do {
            return try await geminiService.generate(from: context)
        } catch {
            return OfflineWorkoutGenerator.generate(from: context)
        }
    }

    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let workout = await Self.generateWithFallback(context: context, geminiService: geminiService)
        guard let record = GeneratedWorkoutRecord.from(workout, userID: context.userID) else {
            throw AIWorkoutServiceError.encodingFailed
        }
        modelContext.insert(record)
        try? modelContext.save()

        // Fire-and-forget: contribute anonymized copy to public DB
        if let sharedRepository {
            Task.detached { [sharedRepository] in
                do {
                    try await sharedRepository.contribute(workout, userID: context.userID)
                } catch {
                    print("[AIWorkoutService] Public contribution failed: \(error)")
                }
            }
        }

        return workout
    }

    func fetchHistory(userID: String) async throws -> [GeneratedWorkout] {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        return records.compactMap { $0.toGeneratedWorkout() }
    }

    func toggleFavorite(workoutID: String, isFavorite: Bool) async throws {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.id == workoutID }
        )
        guard let record = try? modelContext.fetch(descriptor).first else { return }
        record.isFavorite = isFavorite
        try? modelContext.save()
    }

    func fetchFavorites(userID: String) async throws -> [GeneratedWorkout] {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.userID == userID && $0.isFavorite == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        return records.compactMap { $0.toGeneratedWorkout() }
    }

    func deleteWorkout(workoutID: String) async throws {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.id == workoutID }
        )
        guard let record = try? modelContext.fetch(descriptor).first else { return }
        modelContext.delete(record)
        try? modelContext.save()
    }
}
