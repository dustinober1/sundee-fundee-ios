import XCTest
@testable import SundeeFundeeKit

final class PlateauDetectorTests: XCTestCase {

    // MARK: - Helpers

    private func makeRecord(
        exercise: String = "Back Squat",
        weight: Double,
        daysAgo: Int = 0
    ) -> OneRepMaxRecord {
        OneRepMaxRecord(
            id: UUID().uuidString,
            exerciseName: exercise,
            weight: weight,
            unit: .lbs,
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        )
    }

    private func makeWorkout(
        exerciseName: String,
        sets: Int,
        reps: Int,
        weight: Double,
        daysAgo: Int
    ) -> Workout {
        let exerciseSets = (0..<sets).map { _ in
            ExerciseSet(
                reps: reps,
                prescribedWeight: weight,
                type: .fixed,
                completedWeight: weight,
                actualReps: reps,
                isComplete: true
            )
        }
        let exercise = Exercise(
            id: UUID().uuidString,
            name: exerciseName,
            category: .compound,
            bodyweight: 0,
            targetSets: exerciseSets
        )
        return Workout(
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            name: "Workout",
            exercises: [exercise],
            completedAt: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        )
    }

    // MARK: - No Plateau

    func testDetect_ProgressiveRecords_NoAlert() {
        let records = [
            makeRecord(weight: 200, daysAgo: 30),
            makeRecord(weight: 210, daysAgo: 20),
            makeRecord(weight: 220, daysAgo: 10),
        ]
        let alerts = PlateauDetector.detect(from: records)
        XCTAssertTrue(alerts.isEmpty, "Progressive records should not trigger a plateau")
    }

    func testDetect_TooFewRecords_NoAlert() {
        let records = [
            makeRecord(weight: 200, daysAgo: 10),
            makeRecord(weight: 200, daysAgo: 5),
        ]
        let alerts = PlateauDetector.detect(from: records)
        XCTAssertTrue(alerts.isEmpty, "Fewer than 3 records should not trigger a plateau")
    }

    // MARK: - Plateau Detected

