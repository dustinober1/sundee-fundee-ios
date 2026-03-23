package com.sundeefundee.domain

import com.sundeefundee.domain.model.InjuryProfile

/**
 * Result of an exercise adaptation including reason for replacement.
 */
data class ReplacementResult(
    val exerciseName: String,
    val reason: String
)

/**
 * Result of program adaptation with metadata about changes made.
 */
data class AdaptationResult(
    val adaptedExercises: Map<String, String> // Maps replacement exercise names to original names
)

/**
 * Recovery phases for injury tracking.
 */
enum class RecoveryPhase {
    ACUTE,
    REHAB,
    LIGHT_LOAD,
    RETURN_TO_PLAY,
    RESOLVED
}

/**
 * Adapts a workout program for active injury profiles.
 * Pure value semantics — never mutates inputs.
 */
object InjuryAdaptationEngine {

    // MARK: - Clinical synonym normalization

    private val clinicalSynonyms: Map<String, String> = mapOf(
        "acl" to "knee", "mcl" to "knee", "pcl" to "knee", "meniscus" to "knee",
        "patella" to "knee", "patellar" to "knee", "quad" to "knee", "quadriceps" to "knee",
        "rotator cuff" to "shoulder", "labrum" to "shoulder", "deltoid" to "shoulder",
        "supraspinatus" to "shoulder", "infraspinatus" to "shoulder", "bicep tendon" to "shoulder",
        "lumbar" to "back", "lower back" to "back", "upper back" to "back",
        "thoracic" to "back", "cervical" to "back", "disc" to "back", "herniated" to "back",
        "sciatica" to "back", "spinal" to "spine", "vertebra" to "spine", "vertebrae" to "spine",
        "sacroiliac" to "hip", "si joint" to "hip", "groin" to "hip", "labral" to "hip",
        "hip flexor" to "hip", "piriformis" to "hip",
        "achilles" to "ankle", "plantar" to "ankle", "calf" to "ankle",
        "carpal" to "wrist", "carpal tunnel" to "wrist", "forearm" to "wrist"
    )

    // MARK: - Contraindication rules

    private data class ContraindicationRule(
        val categories: List<String>,
        val muscleGroupKeywords: List<String>
    )

    private val contraindicationRules: Map<String, ContraindicationRule> = mapOf(
        "knee" to ContraindicationRule(
            categories = listOf("Squat Variations"),
            muscleGroupKeywords = listOf("quads")
        ),
        "shoulder" to ContraindicationRule(
            categories = listOf("Overhead Pressing", "Bench Press Variations"),
            muscleGroupKeywords = listOf("shoulders")
        ),
        "back" to ContraindicationRule(
            categories = listOf("Hinge Variations", "Deadlift Variations"),
            muscleGroupKeywords = listOf("back")
        ),
        "spine" to ContraindicationRule(
            categories = listOf("Hinge Variations", "Deadlift Variations"),
            muscleGroupKeywords = listOf("back")
        ),
        "hip" to ContraindicationRule(
            categories = emptyList(),
            muscleGroupKeywords = listOf("glutes", "hamstrings")
        ),
        "wrist" to ContraindicationRule(
            categories = listOf("Olympic Weightlifting"),
            muscleGroupKeywords = emptyList()
        )
    )

    // MARK: - Regression table (exercise replacements)

