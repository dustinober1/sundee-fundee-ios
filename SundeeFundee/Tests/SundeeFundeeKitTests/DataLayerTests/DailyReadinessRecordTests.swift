import XCTest
@testable import SundeeFundeeKit

final class DailyReadinessRecordTests: XCTestCase {
    func testStableIDUsesLocalDayAndNotUserIdentity() {
        let zone = TimeZone(identifier: "America/New_York")!
        let record = DailyReadinessRecord(
            assessment: makeAssessment(), timeZone: zone,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        XCTAssertEqual(record.id, "readiness-2023-11-14")
        XCTAssertEqual(record.timeZoneIdentifier, "America/New_York")
    }

    func testJSONRoundTripPreservesAssessment() throws {
        let original = DailyReadinessRecord(assessment: makeAssessment(), timeZone: .gmt)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DailyReadinessRecord.self, from: encoder.encode(original))
        XCTAssertEqual(try decoded.assessment(), makeAssessment())
    }

    func testDecodingLegacyPayloadDefaultsSchemaVersionAndIgnoresUnknownFields() throws {
        let record = DailyReadinessRecord(assessment: makeAssessment(), timeZone: .gmt)
        var payload = try JSONSerialization.jsonObject(with: JSONEncoder().encode(record)) as! [String: Any]
        payload.removeValue(forKey: "schemaVersion")
        payload["futureField"] = "ignored"
        let data = try JSONSerialization.data(withJSONObject: payload)

        let decoded = try JSONDecoder().decode(DailyReadinessRecord.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, DailyReadinessRecord.currentSchemaVersion)
        XCTAssertEqual(decoded.id, record.id)
    }

    func testDatesEncodeAsStringsAndRecordContainsNoBooleanFields() throws {
        let record = DailyReadinessRecord(assessment: makeAssessment(), timeZone: .gmt)
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(record)) as! [String: Any]

        XCTAssertTrue(object["assessmentDate"] is String)
        XCTAssertTrue(object["dateCreated"] is String)
        XCTAssertTrue(object["dateUpdated"] is String)
        let json = String(data: try JSONEncoder().encode(record), encoding: .utf8)!
        XCTAssertFalse(json.contains(":true"))
        XCTAssertFalse(json.contains(":false"))
    }

    @MainActor
    func testLocalClientReplacesTheSameLocalDay() async throws {
        let suiteName = "ReadinessRecordTests.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        let client = LocalDataClient(userDefaults: UserDefaults(suiteName: suiteName)!)
        try await client.save(
            DailyReadinessRecord(assessment: makeAssessment(score: 72), timeZone: .gmt),
            recordType: DailyReadinessRecord.recordType
        )
        try await client.save(
            DailyReadinessRecord(assessment: makeAssessment(score: 68), timeZone: .gmt),
            recordType: DailyReadinessRecord.recordType
        )

        let records: [DailyReadinessRecord] = try await client.fetchAll(
            recordType: DailyReadinessRecord.recordType
        )
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.totalScore, 68)
    }

    private func makeAssessment(score: Int = 72) -> ReadinessAssessment {
        ReadinessAssessment(
            assessmentDate: Date(timeIntervalSince1970: 1_700_000_000), state: .maintain,
            totalScore: score, confidence: .medium,
            subScores: [.physiological: 80, .subjective: 65],
            availableSignals: [.sleep, .energy], missingSignals: [.hrv], staleSignals: [],
            positiveReasons: [], cautionReasons: [.stillLearning], modelVersion: "readiness-v1"
        )
    }
}
