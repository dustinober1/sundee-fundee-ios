package com.sundeefundee.core.domain.intelligence

import com.sundeefundee.core.domain.exercise.WeightliftingCatalog
import com.sundeefundee.core.domain.exercise.WeightliftingCategory
import com.sundeefundee.core.domain.injury.Injury
import com.sundeefundee.core.domain.injury.InjuryAdaptationEngine
import com.sundeefundee.core.domain.injury.RecoveryPhase
import kotlin.math.min

/**
 * Ranks substitute exercises by similarity, equipment match, and injury compatibility.
 *
 * Given a target exercise the user cannot or does not want to perform,
 * plus their context (injuries, available equipment, time constraints),
 * returns a ranked list of alternatives from the exercise catalog.
 *
 * Pure domain logic -- no framework dependencies.
 */
object SubstitutionRanker {

    // MARK: - Types

    /** A ranked substitute exercise. */
    data class RankedSubstitution(
        /** The substitute exercise name. */
        val exerciseName: String,
        /** The category of the substitute. */
        val category: WeightliftingCategory,
        /** Overall match score (0.0-1.0, higher is better). */
        val score: Double,
        /** Why this exercise is a good substitute. */
        val reason: String
    )

    /** Available equipment context for filtering. */
    data class EquipmentContext(
        /** Whether a barbell is available. */
        val hasBarbell: Boolean = true,
        /** Whether dumbbells are available. */
        val hasDumbbells: Boolean = true,
        /** Whether a pull-up bar is available. */
        val hasPullUpBar: Boolean = true,
        /** Whether machines/cables are available. */
        val hasMachines: Boolean = true
    ) {
        companion object {
            /** Full gym -- everything available. */
            val FULL_GYM = EquipmentContext()

            /** Home with dumbbells only. */
            val HOME_DUMBBELLS = EquipmentContext(
                hasBarbell = false,
                hasDumbbells = true,
                hasPullUpBar = false,
                hasMachines = false
            )

            /** Bodyweight only. */
            val BODYWEIGHT_ONLY = EquipmentContext(
                hasBarbell = false,
                hasDumbbells = false,
                hasPullUpBar = false,
                hasMachines = false
            )
        }
    }

    /**
     * User profile for preference-based ranking.
     * Maps to the CoachProfile concept from the coach domain.
     */
    data class UserProfile(
        val favoriteExercises: Set<String> = emptySet(),
        val avoidedExercises: Set<String> = emptySet()
    )

    // MARK: - Muscle Activation Map

