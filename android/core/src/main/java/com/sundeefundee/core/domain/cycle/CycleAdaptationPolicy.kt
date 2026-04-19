package com.sundeefundee.core.domain.cycle

import com.sundeefundee.core.domain.exercise.ExerciseValue
import com.sundeefundee.core.model.CyclePhase
import com.sundeefundee.core.model.CycleSettings
import kotlinx.datetime.LocalDate

// Adaptation readiness tier
enum class AdaptationReadinessTier { LOW, NEUTRAL, HIGH }

// Adaptation confidence level
enum class AdaptationConfidence { LOW, MEDIUM, HIGH }

// Body region classification for region-specific multipliers
enum class ExerciseRegion {
    UPPER, LOWER, FULL_BODY, CORE, CONDITIONING
}

// Phase-specific multipliers for cycle adaptation
data class PhaseMultipliers(
    val load: Double,
    val sets: Double,
    val reps: Double
) {
    fun lerp(other: PhaseMultipliers, t: Double): PhaseMultipliers = PhaseMultipliers(
        load = load + (other.load - load) * t,
        sets = sets + (other.sets - sets) * t,
        reps = reps + (other.reps - reps) * t
    )
}

// Default phase multipliers
val PHASE_MULTIPLIERS = mapOf(
    CyclePhase.MENSTRUAL to PhaseMultipliers(load = 0.90, sets = 0.90, reps = 0.90),
    CyclePhase.FOLLICULAR to PhaseMultipliers(load = 1.00, sets = 1.00, reps = 1.00),
    CyclePhase.OVULATION to PhaseMultipliers(load = 1.12, sets = 1.05, reps = 0.95),
    CyclePhase.LUTEAL to PhaseMultipliers(load = 0.97, sets = 0.95, reps = 0.92)
)

// Region-specific overrides
val REGION_PHASE_MULTIPLIERS = mapOf(
    ExerciseRegion.LOWER to mapOf(
        CyclePhase.MENSTRUAL to PhaseMultipliers(load = 0.85, sets = 0.85, reps = 0.88),
        CyclePhase.FOLLICULAR to PhaseMultipliers(load = 1.00, sets = 1.00, reps = 1.00),
        CyclePhase.OVULATION to PhaseMultipliers(load = 1.15, sets = 1.08, reps = 0.93),
        CyclePhase.LUTEAL to PhaseMultipliers(load = 0.95, sets = 0.93, reps = 0.90)
    ),
    ExerciseRegion.UPPER to mapOf(
        CyclePhase.MENSTRUAL to PhaseMultipliers(load = 0.92, sets = 0.92, reps = 0.92),
        CyclePhase.FOLLICULAR to PhaseMultipliers(load = 1.00, sets = 1.00, reps = 1.00),
        CyclePhase.OVULATION to PhaseMultipliers(load = 1.10, sets = 1.03, reps = 0.96),
        CyclePhase.LUTEAL to PhaseMultipliers(load = 0.98, sets = 0.96, reps = 0.93)
    )
)

private val READINESS_SCALES = mapOf(
    AdaptationReadinessTier.LOW to 0.6,
    AdaptationReadinessTier.NEUTRAL to 1.0,
    AdaptationReadinessTier.HIGH to 1.2
)

private val CONFIDENCE_SCALES = mapOf(
    AdaptationConfidence.LOW to 0.55,
    AdaptationConfidence.MEDIUM to 0.8,
    AdaptationConfidence.HIGH to 1.0
)

private fun clamp(value: Double, min: Double, max: Double): Double =
    value.coerceIn(min, max)

// Classify an exercise name into a body region
fun classifyExerciseRegion(exerciseName: String): ExerciseRegion {
    val lower = exerciseName.lowercase()

    val lowerKeywords = listOf("squat", "deadlift", "leg", "hip thrust", "lunge", "calf", "glute", "hamstring", "good morning")
    if (lowerKeywords.any { lower.contains(it) }) return ExerciseRegion.LOWER

    val upperKeywords = listOf("bench", "press", "row", "pull-up", "chin-up", "curl", "dip", "lat pull", "face pull", "fly", "raise", "overhead", "shoulder", "tricep")
    if (upperKeywords.any { lower.contains(it) }) return ExerciseRegion.UPPER

    val coreKeywords = listOf("plank", "sit-up", "crunch", "ab ", "core", "hollow", "l-sit", "v-up", "toes-to-bar")
    if (coreKeywords.any { lower.contains(it) }) return ExerciseRegion.CORE

    val condKeywords = listOf("run", "row ", "bike", "swim", "burpee", "wall ball", "box jump", "double under", "skierg")
    if (condKeywords.any { lower.contains(it) }) return ExerciseRegion.CONDITIONING

    return ExerciseRegion.FULL_BODY
}

// Look up phase multipliers for a given phase and optional region
fun resolvePhaseMultipliers(phase: CyclePhase, region: ExerciseRegion? = null): PhaseMultipliers {
    if (region != null) {
        val regionMap = REGION_PHASE_MULTIPLIERS[region]
        if (regionMap != null) {
            return regionMap[phase] ?: PHASE_MULTIPLIERS[phase] ?: PhaseMultipliers(1.0, 1.0, 1.0)
        }
    }
    return PHASE_MULTIPLIERS[phase] ?: PhaseMultipliers(1.0, 1.0, 1.0)
}

