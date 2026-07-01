import XCTest
@testable import SundeeFundeeKit

final class ProgressivePromptPolicyTests: XCTestCase {
    func testHealthPromptWaitsUntilFirstWorkoutCompleted() {
        let prompt = ProgressivePromptPolicy.nextPrompt(
            context: ProgressivePromptContext(
                completedWorkoutCount: 1,
                openedCycle: false,
                isAboutToSharePhoto: false,
                declinedPromptIDs: []
            )
        )

        XCTAssertEqual(prompt, .healthKit)
    }

    func testCyclePromptShowsWhenCycleTabOpened() {
        let prompt = ProgressivePromptPolicy.nextPrompt(
            context: ProgressivePromptContext(
                completedWorkoutCount: 0,
                openedCycle: true,
                isAboutToSharePhoto: false,
                declinedPromptIDs: []
            )
        )

        XCTAssertEqual(prompt, .cycleSetup)
    }

    func testDeclinedPromptIsNotRepeated() {
        let prompt = ProgressivePromptPolicy.nextPrompt(
            context: ProgressivePromptContext(
                completedWorkoutCount: 1,
                openedCycle: false,
                isAboutToSharePhoto: false,
                declinedPromptIDs: ["healthKit"]
            )
        )

        XCTAssertNil(prompt)
    }
}
