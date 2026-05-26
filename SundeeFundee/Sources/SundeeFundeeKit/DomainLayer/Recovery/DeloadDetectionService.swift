import Foundation

public struct DeloadRecommendation: Sendable, Equatable {
    public let isRecommended: Bool
    public let reason: String
    public let recommendedDays: Int

    public init(isRecommended: Bool, reason: String, recommendedDays: Int) {
        self.isRecommended = isRecommended
        self.reason = reason
        self.recommendedDays = recommendedDays
    }
}

public enum DeloadDetectionService {
    public static func recommendation(
        recentScores: [RecoveryScoreRecord],
        recentPainLogs: [DailyPainLog],
        recentSleepHours: [Double] = []
    ) -> DeloadRecommendation {
        let recent = recentScores
            .sorted(by: { $0.scoreDate > $1.scoreDate })
            .prefix(7)
        let lowDays = recent.filter { $0.totalScore < 45 }.count
        let veryLowDays = recent.filter { $0.totalScore < 35 }.count
        let highPainDays = recentPainLogs
            .sorted(by: { $0.date > $1.date })
            .prefix(7)
            .filter { $0.intensity >= 7 }
            .count
        let poorSleepDays = recentSleepHours.filter { $0 > 0 && $0 < 6.0 }.count

        if veryLowDays >= 2 || lowDays >= 3 {
            return DeloadRecommendation(
                isRecommended: true,
                reason: "Recovery has been low across multiple recent days.",
                recommendedDays: 2
            )
        }

        if highPainDays >= 2 && lowDays >= 1 {
            return DeloadRecommendation(
                isRecommended: true,
                reason: "Pain and recovery trends suggest reducing load for a short block.",
                recommendedDays: 2
            )
        }

        if highPainDays >= 1 && poorSleepDays >= 2 {
            return DeloadRecommendation(
                isRecommended: true,
                reason: "Pain and sleep trends suggest an active-recovery day.",
                recommendedDays: 1
            )
        }

        if poorSleepDays >= 3 && lowDays >= 1 {
            return DeloadRecommendation(
                isRecommended: true,
                reason: "Sleep and readiness are both trending down.",
                recommendedDays: 1
            )
        }

        return DeloadRecommendation(
            isRecommended: false,
            reason: "No sustained fatigue pattern detected.",
            recommendedDays: 0
        )
    }
}
