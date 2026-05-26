import XCTest
@testable import SundeeFundeeKit

final class WorkoutEffortLogTests: XCTestCase {
    func testInitializerClampsRPEToValidRange() {
        let low = WorkoutEffortLog(
            id: "low",
            workoutID: "workout-1",
            exerciseName: "Back Squat",
            setID: "set-1",
            rpe: -2,
            note: nil,
            dateCreated: Date(timeIntervalSince1970: 1_000)
        )
        let high = WorkoutEffortLog(
            id: "high",
            workoutID: "workout-1",
            exerciseName: nil,
            setID: nil,
            rpe: 14,
            note: nil,
            dateCreated: Date(timeIntervalSince1970: 1_000)
        )

        XCTAssertEqual(low.rpe, 1)
        XCTAssertEqual(high.rpe, 10)
    }

    func testSessionLevelEffortLogSavesAndFetchesThroughMockCloudKitClient() async throws {
        let client = MockCloudKitClient()
        let log = WorkoutEffortLog(
            id: "effort-1",
            workoutID: "workout-1",
            exerciseName: nil,
            setID: nil,
            rpe: 7,
            note: "steady",
            dateCreated: Date(timeIntervalSince1970: 1_000)
        )

        try await client.save([log], recordType: "WorkoutEffortLog")
        let fetched: [WorkoutEffortLog] = try await client.fetchAll(recordType: "WorkoutEffortLog")

        XCTAssertEqual(fetched, [log])
        XCTAssertEqual(client.recordCount(for: "WorkoutEffortLog"), 1)
    }

    func testCodingIncludesRequiredExportFields() throws {
        let log = WorkoutEffortLog(
            id: "effort-1",
            workoutID: "workout-1",
            exerciseName: "Strict Press",
            setID: "set-3",
            rpe: 8,
            note: nil,
            dateCreated: Date(timeIntervalSince1970: 1_000)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(log)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["workoutID"] as? String, "workout-1")
        XCTAssertEqual(json["exerciseName"] as? String, "Strict Press")
        XCTAssertEqual(json["setID"] as? String, "set-3")
        XCTAssertEqual(json["rpe"] as? Int, 8)
        XCTAssertNotNil(json["dateCreated"])
    }
}
