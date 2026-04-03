import XCTest
@testable import SundeeFundeeKit

final class WeeklyLoadAnalyzerTests: XCTestCase {

    // MARK: - Helpers

    private func makeWorkout(
        name: String = "Workout",
        daysAgo: Int = 0,
        duration: Int = 60,
        exercises: [String] = ["Back Squat", "Flat Barbell Bench Press", "Barbell Row"]
    ) -> CompletedWorkoutRecord {
        CompletedWorkoutRecord(
            id: UUID().uuidString,
            name: name,
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            duration: duration,
            exerciseNames: exercises,
            isComplete: true
        )
    }

    // MARK: - Weekly Summaries

    func testWeeklySummaries_GroupsByWeek() {
        // Two workouts this week, one last week
        let workouts = [
            makeWorkout(daysAgo: 0),
            makeWorkout(daysAgo: 2),
            makeWorkout(daysAgo: 8),
        ]
        let summaries = WeeklyLoadAnalyzer.weeklySummaries(from: workouts, weekCount: 4)
        XCTAssertGreaterThanOrEqual(summaries.count, 1)

        // Most recent week should have at least 2 workouts (if they're in the same ISO week)
        let thisWeekCount = summaries.last?.workoutCount ?? 0
        XCTAssertGreaterThanOrEqual(thisWeekCount, 1)
    }

    func testWeeklySummaries_CalculatesTotalMinutes() {
        let workouts = [
            makeWorkout(daysAgo: 0, duration: 45),
            makeWorkout(daysAgo: 1, duration: 60),
        ]
        let summaries = WeeklyLoadAnalyzer.weeklySummaries(from: workouts, weekCount: 1)
        guard let last = summaries.last else {
            XCTFail("Expected at least one summary")
            return
        }
        // Both should be in the same week
        XCTAssertGreaterThanOrEqual(last.totalMinutes, 45)
    }

    func testWeeklySummaries_EmptyInput_ReturnsEmpty() {
        let summaries = WeeklyLoadAnalyzer.weeklySummaries(from: [])
        XCTAssertTrue(summaries.isEmpty)
    }

    // MARK: - Muscle Group Classification

    func testClassifyMuscleGroup_Squat() {
        XCTAssertEqual(WeeklyLoadAnalyzer.classifyMuscleGroup("Back Squat"), "Lower")
    }

    func testClassifyMuscleGroup_BenchPress() {
        XCTAssertEqual(WeeklyLoadAnalyzer.classifyMuscleGroup("Flat Barbell Bench Press"), "Upper Push")
    }

    func testClassifyMuscleGroup_BarbellRow() {
        XCTAssertEqual(WeeklyLoadAnalyzer.classifyMuscleGroup("Barbell Row"), "Upper Pull")
    }

    func testClassifyMuscleGroup_SitUp() {
        XCTAssertEqual(WeeklyLoadAnalyzer.classifyMuscleGroup("Sit-Up"), "Core")
    }

    func testClassifyMuscleGroup_Unknown() {
        XCTAssertNil(WeeklyLoadAnalyzer.classifyMuscleGroup("Farmers Carry"))
    }

    // MARK: - Trend Detection

    func testDetectTrends_FrequencyDrop() {
        let summaries = [
            makeWeeklySummary(workoutCount: 4, weeksAgo: 3),
            makeWeeklySummary(workoutCount: 4, weeksAgo: 2),
            makeWeeklySummary(workoutCount: 1, weeksAgo: 1),
            makeWeeklySummary(workoutCount: 1, weeksAgo: 0),
        ]
        let trends = WeeklyLoadAnalyzer.detectTrends(from: summaries)
        let hasFrequencyDrop = trends.contains { $0.type == .frequencyDrop }
        XCTAssertTrue(hasFrequencyDrop, "Should detect frequency drop from 4 to 1")
    }

    func testDetectTrends_Overreaching() {
        let summaries = [
            makeWeeklySummary(workoutCount: 3, weeksAgo: 2),
            makeWeeklySummary(workoutCount: 7, weeksAgo: 1),
            makeWeeklySummary(workoutCount: 6, weeksAgo: 0),
        ]
        let trends = WeeklyLoadAnalyzer.detectTrends(from: summaries)
        let hasOverreaching = trends.contains { $0.type == .overreaching }
        XCTAssertTrue(hasOverreaching, "Should detect overreaching at 6+ sessions/week")
    }

    func testDetectTrends_Undertraining() {
        let summaries = [
            makeWeeklySummary(workoutCount: 4, weeksAgo: 2),
            makeWeeklySummary(workoutCount: 1, weeksAgo: 1),
            makeWeeklySummary(workoutCount: 0, weeksAgo: 0),
        ]
        let trends = WeeklyLoadAnalyzer.detectTrends(from: summaries)
        let hasUndertraining = trends.contains { $0.type == .undertraining }
        XCTAssertTrue(hasUndertraining, "Should detect undertraining at 0-1 sessions/week")
    }

    func testDetectTrends_SingleWeek_NoTrends() {
        let summaries = [makeWeeklySummary(workoutCount: 3, weeksAgo: 0)]
        let trends = WeeklyLoadAnalyzer.detectTrends(from: summaries)
        XCTAssertTrue(trends.isEmpty, "Single week should not produce trends")
    }

    // MARK: - Test Helpers

    private func makeWeeklySummary(workoutCount: Int, weeksAgo: Int) -> WeeklyLoadAnalyzer.WeeklySummary {
        WeeklyLoadAnalyzer.WeeklySummary(
            weekStartDate: Calendar.current.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date())!,
            workoutCount: workoutCount,
            totalMinutes: workoutCount * 60,
            muscleGroupsHit: ["Lower", "Upper Push", "Upper Pull"],
            exerciseNames: []
        )
    }
}
