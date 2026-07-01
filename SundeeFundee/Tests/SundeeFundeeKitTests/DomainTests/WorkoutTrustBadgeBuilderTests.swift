import XCTest
@testable import SundeeFundeeKit

final class WorkoutTrustBadgeBuilderTests: XCTestCase {
    func testBuildsEnergyEquipmentAndRecoveryBadges() {
        let badges = WorkoutTrustBadgeBuilder.badges(
            reasons: [
                "Your higher energy supports a small intensity nudge while keeping form in focus.",
                "Exercises were filtered to match the equipment you have today.",
                "Your weekly training count is high, so recovery stays part of the plan."
            ],
            cyclePhase: .follicular,
            cycleConfidence: 0.74,
            deloadRecommended: false
        )

        XCTAssertTrue(badges.contains { $0.title == "Energy" })
        XCTAssertTrue(badges.contains { $0.title == "Equipment" })
        XCTAssertTrue(badges.contains { $0.title == "Recovery" })
        XCTAssertTrue(badges.contains { $0.title == "Cycle estimate" && $0.detail == "Medium confidence" })
    }

    func testDeloadBadgeWinsWhenActiveRecoveryRecommended() {
        let badges = WorkoutTrustBadgeBuilder.badges(
            reasons: [],
            cyclePhase: nil,
            cycleConfidence: nil,
            deloadRecommended: true
        )

        XCTAssertEqual(badges.first?.title, "Protected recovery")
    }
}
