import XCTest
@testable import SundeeFundeeKit

final class DeloadDetectionServiceTests: XCTestCase {
    func testTwoHighPainDaysRecommendDeload() {
        let painLogs = [
            makePain(intensity: 8, dayOffset: 0),
            makePain(intensity: 7, dayOffset: 1),
            makePain(intensity: 3, dayOffset: 2),
        ]

        let recommendation = DeloadDetectionService.recommendation(
            recentPainLogs: painLogs
        )

        XCTAssertTrue(recommendation.isRecommended)
    }

    func testHighPainAndPoorSleepRecommendDeload() {
        let recommendation = DeloadDetectionService.recommendation(
            recentPainLogs: [makePain(intensity: 8, dayOffset: 0)],
            recentSleepHours: [5.0, 5.5, 7.2]
        )

        XCTAssertTrue(recommendation.isRecommended)
    }

    func testSingleHighPainDayDoesNotRecommendDeload() {
        let recommendation = DeloadDetectionService.recommendation(
            recentPainLogs: [makePain(intensity: 8, dayOffset: 0)]
        )

        XCTAssertFalse(recommendation.isRecommended)
    }

    func testProlongedReadinessSuppressionRecommendsDeload() {
        let recommendation = DeloadDetectionService.recommendation(
            recentPainLogs: [],
            recentReadinessScores: [38, 42, 40, 75]
        )

        XCTAssertTrue(recommendation.isRecommended)
        XCTAssertEqual(recommendation.trigger, .prolongedReadinessSuppression)
        XCTAssertEqual(recommendation.recommendedDays, 2)
    }

    func testRPECreepRecommendsDeload() {
        let recommendation = DeloadDetectionService.recommendation(
            recentPainLogs: [],
            recentRPEs: [9.5, 9.0, 9.5]
        )

        XCTAssertTrue(recommendation.isRecommended)
        XCTAssertEqual(recommendation.trigger, .rpeCreep)
    }

    func testSustainedVolumeAccumulationRecommendsDeload() {
        let now = Date()
        let workouts = [
            // Week 0 (0-6 days ago)
            makeWorkout(volume: 5000, dayOffset: 1, referenceDate: now),
            makeWorkout(volume: 5000, dayOffset: 4, referenceDate: now),
            // Week 1 (7-13 days ago)
            makeWorkout(volume: 4800, dayOffset: 8, referenceDate: now),
            makeWorkout(volume: 4800, dayOffset: 11, referenceDate: now),
            // Week 2 (14-20 days ago)
            makeWorkout(volume: 4500, dayOffset: 15, referenceDate: now),
            makeWorkout(volume: 4500, dayOffset: 18, referenceDate: now)
        ]

        let recommendation = DeloadDetectionService.recommendation(
            recentPainLogs: [],
            recentWorkouts: workouts,
            referenceDate: now
        )

        XCTAssertTrue(recommendation.isRecommended)
        XCTAssertEqual(recommendation.trigger, .sustainedVolumeAccumulation)
        XCTAssertEqual(recommendation.recommendedDays, 3)
    }

    func testNormalTrainingDoesNotRecommendDeload() {
        let now = Date()
        let workouts = [
            makeWorkout(volume: 3000, dayOffset: 2, referenceDate: now),
            makeWorkout(volume: 3000, dayOffset: 5, referenceDate: now)
        ]

        let recommendation = DeloadDetectionService.recommendation(
            recentPainLogs: [makePain(intensity: 2, dayOffset: 0)],
            recentSleepHours: [7.5, 8.0, 7.0],
            recentWorkouts: workouts,
            recentReadinessScores: [82, 78, 85],
            recentRPEs: [7.0, 7.5],
            referenceDate: now
        )

        XCTAssertFalse(recommendation.isRecommended)
        XCTAssertNil(recommendation.trigger)
    }

    private func makePain(intensity: Int, dayOffset: Int) -> DailyPainLog {
        let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
        return DailyPainLog(
            id: UUID().uuidString,
            locationIds: "knee_left",
            intensity: intensity,
            painType: .aching,
            date: date
        )
    }

    private func makeWorkout(volume: Double, dayOffset: Int, referenceDate: Date) -> Workout {
        let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: referenceDate) ?? referenceDate
        let sets = [
            ExerciseSet(
                reps: 10,
                prescribedWeight: volume / 10.0,
                type: .fixed,
                completedWeight: volume / 10.0,
                actualReps: 10,
                isComplete: true
            )
        ]
        let exercise = Exercise(
            id: UUID().uuidString,
            name: "Squat",
            category: .compound,
            bodyweight: 0,
            targetSets: sets
        )
        return Workout(
            id: UUID().uuidString,
            date: date,
            name: "Leg Day",
            exercises: [exercise],
            completedAt: date
        )
    }
}
