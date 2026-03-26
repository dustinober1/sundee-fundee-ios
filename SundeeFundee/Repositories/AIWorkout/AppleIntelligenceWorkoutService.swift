import Foundation
import SwiftData
import FoundationModels

// MARK: - AIWorkoutServiceError

enum AIWorkoutServiceError: Error {
    case notAuthenticated
    case encodingFailed
    case decodingFailed
    case networkError(Int)
    case noContent
}

// MARK: - AppleIntelligenceWorkoutService

final class AppleIntelligenceWorkoutService: AIWorkoutServiceProtocol, @unchecked Sendable {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let workout: GeneratedWorkout

        if await supportsOnDeviceGeneration() {
            do {
                workout = try await generateWithFoundationModels(context: context)
            } catch {
                print("Foundation Models generation failed: \(error). Using offline generator.")
                workout = OfflineWorkoutGenerator.generate(from: context)
            }
        } else {
            workout = OfflineWorkoutGenerator.generate(from: context)
        }

        guard let record = GeneratedWorkoutRecord.from(workout, userID: context.userID) else {
            throw AIWorkoutServiceError.encodingFailed
        }
        modelContext.insert(record)
        try? modelContext.save()
        return workout
    }

    // MARK: - Foundation Models

    private func supportsOnDeviceGeneration() async -> Bool {
        SystemLanguageModel.default.isAvailable
    }

    private func generateWithFoundationModels(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let prompt = Self.buildPrompt(context: context)
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt, generating: AIWorkoutOutput.self)
        let output = response.content

        guard !output.exercises.isEmpty else {
            return OfflineWorkoutGenerator.generate(from: context)
        }

        return WorkoutPostProcessor.process(raw: output, context: context)
    }

    static func buildPrompt(context: WorkoutGenerationContext) -> String {
        var parts: [String] = [
            "Design a \(context.timeMinutes)-minute \(context.focus.displayName) workout.",
            "Energy level: \(context.energyLevel.displayName).",
            "Equipment: \(context.equipment.displayName).",
            "Experience: \(context.experienceLevel). Goal: \(context.primaryGoal)."
        ]
        if !context.activeInjuries.isEmpty {
            let injuryNotes = context.activeInjuries.map {
                "\($0.location) (\($0.phase)): \($0.restrictions.joined(separator: ", "))"
            }
            parts.append("IMPORTANT — Active injuries, do NOT prescribe exercises that aggravate these: \(injuryNotes.joined(separator: "; "))")
        }
        return parts.joined(separator: " ")
    }

    // MARK: - History & Favorites

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
}
