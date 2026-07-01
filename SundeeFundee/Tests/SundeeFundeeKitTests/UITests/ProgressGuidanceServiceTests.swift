import XCTest
@testable import SundeeFundeeKit

final class ProgressGuidanceServiceTests: XCTestCase {
    func testGuidanceShowsAnalyticsUnlockWhenFewWorkouts() {
        let items = ProgressGuidanceService.guidance(
            input: ProgressDestinationInput(
                hasMaxes: false,
                hasBenchmarks: false,
                hasChallenges: false,
                hasBuddyCheckIns: false,
                hasMonthlyReview: false,
                hasAnalytics: false,
                alwaysShowExport: true
            ),
            completedWorkoutCount: 1
        )

        XCTAssertTrue(items.contains { $0.title == "Complete 2 workouts to unlock analytics" })
        XCTAssertTrue(items.contains { $0.title == "Log your first max" })
    }
}