    private val regressionTable: Map<String, List<String>> = mapOf(
        // Squat variations
        "Back Squat" to listOf("Goblet Squat", "Box Squat", "Wall Ball Thrusters", "Air Squats"),
        "Front Squat" to listOf("Goblet Squat", "Safety Bar Squat", "Air Squats"),
        "Walking Lunges" to listOf("Stationary Lunges", "Step-Ups", "Wall Ball Thrusters"),
        // Hip hinge
        "Romanian Deadlift (No Straps)" to listOf("Nordic Curl", "Glute Bridge", "Hip Thrust", "Cable Pull-Through"),
        "Romanian Deadlift (With Straps)" to listOf("Nordic Curl", "Glute Bridge", "Hip Thrust", "Cable Pull-Through"),
        "Conventional Deadlift (No Straps)" to listOf("Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"),
        "Conventional Deadlift (With Straps)" to listOf("Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"),
        "Sumo Deadlift (No Straps)" to listOf("Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"),
        "Sumo Deadlift (With Straps)" to listOf("Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"),
        "Trap Bar Deadlift (No Straps)" to listOf("Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"),
        "Trap Bar Deadlift (With Straps)" to listOf("Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"),
        "Good Morning" to listOf("Cat-Cow", "Bird-Dogs", "Seated Good Morning"),
        // Machine / accessory
        "Wall Ball Thrusters" to listOf("Goblet Squat", "Air Squats", "Step-Ups"),
        "Banded Leg Curls" to listOf("Nordic Curl", "Glute Bridge", "Swiss Ball Leg Curl"),
        "Plated Calf Step Up" to listOf("Seated Calf Raise", "Single-Leg Calf Raise"),
        // Olympic Weightlifting
        "Squat Snatch" to listOf("Power Snatch", "Hang Snatch", "Overhead Squat"),
        "Squat Clean" to listOf("Power Clean", "Hang Clean", "Front Squat"),
        "Power Clean" to listOf("Hang Clean", "Kettlebell Deadlift", "Hip Thrust"),
        "Power Snatch" to listOf("Hang Snatch", "Kettlebell Deadlift", "Hip Thrust"),
        "Hang Clean" to listOf("Kettlebell Deadlift", "Hip Thrust", "Cable Pull-Through"),
        "Hang Snatch" to listOf("Kettlebell Deadlift", "Hip Thrust", "Cable Pull-Through"),
        "Split Jerk" to listOf("Push Press", "Push Jerk", "Strict Press"),
        "Push Jerk" to listOf("Push Press", "Strict Press", "Dumbbell Overhead Press"),
        "Clean and Jerk" to listOf("Power Clean", "Push Press", "Front Squat"),
        // Upper body press
        "Flat Barbell Bench Press" to listOf("Dumbbell Bench Press", "Floor Press", "Push-Ups"),
        "Strict Press / Military Press" to listOf("Lateral Raises", "Z-Press", "Seated Dumbbell Press"),
        // Upper body pull
        "Pull-Up" to listOf("Lat Pulldown", "Band-Assisted Pull-Up", "TRX Row"),
        "Barbell Row" to listOf("Dumbbell Row", "Cable Row", "TRX Row")
    )

    // MARK: - Recovery prep exercises

    private val recoveryPrepMap: Map<String, List<String>> = mapOf(
        "knee" to listOf("Bird-Dogs", "Bodyweight Lunges", "Terminal Knee Extension", "Straight Leg Raises"),
        "shoulder" to listOf("Banded Pull-Aparts", "Face Pulls", "Wall Slides", "Shoulder Circles"),
        "back" to listOf("Cat-Cow", "Bird-Dogs", "Dead Bug", "Pelvic Tilts"),
        "spine" to listOf("Cat-Cow", "Bird-Dogs", "Dead Bug", "McGill Curl-Up"),
        "hip" to listOf("Hip Circles", "Glute Bridges", "Clamshells", "90/90 Hip Stretch"),
        "ankle" to listOf("Ankle Circles", "Calf Raises (Partial)", "Towel Toe Curls"),
        "wrist" to listOf("Wrist Circles", "Prayer Stretch", "Reverse Wrist Curl")
    )

    private val safeBodyweight: List<String> = listOf("Air Squats", "Bird-Dogs", "Bodyweight Lunges")

    private val contraindicatedExerciseKeywords: Map<String, List<String>> = mapOf(
        "knee" to listOf("squat", "lunge", "leg press", "step-up"),
        "shoulder" to listOf("press", "bench", "overhead", "clean", "snatch", "jerk"),
        "back" to listOf("deadlift", "good morning", "hinge", "row"),
        "spine" to listOf("deadlift", "good morning", "hinge", "row"),
        "hip" to listOf("deadlift", "hinge", "lunge", "hip thrust"),
        "wrist" to listOf("clean", "snatch", "jerk")
    )

    // MARK: - Phase order for most restrictive calculation

    private val phaseOrder: List<RecoveryPhase> = listOf(
        RecoveryPhase.ACUTE,
        RecoveryPhase.REHAB,
        RecoveryPhase.LIGHT_LOAD,
        RecoveryPhase.RETURN_TO_PLAY,
        RecoveryPhase.RESOLVED
    )

    // MARK: - Public API