    /**
     * Primary muscle groups activated by each exercise.
     * Keys match exact catalog IDs from [WeightliftingCatalog].
     */
    private val muscleGroups: Map<String, Set<String>> = mapOf(
        // Squat
        "Back Squat" to setOf("Quads", "Glutes", "Hamstrings", "Core"),
        "Front Squat" to setOf("Quads", "Glutes", "Core", "Upper Back"),
        "Safety Bar Squat" to setOf("Quads", "Glutes", "Hamstrings", "Core"),
        "Box Squat" to setOf("Quads", "Glutes", "Hamstrings"),
        "Pause Squat" to setOf("Quads", "Glutes", "Hamstrings", "Core"),
        "Goblet Squat" to setOf("Quads", "Glutes", "Core"),
        "Leg Press" to setOf("Quads", "Glutes", "Hamstrings"),
        "Hack Squat" to setOf("Quads", "Glutes"),
        "Leg Extension" to setOf("Quads"),

        // Hip Hinge
        "Conventional Deadlift (No Straps)" to setOf("Hamstrings", "Glutes", "Lower Back", "Core", "Upper Back"),
        "Conventional Deadlift (With Straps)" to setOf("Hamstrings", "Glutes", "Lower Back", "Core", "Upper Back"),
        "Romanian Deadlift (No Straps)" to setOf("Hamstrings", "Glutes", "Lower Back"),
        "Romanian Deadlift (With Straps)" to setOf("Hamstrings", "Glutes", "Lower Back"),
        "Sumo Deadlift (No Straps)" to setOf("Hamstrings", "Glutes", "Adductors", "Lower Back"),
        "Sumo Deadlift (With Straps)" to setOf("Hamstrings", "Glutes", "Adductors", "Lower Back"),
        "Trap Bar Deadlift (No Straps)" to setOf("Quads", "Glutes", "Hamstrings", "Lower Back"),
        "Trap Bar Deadlift (With Straps)" to setOf("Quads", "Glutes", "Hamstrings", "Lower Back"),
        "Good Morning" to setOf("Hamstrings", "Glutes", "Lower Back"),
        "Hip Thrust" to setOf("Glutes", "Hamstrings"),
        "Leg Curl (Lying)" to setOf("Hamstrings"),
        "Leg Curl (Seated)" to setOf("Hamstrings"),
        "Glute Ham Raise" to setOf("Hamstrings", "Glutes", "Lower Back"),

        // Press
        "Flat Barbell Bench Press" to setOf("Chest", "Triceps", "Front Delts"),
        "Incline Barbell Bench Press" to setOf("Upper Chest", "Triceps", "Front Delts"),
        "Decline Barbell Bench Press" to setOf("Chest", "Triceps", "Front Delts"),
        "Strict Press" to setOf("Front Delts", "Triceps", "Upper Chest"),
        "Push Press" to setOf("Front Delts", "Triceps", "Upper Chest", "Core"),
        "Dumbbell Bench Press" to setOf("Chest", "Triceps", "Front Delts"),
        "Dumbbell Incline Press" to setOf("Upper Chest", "Triceps", "Front Delts"),
        "Dumbbell Overhead Press" to setOf("Front Delts", "Triceps", "Side Delts"),
        "Dips (Weighted)" to setOf("Chest", "Triceps", "Front Delts"),
        "Close Grip Bench Press" to setOf("Triceps", "Chest", "Front Delts"),

        // Pull
        "Barbell Row" to setOf("Upper Back", "Lats", "Biceps", "Rear Delts"),
        "Pendlay Row" to setOf("Upper Back", "Lats", "Biceps"),
        "Pull-Up" to setOf("Lats", "Biceps", "Upper Back"),
        "Weighted Pull-Up" to setOf("Lats", "Biceps", "Upper Back"),
        "Lat Pulldown" to setOf("Lats", "Biceps", "Upper Back"),
        "Cable Row" to setOf("Upper Back", "Lats", "Biceps"),
        "Dumbbell Row" to setOf("Upper Back", "Lats", "Biceps"),
        "Face Pull" to setOf("Rear Delts", "Upper Back"),
        "Bicep Curl (Barbell)" to setOf("Biceps"),
        "Bicep Curl (Dumbbell)" to setOf("Biceps"),
        "Hammer Curl" to setOf("Biceps", "Forearms"),
        "Upright Row" to setOf("Side Delts", "Traps", "Biceps"),

        // Carry
        "Farmers Carry" to setOf("Grip", "Core", "Traps", "Shoulders"),
        "Suitcase Carry" to setOf("Core", "Grip", "Shoulders"),
        "Zercher Carry" to setOf("Core", "Upper Back", "Biceps"),
        "Yoke Walk" to setOf("Core", "Traps", "Quads", "Glutes"),

        // Olympic Weightlifting
        "Squat Snatch" to setOf("Quads", "Glutes", "Shoulders", "Core", "Upper Back"),
        "Squat Clean" to setOf("Quads", "Glutes", "Hamstrings", "Upper Back", "Core"),
        "Power Clean" to setOf("Quads", "Glutes", "Hamstrings", "Upper Back", "Core"),
        "Power Snatch" to setOf("Quads", "Glutes", "Shoulders", "Core"),
        "Hang Clean" to setOf("Hamstrings", "Glutes", "Upper Back", "Core"),
        "Hang Snatch" to setOf("Hamstrings", "Glutes", "Shoulders", "Core"),
        "Split Jerk" to setOf("Quads", "Shoulders", "Triceps", "Core"),
        "Push Jerk" to setOf("Shoulders", "Triceps", "Core", "Quads"),
        "Clean and Jerk" to setOf("Quads", "Glutes", "Hamstrings", "Shoulders", "Core", "Upper Back"),
        "Muscle Snatch" to setOf("Shoulders", "Upper Back", "Core"),
        "Muscle Clean" to setOf("Upper Back", "Biceps", "Core"),
    )

