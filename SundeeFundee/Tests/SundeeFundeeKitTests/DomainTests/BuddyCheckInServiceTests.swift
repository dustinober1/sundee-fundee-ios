import XCTest
@testable import SundeeFundeeKit

final class BuddyCheckInServiceTests: XCTestCase {

    // MARK: - Record Stores Only Allowed Fields

    func testCheckInRecordStoresStatusDisplayNameAndOptionalMessage() {
        let record = BuddyCheckInRecord(
            id: "test-1",
            threadID: "thread-1",
            displayName: "Alice",
            statusRaw: "completed",
            message: "Great workout!",
            checkInDate: Date(),
            dateCreated: Date()
        )

        XCTAssertEqual(record.status, .completed)
        XCTAssertEqual(record.displayName, "Alice")
        XCTAssertEqual(record.message, "Great workout!")
        XCTAssertEqual(record.threadID, "thread-1")
    }

    func testCheckInRecordStatusDefaultsToPlannedForInvalidRawValue() {
        let record = BuddyCheckInRecord(
            id: "test-2",
            threadID: "thread-1",
            displayName: "Bob",
            statusRaw: "invalid_status",
            message: nil,
            checkInDate: Date(),
            dateCreated: Date()
        )

        XCTAssertEqual(record.status, .planned)
    }

    func testCheckInRecordNeverStoresHealthData() {
        // Verify BuddyCheckInRecord has no properties for:
        // cycle phase, pain intensity, HealthKit IDs, or exact workout details.
        // This test ensures the record type remains minimal.
        let record = BuddyCheckInRecord(
            id: "test-3",
            threadID: "thread-1",
            displayName: "Carol",
            statusRaw: "completed",
            message: "Feeling good",
            checkInDate: Date(),
            dateCreated: Date()
        )

        // The record should only expose: id, threadID, displayName, statusRaw, message,
        // checkInDate, dateCreated, and the computed status.
        // No health-related fields should exist.
        XCTAssertEqual(record.id, "test-3")
        XCTAssertEqual(record.threadID, "thread-1")
        XCTAssertEqual(record.displayName, "Carol")
        XCTAssertEqual(record.statusRaw, "completed")
        XCTAssertNotNil(record.message)
        XCTAssertNotNil(record.checkInDate)
        XCTAssertNotNil(record.dateCreated)
    }

    // MARK: - Round-Trip Save and Load

    func testSaveAndLoadRoundTripsCorrectly() async throws {
        let mockClient = MockCloudKitClient()
        let service = BuddyCheckInService(dataClient: mockClient)

        let now = Date()
        let record = BuddyCheckInRecord(
            id: "round-trip-1",
            threadID: "thread-rt",
            displayName: "Dana",
            statusRaw: "completed",
            message: "Crushed it today",
            checkInDate: now,
            dateCreated: now
        )

        try await service.save(record)

        let loaded: [BuddyCheckInRecord] = try await mockClient.fetchAll(
            recordType: "BuddyCheckInRecord"
        )

        XCTAssertEqual(loaded.count, 1)
        let fetched = loaded[0]
        XCTAssertEqual(fetched.id, record.id)
        XCTAssertEqual(fetched.threadID, record.threadID)
        XCTAssertEqual(fetched.displayName, record.displayName)
        XCTAssertEqual(fetched.statusRaw, record.statusRaw)
        XCTAssertEqual(fetched.message, record.message)
        XCTAssertEqual(fetched.status, .completed)
    }

    func testSaveMultipleCheckInsAndLoadAll() async throws {
        let mockClient = MockCloudKitClient()
        let service = BuddyCheckInService(dataClient: mockClient)

        let now = Date()
        let record1 = BuddyCheckInRecord(
            id: "multi-1",
            threadID: "thread-multi",
            displayName: "Eve",
            statusRaw: "completed",
            message: nil,
            checkInDate: now,
            dateCreated: now
        )
        let record2 = BuddyCheckInRecord(
            id: "multi-2",
            threadID: "thread-multi",
            displayName: "Eve",
            statusRaw: "skipped",
            message: "Rest day",
            checkInDate: now,
            dateCreated: now
        )

        try await service.save(record1)
        try await service.save(record2)

        let loaded: [BuddyCheckInRecord] = try await mockClient.fetchAll(
            recordType: "BuddyCheckInRecord"
        )

        XCTAssertEqual(loaded.count, 2)
    }

    // MARK: - weeklySummary

