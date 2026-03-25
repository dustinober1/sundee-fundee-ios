import Foundation

struct RemoteWorkoutResponse: Codable, Sendable {
    let coachingSummary: String
    let exercises: [RemoteExercise]

    func toGeneratedWorkout(questionnaire: QuestionnaireAnswers) -> GeneratedWorkout {
        GeneratedWorkout(
            coachingSummary: coachingSummary,
            exercises: exercises.map { $0.toGeneratedExercise() },
            questionnaire: questionnaire
        )
    }

    static func stripMarkdownFences(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^```(?:json)?\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*```$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct RemoteExercise: Codable, Sendable {
    let name: String
    let sets: Int
    let reps: String
    let weightKg: Double?
    let restMinutes: Double?
    let notes: String?
    let reasoning: String?
    let bodyweightOnly: Bool?

    func toGeneratedExercise() -> GeneratedExercise {
        GeneratedExercise(
            name: name,
            sets: sets,
            reps: reps,
            weightKg: weightKg,
            restMinutes: restMinutes,
            notes: notes,
            reasoning: reasoning,
            bodyweightOnly: bodyweightOnly ?? false
        )
    }
}
