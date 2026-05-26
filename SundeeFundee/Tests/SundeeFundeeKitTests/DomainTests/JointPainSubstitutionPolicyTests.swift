import XCTest
@testable import SundeeFundeeKit

final class JointPainSubstitutionPolicyTests: XCTestCase {
    func testKneePainPolicy() {
        let policy = JointPainSubstitutionPolicyService.resolve(
            currentExercise: "Back Squat",
            recentPainLogs: [painLog("knee_left")],
            injuries: []
        )

        XCTAssertEqual(policy.primaryRegionKey, "knee")
        XCTAssertTrue(policy.avoidedPatterns.contains(.squat))
        XCTAssertTrue(policy.preferredPatterns.contains(.hinge))
        XCTAssertNotNil(policy.reason)
    }

    func testBackPainPolicy() {
        let policy = JointPainSubstitutionPolicyService.resolve(
            currentExercise: "Romanian Deadlift",
            recentPainLogs: [painLog("lower_back")],
            injuries: []
        )

        XCTAssertEqual(policy.primaryRegionKey, "back")
        XCTAssertTrue(policy.avoidedPatterns.contains(.hinge))
    }

    func testShoulderPainPolicy() {
        let policy = JointPainSubstitutionPolicyService.resolve(
            currentExercise: "Strict Press",
            recentPainLogs: [painLog("shoulder_left")],
            injuries: []
        )

        XCTAssertEqual(policy.primaryRegionKey, "shoulder")
        XCTAssertTrue(policy.avoidedPatterns.contains(.push))
    }

    func testWristPainPolicy() {
        let policy = JointPainSubstitutionPolicyService.resolve(
            currentExercise: "Push-Up",
            recentPainLogs: [painLog("wrist_left")],
            injuries: []
        )

        XCTAssertEqual(policy.primaryRegionKey, "wrist")
        XCTAssertTrue(policy.avoidedPatterns.contains(.push))
    }

    func testHipPainPolicy() {
        let policy = JointPainSubstitutionPolicyService.resolve(
            currentExercise: "Lunge",
            recentPainLogs: [painLog("hip_right")],
            injuries: []
        )

        XCTAssertEqual(policy.primaryRegionKey, "hip")
        XCTAssertTrue(policy.avoidedPatterns.contains(.squat))
    }

    private func painLog(_ locationId: String) -> DailyPainLog {
        DailyPainLog(
            id: UUID().uuidString,
            locationIds: locationId,
            intensity: 6,
            painType: .aching,
            date: Date()
        )
    }
}
