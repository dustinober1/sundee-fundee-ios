import Foundation

public enum CoachDecisionPacketBuilder {
    public static func workoutPacket(
        base: CoachWorkoutResponse,
        context: CoachContext,
        preferences: QuestionnaireAnswers,
        promptVersion: String
    ) -> CoachDecisionPacket {
        let codes = CoachReasonCodeBuilder.codes(context: context, preferences: preferences)
        let selected = base.workout.exercises.map(\.name)
        return CoachDecisionPacket(
            promptVersion: promptVersion,
            durationMinutes: preferences.timeMinutes,
            focus: preferences.focus,
            energyLevel: preferences.energyLevel,
            equipment: preferences.equipment,
            cyclePhase: context.cyclePhase,
            cycleConfidence: context.cycleConfidence,
            workoutsThisWeek: context.workoutsThisWeek,
            activeInjuryCount: context.injuries.count,
            selectedExerciseNames: selected,
            allowedExerciseNames: selected,
            reasonCodes: codes,
            cautionCodes: codes.filter(\.isCaution),
            deterministicSummary: base.coachingSummary,
            deterministicTips: base.tips
        )
    }

    public static func insightsPacket(
        base: CoachInsightsResponse,
        context: CoachContext,
        promptVersion: String
    ) -> CoachDecisionPacket {
        let preferences = QuestionnaireAnswers(timeMinutes: nilSafeDuration(context), focus: .fullBody, energyLevel: .medium, equipment: context.equipment)
        let codes = CoachReasonCodeBuilder.codes(context: context, preferences: preferences)
        let plateauNames = Array(Set((context.plateaus + context.volumePlateaus).map(\.exerciseName))).sorted()
        return CoachDecisionPacket(
            promptVersion: promptVersion,
            durationMinutes: nil,
            focus: nil,
            energyLevel: nil,
            equipment: context.equipment,
            cyclePhase: context.cyclePhase,
            cycleConfidence: context.cycleConfidence,
            workoutsThisWeek: context.workoutsThisWeek,
            activeInjuryCount: context.injuries.count,
            selectedExerciseNames: [],
            allowedExerciseNames: plateauNames,
            reasonCodes: codes,
            cautionCodes: codes.filter(\.isCaution),
            deterministicSummary: base.summary,
            deterministicTips: base.priorityActions
        )
    }

    public static func planPacket(
        base: CoachPlanResponse,
        context: CoachContext,
        promptVersion: String
    ) -> CoachDecisionPacket {
        let preferences = QuestionnaireAnswers(timeMinutes: nilSafeDuration(context), focus: .fullBody, energyLevel: .medium, equipment: context.equipment)
        var codes = CoachReasonCodeBuilder.codes(context: context, preferences: preferences)
        if !base.result.droppedSessions.isEmpty { codes.append(.droppedSessionRecoveryProtected) }
        if base.volumeWarning != nil { codes.append(.packedWeekVolumeWarning) }
        codes = CoachReasonCodeBuilder.dedupe(codes).sorted { $0.priority < $1.priority }
        return CoachDecisionPacket(
            promptVersion: promptVersion,
            durationMinutes: nil,
            focus: nil,
            energyLevel: nil,
            equipment: context.equipment,
            cyclePhase: context.cyclePhase,
            cycleConfidence: context.cycleConfidence,
            workoutsThisWeek: context.workoutsThisWeek,
            activeInjuryCount: context.injuries.count,
            selectedExerciseNames: [],
            allowedExerciseNames: [],
            reasonCodes: codes,
            cautionCodes: codes.filter(\.isCaution),
            deterministicSummary: [base.explanation, base.volumeWarning].compactMap { $0 }.joined(separator: " "),
            deterministicTips: []
        )
    }

    private static func nilSafeDuration(_ context: CoachContext) -> Int { 0 }
}
