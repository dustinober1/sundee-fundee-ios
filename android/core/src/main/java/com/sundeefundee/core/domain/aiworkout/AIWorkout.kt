package com.sundeefundee.core.domain.aiworkout

import com.sundeefundee.core.domain.cycle.ExerciseRegion
import com.sundeefundee.core.domain.cycle.resolvePhaseMultipliers
import com.sundeefundee.core.model.CyclePhase
import kotlinx.serialization.Serializable
import java.util.UUID

// MARK: - Types

/**
 * Workout focus area.
 */
@Serializable
enum class WorkoutFocus(val serialName: String) {
    UPPER_BODY("upper_body"),
    LOWER_BODY("lower_body"),
    FULL_BODY("full_body"),
    PUSH("push"),
    PULL("pull"),
    CORE("core"),
    CONDITIONING("conditioning")
}

/**
 * Energy level for workout generation.
 */
@Serializable
enum class EnergyLevel(val serialName: String) {
    LOW("low"),
    MEDIUM("medium"),
    HIGH("high")
}

/**
 * Equipment access level.
 */
@Serializable
enum class EquipmentAccess(val serialName: String) {
    FULL_GYM("full_gym"),
    HOME_DUMBBELLS("home_dumbbells"),
    BODYWEIGHT_ONLY("bodyweight_only"),
    OUTDOOR("outdoor")
}

/**
 * Questionnaire answers for AI workout generation.
 */
@Serializable
data class QuestionnaireAnswers(
    val timeMinutes: Int,
    val focus: WorkoutFocus,
    val energyLevel: EnergyLevel,
    val equipment: EquipmentAccess
)

/**
 * A generated exercise from AI.
 */
@Serializable
data class GeneratedExercise(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val sets: Int,
    val reps: String,
    val weightKg: Double? = null,
    val restMinutes: Double? = null,
    val notes: String? = null,
    val reasoning: String? = null,
    val bodyweightOnly: Boolean = false,
    /** Percentage of 1RM used (e.g., 0.70 for 70%) */
    var percentageOfMax: Double? = null
)

/**
 * A complete generated workout.
 */
@Serializable
data class GeneratedWorkout(
    val id: String = UUID.randomUUID().toString(),
    val createdAt: String, // ISO8601
    var isFavorite: Boolean = false,
    val coachingSummary: String,
    val exercises: List<GeneratedExercise>,
    val questionnaire: QuestionnaireAnswers
)

/**
 * An exercise max for weight calculation.
 */
data class ExerciseMax(
    val name: String,
    val weightKg: Double
)

// MARK: - Extract Muscle Groups

/**
 * Extract targeted muscle groups from exercise names.
 */
fun extractMuscleGroups(exercises: List<GeneratedExercise>): List<String> {
    val groups = mutableSetOf<String>()
    for (ex in exercises) {
        val name = ex.name.lowercase()
        if (name.contains("squat") || name.contains("lunge") || name.contains("leg press")) groups.add("Quads")
        if (name.contains("deadlift") || name.contains("hip thrust") || name.contains("glute")) groups.add("Glutes")
        if (name.contains("bench") || name.contains("push") || name.contains("chest") || name.contains("fly")) groups.add("Chest")
        if (name.contains("row") || name.contains("pull") || name.contains("lat")) groups.add("Back")
        if (name.contains("press") && (name.contains("overhead") || name.contains("shoulder") || name.contains("military"))) groups.add("Shoulders")
        if (name.contains("curl") || name.contains("bicep")) groups.add("Biceps")
        if (name.contains("tricep") || name.contains("extension") || name.contains("dip")) groups.add("Triceps")
        if (name.contains("core") || name.contains("plank") || name.contains("crunch") || name.contains("ab")) groups.add("Core")
        if (name.contains("calf")) groups.add("Calves")
        if (name.contains("hamstring") || name.contains("romanian") || name.contains("nordic")) groups.add("Hamstrings")
    }
    return groups.sorted()
}

// MARK: - Default Percentage

/**
 * Map rep count string to default %1RM.
 */
fun aiDefaultPercentage(reps: String): Double {
    val firstPart = reps.split("-").firstOrNull() ?: ""
    val repCount = firstPart.toIntOrNull() ?: 10
    return when (repCount) {
        in 1..3 -> 0.85
        in 4..5 -> 0.80
        in 6..8 -> 0.70
        in 9..12 -> 0.65
        else -> 0.60
    }
}

// MARK: - Assign Rest Minutes

/**
 * Assign rest time based on bodyweight flag and rep count.
 */
fun assignRestMinutes(bodyweight: Boolean, reps: String): Double {
    if (bodyweight) return 1.0
    val firstPart = reps.split("-").firstOrNull() ?: ""
    val repCount = firstPart.toIntOrNull() ?: 10
    return when (repCount) {
        in 1..5 -> 2.5
        in 6..8 -> 2.0
        in 9..12 -> 1.5
        else -> 1.0
    }
}

// MARK: - Total Estimated Minutes

/**
 * Estimate total workout duration in minutes.
 */
