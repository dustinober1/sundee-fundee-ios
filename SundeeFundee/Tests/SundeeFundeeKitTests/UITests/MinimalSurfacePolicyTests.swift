import XCTest
@testable import SundeeFundeeKit

final class MinimalSurfacePolicyTests: XCTestCase {
    func testPrimaryTabsUseFourMinimalDestinations() {
        XCTAssertEqual(
            MinimalSurfacePolicy.primaryTabs,
            [.today, .train, .cycle, .progress]
        )
    }

    func testTodaySecondarySectionsHideWhenNoDataIsRelevant() {
        let sections = MinimalSurfacePolicy.todaySecondarySections(
            input: TodaySecondarySectionInput(
                hasWeeklyPlan: false,
                hasMissedWorkoutPlan: false,
                hasFirstWeekChecklist: false,
                hasRecoveryInputGaps: false,
                hasActiveChallenge: false,
                hasCoachInsights: false,
                hasRecentWins: false
            )
        )

        XCTAssertEqual(sections, [])
    }

    func testTodaySecondarySectionsKeepOnlyRelevantData() {
        let sections = MinimalSurfacePolicy.todaySecondarySections(
            input: TodaySecondarySectionInput(
                hasWeeklyPlan: true,
                hasMissedWorkoutPlan: true,
                hasFirstWeekChecklist: false,
                hasRecoveryInputGaps: true,
                hasActiveChallenge: false,
                hasCoachInsights: true,
                hasRecentWins: false
            )
        )

        XCTAssertEqual(sections, [.weeklyPlan, .missedWorkoutPlan, .recoveryInputs, .coachInsights])
    }

    func testProgressDestinationVisibilityHidesInactiveFeatures() {
        let destinations = MinimalSurfacePolicy.progressDestinations(
            input: ProgressDestinationInput(
                hasMaxes: true,
                hasBenchmarks: false,
                hasChallenges: false,
                hasBuddyCheckIns: false,
                hasMonthlyReview: true,
                hasAnalytics: false,
                alwaysShowExport: true
            )
        )

        XCTAssertEqual(destinations, [.monthlyReview, .maxes, .export])
    }

    func testProgressAlwaysKeepsExportAvailable() {
        let destinations = MinimalSurfacePolicy.progressDestinations(
            input: ProgressDestinationInput(
                hasMaxes: false,
                hasBenchmarks: false,
                hasChallenges: false,
                hasBuddyCheckIns: false,
                hasMonthlyReview: false,
                hasAnalytics: false,
                alwaysShowExport: true
            )
        )

        XCTAssertEqual(destinations, [.export])
    }

    func testSharePromptRequiresMeaningfulWin() {
        XCTAssertFalse(MinimalSurfacePolicy.shouldPromptShare(for: .completedWorkout))
        XCTAssertTrue(MinimalSurfacePolicy.shouldPromptShare(for: .personalRecord))
        XCTAssertTrue(MinimalSurfacePolicy.shouldPromptShare(for: .challengeMilestone))
        XCTAssertTrue(MinimalSurfacePolicy.shouldPromptShare(for: .monthlyReview))
        XCTAssertFalse(MinimalSurfacePolicy.shouldPromptShare(for: .cycleInsight))
    }
}
