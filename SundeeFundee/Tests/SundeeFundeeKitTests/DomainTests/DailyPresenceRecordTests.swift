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
            ) == "presence-2026-07-26"
        )
        #expect(
            DailyPresenceRecord.makeID(
                dayKey: "2026-07-26",
                timeZoneIdentifier: "Pacific/Kiritimati"
            ) == "presence-2026-07-26"
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
        #expect(attemptedDowngrade.actionEvidence == [.rested])
        #expect(attemptedDowngrade.mostRecentOpenDate == firstOpen.addingTimeInterval(120))
    }

    @Test(
        "A later check-in never erases durable action evidence",
        arguments: [
            (
                DailyPresenceStatus.trained,
                DailyPresenceStatus.ready,
                DailyPresenceActionEvidence.trained
            ),
            (
                DailyPresenceStatus.resting,
                DailyPresenceStatus.tired,
                DailyPresenceActionEvidence.rested
            ),
            (
                DailyPresenceStatus.resting,
                DailyPresenceStatus.sore,
                DailyPresenceActionEvidence.recovered
            ),
        ]
    )
    func statusAfterAction(
        actionStatus: DailyPresenceStatus,
        checkInStatus: DailyPresenceStatus,
        evidence: DailyPresenceActionEvidence
    ) {
        let firstOpen = Date(timeIntervalSince1970: 1_753_500_000)
        let record = DailyPresenceRecord(
            dayKey: "2026-07-26",
            timeZoneIdentifier: "America/New_York",
            firstOpenDate: firstOpen
        )
        let acted = record.promoting(
            to: .acted,
            status: actionStatus,
            action: evidence,
            at: firstOpen.addingTimeInterval(60)
        )

        let checkedIn = acted.promoting(
            to: .checkedIn,
            status: checkInStatus,
            at: firstOpen.addingTimeInterval(120)
        )

        #expect(checkedIn.participationLevel == .acted)
        #expect(checkedIn.status == checkInStatus)
        #expect(checkedIn.actionEvidence == [evidence])
    }

    @Test func mergeIsMonotonicAcrossDevicesAndLegacyIdentifiers() {
        let early = Date(timeIntervalSince1970: 1_753_500_000)
        let late = early.addingTimeInterval(300)
        let local = DailyPresenceRecord(
            dayKey: "2026-07-26",
            timeZoneIdentifier: "America/New_York",
            firstOpenDate: late,
            participationLevel: .checkedIn,
            status: .tired,
            dateCreated: late,
            dateUpdated: late
        )
        let remote = DailyPresenceRecord(
            id: "presence-2026-07-26-Pacific-Kiritimati",
            dayKey: "2026-07-26",
            timeZoneIdentifier: "Pacific/Kiritimati",
            firstOpenDate: early,
            mostRecentOpenDate: early.addingTimeInterval(60),
            participationLevel: .acted,
            status: .trained,
            actionEvidence: [.trained],
            dateCreated: early,
            dateUpdated: early.addingTimeInterval(60),
            modelVersion: 1
        )

        let merged = local.merging(with: remote)

        #expect(merged.id == "presence-2026-07-26")
        #expect(merged.firstOpenDate == early)
        #expect(merged.mostRecentOpenDate == late)
        #expect(merged.dateCreated == early)
        #expect(merged.dateUpdated == late)
        #expect(merged.participationLevel == .acted)
        #expect(merged.status == .tired)
        #expect(merged.actionEvidence == [.trained])
        #expect(merged.timeZoneIdentifier == "Pacific/Kiritimati")
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
        #expect(record.actionEvidence.isEmpty)
        #expect(record.modelVersion == 1)
    }

    @Test func legacyActedStatusDecodesDurableEvidence() throws {
        let json = """
        {
          "id":"presence-2026-07-26-America-New_York",
          "dayKey":"2026-07-26",
          "timeZoneIdentifier":"America/New_York",
          "firstOpenDate":"2026-07-26T12:00:00Z",
          "mostRecentOpenDate":"2026-07-26T12:00:00Z",
          "participationLevelRaw":"acted",
          "statusRaw":"trained",
          "dateCreated":"2026-07-26T12:00:00Z",
          "dateUpdated":"2026-07-26T12:00:00Z",
          "modelVersion":1
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let record = try decoder.decode(DailyPresenceRecord.self, from: Data(json.utf8))

        #expect(record.actionEvidence == [.trained])
    }
}
