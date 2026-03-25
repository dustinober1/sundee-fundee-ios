import Testing
import Foundation
@testable import SundeeFundee

@Suite("RemoteWorkoutResponse")
struct RemoteWorkoutResponseTests {

    static let sampleJSON = """
    {
      "coachingSummary": "Great session targeting posterior chain.",
      "exercises": [
        {
          "name": "Back Squat",
          "sets": 4,
          "reps": "5",
          "weightKg": 80.0,
          "restMinutes": 3.0,
          "notes": "Brace core",
          "reasoning": "Primary compound lift",
          "bodyweightOnly": false
        },
        {
          "name": "Pull-Up",
          "sets": 3,
          "reps": "AMRAP",
          "weightKg": null,
          "restMinutes": 2.0,
          "notes": null,
          "reasoning": null,
          "bodyweightOnly": true
        }
      ]
    }
    """.data(using: .utf8)!

    @Test func decodesValidJSON() throws {
        let response = try JSONDecoder().decode(RemoteWorkoutResponse.self, from: Self.sampleJSON)
        #expect(response.coachingSummary == "Great session targeting posterior chain.")
        #expect(response.exercises.count == 2)
        #expect(response.exercises[0].name == "Back Squat")
        #expect(response.exercises[0].sets == 4)
        #expect(response.exercises[0].weightKg == 80.0)
        #expect(response.exercises[1].bodyweightOnly == true)
        #expect(response.exercises[1].weightKg == nil)
    }

    @Test func mapsToGeneratedWorkout() throws {
        let response = try JSONDecoder().decode(RemoteWorkoutResponse.self, from: Self.sampleJSON)
        let questionnaire = QuestionnaireAnswers(
            timeMinutes: 45,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .fullGym
        )
        let workout = response.toGeneratedWorkout(questionnaire: questionnaire)

        #expect(!workout.id.isEmpty)
        #expect(workout.coachingSummary == "Great session targeting posterior chain.")
        #expect(workout.exercises.count == 2)
        #expect(workout.exercises[0].name == "Back Squat")
        #expect(workout.exercises[0].sets == 4)
        #expect(workout.exercises[0].reps == "5")
        #expect(workout.exercises[0].weightKg == 80.0)
        #expect(workout.exercises[0].bodyweightOnly == false)
        #expect(!workout.exercises[0].id.isEmpty)
        #expect(workout.exercises[1].name == "Pull-Up")
        #expect(workout.exercises[1].bodyweightOnly == true)
        #expect(workout.questionnaire == questionnaire)
        #expect(workout.isFavorite == false)
    }

    @Test func exerciseIDsAreUnique() throws {
        let response = try JSONDecoder().decode(RemoteWorkoutResponse.self, from: Self.sampleJSON)
        let questionnaire = QuestionnaireAnswers(timeMinutes: 30, focus: .push, energyLevel: .high, equipment: .fullGym)
        let workout = response.toGeneratedWorkout(questionnaire: questionnaire)

        let ids = workout.exercises.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func stripsMarkdownFences() throws {
        let wrapped = """
        ```json
        {"coachingSummary":"test","exercises":[]}
        ```
        """
        let cleaned = RemoteWorkoutResponse.stripMarkdownFences(wrapped)
        let response = try JSONDecoder().decode(RemoteWorkoutResponse.self, from: Data(cleaned.utf8))
        #expect(response.coachingSummary == "test")
        #expect(response.exercises.isEmpty)
    }
}
