import Foundation

// MARK: - CoachServiceProtocol

/// Defines the capabilities of the training coach.
///
/// Implementations may use deterministic domain logic (fallback),
/// on-device AI (Apple Foundation Models), or cloud AI.
/// The protocol is designed so that deterministic services produce
/// the decisions and AI services explain/package them.
public protocol CoachServiceProtocol: Sendable {

    /// Generates a personalized workout based on context and preferences.
    func generateWorkout(
        context: CoachContext,
        preferences: QuestionnaireAnswers
    ) async throws -> CoachWorkoutResponse

    /// Returns training insights: plateaus, load trends, and recommendations.
    func getInsights(
        context: CoachContext
    ) async throws -> CoachInsightsResponse

    /// Suggests substitute exercises for a given exercise.
    func suggestSubstitutions(
        for exercise: String,
        context: CoachContext
    ) async throws -> CoachSubstitutionResponse

    /// Adapts the weekly plan based on missed/completed sessions.
    func adaptWeeklyPlan(
        plan: [ScheduleReshuffler.PlannedSession],
        completedDays: Set<Int>,
        missedDays: Set<Int>,
        currentDay: Int,
        context: CoachContext
    ) async throws -> CoachPlanResponse
}

// MARK: - Response Types

/// Response from workout generation.
public struct CoachWorkoutResponse: Sendable {
    /// The generated workout.
    public let workout: GeneratedWorkout

    /// A personalized coaching summary explaining the workout choices.
    public let coachingSummary: String

    /// Optional tips specific to the user's current state.
    public let tips: [String]

    public init(workout: GeneratedWorkout, coachingSummary: String, tips: [String] = []) {
        self.workout = workout
        self.coachingSummary = coachingSummary
        self.tips = tips
    }
}

/// Response from training insights analysis.
public struct CoachInsightsResponse: Sendable {
    /// Detected plateaus with recommendations.
    public let plateaus: [PlateauDetector.PlateauAlert]

    /// Weekly load trends.
    public let trends: [WeeklyLoadAnalyzer.LoadTrend]

    /// Human-readable summary of insights.
    public let summary: String

    /// Priority actions the user should take.
    public let priorityActions: [String]

    public init(
        plateaus: [PlateauDetector.PlateauAlert],
        trends: [WeeklyLoadAnalyzer.LoadTrend],
        summary: String,
        priorityActions: [String]
    ) {
        self.plateaus = plateaus
        self.trends = trends
        self.summary = summary
        self.priorityActions = priorityActions
    }
}

/// Response from exercise substitution suggestions.
public struct CoachSubstitutionResponse: Sendable {
    /// The original exercise being substituted.
    public let originalExercise: String

    /// Ranked substitution options.
    public let substitutions: [SubstitutionRanker.RankedSubstitution]

    /// Explanation of why these alternatives were chosen.
    public let explanation: String

    public init(
        originalExercise: String,
        substitutions: [SubstitutionRanker.RankedSubstitution],
        explanation: String
    ) {
        self.originalExercise = originalExercise
        self.substitutions = substitutions
        self.explanation = explanation
    }
}

/// Response from weekly plan adaptation.
public struct CoachPlanResponse: Sendable {
    /// The reshuffled plan result.
    public let result: ScheduleReshuffler.ReshuffleResult

    /// Personalized explanation of the changes.
    public let explanation: String

    /// Whether the user should consider extending the week or adjusting volume.
    public let volumeWarning: String?

    public init(
        result: ScheduleReshuffler.ReshuffleResult,
        explanation: String,
        volumeWarning: String? = nil
    ) {
        self.result = result
        self.explanation = explanation
        self.volumeWarning = volumeWarning
    }
}

// MARK: - CoachServiceFactory

/// Creates the appropriate coach service based on device capabilities.
public enum CoachServiceFactory {

    /// Returns the best available coach service.
    ///
    /// - On iOS 26+ with Apple Intelligence: returns `OnDeviceCoachService`
    /// - Otherwise: returns `DeterministicCoachService`
    public static func makeService() -> CoachServiceProtocol {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return OnDeviceCoachService()
        }
        #endif
        return DeterministicCoachService()
    }
}
