import XCTest
@testable import SundeeFundeeKit

final class InjuryAdaptationEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeInjury(
        location: String,
        name: String = "Test Injury",
        recoveryPhase: RecoveryPhase = .rehab
    ) -> Injury {
        Injury(
            id: UUID().uuidString,
            locationIds: location,
            name: name,
            recoveryPhase: recoveryPhase,
            dateCreated: Date(),
            phaseUpdated: Date()
        )
    }

    // MARK: - isContraindicated

    func testIsContraindicated_KneeInjury_Squat() {
        let injuries = [makeInjury(location: "knee_left")]
        XCTAssertTrue(InjuryAdaptationEngine.isContraindicated(
            exerciseName: "Back Squat",
            exerciseCategory: nil,
            injuries: injuries
        ))
    }

    func testIsContraindicated_KneeInjury_Lunge() {
        let injuries = [makeInjury(location: "knee_left")]
        XCTAssertTrue(InjuryAdaptationEngine.isContraindicated(
            exerciseName: "Walking Lunge",
            exerciseCategory: nil,
            injuries: injuries
        ))
    }

    func testIsContraindicated_ShoulderInjury_Press() {
        let injuries = [makeInjury(location: "shoulder_right")]
        XCTAssertTrue(InjuryAdaptationEngine.isContraindicated(
            exerciseName: "Strict Press",
            exerciseCategory: nil,
            injuries: injuries
        ))
    }

    func testIsContraindicated_BackInjury_Deadlift() {
        let injuries = [makeInjury(location: "lower_back")]
        XCTAssertTrue(InjuryAdaptationEngine.isContraindicated(
            exerciseName: "Conventional Deadlift",
            exerciseCategory: nil,
            injuries: injuries
        ))
    }

    func testIsContraindicated_ResolvedInjury_NotContraindicated() {
        let injuries = [makeInjury(location: "knee_left", recoveryPhase: .resolved)]
        XCTAssertFalse(InjuryAdaptationEngine.isContraindicated(
            exerciseName: "Back Squat",
            exerciseCategory: nil,
            injuries: injuries
        ))
    }

    func testIsContraindicated_NoInjuries() {
        XCTAssertFalse(InjuryAdaptationEngine.isContraindicated(
            exerciseName: "Back Squat",
            exerciseCategory: nil,
            injuries: []
        ))
    }

    func testIsContraindicated_UnrelatedExercise() {
        let injuries = [makeInjury(location: "knee_left")]
        XCTAssertFalse(InjuryAdaptationEngine.isContraindicated(
            exerciseName: "Bicep Curl",
            exerciseCategory: nil,
            injuries: injuries
        ))
    }

    func testIsContraindicated_ClinicalSynonym_ACL() {
        let injuries = [makeInjury(location: "knee_left", name: "ACL")]
        XCTAssertTrue(InjuryAdaptationEngine.isContraindicated(
            exerciseName: "Back Squat",
            exerciseCategory: nil,
            injuries: injuries
        ))
    }

    // MARK: - getRegressions

    func testGetRegressions_BackSquat() {
        let injuries = [makeInjury(location: "knee_left")]
        let regressions = InjuryAdaptationEngine.getRegressions(
            exerciseName: "Back Squat",
            injuries: injuries
        )
        XCTAssertFalse(regressions.isEmpty)
        XCTAssertTrue(regressions.contains("Goblet Squat"))
    }

    func testGetRegressions_BenchPress() {
        let injuries = [makeInjury(location: "shoulder_left")]
        let regressions = InjuryAdaptationEngine.getRegressions(
            exerciseName: "Flat Barbell Bench Press",
            injuries: injuries
        )
        XCTAssertFalse(regressions.isEmpty)
        XCTAssertTrue(regressions.contains("Push-Ups"))
    }

    func testGetRegressions_UnknownExercise() {
        let injuries = [makeInjury(location: "knee_left")]
        let regressions = InjuryAdaptationEngine.getRegressions(
            exerciseName: "Some Unknown Exercise",
            injuries: injuries
        )
        XCTAssertTrue(regressions.isEmpty)
    }

    // MARK: - calculateLoadMultiplier

    func testLoadMultiplier_AcutePhase() {
        let injuries = [makeInjury(location: "knee_left", recoveryPhase: .acute)]
        let result = InjuryAdaptationEngine.calculateLoadMultiplier(
            baseLoad: 100.0,
            injuries: injuries
        )
        XCTAssertEqual(result, 30.0, accuracy: 0.01)
    }

    func testLoadMultiplier_RehabPhase() {
        let injuries = [makeInjury(location: "knee_left", recoveryPhase: .rehab)]
        let result = InjuryAdaptationEngine.calculateLoadMultiplier(
            baseLoad: 100.0,
            injuries: injuries
        )
        XCTAssertEqual(result, 50.0, accuracy: 0.01)
    }

    func testLoadMultiplier_LightLoadPhase() {
        let injuries = [makeInjury(location: "knee_left", recoveryPhase: .lightLoad)]
        let result = InjuryAdaptationEngine.calculateLoadMultiplier(
            baseLoad: 100.0,
            injuries: injuries
        )
        XCTAssertEqual(result, 70.0, accuracy: 0.01)
    }

    func testLoadMultiplier_ReturnToPlayPhase() {
        let injuries = [makeInjury(location: "knee_left", recoveryPhase: .returnToPlay)]
        let result = InjuryAdaptationEngine.calculateLoadMultiplier(
            baseLoad: 100.0,
            injuries: injuries
        )
        XCTAssertEqual(result, 85.0, accuracy: 0.01)
    }

    func testLoadMultiplier_ResolvedPhase() {
        let injuries = [makeInjury(location: "knee_left", recoveryPhase: .resolved)]
        let result = InjuryAdaptationEngine.calculateLoadMultiplier(
            baseLoad: 100.0,
            injuries: injuries
        )
        // Resolved injuries are filtered out, so full load
        XCTAssertEqual(result, 1.0, accuracy: 0.01)
    }

    func testLoadMultiplier_MultipleInjuries_TakesMostRestrictive() {
        let injuries = [
            makeInjury(location: "knee_left", recoveryPhase: .lightLoad),
            makeInjury(location: "shoulder_left", recoveryPhase: .acute),
        ]
        let result = InjuryAdaptationEngine.calculateLoadMultiplier(
            baseLoad: 100.0,
            injuries: injuries
        )
        // Should use acute (0.3), the most restrictive
        XCTAssertEqual(result, 30.0, accuracy: 0.01)
    }

    func testLoadMultiplier_NoInjuries() {
        let result = InjuryAdaptationEngine.calculateLoadMultiplier(
            baseLoad: 100.0,
            injuries: []
        )
        XCTAssertEqual(result, 1.0, accuracy: 0.01)
    }
}
