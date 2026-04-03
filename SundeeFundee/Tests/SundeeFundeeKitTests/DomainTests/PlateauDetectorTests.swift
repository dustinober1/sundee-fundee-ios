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
