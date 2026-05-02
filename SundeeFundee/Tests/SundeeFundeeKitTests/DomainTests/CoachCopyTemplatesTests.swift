import XCTest
@testable import SundeeFundeeKit

final class CoachCopyTemplatesTests: XCTestCase {
    func testFallbackCopyIsNonEmptyAndAvoidsMedicalClaims() {
        let packet = CoachDecisionPacket(
            promptVersion: "test",
            durationMinutes: 30,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .fullGym,
            cyclePhase: nil,
            workoutsThisWeek: 0,
            activeInjuryCount: 0,
            selectedExerciseNames: [],
            allowedExerciseNames: [],
            reasonCodes: [.balancedMovementPatterns],
            cautionCodes: [],
            deterministicSummary: "Balanced full-body work.",
            deterministicTips: ["Keep reps smooth."]
        )
        let copy = CoachCopyTemplates.fallbackCopy(from: packet)
        XCTAssertFalse(copy.summary.isEmpty)
        XCTAssertFalse(copy.tips.isEmpty)
        let joined = ([copy.summary] + copy.tips).joined(separator: " ").lowercased()
        XCTAssertFalse(joined.contains("diagnose"))
        XCTAssertFalse(joined.contains("treat"))
        XCTAssertFalse(joined.contains("doctor"))
    }
}
