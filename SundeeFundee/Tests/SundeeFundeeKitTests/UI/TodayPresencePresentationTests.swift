import Testing
@testable import SundeeFundeeKit

@Suite("Today presence presentation")
struct TodayPresencePresentationTests {
    @Test func statusLabelsAreShortAndSupportive() {
        #expect(DailyPresenceStatus.ready.displayName == "Ready")
        #expect(DailyPresenceStatus.resting.displayName == "Resting")
        #expect(DailyPresenceStatus.trained.systemImage == "checkmark.circle")
    }

    @Test func actionCopyDoesNotPunishMissedDays() {
        let forbidden = ["lost", "failed", "reset", "broke"]
        #expect(forbidden.allSatisfy {
            !ConsistencyMomentumCopy.welcomeBack.lowercased().contains($0)
        })
    }
}
