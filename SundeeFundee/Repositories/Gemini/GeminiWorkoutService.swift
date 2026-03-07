import Foundation

// MARK: - GeminiServiceError

enum GeminiServiceError: Error, Equatable {
    case httpError(statusCode: Int)
    case invalidResponse
}

// MARK: - GeminiWorkoutService

final class GeminiWorkoutService: Sendable {

    static let proxyURL = URL(string: "https://workout-proxy.sundeefundee.workers.dev/generate-workout")!

    private let session: URLSession
    private let timeoutInterval: TimeInterval

    init(session: URLSession = .shared, timeoutInterval: TimeInterval = 15) {
        self.session = session
        self.timeoutInterval = timeoutInterval
    }

    func generate(from context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let request = try buildRequest(from: context)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw GeminiServiceError.httpError(statusCode: httpResponse.statusCode)
        }

        let questionnaire = QuestionnaireAnswers(
            timeMinutes: context.timeMinutes,
            focus: context.focus,
            energyLevel: context.energyLevel,
            equipment: context.equipment
        )

        return try GeminiResponseParser.parse(data: data, questionnaire: questionnaire)
    }

    // MARK: - Private

    private func buildRequest(from context: WorkoutGenerationContext) throws -> URLRequest {
        let userPrompt = GeminiPromptBuilder.userPrompt(from: context)
        let systemPrompt = GeminiPromptBuilder.systemPrompt

        let body: [String: Any] = [
            "_userID": context.userID,
            "contents": [
                ["role": "user", "parts": [["text": userPrompt]]]
            ],
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": GeminiPromptBuilder.responseSchema
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: Self.proxyURL, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        return request
    }
}