// Next phase in cycle sequence
private fun nextCyclePhase(phase: CyclePhase): CyclePhase = when (phase) {
    CyclePhase.MENSTRUAL -> CyclePhase.FOLLICULAR
    CyclePhase.FOLLICULAR -> CyclePhase.OVULATION
    CyclePhase.OVULATION -> CyclePhase.LUTEAL
    CyclePhase.LUTEAL -> CyclePhase.MENSTRUAL
}

// Previous phase in cycle sequence
private fun previousCyclePhase(phase: CyclePhase): CyclePhase = when (phase) {
    CyclePhase.MENSTRUAL -> CyclePhase.LUTEAL
    CyclePhase.FOLLICULAR -> CyclePhase.MENSTRUAL
    CyclePhase.OVULATION -> CyclePhase.FOLLICULAR
    CyclePhase.LUTEAL -> CyclePhase.OVULATION
}

// Blended multipliers at phase boundaries (within 1 day)
fun blendedMultiplier(
    phase: CyclePhase,
    cycleDay: Int,
    settings: CycleSettings,
    region: ExerciseRegion? = null
): PhaseMultipliers {
    val boundaries = getPhaseBoundaries(settings)
    val current = resolvePhaseMultipliers(phase, region)
    val boundary = boundaries[phase] ?: return current

    if (cycleDay >= boundary.end) {
        val next = resolvePhaseMultipliers(nextCyclePhase(phase), region)
        return current.lerp(next, 0.5)
    }

    if (cycleDay <= boundary.start) {
        val prev = resolvePhaseMultipliers(previousCyclePhase(phase), region)
        return prev.lerp(current, 0.5)
    }

    return current
}

// Resolve readiness tier from 0-10 score
fun resolveReadinessTier(score: Double?): AdaptationReadinessTier {
    score ?: return AdaptationReadinessTier.NEUTRAL
    return when {
        score <= 3 -> AdaptationReadinessTier.LOW
        score >= 8 -> AdaptationReadinessTier.HIGH
        else -> AdaptationReadinessTier.NEUTRAL
    }
}

// Resolve confidence from cycle data availability
fun resolveConfidence(
    currentPhase: CyclePhase?,
    periodLogCount: Int,
    lastPeriodStartDate: LocalDate?,
    referenceDate: LocalDate
): AdaptationConfidence {
    if (periodLogCount == 0) return AdaptationConfidence.LOW

    if (lastPeriodStartDate != null) {
        val daysSince = referenceDate.toEpochDays() - lastPeriodStartDate.toEpochDays()
        if (daysSince > 60) return AdaptationConfidence.MEDIUM
    }

    if (currentPhase != null && periodLogCount >= 3) return AdaptationConfidence.HIGH
    if (currentPhase != null) return AdaptationConfidence.MEDIUM
    return AdaptationConfidence.LOW
}

// Adjust an ExerciseValue by a multiplier
fun adjustExerciseValueByMultiplier(value: ExerciseValue, multiplier: Double): ExerciseValue = when (value) {
    is ExerciseValue.Fixed -> ExerciseValue.Fixed(maxOf(1, (value.value * multiplier).toInt()))
    is ExerciseValue.Amrap -> value
    is ExerciseValue.Range -> ExerciseValue.Range(
        min = maxOf(1, (value.min * multiplier).toInt()),
        max = maxOf(1, (value.max * multiplier).toInt()).also { max ->
            if (max < maxOf(1, (value.min * multiplier).toInt())) {
                return ExerciseValue.Range(min = max, max = maxOf(1, (value.min * multiplier).toInt()))
            }
        }
    )
    is ExerciseValue.Text -> value
}

// Convenience: adjust weight by phase (returns adjusted weight)
fun adjustWeightByPhase(weight: Double, phase: CyclePhase): Double {
    val multiplier = PHASE_MULTIPLIERS[phase]?.load ?: 1.0
    return weight * multiplier
}

// Apply cycle phase adjustment to sets, reps, and load
fun applyPhaseAdjustment(
    sets: ExerciseValue,
    reps: ExerciseValue,
    percent1RM: Double?,
    phase: CyclePhase,
    readinessTier: AdaptationReadinessTier,
    confidence: AdaptationConfidence,
    exerciseRegion: ExerciseRegion? = null
): Triple<ExerciseValue, ExerciseValue, Double?> {
    val settings = resolvePhaseMultipliers(phase, exerciseRegion)
    val rs = READINESS_SCALES[readinessTier] ?: 1.0
    val cs = CONFIDENCE_SCALES[confidence] ?: 1.0

    fun blendMult(target: Double): Double = clamp(1.0 + (target - 1.0) * rs * cs, 0.75, 1.25)

    val adjustedSets = adjustExerciseValueByMultiplier(sets, blendMult(settings.sets))
    val adjustedReps = adjustExerciseValueByMultiplier(reps, blendMult(settings.reps))
    val adjustedLoad = percent1RM?.let { clamp(it * blendMult(settings.load), 0.4, 1.1) }

    return Triple(adjustedSets, adjustedReps, adjustedLoad)
}