    // MARK: - Ranking

    /**
     * Finds and ranks substitute exercises for a given target.
     *
     * @param target The exercise to substitute.
     * @param injuries Current active injuries (used for graded injury compatibility scoring).
     * @param equipment Available equipment.
     * @param profile Optional user profile for history preferences.
     * @param limit Maximum number of results (default 5).
     * @return Ranked substitutions, best first.
     */
    fun rank(
        target: String,
        injuries: List<Injury> = emptyList(),
        equipment: EquipmentContext = EquipmentContext.FULL_GYM,
        profile: UserProfile? = null,
        limit: Int = 5
    ): List<RankedSubstitution> {
        val targetEntry = WeightliftingCatalog.all.firstOrNull { it.id == target }
            ?: return emptyList()
        val targetCategory = targetEntry.category

        val candidates = WeightliftingCatalog.all.filter { it.id != target }
        val scored = mutableListOf<RankedSubstitution>()

        for (candidate in candidates) {
            // Graded injury compatibility (replaces binary filtering)
            val injuryScore = injuryCompatibilityScore(
                exerciseName = candidate.id,
                injuries = injuries
            )
            // Skip fully contraindicated exercises (acute/rehab phase)
            if (injuryScore <= 0) continue

            // Skip if equipment doesn't match
            if (!matchesEquipment(candidate.id, equipment)) continue

            var score = 0.0
            val reasons = mutableListOf<String>()

            // Muscle activation overlap (strongest signal)
            val muscleOverlap = muscleOverlapScore(target, candidate.id)
            if (muscleOverlap > 0) {
                score += muscleOverlap * 0.4
                if (muscleOverlap > 0.5) {
                    reasons.add("targets similar muscles")
                }
            }

            // Same category bonus (reduced since muscle overlap is now primary)
            if (candidate.category == targetCategory) {
                score += 0.35
                if (muscleOverlap == 0.0) {
                    reasons.add("same movement pattern")
                }
            } else if (areRelatedCategories(targetCategory, candidate.category)) {
                score += 0.2
                reasons.add("related movement")
            }

            // Similarity bonus based on name overlap
            val nameSim = nameSimilarityScore(target, candidate.id)
            score += nameSim * 0.2
            if (nameSim > 0.3) {
                reasons.add("similar exercise variant")
            }

            // Equipment simplicity bonus
            if (isDumbbellExercise(candidate.id) && !isDumbbellExercise(target)) {
                score += 0.1
                reasons.add("dumbbell alternative")
            }

            // Machine alternative bonus when injured
            if (injuries.isNotEmpty() && isMachineExercise(candidate.id)) {
                score += 0.1
                reasons.add("machine (more controlled)")
            }

            // User history preferences
            if (profile != null) {
                if (candidate.id in profile.favoriteExercises) {
                    score += 0.15
                    reasons.add("matches your preferences")
                }
                if (candidate.id in profile.avoidedExercises) {
                    score -= 0.2
                    reasons.add("previously avoided")
                }
            }

            // Apply graded injury penalty
            score *= injuryScore
            if (injuryScore < 1.0 && injuryScore > 0) {
                reasons.add("caution: near injury area")
            }

            val reason = if (reasons.isEmpty()) "Alternative option"
            else reasons.joinToString(", ").replaceFirstChar { it.uppercase() }

            val capped = min(maxOf(score, 0.0), 1.0)

            scored.add(
                RankedSubstitution(
                    exerciseName = candidate.id,
                    category = candidate.category,
                    score = capped,
                    reason = reason
                )
            )
        }

        return scored.sortedByDescending { it.score }.take(limit)
    }

