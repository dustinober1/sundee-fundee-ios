import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("Daily presence privacy")
struct DailyPresencePrivacyTests {
    @Test func encodedRecordContainsOnlyApprovedFields() throws {
        let record = DailyPresenceRecord(
            dayKey: "2026-07-26",
            timeZoneIdentifier: "America/New_York",
            firstOpenDate: Date(timeIntervalSince1970: 1_753_528_400),
            participationLevel: .checkedIn,
            status: .tired
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let object = try #require(
            JSONSerialization.jsonObject(with: encoder.encode(record)) as? [String: Any]
        )

        let approved = Set([
            "id", "dayKey", "timeZoneIdentifier", "firstOpenDate",
            "mostRecentOpenDate", "participationLevelRaw", "statusRaw",
            "actionEvidenceRaw", "dateCreated", "dateUpdated", "modelVersion"
        ])
        #expect(Set(object.keys) == approved)
        #expect(object.keys.allSatisfy { key in
            !["cycle", "pain", "health", "hrv", "readiness"].contains { term in
                key.localizedCaseInsensitiveContains(term)
            }
        })
    }
}
