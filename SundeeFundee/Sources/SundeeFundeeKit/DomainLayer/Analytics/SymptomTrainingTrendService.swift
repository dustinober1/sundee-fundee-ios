import Foundation

// MARK: - SymptomTrainingInsight

/// A single insight produced by correlating symptom check-ins with workout
/// completion over a rolling 7-day window. All language is non-diagnostic
/// and focuses on observable patterns and encouragement.
public struct SymptomTrainingInsight: Sendable, Equatable {
    public let title: String
    public let message: String
    public let relatedSignal: String

    public init(title: String, message: String, relatedSignal: String) {
        self.title = title
        self.message = message
        self.relatedSignal = relatedSignal
    }
}

// MARK: - SymptomTrainingTrendService

/// Pure domain service that correlates symptom check-ins with workout
/// completion over the last 7 days and returns actionable insights.
///
/// Rules:
/// - Filters symptoms to the last 7 days from now.
/// - Counts completed workouts in the same window.
/// - High cramps (avg >= 7) + few completed workouts (0) -> pattern insight.
/// - High energy (avg >= 8) + good completed workouts (3+) -> consistency insight.
/// - High fatigue (avg >= 7) + few completed workouts (0) -> rest balance insight.
/// - Never produces diagnostic language ("diagnose", "treat", "condition").
public enum SymptomTrainingTrendService {

    /// Returns trend insights based on the last 7 days of symptoms and workouts.
    ///
    /// - Parameters:
    ///   - symptoms: All symptom check-in records (filtered internally to last 7 days).
    ///   - workouts: All workouts (filtered internally to last 7 days).
    ///   - cyclePhase: Optional current cycle phase for contextual framing.
    /// - Returns: An array of insights, empty when no meaningful pattern is detected.
    public static func insights(
        symptoms: [SymptomCheckInRecord],
        workouts: [Workout],
        cyclePhase: CyclePhase?
    ) -> [SymptomTrainingInsight] {
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now

        let recentSymptoms = symptoms.filter { $0.symptomDate >= sevenDaysAgo }
        let completedWorkoutCount = workouts.filter { workout in
            guard let completed = workout.completedAt else { return false }
            return completed >= sevenDaysAgo
        }.count

        guard !recentSymptoms.isEmpty else {
            // No symptom data at all -> nothing to say
            return []
        }

        let avgCramps = recentSymptoms.map(\.cramps).reduce(0, +) / recentSymptoms.count
        let avgFatigue = recentSymptoms.map(\.fatigue).reduce(0, +) / recentSymptoms.count
        let avgEnergy = recentSymptoms.map(\.energy).reduce(0, +) / recentSymptoms.count

        var insights: [SymptomTrainingInsight] = []

        // High cramps + no completed workouts -> pattern insight
        if avgCramps >= 7 && completedWorkoutCount == 0 {
            let phaseContext = phaseLabel(cyclePhase)
            insights.append(SymptomTrainingInsight(
                title: "Movement Patterns This Week",
                message: "Cramps have been prominent this week and no workouts were logged. " +
                    "Gentle movement like walking or stretching can sometimes help. " +
                    phaseContext,
                relatedSignal: "cramps"
            ))
        }

        // High energy + good workout consistency -> positive insight
        if avgEnergy >= 8 && completedWorkoutCount >= 3 {
            insights.append(SymptomTrainingInsight(
                title: "Strong Consistency",
                message: "Energy levels have been high and \(completedWorkoutCount) workouts were completed this week. " +
                    "This is a great rhythm — keep it going.",
                relatedSignal: "energy"
            ))
        }

        // High fatigue + no completed workouts -> rest balance insight
        if avgFatigue >= 7 && completedWorkoutCount == 0 {
            let phaseContext = phaseLabel(cyclePhase)
            insights.append(SymptomTrainingInsight(
                title: "Rest and Balance",
                message: "Fatigue has been elevated this week with rest taking priority. " +
                    "Listening to your body is an important part of training. " +
                    phaseContext,
                relatedSignal: "fatigue"
            ))
        }

        return insights
    }

    // MARK: - Private Helpers

    private static func phaseLabel(_ phase: CyclePhase?) -> String {
        guard let phase else { return "" }
        switch phase {
        case .menstrual:
            return "This is common during the menstrual phase."
        case .follicular:
            return "Energy often rebounds in the follicular phase."
        case .ovulation:
            return "Energy tends to peak around ovulation."
        case .luteal:
            return "Fatigue and cramps are common in the luteal phase."
        }
    }
}