    // MARK: - Muscle Overlap

    /** Computes Jaccard similarity between the muscle groups of two exercises.
     * Returns 0 if either exercise has no known muscle data. */
    fun muscleOverlapScore(a: String, b: String): Double {
        val aMuscles = muscleGroups[a] ?: return 0.0
        val bMuscles = muscleGroups[b] ?: return 0.0

        val intersection = aMuscles.intersect(bMuscles)
        val union = aMuscles.union(bMuscles)
        if (union.isEmpty()) return 0.0

        return intersection.size.toDouble() / union.size.toDouble()
    }

    // MARK: - Injury Compatibility

    /**
     * Returns a graded injury compatibility score.
     * - 1.0: fully safe (no relevant injuries or resolved phase)
     * - 0.5: partially restricted (lightLoad or returnToPlay phase)
     * - 0.0: contraindicated (acute or rehab phase)
     */
    private fun injuryCompatibilityScore(
        exerciseName: String,
        injuries: List<Injury>
    ): Double {
        if (injuries.isEmpty()) return 1.0

        var worstScore = 1.0
        for (injury in injuries) {
            val contraindicated = InjuryAdaptationEngine.isContraindicated(
                exerciseName = exerciseName,
                exerciseCategory = null,
                injuries = listOf(injury)
            )
            if (contraindicated) {
                when (injury.recoveryPhase) {
                    RecoveryPhase.ACUTE, RecoveryPhase.REHAB -> return 0.0
                    RecoveryPhase.LIGHT_LOAD, RecoveryPhase.RETURN_TO_PLAY ->
                        worstScore = minOf(worstScore, 0.5)
                    RecoveryPhase.RESOLVED -> { /* safe */ }
                }
            }
        }
        return worstScore
    }

    // MARK: - Private Helpers

    private fun matchesEquipment(exercise: String, equipment: EquipmentContext): Boolean {
        val name = exercise.lowercase()

        if (name.contains("barbell") || name.contains("bar ")) {
            return equipment.hasBarbell
        }
        if (name.contains("dumbbell")) {
            return equipment.hasDumbbells
        }
        if (name.contains("pull-up") || name.contains("chin-up") || name.contains("muscle-up")) {
            return equipment.hasPullUpBar
        }
        if (name.contains("cable") || name.contains("machine") ||
            name.contains("lat pulldown") || name.contains("leg press") ||
            name.contains("hack squat") || name.contains("leg extension") ||
            name.contains("leg curl")
        ) {
            return equipment.hasMachines
        }

        return true
    }

    private val relatedCategoryPairs: Set<Set<WeightliftingCategory>> = setOf(
        setOf(WeightliftingCategory.SQUAT, WeightliftingCategory.HIP_HINGE),
        setOf(WeightliftingCategory.PRESS, WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
        setOf(WeightliftingCategory.PULL, WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
    )

    private fun areRelatedCategories(
        a: WeightliftingCategory,
        b: WeightliftingCategory
    ): Boolean {
        return relatedCategoryPairs.contains(setOf(a, b))
    }

    private fun nameSimilarityScore(a: String, b: String): Double {
        val aWords = a.lowercase().split(" ").toSet()
        val bWords = b.lowercase().split(" ").toSet()
        val common = aWords.intersect(bWords)
        val total = aWords.union(bWords)
        if (total.isEmpty()) return 0.0
        return common.size.toDouble() / total.size.toDouble()
    }

    private fun isDumbbellExercise(name: String): Boolean =
        name.lowercase().contains("dumbbell")

    private fun isMachineExercise(name: String): Boolean {
        val keywords = listOf(
            "machine", "cable", "lat pulldown", "leg press",
            "hack squat", "leg extension", "leg curl"
        )
        val lower = name.lowercase()
        return keywords.any { lower.contains(it) }
    }
}
