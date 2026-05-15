import XCTest
@testable import SundeeFundeeKit

final class OnDeviceCoachServiceTests: XCTestCase {
    func testAcceptedCopyUpdatesOnlySummaryTipsAndMetadata() async throws {
        let service = OnDeviceCoachService(fallback: FixedCoachService(), copyEditor: AcceptingFakeCopyEditor(), configuration: CoachAIConfiguration())
        let response = try await service.generateWorkout(context: CoachContext(), preferences: Self.preferences)
        XCTAssertEqual(response.copySource, .onDeviceAIAccepted)
        XCTAssertEqual(response.coachingSummary, "Friendly copy fits today. Movement stays focused.")
        XCTAssertEqual(response.tips, ["Base tip."])
        XCTAssertEqual(response.workout.exercises, Self.baseWorkout.exercises)
        XCTAssertEqual(response.workout.questionnaire, Self.baseWorkout.questionnaire)
        XCTAssertEqual(response.workout.id, Self.baseWorkout.id)
        XCTAssertEqual(response.workout.createdAt, Self.baseWorkout.createdAt)
        XCTAssertEqual(response.workout.isFavorite, Self.baseWorkout.isFavorite)
    }

    func testHallucinatedExerciseFallsBack() async throws {
        let service = OnDeviceCoachService(fallback: FixedCoachService(), copyEditor: HallucinatingExerciseFakeCopyEditor(), configuration: CoachAIConfiguration())
        let response = try await service.generateWorkout(context: CoachContext(), preferences: Self.preferences)
        XCTAssertEqual(response.copySource, .onDeviceAIRejectedFallback)
        XCTAssertEqual(response.workout.exercises, Self.baseWorkout.exercises)
        XCTAssertEqual(response.workout.questionnaire, Self.baseWorkout.questionnaire)
    }

    func testMedicalAdviceFallsBack() async throws {
        let service = OnDeviceCoachService(fallback: FixedCoachService(), copyEditor: MedicalAdviceFakeCopyEditor(), configuration: CoachAIConfiguration())
        let response = try await service.generateWorkout(context: CoachContext(), preferences: Self.preferences)
        XCTAssertEqual(response.copySource, .onDeviceAIRejectedFallback)
        XCTAssertEqual(response.workout.exercises, Self.baseWorkout.exercises)
    }

    func testThrownErrorFallsBackUnavailable() async throws {
        let service = OnDeviceCoachService(fallback: FixedCoachService(), copyEditor: ThrowingFakeCopyEditor(), configuration: CoachAIConfiguration())
        let response = try await service.generateWorkout(context: CoachContext(), preferences: Self.preferences)
        XCTAssertEqual(response.copySource, .onDeviceAIUnavailableFallback)
        XCTAssertEqual(response.workout.exercises, Self.baseWorkout.exercises)
    }

    func testModelSuppliedTipsAreRejectedForSummaryOnlyCopy() async throws {
        let service = OnDeviceCoachService(fallback: FixedCoachService(), copyEditor: TipSupplyingFakeCopyEditor(), configuration: CoachAIConfiguration())
        let response = try await service.generateWorkout(context: CoachContext(), preferences: Self.preferences)
        XCTAssertEqual(response.copySource, .onDeviceAIRejectedFallback)
        XCTAssertEqual(response.tips, ["Base tip."])
        XCTAssertEqual(response.workout.exercises, Self.baseWorkout.exercises)
    }

    fileprivate static let preferences = QuestionnaireAnswers(timeMinutes: 30, focus: .fullBody, energyLevel: .medium, equipment: .fullGym)
    fileprivate static let baseWorkout = GeneratedWorkout(
        id: "base",
        createdAt: Date(timeIntervalSince1970: 1_000),
        isFavorite: false,
        coachingSummary: "Deterministic summary.",
        exercises: [GeneratedExercise(id: "e1", name: "Push-Up", sets: 3, reps: "8", restMinutes: 1.0, bodyweightOnly: true)],
        questionnaire: preferences
    )
}

private struct FixedCoachService: CoachServiceProtocol {
    func generateWorkout(context: CoachContext, preferences: QuestionnaireAnswers) async throws -> CoachWorkoutResponse {
        CoachWorkoutResponse(workout: OnDeviceCoachServiceTests.baseWorkout, coachingSummary: OnDeviceCoachServiceTests.baseWorkout.coachingSummary, tips: ["Base tip."])
    }
    func getInsights(context: CoachContext) async throws -> CoachInsightsResponse {
        CoachInsightsResponse(plateaus: [], trends: [], summary: "Base insights.", priorityActions: [])
    }
    func suggestSubstitutions(for exercise: String, context: CoachContext) async throws -> CoachSubstitutionResponse {
        CoachSubstitutionResponse(originalExercise: exercise, substitutions: [], explanation: "Deterministic.")
    }
    func adaptWeeklyPlan(plan: [ScheduleReshuffler.PlannedSession], completedDays: Set<Int>, missedDays: Set<Int>, currentDay: Int, context: CoachContext) async throws -> CoachPlanResponse {
        throw CoachCopyEditingError.unavailable
    }
}

private struct AcceptingFakeCopyEditor: CoachCopyEditing {
    func rewriteWorkoutSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate {
        CoachCopyCandidate(summary: "Friendly copy fits today. Movement stays focused.", promptVersion: packet.promptVersion)
    }
    func rewriteInsightsSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { CoachCopyCandidate(summary: "Insights look steady.", promptVersion: packet.promptVersion) }
    func rewritePlanExplanation(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { CoachCopyCandidate(summary: "Plan is adjusted.", promptVersion: packet.promptVersion) }
}

private struct HallucinatingExerciseFakeCopyEditor: CoachCopyEditing {
    func rewriteWorkoutSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { CoachCopyCandidate(summary: "Back Squat is added today. Keep moving.", promptVersion: packet.promptVersion) }
    func rewriteInsightsSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { CoachCopyCandidate(summary: "Back Squat is added.", promptVersion: packet.promptVersion) }
    func rewritePlanExplanation(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { CoachCopyCandidate(summary: "Back Squat is added.", promptVersion: packet.promptVersion) }
}

private struct MedicalAdviceFakeCopyEditor: CoachCopyEditing {
    func rewriteWorkoutSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { CoachCopyCandidate(summary: "This is safe for your injury. Push through pain.", promptVersion: packet.promptVersion) }
    func rewriteInsightsSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { CoachCopyCandidate(summary: "Ask a doctor.", promptVersion: packet.promptVersion) }
    func rewritePlanExplanation(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { CoachCopyCandidate(summary: "Ask a doctor.", promptVersion: packet.promptVersion) }
}

private struct ThrowingFakeCopyEditor: CoachCopyEditing {
    func rewriteWorkoutSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { throw CoachCopyEditingError.unavailable }
    func rewriteInsightsSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { throw CoachCopyEditingError.unavailable }
    func rewritePlanExplanation(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { throw CoachCopyEditingError.unavailable }
}

private struct TipSupplyingFakeCopyEditor: CoachCopyEditing {
    func rewriteWorkoutSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate {
        CoachCopyCandidate(summary: "Friendly copy fits today.", tips: ["Add extra reps."], promptVersion: packet.promptVersion)
    }
    func rewriteInsightsSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { CoachCopyCandidate(summary: "Insights look steady.", promptVersion: packet.promptVersion) }
    func rewritePlanExplanation(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { CoachCopyCandidate(summary: "Plan is adjusted.", promptVersion: packet.promptVersion) }
}
