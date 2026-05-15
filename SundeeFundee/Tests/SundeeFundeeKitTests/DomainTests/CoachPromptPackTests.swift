import XCTest
@testable import SundeeFundeeKit

final class CoachPromptPackTests: XCTestCase {
    func testWorkoutPromptContainsVersionRulesAndSelectedExercises() {
        let packet = CoachDecisionPacket(
            promptVersion: CoachPromptVersion.workoutSummaryV18.rawValue,
            durationMinutes: 30,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .fullGym,
            cyclePhase: .luteal,
            cycleConfidence: 0.55,
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
        XCTAssertTrue(prompt.contains(CoachPromptVersion.workoutSummaryV18.rawValue))
        XCTAssertTrue(prompt.contains("Hard rules"))
        XCTAssertTrue(prompt.contains("Push-Up"))
        XCTAssertTrue(prompt.contains("Cycle confidence: 55%"))
        XCTAssertTrue(prompt.contains("use \"may\" or \"can\""))
        XCTAssertTrue(prompt.contains("Do not mention AI"))
        XCTAssertTrue(prompt.contains("Return exactly one summary line"))
        XCTAssertTrue(prompt.contains("Do not return tips"))
        XCTAssertTrue(prompt.contains("Avoid hype"))
        XCTAssertFalse(prompt.lowercased().contains("active injury"))
        XCTAssertLessThan(prompt.count, 2_000)
    }
}
