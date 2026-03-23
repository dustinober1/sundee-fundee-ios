package com.sundeefundee.domain

/**
 * Adaptation readiness tiers based on user-reported energy/fatigue scores.
 */
enum class AdaptationReadinessTier {
    LOW,
    NEUTRAL,
    HIGH
}

/**
 * Confidence levels for cycle phase predictions.
 */
enum class AdaptationConfidence {
    LOW,
    MEDIUM,
    HIGH
}

/**
 * Phase-specific baseline settings for load, sets, and reps multipliers.
 */
data class PhaseSettings(
    val loadMultiplier: Double,
    val setsMultiplier: Double,
    val repsMultiplier: Double
)

/**
 * Policy for adapting workout programs based on menstrual cycle phase.
 * Pure value semantics - never mutates inputs, returns new instances.
 */
object CycleAdaptationPolicy {

    private val baselinePhaseSettings: Map<CyclePhase, PhaseSettings> = mapOf(
        CyclePhase.MENSTRUAL to PhaseSettings(0.90, 0.90, 0.90),
        CyclePhase.FOLLICULAR to PhaseSettings(1.00, 1.00, 1.00),
        CyclePhase.OVULATION to PhaseSettings(1.12, 1.05, 0.95),
        CyclePhase.LUTEAL to PhaseSettings(0.97, 0.95, 0.92)
    )

    private val readinessScales: Map<AdaptationReadinessTier, Double> = mapOf(
        AdaptationReadinessTier.LOW to 0.6,
        AdaptationReadinessTier.NEUTRAL to 1.0,
        AdaptationReadinessTier.HIGH to 1.2
    )

    private val confidenceScales: Map<AdaptationConfidence, Double> = mapOf(
        AdaptationConfidence.LOW to 0.55,
        AdaptationConfidence.MEDIUM to 0.8,
        AdaptationConfidence.HIGH to 1.0
    )

    /**
     * Determines readiness tier from an optional readiness score (1-10 scale).
     */
    fun resolveReadinessTier(readinessScore: Int?): AdaptationReadinessTier {
        if (readinessScore == null) return AdaptationReadinessTier.NEUTRAL
        return when {
            readinessScore <= 3 -> AdaptationReadinessTier.LOW
            readinessScore >= 8 -> AdaptationReadinessTier.HIGH
            else -> AdaptationReadinessTier.NEUTRAL
        }
    }

    /**
     * Resolves confidence scale based on confidence level.
     */
    fun resolveConfidenceScale(
        confidence: AdaptationConfidence,
        lowConfidenceScale: Double = 0.7
    ): Double {
        val base = confidenceScales[confidence] ?: 1.0
        return if (confidence == AdaptationConfidence.LOW) {
            (base * lowConfidenceScale).coerceIn(0.1, 1.0)
        } else {
            base
        }
    }

    /**
     * Resolves the current cycle phase with fallback logic.
     */
    fun resolvePhase(
        currentPhase: CyclePhase?,
        lastKnownPhase: CyclePhase?,
        fallbackPhase: CyclePhase = CyclePhase.FOLLICULAR
    ): CyclePhase {
        return currentPhase ?: lastKnownPhase ?: fallbackPhase
    }

    /**
     * Determines confidence level based on available data.
     */
    fun resolveConfidence(
        currentPhase: CyclePhase?,
        lastPeriodStart: Long?,
        periodLogCount: Int,
        referenceDate: Long = System.currentTimeMillis()
    ): AdaptationConfidence {
        if (periodLogCount <= 0) return AdaptationConfidence.LOW

        if (lastPeriodStart != null) {
            val daysSinceLastPeriod = (referenceDate - lastPeriodStart) / (24 * 60 * 60 * 1000)
            if (daysSinceLastPeriod > 45) {
                return AdaptationConfidence.LOW
            }
        }

        return when {
            currentPhase != null && periodLogCount >= 3 -> AdaptationConfidence.HIGH
            currentPhase != null -> AdaptationConfidence.MEDIUM
            else -> AdaptationConfidence.LOW
        }
    }

    /**
     * Applies phase adjustment to a target multiplier.
     */
    fun applyPhaseAdjustment(
        targetMultiplier: Double,
        readinessTier: AdaptationReadinessTier,
        confidence: AdaptationConfidence
    ): Double {
        val rs = readinessScales[readinessTier] ?: 1.0
        val cs = resolveConfidenceScale(confidence)
        val blended = 1.0 + (targetMultiplier - 1.0) * rs * cs
        return blended.coerceIn(0.75, 1.25)
    }

    /**
     * Gets phase settings for a given cycle phase.
     */
    fun getPhaseSettings(phase: CyclePhase): PhaseSettings {
        return baselinePhaseSettings[phase] ?: PhaseSettings(1.0, 1.0, 1.0)
    }

    /**
     * Gets load multiplier for a given cycle phase.
     */
    fun getLoadMultiplier(phase: CyclePhase): Double {
        return getPhaseSettings(phase).loadMultiplier
    }

    /**
     * Gets sets multiplier for a given cycle phase.
     */
    fun getSetsMultiplier(phase: CyclePhase): Double {
        return getPhaseSettings(phase).setsMultiplier
    }

    /**
     * Gets reps multiplier for a given cycle phase.
     */
    fun getRepsMultiplier(phase: CyclePhase): Double {
        return getPhaseSettings(phase).repsMultiplier
    }
}

/**
 * Extension function to clamp a comparable value within a range.
 */
fun <T : Comparable<T>> T.clamped(to range: ClosedRange<T>): T {
    return maxOf(minOf(this, range.endInclusive), range.start)
}
