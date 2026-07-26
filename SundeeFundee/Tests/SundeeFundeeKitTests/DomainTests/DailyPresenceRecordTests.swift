import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("Daily presence record")
struct DailyPresenceRecordTests {
    @Test func identifierIsStableAndCloudKitSafe() {
        #expect(
            DailyPresenceRecord.makeID(
                dayKey: "2026-07-26",
                timeZoneIdentifier: "America/New_York"
            ) == "presence-2026-07-26-America-New_York"
        )
    }

    @Test func promotionNeverDowngradesParticipation() {
        let firstOpen = Date(timeIntervalSince1970: 1_753_500_000)
        let record = DailyPresenceRecord(
            dayKey: "2026-07-26",
            timeZoneIdentifier: "America/New_York",
            firstOpenDate: firstOpen
        )

        let acted = record.promoting(to: .acted, status: .resting, at: firstOpen.addingTimeInterval(60))
        let attemptedDowngrade = acted.promoting(to: .checkedIn, status: .tired, at: firstOpen.addingTimeInterval(120))

        #expect(attemptedDowngrade.participationLevel == .acted)
        #expect(attemptedDowngrade.status == .tired)
        #expect(attemptedDowngrade.mostRecentOpenDate == firstOpen.addingTimeInterval(120))
    }

    @Test func oldRecordWithoutOptionalFieldsDecodes() throws {
        let json = """
        {
          "id":"presence-2026-07-26-America_New_York",
          "dayKey":"2026-07-26",
          "timeZoneIdentifier":"America/New_York",
          "firstOpenDate":"2026-07-26T12:00:00Z",
          "mostRecentOpenDate":"2026-07-26T12:00:00Z",
          "participationLevelRaw":"showedUp",
          "dateCreated":"2026-07-26T12:00:00Z",
          "dateUpdated":"2026-07-26T12:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let record = try decoder.decode(DailyPresenceRecord.self, from: Data(json.utf8))

        #expect(record.status == nil)
        #expect(record.modelVersion == 1)
    }
}