    /**
     * Maps free-text injury locations to engine contraindication keys
     * using clinical synonym matching.
     */
    fun normalizedBodyRegions(from injuries: List<InjuryProfile>): List<String> {
        val regions = mutableSetOf<String>()
        val knownKeys = contraindicationRules.keys

        for (injury in injuries) {
            val loc = injury.bodyLocationRaw.lowercase()

            // Direct match against known keys
            for (key in knownKeys) {
                if (loc.contains(key)) {
                    regions.add(key)
                }
            }

            // Clinical synonym matching
            for ((synonym, region) in clinicalSynonyms) {
                if (loc.contains(synonym)) {
                    regions.add(region)
                }
            }
        }

        return regions.toList()
    }

    /**
     * Returns the most restrictive (earliest) phase from a list.
     */
    fun mostRestrictivePhase(phases: List<RecoveryPhase>): RecoveryPhase? {
        return phases.minByOrNull { phase ->
            phaseOrder.indexOf(phase)
        }
    }

    /**
     * Checks if an exercise is contraindicated for the given injuries.
     */
    fun isContraindicated(exerciseId: String, injuries: List<InjuryProfile>): Boolean {
        val exerciseName = exerciseId.lowercase()

        for (injury in injuries) {
            val loc = injury.bodyLocationRaw.lowercase()

            for ((key, rule) in contraindicationRules) {
                if (!loc.contains(key)) continue

                for (keyword in rule.muscleGroupKeywords) {
                    if (exerciseName.contains(keyword)) return true
                }

                for (cat in rule.categories) {
                    if (exerciseName.contains(cat.lowercase())) return true
                }

                contraindicatedExerciseKeywords[key]?.forEach { keyword ->
                    if (exerciseName.contains(keyword)) return true
                }
            }
        }

        return false
    }

    /**
     * Finds a replacement exercise for a contraindicated exercise.
     */
    fun findReplacement(exerciseId: String, injuries: List<InjuryProfile>): ReplacementResult {
        val locations = injuries.joinToString(", ") { it.bodyLocationRaw }

        // Try regression table first
        regressionTable[exerciseId]?.forEach { candidate ->
            if (!isContraindicated(candidate, injuries)) {
                return ReplacementResult(
                    exerciseName = candidate,
                    reason = "Replaced due to $locations injury. Using $candidate."
                )
            }
        }

        // Fall back to safe bodyweight exercises
        for (safe in safeBodyweight) {
            if (!isContraindicated(safe, injuries)) {
                return ReplacementResult(
                    exerciseName = safe,
                    reason = "Replaced due to $locations injury. Using $safe."
                )
            }
        }

        return ReplacementResult(
            exerciseName = exerciseId,
            reason = "Consult your coach — no safe automatic replacement found for $locations injury."
        )
    }

    /**
     * Calculates the load reduction factor for an injury.
     * Returns a value between 0.0 and 1.0 representing the percentage of normal load allowed.
     */
    fun getLoadReduction(injury: InjuryProfile): Double {
        // This would typically use the recovery phase, but since InjuryProfile
        // doesn't have that field, we use severity as a proxy (1-10 scale)
        return when {
            injury.severity >= 8 -> 0.3
            injury.severity >= 5 -> 0.5
            injury.severity >= 3 -> 0.7
            else -> 0.9
        }
    }

    /**
     * Gets an alternative exercise name for the given injury and original exercise.
     * Returns null if no specific alternative is needed.
     */
    fun getAlternativeExercise(original: String, injury: InjuryProfile): String? {
        val injuries = listOf(injury)
        return if (isContraindicated(original, injuries)) {
            findReplacement(original, injuries).exerciseName
        } else {
            null
        }
    }

    /**
     * Builds a recovery prep exercise block for the given injuries.
     */
    fun buildRecoveryPrepBlock(injuries: List<InjuryProfile>): List<String> {
        val seen = mutableSetOf<String>()
        val block = mutableListOf<String>()

        for (injury in injuries) {
            val loc = injury.bodyLocationRaw.lowercase()

            for ((key, exercises) in recoveryPrepMap) {
                if (!loc.contains(key)) continue

                for (ex in exercises) {
                    if (!seen.contains(ex)) {
                        seen.add(ex)
                        block.add(ex)
                    }
                }
            }
        }

        return block
    }
}