fun totalEstimatedMinutes(exercises: List<GeneratedExercise>): Int {
    val total = exercises.sumOf { ex ->
        val rest = ex.restMinutes ?: 1.5
        ex.sets.toDouble() * (rest + 0.5)
    }
    return maxOf(1, kotlin.math.round(total).toInt())
}

// MARK: - Energy Multiplier

/**
 * Get energy level multiplier.
 */
fun energyMultiplier(level: EnergyLevel): Double = when (level) {
    EnergyLevel.LOW -> 0.85
    EnergyLevel.MEDIUM -> 1.0
    EnergyLevel.HIGH -> 1.05
}

// MARK: - Cycle Phase Multiplier (AI)

/**
 * Get cycle phase multiplier for AI workout generation.
 * When an exercise region is provided, uses region-specific multipliers
 * (e.g., lower body gets bigger menstrual reduction).
 */
fun aiCyclePhaseMultiplier(
    phase: CyclePhase?,
    region: ExerciseRegion? = null
): Double {
    phase ?: return 1.0
    return resolvePhaseMultipliers(phase, region).load
}

// MARK: - Apply Weights

/**
 * Apply weights to exercises based on user's maxes.
 */
fun applyWeights(
    exercises: List<GeneratedExercise>,
    maxes: List<ExerciseMax>,
    energyMult: Double,
    cycleMult: Double
): List<GeneratedExercise> {
    return exercises.map { ex ->
        if (ex.bodyweightOnly) return@map ex
        val matched = findMatchingMax(ex.name, maxes) ?: return@map ex

        val pct = aiDefaultPercentage(ex.reps)
        val raw = matched.weightKg * pct * energyMult * cycleMult
        val rounded = kotlin.math.round(raw / 5.0) * 5.0

        // Store the effective percentage (including multipliers) for display
        val effectivePct = pct * energyMult * cycleMult

        ex.copy(
            weightKg = rounded,
            percentageOfMax = effectivePct
        )
    }
}

// MARK: - Find Matching Max (fuzzy)

/**
 * Fuzzy match an exercise name to a user's max.
 */
fun findMatchingMax(exerciseName: String, maxes: List<ExerciseMax>): ExerciseMax? {
    val lower = exerciseName.lowercase()
    // Exact match first
    maxes.firstOrNull { it.name.lowercase() == lower }?.let { return it }
    // Substring match
    return maxes.firstOrNull { m ->
        m.name.lowercase().contains(lower) || lower.contains(m.name.lowercase())
    }
}

// MARK: - Volume-Targeted Workout Generation

/**
 * Suggested set breakdown for reaching a volume target.
 */
data class VolumeTargetBreakdown(
    /** Suggested sets. */
    val sets: Int,
    /** Suggested reps per set. */
    val reps: Int,
    /** Weight per rep in the user's unit. */
    val weight: Double,
    /** Total volume from this breakdown. */
    val totalVolume: Double,
    /** How close this is to the target (within +/-5% is ideal). */
    val variancePercent: Double
)

/**
 * Generates a suggested sets/reps/weight breakdown to reach a target volume for an exercise.
 *
 * Uses the user's working weight (from maxes at 70% 1RM) and distributes reps
 * across sets to approximate the target volume.
 *
 * @param targetVolumeLbs The volume goal (reps x weight).
 * @param exerciseName The exercise to target.
 * @param maxes The user's 1RM records.
 * @return A breakdown suggestion, or null if no max is found.
 */
fun generateVolumeTargetedBreakdown(
    targetVolumeLbs: Double,
    exerciseName: String,
    maxes: List<ExerciseMax>
): VolumeTargetBreakdown? {
    val matched = findMatchingMax(exerciseName, maxes) ?: return null

    // Use 70% of 1RM as the working weight (moderate intensity for volume work)
    val workingWeight = kotlin.math.round(matched.weightKg * 0.70 * 2.20462) // Convert kg to lbs
    val roundedWeight = kotlin.math.round(workingWeight / 5.0) * 5.0 // Round to nearest 5 lbs

    if (roundedWeight <= 0) return null

    // Calculate total reps needed
    val totalRepsNeeded = targetVolumeLbs / roundedWeight

    // Distribute across sets (target 8-12 reps per set)
    val idealReps = 8
    var setsNeeded = kotlin.math.round(totalRepsNeeded / idealReps).toInt()
    setsNeeded = setsNeeded.coerceIn(1, 6)
    var repsPerSet = kotlin.math.round(totalRepsNeeded / setsNeeded).toInt()
    repsPerSet = repsPerSet.coerceIn(1, 15)

    val totalVolume = (setsNeeded * repsPerSet).toDouble() * roundedWeight
    val variance = if (targetVolumeLbs > 0) {
        (totalVolume - targetVolumeLbs) / targetVolumeLbs * 100
    } else {
        0.0
    }

    return VolumeTargetBreakdown(
        sets = setsNeeded,
        reps = repsPerSet,
        weight = roundedWeight,
        totalVolume = totalVolume,
        variancePercent = variance
    )
}
