import XCTest
@testable import SundeeFundeeKit

final class CoachPromptPackTests: XCTestCase {
    func testWorkoutPromptContainsVersionRulesAndSelectedExercises() {
        let packet = CoachDecisionPacket(
            promptVersion: CoachPromptVersion.workoutSummaryV17.rawValue,
            durationMinutes: 30,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .fullGym,
            cyclePhase: nil,
            workoutsThisWeek: 1,
            activeInjuryCount: 1,
            selectedExerciseNames: ["Push-Up"],
            allowedExerciseNames: ["Push-Up"],
            reasonCodes: [.balancedMovementPatterns],
            cautionCodes: [],
            deterministicSummary: "Summary",
            deterministicTips: []
        )
        let prompt = CoachPromptPack.workoutSummaryPrompt(packet: packet)
        XCTAssertTrue(prompt.contains(CoachPromptVersion.workoutSummaryV17.rawValue))
        XCTAssertTrue(prompt.contains("Hard rules"))
        XCTAssertTrue(prompt.contains("Push-Up"))
        XCTAssertFalse(prompt.lowercased().contains("active injury"))
        XCTAssertLessThan(prompt.count, 2_000)
    }
}
