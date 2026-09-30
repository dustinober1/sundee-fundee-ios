import Foundation

// MARK: - DeloadTrigger

public enum DeloadTrigger: String, Sendable, Equatable {
    case highPain
    case acuteSleepDeficit
    case painAndSleep
    case sustainedVolumeAccumulation
    case prolongedReadinessSuppression
    case rpeCreep
}

// MARK: - DeloadRecommendation

public struct DeloadRecommendation: Sendable, Equatable {
    public let isRecommended: Bool
    public let reason: String
    public let recommendedDays: Int
    public let trigger: DeloadTrigger?

    public init(
        isRecommended: Bool,
        reason: String,
        recommendedDays: Int,
        trigger: DeloadTrigger? = nil
    ) {
        self.isRecommended = isRecommended
        self.reason = reason
        self.recommendedDays = recommendedDays
        self.trigger = trigger
    }
}

// MARK: - DeloadDetectionService

public enum DeloadDetectionService {
    /// Evaluates acute symptom markers and multi-week athletic load patterns
    /// to recommend structured deloads or active recovery sessions.
    public static func recommendation(
        recentPainLogs: [DailyPainLog],
        recentSleepHours: [Double] = [],
        recentWorkouts: [Workout] = [],
        recentReadinessScores: [Int] = [],
        recentEffortLogs: [WorkoutEffortLog] = [],
        recentRPEs: [Double] = [],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> DeloadRecommendation {
        let highPainDays = recentPainLogs
            .sorted { $0.date > $1.date }
            .prefix(7)
            .filter { $0.intensity >= 7 }
            .count
        let poorSleepDays = recentSleepHours.filter { $0 > 0 && $0 < 6.0 }.count

        // 1. High pain across multiple recent days
        if highPainDays >= 2 {
            return DeloadRecommendation(
                isRecommended: true,
                reason: "Pain has been high across multiple recent days.",
                recommendedDays: 2,
                trigger: .highPain
            )
        }

        // 2. High pain combined with poor sleep
        if highPainDays >= 1 && poorSleepDays >= 2 {
            return DeloadRecommendation(
                isRecommended: true,
                reason: "Pain and sleep trends suggest an active-recovery day.",
                recommendedDays: 1,
                trigger: .painAndSleep
            )
        }

        // 3. Acute multi-night sleep deficit
        if poorSleepDays >= 3 {
            return DeloadRecommendation(
                isRecommended: true,
                reason: "Sleep has been low across multiple recent nights.",
                recommendedDays: 1,
                trigger: .acuteSleepDeficit
            )
        }

        // 4. Prolonged readiness suppression (3+ consecutive low scores)
        if evaluateReadinessSuppression(scores: recentReadinessScores) {
            return DeloadRecommendation(
                isRecommended: true,
                reason: "Readiness has been suppressed for 3+ consecutive days, signaling accumulated systemic fatigue.",
                recommendedDays: 2,
                trigger: .prolongedReadinessSuppression
            )
        }

        // 5. RPE creep / elevated perceived exertion
        if evaluateRPECreep(effortLogs: recentEffortLogs, rawRPEs: recentRPEs) {
            return DeloadRecommendation(
                isRecommended: true,
                reason: "Perceived effort (RPE) has remained elevated across recent sessions, indicating central nervous system fatigue.",
                recommendedDays: 2,
                trigger: .rpeCreep
            )
        }

        // 6. Sustained progressive volume accumulation without recovery (3+ weeks)
        if evaluateVolumeAccumulation(workouts: recentWorkouts, calendar: calendar, referenceDate: referenceDate) {
            return DeloadRecommendation(
                isRecommended: true,
                reason: "You've completed 3+ consecutive weeks of progressive training volume. A structured deload will prevent overreaching.",
                recommendedDays: 3,
                trigger: .sustainedVolumeAccumulation
            )
        }

        return DeloadRecommendation(
            isRecommended: false,
            reason: "No sustained fatigue pattern detected.",
            recommendedDays: 0,
            trigger: nil
        )
    }

    // MARK: - Evaluation Helpers

    private static func evaluateReadinessSuppression(scores: [Int]) -> Bool {
        guard scores.count >= 3 else { return false }
        let recentThree = scores.prefix(3)
        return recentThree.allSatisfy { $0 <= 45 }
    }

    private static func evaluateRPECreep(
        effortLogs: [WorkoutEffortLog],
        rawRPEs: [Double]
    ) -> Bool {
        if !rawRPEs.isEmpty {
            guard rawRPEs.count >= 3 else { return false }
            let recentThree = rawRPEs.prefix(3)
            let average = recentThree.reduce(0, +) / Double(recentThree.count)
            return average >= 9.0
        }

        guard effortLogs.count >= 3 else { return false }
        let recentThree = effortLogs.sorted { $0.dateCreated > $1.dateCreated }.prefix(3)
        let average = Double(recentThree.map(\.rpe).reduce(0, +)) / Double(recentThree.count)
        return average >= 9.0
    }

    private static func evaluateVolumeAccumulation(
        workouts: [Workout],
        calendar: Calendar,
        referenceDate: Date
    ) -> Bool {
        let completed = workouts.filter { $0.isComplete || $0.completedAt != nil }
        guard completed.count >= 6 else { return false }

        var weeklyTonnage = [Double](repeating: 0.0, count: 3)
        var weeklyCounts = [Int](repeating: 0, count: 3)

        for workout in completed {
            let workoutDate = workout.completedAt ?? workout.date
            let daysAgo = calendar.dateComponents([.day], from: workoutDate, to: referenceDate).day ?? -1
            if (0..<7).contains(daysAgo) {
                weeklyTonnage[0] += workout.totalVolume
                weeklyCounts[0] += 1
            } else if (7..<14).contains(daysAgo) {
                weeklyTonnage[1] += workout.totalVolume
                weeklyCounts[1] += 1
            } else if (14..<21).contains(daysAgo) {
                weeklyTonnage[2] += workout.totalVolume
                weeklyCounts[2] += 1
            }
        }

        guard weeklyCounts[0] >= 2, weeklyCounts[1] >= 2, weeklyCounts[2] >= 2,
              weeklyTonnage[0] > 0, weeklyTonnage[1] > 0, weeklyTonnage[2] > 0 else {
            return false
        }

        // Tonnage stayed sustained or progressively increased across all 3 weeks
        let isProgressiveOrSustained = (weeklyTonnage[0] >= weeklyTonnage[1] * 0.95) &&
                                      (weeklyTonnage[1] >= weeklyTonnage[2] * 0.95)
        return isProgressiveOrSustained
    }
}
