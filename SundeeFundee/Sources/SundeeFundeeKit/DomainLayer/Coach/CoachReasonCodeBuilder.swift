import Foundation

public enum CoachReasonCodeBuilder {
    public static func codes(
        context: CoachContext,
        preferences: QuestionnaireAnswers,
        adjustment: CycleAwareAdjustment? = nil
    ) -> [CoachReasonCode] {
        var codes: [CoachReasonCode] = []

        switch preferences.energyLevel {
        case .low: codes.append(.lowEnergyReducedVolume)
        case .medium: codes.append(.mediumEnergyStandardPlan)
        case .high: codes.append(.highEnergySlightIntensityBump)
        }

        switch context.cyclePhase {
        case .menstrual: codes.append(.menstrualLowerVolumeLongerRest)
        case .follicular: codes.append(.follicularProgressionFocus)
        case .ovulation: codes.append(.ovulationControlledIntensity)
        case .luteal: codes.append(.lutealModerateIntensityLongerRest)
        case nil: codes.append(.noCyclePhaseEnergyBased)
        }

        if !context.injuries.isEmpty { codes.append(.activeInjuriesFilteredExercises) }
        if preferences.equipment != .fullGym || context.equipment != .fullGym { codes.append(.equipmentLimitedExercisePool) }
        codes.append(.balancedMovementPatterns)
        if preferences.energyLevel == .low { codes.append(.highSkillFilteredForLowEnergy) }
        if !context.plateaus.isEmpty { codes.append(.plateauNeedsRepVariation) }
        if !context.volumePlateaus.isEmpty { codes.append(.volumePlateauNeedsVariation) }
        if !context.progressWarnings.isEmpty { codes.append(.progressSlowdownWarning) }
        if context.workoutsThisWeek >= 5 { codes.append(.highWeeklyTrainingRecoveryReminder) }

        return dedupe(codes).sorted { lhs, rhs in
            if lhs.priority == rhs.priority { return lhs.rawValue < rhs.rawValue }
            return lhs.priority < rhs.priority
        }
    }

    public static func dedupe(_ codes: [CoachReasonCode]) -> [CoachReasonCode] {
        var seen = Set<CoachReasonCode>()
        return codes.filter { seen.insert($0).inserted }
    }
}
