import XCTest
@testable import SundeeFundeeKit

final class CoachCopyFallbackTests: XCTestCase {
    func testFallbackPreservesWorkoutStructure() async throws {
        let preferences = QuestionnaireAnswers(timeMinutes: 30, focus: .fullBody, energyLevel: .medium, equipment: .fullGym)
        let base = try await DeterministicCoachService().generateWorkout(context: CoachContext(), preferences: preferences)
        let packet = CoachDecisionPacketBuilder.workoutPacket(base: base, context: CoachContext(), preferences: preferences, promptVersion: "test")
        let fallback = CoachCopyFallback.workoutResponse(base: base, packet: packet, source: .onDeviceAIRejectedFallback)
        XCTAssertEqual(fallback.workout.exercises, base.workout.exercises)
        XCTAssertEqual(fallback.workout.id, base.workout.id)
        XCTAssertEqual(fallback.copySource, .onDeviceAIRejectedFallback)
        XCTAssertNotNil(fallback.decisionPacket)
    }
}
