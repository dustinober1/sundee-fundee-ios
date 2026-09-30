import Foundation

// MARK: - OnDeviceCoachService

/// Coach service that delegates all training decisions to deterministic logic and
/// uses on-device AI only as a validated copy editor.
public final class OnDeviceCoachService: CoachServiceProtocol, @unchecked Sendable {
    private let fallback: CoachServiceProtocol
    private let copyEditor: CoachCopyEditing?
    private let configuration: CoachAIConfiguration

    public init(
        fallback: CoachServiceProtocol = DeterministicCoachService(),
        copyEditor: CoachCopyEditing? = nil,
        configuration: CoachAIConfiguration = .shared
    ) {
        self.fallback = fallback
        self.configuration = configuration
        self.copyEditor = copyEditor
    }

    public func generateWorkout(
        context: CoachContext,
        preferences: QuestionnaireAnswers
    ) async throws -> CoachWorkoutResponse {
        let base = try await fallback.generateWorkout(context: context, preferences: preferences)
        return await enhanceWorkoutCopy(base: base, context: context, preferences: preferences)
    }

    public func getInsights(context: CoachContext) async throws -> CoachInsightsResponse {
        let base = try await fallback.getInsights(context: context)
        return await enhanceInsightsCopy(base: base, context: context)
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
        let base = try await fallback.adaptWeeklyPlan(
            plan: plan,
            completedDays: completedDays,
            missedDays: missedDays,
            currentDay: currentDay,
            context: context
        )
        return await enhancePlanCopy(base: base, context: context)
    }

    private func enhanceWorkoutCopy(
        base: CoachWorkoutResponse,
        context: CoachContext,
        preferences: QuestionnaireAnswers
    ) async -> CoachWorkoutResponse {
        let packet = CoachDecisionPacketBuilder.workoutPacket(
            base: base,
            context: context,
            preferences: preferences,
            promptVersion: CoachPromptVersion.workoutSummaryV18.rawValue
        )

        guard await configuration.shouldUseOnDeviceCopy(), let copyEditor else {
            return CoachCopyFallback.workoutResponse(base: base, packet: packet, source: .onDeviceAIUnavailableFallback)
        }

        do {
            let candidate = try await copyEditor.rewriteWorkoutSummary(packet: packet)
            let issues = CoachCopyValidator.validateWorkoutSummary(candidate, packet: packet)
            guard issues.isEmpty else {
                await configuration.recordRejectedCopy()
                return CoachCopyFallback.workoutResponse(base: base, packet: packet, source: .onDeviceAIRejectedFallback)
            }
            await configuration.recordAcceptedCopy()
            return base.replacingCopy(
                summary: candidate.summary,
                tips: base.tips,
                packet: packet,
                source: .onDeviceAIAccepted
            )
        } catch {
            return CoachCopyFallback.workoutResponse(base: base, packet: packet, source: .onDeviceAIUnavailableFallback)
        }
    }

    private func enhanceInsightsCopy(base: CoachInsightsResponse, context: CoachContext) async -> CoachInsightsResponse {
        let packet = CoachDecisionPacketBuilder.insightsPacket(
            base: base,
            context: context,
            promptVersion: CoachPromptVersion.insightsSummaryV18.rawValue
        )
        guard await configuration.shouldUseOnDeviceCopy(), let copyEditor else { return base }
        do {
            let candidate = try await copyEditor.rewriteInsightsSummary(packet: packet)
            let issues = CoachCopyValidator.validateInsightsSummary(candidate, packet: packet)
            guard issues.isEmpty else {
                await configuration.recordRejectedCopy()
                return base
            }
            await configuration.recordAcceptedCopy()
            return CoachInsightsResponse(
                plateaus: base.plateaus,
                trends: base.trends,
                summary: candidate.summary,
                priorityActions: base.priorityActions
            )
        } catch {
            return base
        }
    }

    private func enhancePlanCopy(base: CoachPlanResponse, context: CoachContext) async -> CoachPlanResponse {
        let packet = CoachDecisionPacketBuilder.planPacket(
            base: base,
            context: context,
            promptVersion: CoachPromptVersion.planExplanationV18.rawValue
        )
        guard await configuration.shouldUseOnDeviceCopy(), let copyEditor else { return base }
        do {
            let candidate = try await copyEditor.rewritePlanExplanation(packet: packet)
            let issues = CoachCopyValidator.validatePlanExplanation(candidate, packet: packet)
            guard issues.isEmpty else {
                await configuration.recordRejectedCopy()
                return base
            }
            await configuration.recordAcceptedCopy()
            return CoachPlanResponse(result: base.result, explanation: candidate.summary, volumeWarning: base.volumeWarning)
        } catch {
            return base
        }
    }
}
