import XCTest
@testable import SundeeFundeeKit

final class TodayWorkoutPreferenceServiceTests: XCTestCase {
    func testSaveDurationPreferenceUsesStableDateKey() async throws {
        let client = MockCloudKitClient()
        let service = TodayWorkoutPreferenceService(dataClient: client)
        let date = ISO8601DateFormatter().date(from: "2026-06-30T12:00:00Z")!

        try await service.saveDurationPreference(minutes: 30, date: date)

        let records: [TodayWorkoutPreferenceRecord] = try await client.fetchAll(recordType: "TodayWorkoutPreference")
        XCTAssertEqual(records.first?.id, "today_preferences_2026-06-30")
        XCTAssertEqual(records.first?.preferredMinutes, 30)
    }
}
