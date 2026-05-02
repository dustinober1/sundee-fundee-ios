import XCTest
@testable import SundeeFundeeKit

final class CoachDecisionPacketTests: XCTestCase {
    func testSanitizedPromptOmitsRawPrivateInjuryFields() {
        let packet = CoachDecisionPacket(
            promptVersion: "test",
            durationMinutes: 30,
            focus: .fullBody,
            energyLevel: .low,
            equipment: .fullGym,
            cyclePhase: .menstrual,
            workoutsThisWeek: 2,
            activeInjuryCount: 1,
            selectedExerciseNames: ["Push-Up"],
            allowedExerciseNames: ["Push-Up"],
            reasonCodes: [.activeInjuriesFilteredExercises],
            cautionCodes: [.activeInjuriesFilteredExercises],
            deterministicSummary: "Summary",
            deterministicTips: []
        )
        let prompt = packet.sanitizedForPrompt().lowercased()
        XCTAssertFalse(prompt.contains("knee strain"))
        XCTAssertFalse(prompt.contains("raw pain"))
        XCTAssertFalse(prompt.contains("active injury"))
        XCTAssertTrue(prompt.contains("movement constraint count: 1"))
    }
}
