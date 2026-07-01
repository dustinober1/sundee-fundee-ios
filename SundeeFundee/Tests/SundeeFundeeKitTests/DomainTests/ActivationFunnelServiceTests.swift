import XCTest
@testable import SundeeFundeeKit

final class ActivationFunnelServiceTests: XCTestCase {
    func testSummarizesActivationStages() {
        let now = Date()
        let events = [
            GrowthEvent(name: GrowthEventName.onboardingStarted, dateCreated: now, source: "onboarding"),
            GrowthEvent(name: GrowthEventName.onboardingCompleted, dateCreated: now, source: "onboarding"),
            GrowthEvent(name: GrowthEventName.firstWorkoutStarted, dateCreated: now, source: "onboarding"),
            GrowthEvent(name: GrowthEventName.firstWorkoutCompleted, dateCreated: now, source: "active_workout")
        ]

        let snapshot = ActivationFunnelService.snapshot(from: events, now: now)

        XCTAssertTrue(snapshot.onboardingStarted)
        XCTAssertTrue(snapshot.onboardingCompleted)
        XCTAssertTrue(snapshot.firstWorkoutStarted)
        XCTAssertTrue(snapshot.firstWorkoutCompleted)
        XCTAssertFalse(snapshot.secondSessionWithinSevenDays)
    }

    func testDetectsSecondSessionWithinSevenDays() {
        let first = ISO8601DateFormatter().date(from: "2026-06-01T12:00:00Z")!
        let second = ISO8601DateFormatter().date(from: "2026-06-07T12:00:00Z")!
        let events = [
            GrowthEvent(name: GrowthEventName.firstWorkoutCompleted, dateCreated: first, source: "active_workout"),
            GrowthEvent(name: "workout_completed", dateCreated: second, source: "active_workout")
        ]

        let snapshot = ActivationFunnelService.snapshot(from: events, now: second)

        XCTAssertTrue(snapshot.secondSessionWithinSevenDays)
    }
}
