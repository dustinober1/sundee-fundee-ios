import Foundation
import SwiftData

@MainActor
final class CloudAIWorkoutService: AIWorkoutServiceProtocol {

    private let modelContext: ModelContext
    private let urlSession: URLSession

    init(modelContext: ModelContext, urlSession: URLSession = .shared) {
        self.modelContext = modelContext
        self.urlSession = urlSession
    }

    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let prompt = AppleIntelligenceWorkoutService.buildPrompt(context: context)
        let systemInstruction = "You are a strength training coach. Return a JSON object with two fields: coachingSummary (string) and exercises (array of objects with name, sets, reps, weightKg, restMinutes, notes, bodyweightOnly). reps must be a string like \"8\" or \"AMRAP\". Return ONLY valid JSON, no markdown fences."

        let token = try await CloudAIConfig.createJwt(
            userID: context.userID,
            tier: currentTier(for: context.userID)
        )

        guard let url = URL(string: CloudAIConfig.workerURL) else {
            throw AIWorkoutServiceError.networkError(0)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let body: [String: String] = [
            "prompt": prompt,
            "systemInstruction": systemInstruction,
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIWorkoutServiceError.networkError(0)
        }

        guard httpResponse.statusCode == 200 else {
            throw AIWorkoutServiceError.networkError(httpResponse.statusCode)
        }

        let cloudResponse = try JSONDecoder().decode(CloudWorkoutResponse.self, from: data)

        let questionnaire = QuestionnaireAnswers(
            timeMinutes: context.timeMinutes,
            focus: context.focus,
            energyLevel: context.energyLevel,
            equipment: context.equipment
        )

        let exercises = cloudResponse.exercises.map { ex in
            GeneratedExercise(
                name: ex.name,
                sets: ex.sets,
                reps: ex.reps,
                weightKg: ex.weightKg,
                restMinutes: ex.restMinutes,
                notes: ex.notes,
                bodyweightOnly: ex.bodyweightOnly
            )
        }

        let workout = GeneratedWorkout(
            coachingSummary: cloudResponse.coachingSummary,
            exercises: exercises,
            questionnaire: questionnaire
        )

        guard let record = GeneratedWorkoutRecord.from(workout, userID: context.userID) else {
            throw AIWorkoutServiceError.encodingFailed
        }
        modelContext.insert(record)
        try? modelContext.save()

        return workout
    }

    // MARK: - History & Favorites (delegate to same SwiftData store)

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

    // MARK: - Private

    private func currentTier(for userID: String) -> SubscriptionTier {
        // In production, this would come from AppState.
        // For now, return .plus as a safe default — the worker validates server-side.
        .plus
    }
}

// MARK: - Response Types

private struct CloudWorkoutResponse: Codable {
    let coachingSummary: String
    let exercises: [CloudExercise]
}

private struct CloudExercise: Codable {
    let name: String
    let sets: Int
    let reps: String
    let weightKg: Double?
    let restMinutes: Double?
    let notes: String?
    let bodyweightOnly: Bool
}
