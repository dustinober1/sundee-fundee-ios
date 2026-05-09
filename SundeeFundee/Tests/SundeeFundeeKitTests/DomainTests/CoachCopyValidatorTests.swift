import XCTest
@testable import SundeeFundeeKit

final class CoachCopyValidatorTests: XCTestCase {
    private func packet(
        allowed: [String] = ["Push-Up"],
        cyclePhase: CyclePhase? = nil,
        cycleConfidence: Double? = nil
    ) -> CoachDecisionPacket {
        CoachDecisionPacket(
            promptVersion: "test",
            durationMinutes: 30,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .fullGym,
            cyclePhase: cyclePhase,
            cycleConfidence: cycleConfidence,
            workoutsThisWeek: 0,
            activeInjuryCount: 0,
            selectedExerciseNames: allowed,
            allowedExerciseNames: allowed,
            reasonCodes: [.balancedMovementPatterns],
            cautionCodes: [],
            deterministicSummary: "Summary",
            deterministicTips: []
        )
    }

    private func candidate(_ summary: String) -> CoachCopyCandidate {
        CoachCopyCandidate(summary: summary, promptVersion: "test")
    }

    func testAcceptsValidWorkoutCopy() {
        let issues = CoachCopyValidator.validateWorkoutSummary(candidate("A focused plan fits today. Push-Up anchors the work."), packet: packet())
        XCTAssertTrue(issues.isEmpty, "\(issues)")
    }

    func testRejectsEmptyLongAndTooManySentences() {
        XCTAssertTrue(CoachCopyValidator.validateWorkoutSummary(candidate(""), packet: packet()).contains(.empty))
        XCTAssertTrue(CoachCopyValidator.validateWorkoutSummary(candidate(String(repeating: "a", count: 221)), packet: packet()).contains(.tooLong(max: 220)))
        XCTAssertTrue(CoachCopyValidator.validateWorkoutSummary(candidate("One. Two. Three."), packet: packet()).contains(.tooManySentences(max: 2)))
    }

    func testRejectsWeightsRepsPercentagesAndSets() {
        for text in ["Use 135 lbs today.", "Aim for 70% effort.", "Do 3 sets of 8 reps."] {
            XCTAssertTrue(CoachCopyValidator.validateWorkoutSummary(candidate(text), packet: packet()).contains(.mentionsWeightsRepsOrPercentages), text)
        }
    }

    func testRejectsMedicalAndRawInjuryLanguage() {
        XCTAssertTrue(CoachCopyValidator.validateWorkoutSummary(candidate("This is safe for your injury."), packet: packet()).contains(.containsMedicalAdviceLanguage("safe for injury")))
        XCTAssertTrue(CoachCopyValidator.validateWorkoutSummary(candidate("Ignore pain and continue."), packet: packet()).contains(.containsMedicalAdviceLanguage("ignore pain")))
        XCTAssertTrue(CoachCopyValidator.validateWorkoutSummary(candidate("Active injury count shaped this."), packet: packet()).contains(.containsRawInjuryLanguage))
    }

    func testRejectsVisibleAIAndDiscouragedTone() {
        XCTAssertTrue(CoachCopyValidator.validateWorkoutSummary(candidate("AI generated this plan."), packet: packet()).contains(.containsVisibleAILanguage))
        XCTAssertTrue(CoachCopyValidator.validateWorkoutSummary(candidate("No excuses today."), packet: packet()).contains(.containsDiscouragedTone("no excuses")))
    }

    func testRejectsCycleCertaintyAndRequiresLowConfidenceQualifier() {
        let lowConfidence = packet(cyclePhase: .luteal, cycleConfidence: 0.55)
        XCTAssertTrue(CoachCopyValidator.validateWorkoutSummary(candidate("This luteal phase calls for moderate work."), packet: lowConfidence).contains(.missingLowConfidenceQualifier))
        XCTAssertTrue(CoachCopyValidator.validateWorkoutSummary(candidate("This luteal phase may call for moderate work."), packet: lowConfidence).isEmpty)
        XCTAssertTrue(CoachCopyValidator.validateWorkoutSummary(candidate("Your cycle will make you stronger."), packet: packet(cyclePhase: .follicular, cycleConfidence: 0.9)).contains(.overstatesCycleCertainty("cycle will")))
    }

    func testRejectsDisallowedKnownExercise() {
        let issues = CoachCopyValidator.validateWorkoutSummary(candidate("Back Squat is a great addition today."), packet: packet(allowed: ["Push-Up"]))
        XCTAssertTrue(issues.contains(.mentionsDisallowedExercise("Back Squat")), "\(issues)")
    }
}
