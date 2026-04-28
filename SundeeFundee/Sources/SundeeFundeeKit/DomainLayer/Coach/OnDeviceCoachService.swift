import Foundation

// MARK: - OnDeviceCoachService

/// Coach service that uses Apple Foundation Models for natural language
/// generation while delegating structural decisions to deterministic logic.
///
/// Requires iOS 26+ and Apple Intelligence to be enabled on the device.
/// When Foundation Models are unavailable at runtime, falls back to
/// `DeterministicCoachService`.
///
/// Architecture:
///   1. Deterministic services (PlateauDetector, WeeklyLoadAnalyzer, etc.)
///      make the training decisions.
///   2. This service feeds those decisions into the on-device language model
///      to generate personalized explanations, coaching summaries, and tips.
///   3. The model explains and packages decisions — it doesn't invent them.
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
public final class OnDeviceCoachService: CoachServiceProtocol, @unchecked Sendable {
    private let fallback = DeterministicCoachService()

    public init() {}

    // MARK: - Generate Workout

    public func generateWorkout(
        context: CoachContext,
        preferences: QuestionnaireAnswers
    ) async throws -> CoachWorkoutResponse {
        // Get the deterministic workout first (exercises, weights, structure)
        let base = try await fallback.generateWorkout(context: context, preferences: preferences)

        // Enhance the coaching summary with AI
        let enhanced = try await enhanceCoachingSummary(
            base: base,
            context: context,
            preferences: preferences
        )

        return CoachWorkoutResponse(
            workout: enhanced.workout,
            coachingSummary: enhanced.coachingSummary,
            tips: enhanced.tips
        )
    }

    // MARK: - Get Insights

    public func getInsights(context: CoachContext) async throws -> CoachInsightsResponse {
        let base = try await fallback.getInsights(context: context)

        // Use AI to generate a more personalized summary
        let summary = await generateInsightsSummary(base: base, context: context)

        return CoachInsightsResponse(
            plateaus: base.plateaus,
            trends: base.trends,
            summary: summary ?? base.summary,
            priorityActions: base.priorityActions
        )
    }

    // MARK: - Suggest Substitutions

    public func suggestSubstitutions(
        for exercise: String,
        context: CoachContext
    ) async throws -> CoachSubstitutionResponse {
        // Substitution ranking is purely deterministic
        return try await fallback.suggestSubstitutions(for: exercise, context: context)
    }

    // MARK: - Adapt Weekly Plan

    public func adaptWeeklyPlan(
        plan: [ScheduleReshuffler.PlannedSession],
        completedDays: Set<Int>,
        missedDays: Set<Int>,
        currentDay: Int,
        context: CoachContext
    ) async throws -> CoachPlanResponse {
        let base = try await fallback.adaptWeeklyPlan(
            plan: plan,
            completedDays: completedDays,
            missedDays: missedDays,
            currentDay: currentDay,
            context: context
        )

        // Use AI to make the explanation more conversational
        let explanation = await generatePlanExplanation(base: base, context: context)

        return CoachPlanResponse(
            result: base.result,
            explanation: explanation ?? base.explanation,
            volumeWarning: base.volumeWarning
        )
    }

    // MARK: - AI Enhancement Helpers

