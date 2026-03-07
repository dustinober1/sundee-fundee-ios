import Foundation

// MARK: - GeminiParseError

enum GeminiParseError: Error {
    case emptyCandidates
    case missingContent
    case invalidWorkoutJSON
}

// MARK: - GeminiResponseParser

enum GeminiResponseParser {

    // MARK: - Public API

    static func parse(data: Data, questionnaire: QuestionnaireAnswers) throws -> GeneratedWorkout {
        let text = try extractText(from: data)
        let rawWorkout = try decodeWorkout(from: text)
        return mapToGeneratedWorkout(rawWorkout, questionnaire: questionnaire)
    }

    // MARK: - Private Helpers

    private struct RawGeminiWorkout: Decodable {
        let coachingSummary: String
        let exercises: [RawGeminiExercise]
    }

    private struct RawGeminiExercise: Decodable {
        let name: String
        let sets: Int
        let reps: String
        let weightKg: Double?
        let restMinutes: Double?
        let notes: String?
        let reasoning: String?
        let bodyweightOnly: Bool
    }

    private static func extractText(from data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]] else {
            throw GeminiParseError.missingContent
        }

        guard let firstCandidate = candidates.first else {
            throw GeminiParseError.emptyCandidates
        }

        guard let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiParseError.missingContent
        }

        return text
    }

    private static func decodeWorkout(from text: String) throws -> RawGeminiWorkout {
        guard let textData = text.data(using: .utf8) else {
            throw GeminiParseError.invalidWorkoutJSON
        }

        do {
            return try JSONDecoder().decode(RawGeminiWorkout.self, from: textData)
        } catch {
            throw GeminiParseError.invalidWorkoutJSON
        }
    }

    private static func mapToGeneratedWorkout(
        _ raw: RawGeminiWorkout,
        questionnaire: QuestionnaireAnswers
    ) -> GeneratedWorkout {
        let exercises = raw.exercises.map { rawExercise in
            GeneratedExercise(
                id: UUID().uuidString,
                name: rawExercise.name,
                sets: rawExercise.sets,
                reps: rawExercise.reps,
                weightKg: rawExercise.weightKg,
                restMinutes: rawExercise.restMinutes,
                notes: rawExercise.notes,
                reasoning: rawExercise.reasoning,
                bodyweightOnly: rawExercise.bodyweightOnly
            )
        }

        return GeneratedWorkout(
            coachingSummary: raw.coachingSummary,
            exercises: exercises,
            questionnaire: questionnaire
        )
    }
}
