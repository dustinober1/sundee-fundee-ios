package com.sundeefundee.domain

/**
 * Phase-specific multipliers for exercise load, sets, and reps.
 * Applied to replacement exercises during injury adaptation.
 */
object LoadAdjustmentPolicy {

    /**
     * Returns multipliers for a given recovery phase.
     */
    fun multipliers(for phase: RecoveryPhase): Multipliers {
        return when (phase) {
            RecoveryPhase.ACUTE -> Multipliers(load = 0.0, sets = 0.0, reps = 0.0)
            RecoveryPhase.REHAB -> Multipliers(load = 0.30, sets = 0.50, reps = 0.70)
            RecoveryPhase.LIGHT_LOAD -> Multipliers(load = 0.50, sets = 0.75, reps = 0.85)
            RecoveryPhase.RETURN_TO_PLAY -> Multipliers(load = 0.80, sets = 0.90, reps = 1.0)
            RecoveryPhase.RESOLVED -> Multipliers(load = 1.0, sets = 1.0, reps = 1.0)
        }
    }

    /**
     * Returns the load multiplier for a given cycle phase.
     */
    fun getLoadMultiplier(phase: CyclePhase): Double {
        return when (phase) {
            CyclePhase.MENSTRUAL -> 0.90
            CyclePhase.FOLLICULAR -> 1.00
            CyclePhase.OVULATION -> 1.12
            CyclePhase.LUTEAL -> 0.97
        }
    }

    /**
     * Returns the intensity multiplier for a given cycle phase.
     * This is a simplified version combining load, sets, and reps.
     */
    fun getIntensityMultiplier(phase: CyclePhase): Double {
        return when (phase) {
            CyclePhase.MENSTRUAL -> 0.85
            CyclePhase.FOLLICULAR -> 1.00
            CyclePhase.OVULATION -> 1.10
            CyclePhase.LUTEAL -> 0.95
        }
    }

    /**
     * Returns the adjustment factor for a given cycle phase and injuries.
     * Combines cycle phase and injury considerations.
     */
    fun getAdjustmentForPhase(
        phase: CyclePhase,
        injuries: List<InjuryProfile> = emptyList()
    ): Double {
        val phaseMultiplier = getIntensityMultiplier(phase)

        // Apply injury severity reduction
        if (injuries.isEmpty()) return phaseMultiplier

        val avgSeverity = injuries.map { it.severity }.average()
        val injuryReduction = when {
            avgSeverity >= 8 -> 0.5
            avgSeverity >= 5 -> 0.7
            avgSeverity >= 3 -> 0.85
            else -> 1.0
        }

        return phaseMultiplier * injuryReduction
    }

    /**
     * Multiplier set for injury recovery.
     */
    data class Multipliers(
        val load: Double,
        val sets: Double,
        val reps: Double
    )
}