    func testWeeklySummaryCountsCompletedCheckIns() async throws {
        let mockClient = MockCloudKitClient()
        let service = BuddyCheckInService(dataClient: mockClient)

        let weekStart = Date(timeIntervalSince1970: 1_770_000_000)
        let day1 = weekStart
        let day2 = weekStart.addingTimeInterval(86400)
        let day3 = weekStart.addingTimeInterval(2 * 86400)

        // 2 completed, 1 skipped, 1 planned
        let records = [
            BuddyCheckInRecord(
                id: "ws-1", threadID: "thread-ws",
                displayName: "Frank", statusRaw: "completed",
                message: nil, checkInDate: day1, dateCreated: day1
            ),
            BuddyCheckInRecord(
                id: "ws-2", threadID: "thread-ws",
                displayName: "Frank", statusRaw: "completed",
                message: "Strong", checkInDate: day2, dateCreated: day2
            ),
            BuddyCheckInRecord(
                id: "ws-3", threadID: "thread-ws",
                displayName: "Frank", statusRaw: "skipped",
                message: nil, checkInDate: day3, dateCreated: day3
            ),
            BuddyCheckInRecord(
                id: "ws-4", threadID: "thread-ws",
                displayName: "Frank", statusRaw: "planned",
                message: nil, checkInDate: day3, dateCreated: day3
            ),
        ]

        for record in records {
            try await service.save(record)
        }

        let summary = await service.weeklySummary(
            threadID: "thread-ws",
            weekStartDate: weekStart
        )

        XCTAssertEqual(summary.threadID, "thread-ws")
        XCTAssertEqual(summary.totalCheckIns, 4)
        XCTAssertEqual(summary.completedCheckIns, 2)
        XCTAssertEqual(summary.weekStartDate, weekStart)
    }

    func testWeeklySummaryExcludesOtherThreads() async throws {
        let mockClient = MockCloudKitClient()
        let service = BuddyCheckInService(dataClient: mockClient)

        let weekStart = Date(timeIntervalSince1970: 1_770_000_000)

        let recordOtherThread = BuddyCheckInRecord(
            id: "other-1", threadID: "thread-other",
            displayName: "Grace", statusRaw: "completed",
            message: nil, checkInDate: weekStart, dateCreated: weekStart
        )
        let recordTargetThread = BuddyCheckInRecord(
            id: "target-1", threadID: "thread-target",
            displayName: "Grace", statusRaw: "completed",
            message: nil, checkInDate: weekStart, dateCreated: weekStart
        )

        try await service.save(recordOtherThread)
        try await service.save(recordTargetThread)

        let summary = await service.weeklySummary(
            threadID: "thread-target",
            weekStartDate: weekStart
        )

        XCTAssertEqual(summary.totalCheckIns, 1)
        XCTAssertEqual(summary.completedCheckIns, 1)
    }

    func testWeeklySummaryExcludesDatesOutsideWeek() async throws {
        let mockClient = MockCloudKitClient()
        let service = BuddyCheckInService(dataClient: mockClient)

        let weekStart = Date(timeIntervalSince1970: 1_770_000_000)
        let previousWeek = weekStart.addingTimeInterval(-7 * 86400)

        let recordOutside = BuddyCheckInRecord(
            id: "outside-1", threadID: "thread-range",
            displayName: "Heidi", statusRaw: "completed",
            message: nil, checkInDate: previousWeek, dateCreated: previousWeek
        )
        let recordInside = BuddyCheckInRecord(
            id: "inside-1", threadID: "thread-range",
            displayName: "Heidi", statusRaw: "completed",
            message: nil, checkInDate: weekStart, dateCreated: weekStart
        )

        try await service.save(recordOutside)
        try await service.save(recordInside)

        let summary = await service.weeklySummary(
            threadID: "thread-range",
            weekStartDate: weekStart
        )

        XCTAssertEqual(summary.totalCheckIns, 1)
        XCTAssertEqual(summary.completedCheckIns, 1)
    }

    func testWeeklySummaryReturnsZeroForThreadWithNoCheckIns() async {
        let mockClient = MockCloudKitClient()
        let service = BuddyCheckInService(dataClient: mockClient)

        let weekStart = Date(timeIntervalSince1970: 1_770_000_000)

        let summary = await service.weeklySummary(
            threadID: "thread-empty",
            weekStartDate: weekStart
        )

        XCTAssertEqual(summary.threadID, "thread-empty")
        XCTAssertEqual(summary.totalCheckIns, 0)
        XCTAssertEqual(summary.completedCheckIns, 0)
    }

    // MARK: - Codable Round-Trip

    func testCheckInRecordCodableRoundTrip() throws {
        // The repo's persistence stack uses `.iso8601`, which normalizes dates
        // to whole-second precision during JSON round-trips.
        let now = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970))
        let record = BuddyCheckInRecord(
            id: "codec-1",
            threadID: "thread-codec",
            displayName: "Ivan",
            statusRaw: "skipped",
            message: "Too tired",
            checkInDate: now,
            dateCreated: now
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(BuddyCheckInRecord.self, from: data)

        XCTAssertEqual(decoded, record)
        XCTAssertEqual(decoded.status, .skipped)
    }
}
