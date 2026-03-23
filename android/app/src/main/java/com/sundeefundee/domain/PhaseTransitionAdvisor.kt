package com.sundeefundee.domain

import com.sundeefundee.domain.model.InjuryProfile
import com.sundeefundee.domain.model.PainLog

/**
 * Transition warning for cycle phase changes.
 */
data class TransitionWarning(
    val injuryId: String,
    val currentPhase: RecoveryPhase,
    val suggestedPhase: RecoveryPhase,
    val reason: String,
    val painThreshold: Int,
    val daysAtCurrentLevel: Int
)

/**
 * Suggestion for injury recovery phase transition.
 */
data class TransitionSuggestion(
    val injuryId: String,
    val currentPhase: RecoveryPhase,
    val suggestedPhase: RecoveryPhase
)

/**
 * Pure logic rules for suggesting recovery phase transitions based on pain trends.
 * User always manually confirms — no auto-transitions.
 */
object PhaseTransitionAdvisor {

    private const val RECENT_LOGS_COUNT = 5

    /**
     * Evaluates whether an injury is ready to advance to the next phase.
     * Returns null if no transition is suggested.
     */
    fun evaluateTransition(
        injuryId: String,
        currentPhase: RecoveryPhase,
        painLogs: List<PainLog>
    ): TransitionSuggestion? {
        val recentLogs = painLogs.take(RECENT_LOGS_COUNT)

        return when (currentPhase) {
            RecoveryPhase.ACUTE -> {
                // acute → rehab: 3 consecutive days pain ≤ 5
                if (meetsThreshold(recentLogs, count = 3, maxPain = 5)) {
                    TransitionSuggestion(injuryId = injuryId, currentPhase = RecoveryPhase.ACUTE, suggestedPhase = RecoveryPhase.REHAB)
                } else null
            }
            RecoveryPhase.REHAB -> {
                // rehab → lightLoad: 3 consecutive days pain ≤ 3
                if (meetsThreshold(recentLogs, count = 3, maxPain = 3)) {
                    TransitionSuggestion(injuryId = injuryId, currentPhase = RecoveryPhase.REHAB, suggestedPhase = RecoveryPhase.LIGHT_LOAD)
                } else null
            }
            RecoveryPhase.LIGHT_LOAD -> {
                // lightLoad → returnToPlay: 3 consecutive days pain ≤ 2
                if (meetsThreshold(recentLogs, count = 3, maxPain = 2)) {
                    TransitionSuggestion(injuryId = injuryId, currentPhase = RecoveryPhase.LIGHT_LOAD, suggestedPhase = RecoveryPhase.RETURN_TO_PLAY)
                } else null
            }
            RecoveryPhase.RETURN_TO_PLAY -> {
                // returnToPlay → resolved: 5 consecutive days pain ≤ 1
                if (meetsThreshold(recentLogs, count = 5, maxPain = 1)) {
                    TransitionSuggestion(injuryId = injuryId, currentPhase = RecoveryPhase.RETURN_TO_PLAY, suggestedPhase = RecoveryPhase.RESOLVED)
                } else null
            }
            RecoveryPhase.RESOLVED -> null
        }
    }

    /**
     * Checks if the N most recent logs all have pain at or below the threshold.
     * Logs are assumed sorted newest-first.
     */
    fun meetsThreshold(logs: List<PainLog>, count: Int, maxPain: Int): Boolean {
        if (logs.size < count) return false
        return logs.take(count).all { it.painLevel <= maxPain }
    }

    /**
     * Gets a warning for a cycle phase transition based on injury profiles.
     * Returns null if no warning is needed.
     */
    fun getWarning(
        phase: CyclePhase,
        injuryProfiles: List<InjuryProfile>
    ): TransitionWarning? {
        // This would be implemented based on specific business logic
        // for how injuries affect phase transitions
        return null
    }

    /**
     * Determines if a phase transition should be delayed due to injury concerns.
     */
    fun shouldDelayTransition(
        injuryProfiles: List<InjuryProfile>,
        targetPhase: CyclePhase
    ): Boolean {
        // High-severity injuries in certain body locations may warrant delaying
        // transitions to higher-intensity phases
        val highSeverityInjuries = injuryProfiles.filter { it.severity >= 7 }

        for (injury in highSeverityInjuries) {
            val loc = injury.bodyLocationRaw.lowercase()

            // Lower back and knee injuries should delay ovulation phase transition
            // due to peak intensity recommendations
            if (targetPhase == CyclePhase.OVULATION) {
                if (loc.contains("back") || loc.contains("knee") || loc.contains("lumbar")) {
                    return true
                }
            }

            // Shoulder injuries should delay ovulation phase
            if (targetPhase == CyclePhase.OVULATION && loc.contains("shoulder")) {
                return true
            }
        }

        return false
    }

    /**
     * Gets the recommended pain threshold for advancing from a given phase.
     */
    fun getPainThresholdForPhase(phase: RecoveryPhase): Int {
        return when (phase) {
            RecoveryPhase.ACUTE -> 5
            RecoveryPhase.REHAB -> 3
            RecoveryPhase.LIGHT_LOAD -> 2
            RecoveryPhase.RETURN_TO_PLAY -> 1
            RecoveryPhase.RESOLVED -> 0
        }
    }

    /**
     * Gets the number of consecutive days required to advance from a given phase.
     */
    fun getDaysRequiredForPhase(phase: RecoveryPhase): Int {
        return when (phase) {
            RecoveryPhase.ACUTE -> 3
            RecoveryPhase.REHAB -> 3
            RecoveryPhase.LIGHT_LOAD -> 3
            RecoveryPhase.RETURN_TO_PLAY -> 5
            RecoveryPhase.RESOLVED -> 0
        }
    }
}
