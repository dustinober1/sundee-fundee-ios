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

    @Test func openCopyOnlyClaimsSuccessAfterPresencePersists() {
        #expect(
            TodayPresenceCopy.openState(hasPresence: true)
                == "Opening Today already counted as showing up"
        )
        #expect(
            TodayPresenceCopy.openState(hasPresence: false)
                == "Open Today to count today as showing up"
        )
    }

    @Test func achievementCopyIsConciseAndNonPunitive() {
        let forbidden = ["lost", "failed", "reset", "broke", "missed"]

        for achievement in ConsistencyAchievement.allCases {
            #expect(!achievement.title.isEmpty)
            #expect(!achievement.supportiveDescription.isEmpty)
            #expect(!achievement.systemImage.isEmpty)
            #expect(forbidden.allSatisfy {
                !achievement.supportiveDescription.lowercased().contains($0)
            })
        }
    }
}
