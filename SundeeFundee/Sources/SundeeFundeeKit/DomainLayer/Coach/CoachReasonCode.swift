import Foundation

public enum CoachReasonCode: String, Codable, Sendable, CaseIterable {
    case lowEnergyReducedVolume
    case mediumEnergyStandardPlan
    case highEnergySlightIntensityBump

    case menstrualLowerVolumeLongerRest
    case follicularProgressionFocus
    case ovulationControlledIntensity
    case lutealModerateIntensityLongerRest
    case noCyclePhaseEnergyBased

    case activeInjuriesFilteredExercises
    case equipmentLimitedExercisePool
    case balancedMovementPatterns
    case highSkillFilteredForLowEnergy

    case plateauNeedsRepVariation
    case volumePlateauNeedsVariation
    case progressSlowdownWarning
    case highWeeklyTrainingRecoveryReminder

    case missedSessionReshuffled
    case packedWeekVolumeWarning
    case droppedSessionRecoveryProtected

    public var defaultUserText: String {
        switch self {
        case .lowEnergyReducedVolume: return "Volume is trimmed today so you can move well without forcing intensity."
        case .mediumEnergyStandardPlan: return "Today's plan keeps the standard training dose for steady progress."
        case .highEnergySlightIntensityBump: return "Your higher energy supports a small intensity nudge while keeping form in focus."
        case .menstrualLowerVolumeLongerRest: return "Cycle-aware adjustments lower volume and add more rest today."
        case .follicularProgressionFocus: return "This phase supports a progression-focused session."
        case .ovulationControlledIntensity: return "This phase supports controlled intensity with clean movement quality."
        case .lutealModerateIntensityLongerRest: return "This phase favors moderate intensity and a little more rest."
        case .noCyclePhaseEnergyBased: return "No cycle phase is available, so the plan is guided by your energy and goals."
        case .activeInjuriesFilteredExercises: return "Movement constraints were used to narrow the exercise list."
        case .equipmentLimitedExercisePool: return "Exercises were filtered to match the equipment you have today."
        case .balancedMovementPatterns: return "The session balances movement patterns instead of repeating the same demand."
        case .highSkillFilteredForLowEnergy: return "Lower-energy settings avoid high-skill options today."
        case .plateauNeedsRepVariation: return "Recent strength patterns suggest adding rep variation."
        case .volumePlateauNeedsVariation: return "Recent volume patterns suggest changing the training stimulus."
        case .progressSlowdownWarning: return "Progress has slowed, so the plan keeps changes conservative and trackable."
        case .highWeeklyTrainingRecoveryReminder: return "Your weekly training count is high, so recovery stays part of the plan."
        case .missedSessionReshuffled: return "Missed sessions were reshuffled into the remaining week."
        case .packedWeekVolumeWarning: return "The updated week is packed, so watch overall workload."
        case .droppedSessionRecoveryProtected: return "A session was dropped to protect recovery and keep the week realistic."
        }
    }

    public var shortLabel: String {
        switch self {
        case .lowEnergyReducedVolume: return "Low energy"
        case .mediumEnergyStandardPlan: return "Standard dose"
        case .highEnergySlightIntensityBump: return "High energy"
        case .menstrualLowerVolumeLongerRest: return "Cycle-adjusted rest"
        case .follicularProgressionFocus: return "Progression focus"
        case .ovulationControlledIntensity: return "Controlled intensity"
        case .lutealModerateIntensityLongerRest: return "Moderate intensity"
        case .noCyclePhaseEnergyBased: return "Energy-based plan"
        case .activeInjuriesFilteredExercises: return "Movement constraints"
        case .equipmentLimitedExercisePool: return "Equipment fit"
        case .balancedMovementPatterns: return "Balanced patterns"
        case .highSkillFilteredForLowEnergy: return "Lower skill demand"
        case .plateauNeedsRepVariation: return "Rep variation"
        case .volumePlateauNeedsVariation: return "Volume variation"
        case .progressSlowdownWarning: return "Progress check"
        case .highWeeklyTrainingRecoveryReminder: return "Recovery reminder"
        case .missedSessionReshuffled: return "Schedule reshuffle"
        case .packedWeekVolumeWarning: return "Packed week"
        case .droppedSessionRecoveryProtected: return "Recovery protected"
        }
    }

    public var priority: Int {
        switch self {
        case .activeInjuriesFilteredExercises: return 10
        case .menstrualLowerVolumeLongerRest, .lutealModerateIntensityLongerRest: return 20
        case .lowEnergyReducedVolume: return 25
        case .highWeeklyTrainingRecoveryReminder, .packedWeekVolumeWarning, .droppedSessionRecoveryProtected: return 30
        case .progressSlowdownWarning, .plateauNeedsRepVariation, .volumePlateauNeedsVariation: return 40
        case .equipmentLimitedExercisePool, .highSkillFilteredForLowEnergy: return 50
        case .follicularProgressionFocus, .ovulationControlledIntensity: return 60
        case .highEnergySlightIntensityBump, .mediumEnergyStandardPlan, .noCyclePhaseEnergyBased: return 70
        case .balancedMovementPatterns: return 80
        case .missedSessionReshuffled: return 90
        }
    }

    public var isCaution: Bool {
        switch self {
        case .activeInjuriesFilteredExercises,
             .progressSlowdownWarning,
             .highWeeklyTrainingRecoveryReminder,
             .packedWeekVolumeWarning,
             .droppedSessionRecoveryProtected:
            return true
        default:
            return false
        }
    }
}