    private func enhanceCoachingSummary(
        base: CoachWorkoutResponse,
        context: CoachContext,
        preferences: QuestionnaireAnswers
    ) async throws -> CoachWorkoutResponse {
        let session = LanguageModelSession()

        let prompt = """
        You are a supportive fitness copy editor. Write exactly 2 short sentences \
        explaining today's already-selected workout.

        Rules:
        - Do not add, remove, rename, or prescribe exercises.
        - Do not mention weights, reps, or medical advice.
        - Use the workout facts only.
        - Keep it specific and encouraging.

        Workout: \(preferences.timeMinutes) min \(preferences.focus.rawValue.replacingOccurrences(of: "_", with: " "))
        Energy: \(preferences.energyLevel.rawValue)
        Equipment: \(preferences.equipment.rawValue.replacingOccurrences(of: "_", with: " "))
        Exercises: \(base.workout.exercises.map(\.name).joined(separator: ", "))
        \(context.cyclePhase.map { "Cycle phase: \($0)" } ?? "")
        \(context.injuries.isEmpty ? "" : "Active injuries: \(context.injuries.count)")
        \(context.workoutsThisWeek > 0 ? "Workouts this week: \(context.workoutsThisWeek)" : "")
        """

        do {
            let response = try await session.respond(to: prompt)
            let enhanced = String(response.content)

            return CoachWorkoutResponse(
                workout: GeneratedWorkout(
                    id: base.workout.id,
                    createdAt: base.workout.createdAt,
                    isFavorite: base.workout.isFavorite,
                    coachingSummary: enhanced,
                    exercises: base.workout.exercises,
                    questionnaire: base.workout.questionnaire
                ),
                coachingSummary: enhanced,
                tips: base.tips
            )
        } catch {
            // Fall back to deterministic summary
            return base
        }
    }

    private func generateInsightsSummary(
        base: CoachInsightsResponse,
        context: CoachContext
    ) async -> String? {
        let session = LanguageModelSession()

        var dataPoints: [String] = []
        for p in base.plateaus.prefix(3) {
            dataPoints.append("\(p.exerciseName) stalled at \(Int(p.currentWeight)) lbs for \(p.stallCount) attempts")
        }
        for t in base.trends {
            dataPoints.append(t.message)
        }

        guard !dataPoints.isEmpty else { return nil }

        let prompt = """
        You are a fitness coach. Summarize these training insights in 2-3 friendly sentences. \
        Focus on actionable advice, not just restating the data.

        Data: \(dataPoints.joined(separator: ". "))
        """

        do {
            let response = try await session.respond(to: prompt)
            return String(response.content)
        } catch {
            return nil
        }
    }

    private func generatePlanExplanation(
        base: CoachPlanResponse,
        context: CoachContext
    ) async -> String? {
        let session = LanguageModelSession()

        let prompt = """
        You are a fitness coach. Explain this schedule change in 1-2 friendly sentences.

        Change: \(base.result.summary)
        \(base.volumeWarning.map { "Volume concern: \($0)" } ?? "")
        """

        do {
            let response = try await session.respond(to: prompt)
            return String(response.content)
        } catch {
            return nil
        }
    }
}

#else

// MARK: - Fallback when FoundationModels is not available

/// When compiling without the FoundationModels framework (Xcode < 26 / iOS < 26 SDK),
/// OnDeviceCoachService is a thin wrapper around DeterministicCoachService.
public final class OnDeviceCoachService: CoachServiceProtocol, @unchecked Sendable {
    private let fallback = DeterministicCoachService()

    public init() {}

    public func generateWorkout(
        context: CoachContext,
        preferences: QuestionnaireAnswers
    ) async throws -> CoachWorkoutResponse {
        try await fallback.generateWorkout(context: context, preferences: preferences)
    }

    public func getInsights(context: CoachContext) async throws -> CoachInsightsResponse {
        try await fallback.getInsights(context: context)
    }

    public func suggestSubstitutions(
        for exercise: String,
        context: CoachContext
    ) async throws -> CoachSubstitutionResponse {
        try await fallback.suggestSubstitutions(for: exercise, context: context)
    }

    public func adaptWeeklyPlan(
        plan: [ScheduleReshuffler.PlannedSession],
        completedDays: Set<Int>,
        missedDays: Set<Int>,
        currentDay: Int,
        context: CoachContext
    ) async throws -> CoachPlanResponse {
        try await fallback.adaptWeeklyPlan(
            plan: plan,
            completedDays: completedDays,
            missedDays: missedDays,
            currentDay: currentDay,
            context: context
        )
    }
}

#endif
