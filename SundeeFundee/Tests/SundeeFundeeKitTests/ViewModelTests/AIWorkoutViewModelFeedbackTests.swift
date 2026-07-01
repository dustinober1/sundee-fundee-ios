import XCTest
@testable import SundeeFundeeKit

@MainActor
final class AIWorkoutViewModelFeedbackTests: XCTestCase {
    func testSubmitFeedbackSavesMetadataAndTracksEvent() async throws {
        let client = MockCloudKitClient()
        let viewModel = AIWorkoutViewModel(
            coachService: DeterministicCoachService(),
            contextBuilder: CoachContextBuilder(
                healthClient: MockHealthKitClient(),
                dataClient: client
            ),
            memoryService: CoachMemoryService(dataClient: client),
            dataClient: client
        )
        viewModel.generatedWorkout = GeneratedWorkout(
            id: "generated-1",
            createdAt: Date(),
            isFavorite: false,
            coachingSummary: "Coach Plan",
            exercises: [
                GeneratedExercise(id: "ex-1", name: "Goblet Squat", sets: 3, reps: "8")
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 30,
                focus: .fullBody,
                energyLevel: .low,
                equipment: .homeDumbbells
            )
        )
        viewModel.workoutRationale = WorkoutRationale(
            headline: "Lower volume today",
            reasons: ["Low energy reduced volume"],
            cautions: ["Dumbbell-only equipment"]
        )

        await viewModel.submitFeedback(.notHelpful)

        XCTAssertEqual(viewModel.submittedFeedback, .notHelpful)

        let feedback: [CoachPlanFeedbackRecord] = try await client.fetchAll(recordType: "CoachPlanFeedback")
        XCTAssertEqual(feedback.count, 1)
        XCTAssertEqual(feedback.first?.ratingRaw, "notHelpful")
        XCTAssertEqual(feedback.first?.surface, "coach_plan_preview")
        XCTAssertEqual(feedback.first?.workoutID, "generated-1")
        XCTAssertEqual(feedback.first?.copySource, "coach_plan_copy")
        XCTAssertEqual(feedback.first?.promptVersion, "v1")
        XCTAssertEqual(
            feedback.first?.reasonCodesJSON,
            "[\"Lower volume today\",\"Low energy reduced volume\",\"Dumbbell-only equipment\"]"
        )
        XCTAssertNil(feedback.first?.rawPrompt)
        XCTAssertNil(feedback.first?.rawOutput)

        let events: [GrowthEvent] = try await client.fetchAll(recordType: "GrowthEvent")
        XCTAssertEqual(events.map(\.name), [GrowthEventName.coachPlanFeedbackNotHelpful])
    }
}
