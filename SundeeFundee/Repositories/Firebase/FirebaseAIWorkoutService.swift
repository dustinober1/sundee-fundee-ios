import Foundation
import SwiftData

// MARK: - AIWorkoutServiceError

enum AIWorkoutServiceError: Error {
    case notAuthenticated
    case encodingFailed
    case decodingFailed
    case networkError(Int)
    case noContent
}

// MARK: - GeminiResponseParser

enum GeminiResponseParser {
    struct GeminiResponse: Codable {
        struct Candidate: Codable {
            struct Content: Codable {
                struct Part: Codable {
                    let text: String
                }
                let parts: [Part]
            }
            let content: Content
        }
        let candidates: [Candidate]
    }

    static func extractText(from data: Data) throws -> String {
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = response.candidates.first?.content.parts.first?.text else {
            throw AIWorkoutServiceError.noContent
        }
        return text
    }
}

// MARK: - SwiftDataAIWorkoutService

final class SwiftDataAIWorkoutService: AIWorkoutServiceProtocol, @unchecked Sendable {

    private let modelContext: ModelContext
    private let workerURL: URL
    private let session: URLSession

    static let defaultWorkerURL = URL(string: "https://workout-proxy.sundeefundee.workers.dev/generate-workout")!

    init(
        modelContext: ModelContext,
        workerURL: URL = SwiftDataAIWorkoutService.defaultWorkerURL,
        session: URLSession = .shared
    ) {
        self.modelContext = modelContext
        self.workerURL = workerURL
        self.session = session
    }

    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let workout: GeneratedWorkout
        do {
            workout = try await generateRemotely(context: context)
        } catch {
            print("AI workout remote generation failed: \(error). Using offline generator.")
            workout = OfflineWorkoutGenerator.generate(from: context)
        }

        guard let record = GeneratedWorkoutRecord.from(workout, userID: context.userID) else {
            throw AIWorkoutServiceError.encodingFailed
        }
        modelContext.insert(record)
        try? modelContext.save()
        return workout
    }

    // MARK: - Remote Generation

    private func generateRemotely(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        var request = URLRequest(url: workerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let prompt = GeminiWorkoutPrompt.build(from: context)
        let body: [String: Any] = [
            "contents": [["role": "user", "parts": [["text": prompt]]]],
            "systemInstruction": ["parts": [["text": GeminiWorkoutPrompt.systemInstruction]]],
            "generationConfig": ["temperature": 0.7, "maxOutputTokens": 4096]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIWorkoutServiceError.networkError(
                (response as? HTTPURLResponse)?.statusCode ?? -1
            )
        }

        let rawText = try GeminiResponseParser.extractText(from: data)
        let cleaned = RemoteWorkoutResponse.stripMarkdownFences(rawText)
        let remoteResponse = try JSONDecoder().decode(RemoteWorkoutResponse.self, from: Data(cleaned.utf8))

        let questionnaire = QuestionnaireAnswers(
            timeMinutes: context.timeMinutes,
            focus: context.focus,
            energyLevel: context.energyLevel,
            equipment: context.equipment
        )
        return remoteResponse.toGeneratedWorkout(questionnaire: questionnaire)
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
