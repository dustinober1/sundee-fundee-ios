import Testing
import Foundation
@testable import SundeeFundee

@Suite("GeminiResponseParser")
struct GeminiResponseParserTests {

    // MARK: - Helpers

    private let sampleQuestionnaire = QuestionnaireAnswers(
        timeMinutes: 45,
        focus: .fullBody,
        energyLevel: .medium,
        equipment: .fullGym
    )

    private func makeGeminiResponse(text: String) -> Data {
        let json: [String: Any] = [
            "candidates": [
                [
                    "content": [
                        "parts": [
                            ["text": text]
                        ]
                    ]
                ]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func makeWorkoutJSON(
        coachingSummary: String = "Great workout plan.",
        exercises: [[String: Any]]? = nil
    ) -> String {
        let defaultExercises: [[String: Any]] = [
            [
                "name": "Barbell Squat",
                "sets": 4,
                "reps": "8-10",
                "weightKg": 60.0,
                "restMinutes": 2.0,
                "notes": "Keep your core tight.",
                "reasoning": "Compound lower body movement.",
                "bodyweightOnly": false
            ]
        ]
        let workout: [String: Any] = [
            "coachingSummary": coachingSummary,
            "exercises": exercises ?? defaultExercises
        ]
        let data = try! JSONSerialization.data(withJSONObject: workout)
        return String(data: data, encoding: .utf8)!
    }

    // MARK: - Valid Response Tests

    @Test func parsesValidResponseWithWeightedExercise() throws {
        let workoutText = makeWorkoutJSON()
        let data = makeGeminiResponse(text: workoutText)

        let workout = try GeminiResponseParser.parse(
            data: data,
            questionnaire: sampleQuestionnaire
        )

        #expect(workout.coachingSummary == "Great workout plan.")
        #expect(workout.exercises.count == 1)

        let exercise = workout.exercises[0]
        #expect(exercise.name == "Barbell Squat")
        #expect(exercise.sets == 4)
        #expect(exercise.reps == "8-10")
        #expect(exercise.weightKg == 60.0)
        #expect(exercise.restMinutes == 2.0)
        #expect(exercise.notes == "Keep your core tight.")
        #expect(exercise.reasoning == "Compound lower body movement.")
        #expect(exercise.bodyweightOnly == false)
    }

    @Test func parsesBodyweightExercise() throws {
        let exercises: [[String: Any]] = [
            [
                "name": "Push-ups",
                "sets": 3,
                "reps": "AMRAP",
                "bodyweightOnly": true,
                "reasoning": "Upper body pushing movement."
            ]
        ]
        let workoutText = makeWorkoutJSON(exercises: exercises)
        let data = makeGeminiResponse(text: workoutText)

        let workout = try GeminiResponseParser.parse(
            data: data,
            questionnaire: sampleQuestionnaire
        )

        let exercise = workout.exercises[0]
        #expect(exercise.name == "Push-ups")
        #expect(exercise.weightKg == nil)
        #expect(exercise.restMinutes == nil)
        #expect(exercise.notes == nil)
        #expect(exercise.bodyweightOnly == true)
    }

    // MARK: - Error Cases

    @Test func throwsEmptyCandidatesOnEmptyArray() {
        let json: [String: Any] = ["candidates": [Any]()]
        let data = try! JSONSerialization.data(withJSONObject: json)

        #expect(throws: GeminiParseError.emptyCandidates) {
            try GeminiResponseParser.parse(
                data: data,
                questionnaire: sampleQuestionnaire
            )
        }
    }

    @Test func throwsOnMalformedData() {
        let data = "not json at all".data(using: .utf8)!

        #expect(throws: GeminiParseError.missingContent) {
            try GeminiResponseParser.parse(
                data: data,
                questionnaire: sampleQuestionnaire
            )
        }
    }

    @Test func throwsOnInvalidWorkoutJSON() {
        let data = makeGeminiResponse(text: "this is not valid json")

        #expect(throws: GeminiParseError.invalidWorkoutJSON) {
            try GeminiResponseParser.parse(
                data: data,
                questionnaire: sampleQuestionnaire
            )
        }
    }

    // MARK: - Metadata Tests

    @Test func assignsUniqueUUIDsToExercises() throws {
        let exercises: [[String: Any]] = [
            [
                "name": "Squat",
                "sets": 3,
                "reps": "5",
                "bodyweightOnly": false
            ],
            [
                "name": "Bench Press",
                "sets": 3,
                "reps": "5",
                "bodyweightOnly": false
            ]
        ]
        let workoutText = makeWorkoutJSON(exercises: exercises)
        let data = makeGeminiResponse(text: workoutText)

        let workout = try GeminiResponseParser.parse(
            data: data,
            questionnaire: sampleQuestionnaire
        )

        #expect(workout.exercises.count == 2)
        #expect(workout.exercises[0].id != workout.exercises[1].id)
        // Verify they are valid UUID strings
        #expect(UUID(uuidString: workout.exercises[0].id) != nil)
        #expect(UUID(uuidString: workout.exercises[1].id) != nil)
    }

    @Test func returnedWorkoutHasCorrectMetadata() throws {
        let workoutText = makeWorkoutJSON()
        let data = makeGeminiResponse(text: workoutText)

        let workout = try GeminiResponseParser.parse(
            data: data,
            questionnaire: sampleQuestionnaire
        )

        #expect(UUID(uuidString: workout.id) != nil)
        #expect(workout.isFavorite == false)
        #expect(workout.questionnaire == sampleQuestionnaire)
    }
}
