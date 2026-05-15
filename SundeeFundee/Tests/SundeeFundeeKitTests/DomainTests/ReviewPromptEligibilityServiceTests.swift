import XCTest
@testable import SundeeFundeeKit

final class ReviewPromptEligibilityServiceTests: XCTestCase {
    private let service = ReviewPromptEligibilityService(cooldownDays: 120)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testThirdWorkoutCompletedIsEligibleAtThreeCompletedWorkouts() {
        let result = service.evaluate(
            trigger: .thirdWorkoutCompleted,
            triggerID: "third-workout",
            context: ReviewPromptContext(completedWorkoutCount: 3, actionSucceeded: true),
            state: ReviewPromptState(),
            appVersion: "1.7.0",
            now: now
        )

        XCTAssertTrue(result.shouldRequestReview)
        XCTAssertEqual(result.state.lastPromptedAppVersion, "1.7.0")
        XCTAssertEqual(result.state.lastPromptedAt, now)
        XCTAssertTrue(result.state.completedTriggerIDs.contains("third-workout"))
    }

    func testThirdWorkoutCompletedIsNotEligibleBeforeThreeCompletedWorkouts() {
        let result = service.evaluate(
            trigger: .thirdWorkoutCompleted,
            triggerID: "third-workout",
            context: ReviewPromptContext(completedWorkoutCount: 2, actionSucceeded: true),
            state: ReviewPromptState(),
            appVersion: "1.7.0",
            now: now
        )

        XCTAssertFalse(result.shouldRequestReview)
        XCTAssertNil(result.state.lastPromptedAppVersion)
        XCTAssertFalse(result.state.completedTriggerIDs.contains("third-workout"))
    }

    func testDuplicateTriggerIsIgnored() {
        let state = ReviewPromptState(
            lastPromptedAppVersion: nil,
            lastPromptedAt: nil,
            completedTriggerIDs: ["benchmark:vanessa"]
        )

        let result = service.evaluate(
            trigger: .benchmarkLogged,
            triggerID: "benchmark:vanessa",
            context: ReviewPromptContext(actionSucceeded: true),
            state: state,
            appVersion: "1.7.0",
            now: now
        )

        XCTAssertFalse(result.shouldRequestReview)
        XCTAssertEqual(result.state, state)
    }

    func testSameAppVersionIsIgnored() {
        let state = ReviewPromptState(
            lastPromptedAppVersion: "1.7.0",
            lastPromptedAt: nil,
            completedTriggerIDs: []
        )

        let result = service.evaluate(
            trigger: .personalRecordLogged,
            triggerID: "pr:bench-press",
            context: ReviewPromptContext(actionSucceeded: true),
            state: state,
            appVersion: "1.7.0",
            now: now
        )

        XCTAssertFalse(result.shouldRequestReview)
        XCTAssertEqual(result.state, state)
    }

    func testCooldownIsEnforced() {
        let state = ReviewPromptState(
            lastPromptedAppVersion: "1.6.0",
            lastPromptedAt: now.addingTimeInterval(-119 * 24 * 60 * 60),
            completedTriggerIDs: []
        )

        let result = service.evaluate(
            trigger: .personalRecordLogged,
            triggerID: "pr:squat",
            context: ReviewPromptContext(actionSucceeded: true),
            state: state,
            appVersion: "1.7.0",
            now: now
        )

        XCTAssertFalse(result.shouldRequestReview)
        XCTAssertEqual(result.state, state)
    }

    func testSuccessfulActionTriggersAreEligible() {
        let triggers: [ReviewPromptTrigger] = [
            .personalRecordLogged,
            .benchmarkLogged,
            .firstCoachPlanCompleted,
            .painAwareSwapWorkoutCompleted
        ]

        for trigger in triggers {
            let result = service.evaluate(
                trigger: trigger,
                triggerID: "\(trigger.rawValue):success",
                context: ReviewPromptContext(actionSucceeded: true),
                state: ReviewPromptState(),
                appVersion: "1.7.0",
                now: now
            )

            XCTAssertTrue(result.shouldRequestReview, "\(trigger.rawValue) should be eligible after success")
        }
    }

    func testUnsuccessfulActionTriggersAreIgnored() {
        let triggers: [ReviewPromptTrigger] = [
            .personalRecordLogged,
            .benchmarkLogged,
            .firstCoachPlanCompleted,
            .painAwareSwapWorkoutCompleted
        ]

        for trigger in triggers {
            let result = service.evaluate(
                trigger: trigger,
                triggerID: "\(trigger.rawValue):failed",
                context: ReviewPromptContext(actionSucceeded: false),
                state: ReviewPromptState(),
                appVersion: "1.7.0",
                now: now
            )

            XCTAssertFalse(result.shouldRequestReview, "\(trigger.rawValue) should be ignored after failure")
        }
    }
}