    func testDetect_FlatRecords_AlertGenerated() {
        let records = [
            makeRecord(weight: 200, daysAgo: 30),
            makeRecord(weight: 200, daysAgo: 20),
            makeRecord(weight: 200, daysAgo: 10),
        ]
        let alerts = PlateauDetector.detect(from: records)
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts.first?.exerciseName, "Back Squat")
        XCTAssertEqual(alerts.first?.currentWeight, 200)
        XCTAssertEqual(alerts.first?.plateauType, .strength)
    }

    func testDetect_DecliningRecords_AlertGenerated() {
        let records = [
            makeRecord(weight: 220, daysAgo: 30),
            makeRecord(weight: 210, daysAgo: 20),
            makeRecord(weight: 205, daysAgo: 10),
        ]
        let alerts = PlateauDetector.detect(from: records)
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts.first?.exerciseName, "Back Squat")
    }

    // MARK: - Exercise-Specific Thresholds

    func testDetect_CompoundLift_UsesLowerThreshold() {
        // Back Squat (squat category) uses 0.5% threshold with catalog.
        // 0.8% improvement: above 0.5% compound threshold (no alert),
        // but below 1.0% default threshold (alert without catalog).
        let records = [
            makeRecord(exercise: "Back Squat", weight: 250.0, daysAgo: 30),
            makeRecord(exercise: "Back Squat", weight: 251.0, daysAgo: 20),
            makeRecord(exercise: "Back Squat", weight: 252.0, daysAgo: 10),
        ]
        // Without catalog: 0.8% < 1.0% default → flagged
        let alertsNoCatalog = PlateauDetector.detect(from: records)
        XCTAssertEqual(alertsNoCatalog.count, 1, "Without catalog, 0.8% is below 1.0% default threshold")

        // With catalog: 0.8% > 0.5% compound threshold → NOT flagged
        let alertsWithCatalog = PlateauDetector.detect(from: records, catalog: weightliftingExercises)
        XCTAssertTrue(alertsWithCatalog.isEmpty, "With catalog, 0.8% is above 0.5% compound threshold")

        // 0.3% improvement: below even the compound threshold → flagged with catalog
        let tightRecords = [
            makeRecord(exercise: "Back Squat", weight: 300.0, daysAgo: 30),
            makeRecord(exercise: "Back Squat", weight: 300.5, daysAgo: 20),
            makeRecord(exercise: "Back Squat", weight: 301.0, daysAgo: 10),
        ]
        let tightAlerts = PlateauDetector.detect(from: tightRecords, catalog: weightliftingExercises)
        XCTAssertEqual(tightAlerts.count, 1, "0.33% is below 0.5% compound threshold")
    }

    func testDetect_IsolationLift_UsesHigherThreshold() {
        // Press category uses 1.5% threshold.
        // 1.2% improvement should NOT be flagged for press exercises with catalog.
        let records = [
            makeRecord(exercise: "Flat Barbell Bench Press", weight: 165.0, daysAgo: 30),
            makeRecord(exercise: "Flat Barbell Bench Press", weight: 166.0, daysAgo: 20),
            makeRecord(exercise: "Flat Barbell Bench Press", weight: 167.0, daysAgo: 10),
        ]
        // 1.2% improvement < 1.5% press threshold → flagged
        let alerts = PlateauDetector.detect(from: records, catalog: weightliftingExercises)
        XCTAssertEqual(alerts.count, 1)

        // Now with 2% improvement → NOT flagged
        let progressRecords = [
            makeRecord(exercise: "Flat Barbell Bench Press", weight: 150.0, daysAgo: 30),
            makeRecord(exercise: "Flat Barbell Bench Press", weight: 152.0, daysAgo: 20),
            makeRecord(exercise: "Flat Barbell Bench Press", weight: 153.0, daysAgo: 10),
        ]
        let progressAlerts = PlateauDetector.detect(from: progressRecords, catalog: weightliftingExercises)
        XCTAssertTrue(progressAlerts.isEmpty)
    }

    // MARK: - Volume Plateau Detection

    func testDetectVolumePlateaus_FlatVolume_AlertGenerated() {
        // Same volume each week for 4 weeks
        let workouts = (0..<4).flatMap { week -> [Workout] in
            [makeWorkout(
                exerciseName: "Back Squat",
                sets: 4, reps: 8, weight: 200,
                daysAgo: week * 7 + 1
            )]
        }
        let alerts = PlateauDetector.detectVolumePlateaus(from: workouts)
        XCTAssertFalse(alerts.isEmpty, "Flat volume should trigger an alert")
        XCTAssertEqual(alerts.first?.plateauType, .volume)
        XCTAssertTrue(alerts.first!.recommendation.contains("volume has plateaued"))
    }

    func testDetectVolumePlateaus_RisingVolume_NoAlert() {
        // Increasing volume each week
        let workouts = (0..<4).map { week in
            makeWorkout(
                exerciseName: "Back Squat",
                sets: 4 + week, reps: 8, weight: 200,
                daysAgo: (3 - week) * 7 + 1
            )
        }
        let alerts = PlateauDetector.detectVolumePlateaus(from: workouts)
        XCTAssertTrue(alerts.isEmpty, "Rising volume should not trigger an alert")
    }

    // MARK: - Rate of Progress Detection

    func testDetectSlowingProgress_HalfRate_EarlyWarning() {
        // First half: rapid progress (10 lbs/week for 3 weeks)
        // Second half: stalled (1 lb/week for 3 weeks)
        let records = [
            makeRecord(weight: 200, daysAgo: 42),
            makeRecord(weight: 210, daysAgo: 35),
            makeRecord(weight: 220, daysAgo: 28),
            makeRecord(weight: 221, daysAgo: 21),
            makeRecord(weight: 222, daysAgo: 14),
            makeRecord(weight: 223, daysAgo: 7),
        ]
        let alerts = PlateauDetector.detectSlowingProgress(from: records)
        XCTAssertEqual(alerts.count, 1)
        XCTAssertTrue(alerts.first!.message.contains("slowing"))
    }

    func testDetectSlowingProgress_TooFewRecords_NoAlert() {
        let records = [
            makeRecord(weight: 200, daysAgo: 20),
            makeRecord(weight: 200, daysAgo: 10),
        ]
        let alerts = PlateauDetector.detectSlowingProgress(from: records)
        XCTAssertTrue(alerts.isEmpty, "Should require at least 5 records")
    }

    func testDetectSlowingProgress_SteadyProgress_NoAlert() {
        // Consistent progress throughout
        let records = (0..<6).map { i in
            makeRecord(weight: 200 + Double(i) * 5, daysAgo: (5 - i) * 7)
        }
        let alerts = PlateauDetector.detectSlowingProgress(from: records)
        XCTAssertTrue(alerts.isEmpty, "Steady progress should not trigger a warning")
    }

    // MARK: - Multiple Exercises

    func testDetect_MultipleExercises_IndependentDetection() {
        let records = [
            // Squat: stalled
            makeRecord(exercise: "Back Squat", weight: 200, daysAgo: 30),
            makeRecord(exercise: "Back Squat", weight: 200, daysAgo: 20),
            makeRecord(exercise: "Back Squat", weight: 200, daysAgo: 10),
            // Bench: progressing
            makeRecord(exercise: "Flat Barbell Bench Press", weight: 150, daysAgo: 30),
            makeRecord(exercise: "Flat Barbell Bench Press", weight: 160, daysAgo: 20),
            makeRecord(exercise: "Flat Barbell Bench Press", weight: 170, daysAgo: 10),
        ]
        let alerts = PlateauDetector.detect(from: records)
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts.first?.exerciseName, "Back Squat")
    }

    // MARK: - Recommendations

    func testDetect_LongStall_RecommendVariation() {
        // 7 stalled records within the 90-day window
        let records = (0..<7).map { i in
            makeRecord(weight: 200, daysAgo: (7 - i) * 10)
        }
        let alerts = PlateauDetector.detect(from: records)
        XCTAssertFalse(alerts.isEmpty)
        XCTAssertTrue(alerts.first!.recommendation.contains("variation"))
    }

    // MARK: - Window Expiry

    func testDetect_OldRecords_NoAlert() {
        let records = [
            makeRecord(weight: 200, daysAgo: 200),
            makeRecord(weight: 200, daysAgo: 150),
            makeRecord(weight: 200, daysAgo: 100),
        ]
        let alerts = PlateauDetector.detect(from: records)
        XCTAssertTrue(alerts.isEmpty, "Records outside the max window should be ignored")
    }

    // MARK: - Sorting

    func testDetect_SortedBySeverity() {
        let records = [
            // Exercise A: 3 stalled
            makeRecord(exercise: "A", weight: 100, daysAgo: 30),
            makeRecord(exercise: "A", weight: 100, daysAgo: 20),
            makeRecord(exercise: "A", weight: 100, daysAgo: 10),
            // Exercise B: 5 stalled
            makeRecord(exercise: "B", weight: 100, daysAgo: 50),
            makeRecord(exercise: "B", weight: 100, daysAgo: 40),
            makeRecord(exercise: "B", weight: 100, daysAgo: 30),
            makeRecord(exercise: "B", weight: 100, daysAgo: 20),
            makeRecord(exercise: "B", weight: 100, daysAgo: 10),
        ]
        let alerts = PlateauDetector.detect(from: records)
        XCTAssertEqual(alerts.count, 2)
        // B should be first (longer stall)
        XCTAssertEqual(alerts.first?.exerciseName, "B")
    }
}
