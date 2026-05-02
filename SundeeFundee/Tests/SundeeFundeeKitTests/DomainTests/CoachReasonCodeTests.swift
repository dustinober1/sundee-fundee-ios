import XCTest
@testable import SundeeFundeeKit

final class CoachReasonCodeTests: XCTestCase {
    func testEveryCaseHasDisplayMetadata() {
        for code in CoachReasonCode.allCases {
            XCTAssertFalse(code.defaultUserText.isEmpty, code.rawValue)
            XCTAssertFalse(code.shortLabel.isEmpty, code.rawValue)
        }
    }

    func testCautionCases() {
        XCTAssertTrue(CoachReasonCode.activeInjuriesFilteredExercises.isCaution)
        XCTAssertTrue(CoachReasonCode.progressSlowdownWarning.isCaution)
        XCTAssertTrue(CoachReasonCode.highWeeklyTrainingRecoveryReminder.isCaution)
        XCTAssertTrue(CoachReasonCode.packedWeekVolumeWarning.isCaution)
        XCTAssertTrue(CoachReasonCode.droppedSessionRecoveryProtected.isCaution)
    }

    func testLabelsAvoidMedicalClaims() {
        let banned = ["safe", "treat", "diagnose", "doctor"]
        for code in CoachReasonCode.allCases {
            let label = code.shortLabel.lowercased()
            XCTAssertFalse(banned.contains { label.contains($0) }, code.rawValue)
        }
    }
}
