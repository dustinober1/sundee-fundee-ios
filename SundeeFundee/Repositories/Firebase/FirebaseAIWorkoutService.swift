import Foundation

// MARK: - AIWorkoutServiceError

enum AIWorkoutServiceError: Error {
    case notAuthenticated
    case networkUnavailable
    case invalidResponse
    case serverError(String)
}

// MARK: - FirebaseAIWorkoutService

/// Cloud-backed AI workout service that calls a Firebase Cloud Function
/// to generate workouts via Claude API.
///
/// Falls back to `OfflineWorkoutGenerator` when the network is unavailable.
/// Stores generated workouts in Firestore for history and favorites.
final class FirebaseAIWorkoutService: AIWorkoutServiceProtocol, @unchecked Sendable {

    private var workoutHistory: [GeneratedWorkout] = []
    private let lock = NSLock()

    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        // TODO: Call Firebase Cloud Function when Firebase SDK is integrated
        // For now, use the offline generator
        let workout = OfflineWorkoutGenerator.generate(from: context)
        lock.withLock { workoutHistory.insert(workout, at: 0) }
        return workout
    }

    func fetchHistory(userID: String) async throws -> [GeneratedWorkout] {
        // TODO: Query Firestore when Firebase SDK is integrated
        lock.withLock { workoutHistory }
    }

    func toggleFavorite(workoutID: String, isFavorite: Bool) async throws {
        // TODO: Update Firestore when Firebase SDK is integrated
        lock.withLock {
            if let index = workoutHistory.firstIndex(where: { $0.id == workoutID }) {
                workoutHistory[index].isFavorite = isFavorite
            }
        }
    }

    func fetchFavorites(userID: String) async throws -> [GeneratedWorkout] {
        // TODO: Query Firestore when Firebase SDK is integrated
        lock.withLock { workoutHistory.filter(\.isFavorite) }
    }
}

// MARK: - OfflineAIWorkoutService

/// Pure offline implementation for use without network.
final class OfflineAIWorkoutService: AIWorkoutServiceProtocol, @unchecked Sendable {

    private var workoutHistory: [GeneratedWorkout] = []
    private let lock = NSLock()

    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let workout = OfflineWorkoutGenerator.generate(from: context)
        lock.withLock { workoutHistory.insert(workout, at: 0) }
        return workout
    }

    func fetchHistory(userID: String) async throws -> [GeneratedWorkout] {
        lock.withLock { workoutHistory }
    }

    func toggleFavorite(workoutID: String, isFavorite: Bool) async throws {
        lock.withLock {
            if let index = workoutHistory.firstIndex(where: { $0.id == workoutID }) {
                workoutHistory[index].isFavorite = isFavorite
            }
        }
    }

    func fetchFavorites(userID: String) async throws -> [GeneratedWorkout] {
        lock.withLock { workoutHistory.filter(\.isFavorite) }
    }
}
