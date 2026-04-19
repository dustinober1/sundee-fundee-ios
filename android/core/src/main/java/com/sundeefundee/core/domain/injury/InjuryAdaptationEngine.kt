package com.sundeefundee.core.domain.injury

import java.util.concurrent.TimeUnit

// MARK: - Injury Adaptation Engine

/**
 * Modifies workouts based on user's active injuries.
 * Pure domain logic with zero framework dependencies.
 */
object InjuryAdaptationEngine {

    // MARK: - Contraindication Rules

    private data class ContraindicationRule(
        val categories: List<String>,
        val keywords: List<String>
    )

    /** Rules for determining which exercises are contraindicated for each body region */
    private val contraindicationRules: Map<String, ContraindicationRule> = mapOf(
        "knee" to ContraindicationRule(
            categories = listOf("Squat"),
            keywords = listOf("squat", "lunge", "leg press", "leg extension", "box jump", "jump")
        ),
        "shoulder" to ContraindicationRule(
            categories = listOf("Press", "Olympic Weightlifting"),
            keywords = listOf("press", "overhead", "bench", "push-up", "dip", "fly", "raise")
        ),
        "back" to ContraindicationRule(
            categories = listOf("Hip Hinge"),
            keywords = listOf("deadlift", "good morning", "row", "back extension", "hyperextension")
        ),
        "hip" to ContraindicationRule(
            categories = emptyList(),
            keywords = listOf("hip thrust", "glute", "hamstring", "lunge", "step-up")
        ),
        "wrist" to ContraindicationRule(
            categories = listOf("Olympic Weightlifting"),
            keywords = listOf("clean", "snatch", "jerk", "front squat", "wrist")
        ),
        "elbow" to ContraindicationRule(
            categories = emptyList(),
            keywords = listOf("curl", "tricep", "extension", "press")
        ),
        "ankle" to ContraindicationRule(
            categories = emptyList(),
            keywords = listOf("calf", "jump", "run", "sprint", "box jump")
        ),
    )

    // MARK: - Clinical Synonyms

    /** Maps clinical terms to body region engine keys */
    private val clinicalSynonyms: Map<String, String> = mapOf(
        "acl" to "knee",
        "mcl" to "knee",
        "meniscus" to "knee",
        "patella" to "knee",
        "rotator cuff" to "shoulder",
        "labrum" to "shoulder",
        "frozen shoulder" to "shoulder",
        "lumbar" to "back",
        "herniated disc" to "back",
        "sciatica" to "back",
        "si joint" to "hip",
        "piriformis" to "hip",
        "carpal tunnel" to "wrist",
        "tennis elbow" to "elbow",
        "golfers elbow" to "elbow",
        "achilles" to "ankle",
        "plantar fascia" to "ankle",
    )

    // MARK: - Regression Table

    /** Maps exercises to progressively easier alternatives */
    private val regressionTable: Map<String, List<String>> = mapOf(
        "Back Squat" to listOf("Goblet Squat", "Box Squat", "Air Squats"),
        "Front Squat" to listOf("Goblet Squat", "Box Squat", "Air Squats"),
        "Flat Barbell Bench Press" to listOf("Dumbbell Bench Press", "Push-Ups", "Floor Press"),
        "Incline Barbell Bench Press" to listOf("Dumbbell Bench Press", "Push-Ups", "Floor Press"),
        "Strict Press" to listOf("Lateral Raises", "Z-Press", "Seated Dumbbell Press"),
        "Push Press" to listOf("Dumbbell Overhead Press", "Lateral Raises", "Arnold Press"),
        "Conventional Deadlift" to listOf("Romanian Deadlift", "Trap Bar Deadlift", "Kettlebell Deadlift"),
        "Romanian Deadlift" to listOf("Nordic Curl", "Glute Bridge", "Hip Thrust"),
        "Squat Snatch" to listOf("Power Snatch", "Hang Snatch", "Overhead Squat"),
        "Squat Clean" to listOf("Power Clean", "Hang Clean", "Front Squat"),
        "Power Clean" to listOf("Hang Clean", "Kettlebell Deadlift", "Hip Thrust"),
        "Power Snatch" to listOf("Hang Snatch", "Kettlebell Deadlift", "Hip Thrust"),
        "Clean and Jerk" to listOf("Power Clean", "Push Press", "Front Squat"),
        "Split Jerk" to listOf("Push Press", "Push Jerk", "Strict Press"),
        "Pull-Up" to listOf("Lat Pulldown", "Band-Assisted Pull-Up", "TRX Row"),
        "Toes-to-Bar" to listOf("Knees-to-Elbows", "Hanging Leg Raises", "Lying Leg Raises"),
        "Box Jump" to listOf("Step-Up", "Box Step-Up", "Air Squats"),
        "Burpee" to listOf("Step-Up Burpee", "Squat Thrust", "Air Squat"),
    )

    // MARK: - Simple Load Multipliers (for calculateLoadMultiplier)

    /** Load reduction multipliers for each recovery phase */
    private val simpleLoadMultipliers: Map<RecoveryPhase, Double> = mapOf(
        RecoveryPhase.ACUTE to 0.3,
        RecoveryPhase.REHAB to 0.5,
        RecoveryPhase.LIGHT_LOAD to 0.7,
        RecoveryPhase.RETURN_TO_PLAY to 0.85,
        RecoveryPhase.RESOLVED to 1.0,
    )

    // MARK: - Public Methods

    /** Check if an exercise is contraindicated for the given injuries */
    fun isContraindicated(
        exerciseName: String,
        exerciseCategory: String?,
        injuries: List<Injury>
    ): Boolean {
        // No active injuries (only resolved ones)
        val activeInjuries = injuries.filter { it.recoveryPhase != RecoveryPhase.RESOLVED }
        if (activeInjuries.isEmpty()) return false

        val lowerExerciseName = exerciseName.lowercase()

        for (injury in activeInjuries) {
            val regions = injury.bodyRegions

            for (region in regions) {
                // Check clinical synonyms first
                val engineKey = clinicalSynonyms[injury.name.lowercase()] ?: region.engineKey

                val rule = contraindicationRules[engineKey] ?: continue

                // Check category match
                if (exerciseCategory != null) {
                    if (rule.categories.any { exerciseCategory.contains(it, ignoreCase = true) }) {
                        return true
                    }
                }

                // Check keyword match
                for (keyword in rule.keywords) {
                    if (lowerExerciseName.contains(keyword.lowercase())) {
                        return true
                    }
                }
            }
        }

        return false
    }

    /** Get regressions for an exercise based on injuries */
    fun getRegressions(
        exerciseName: String,
        injuries: List<Injury>
    ): List<String> {
        // Find the base exercise name in the regression table
        for ((baseExercise, regressions) in regressionTable) {
            if (exerciseName.lowercase().contains(baseExercise.lowercase()) ||
                baseExercise.lowercase().contains(exerciseName.lowercase())
            ) {
                return regressions
            }
        }

        return emptyList()
    }

    /** Calculate appropriate load multiplier based on injuries */
    fun calculateLoadMultiplier(
        baseLoad: Double,
        injuries: List<Injury>
    ): Double {
        // Find the most severe (lowest multiplier) injury
        val activeInjuries = injuries.filter { it.recoveryPhase != RecoveryPhase.RESOLVED }

        if (activeInjuries.isEmpty()) return 1.0

        val minMultiplier = activeInjuries
            .mapNotNull { simpleLoadMultipliers[it.recoveryPhase] }
            .minOrNull() ?: 1.0

        return baseLoad * minMultiplier
    }

    /** Get recommended exercises for a given injury */
    fun getRecommendedExercises(injury: Injury): List<String> {
        val regions = injury.bodyRegions
        val recommendations = mutableSetOf<String>()

        for (region in regions) {
            when (region.engineKey) {
                "knee" -> recommendations.addAll(
                    listOf("Box Squat", "Glute Bridge", "Hip Thrust", "Calf Raises")
                )
                "shoulder" -> recommendations.addAll(
                    listOf("Lateral Raises", "Front Raises", "Face Pulls", "Band Pull-Aparts")
                )
                "back" -> recommendations.addAll(
                    listOf("Bird Dog", "Cat-Cow", "Plank", "Side Plank")
                )
                "hip" -> recommendations.addAll(
                    listOf("Clamshells", "Fire Hydrants", "Glute Bridges", "Lateral Band Walks")
                )
                "wrist" -> recommendations.addAll(
                    listOf("Knuckle Push-Ups", "Ring Rows", "Farmer's Carries")
                )
                "elbow" -> recommendations.addAll(
                    listOf("Hammer Curls", "Reverse Curls", "Tricep Pushdowns (Light Band)")
                )
                "ankle" -> recommendations.addAll(
                    listOf("Ankle Circles", "Single-Leg Balance", "Calf Raises (Seated)")
                )
            }
        }

        return recommendations.toList()
    }

    /** Get substitution exercises for a body region (convenience for UI) */
    fun getSubstitutionsForRegion(regionName: String): List<String> {
        val region = BodyRegion.ALL.find { it.name == regionName || it.displayName.equals(regionName, ignoreCase = true) }
            ?: return emptyList()
        val injuries = listOf(Injury(
            id = "temp", name = region.displayName,
            bodyRegion = region.name, dateOccurred = "",
            isActive = true, recoveryPhase = RecoveryPhase.LIGHT_LOAD,
            bodyRegions = listOf(region)
        ))
        return getRecommendedExercises(injuries.first())
    }

    /** Get contraindicated keywords for a given injury */
    fun getContraindicatedKeywords(injury: Injury): List<String> {
        val regions = injury.bodyRegions
        val keywords = mutableSetOf<String>()

        for (region in regions) {
            // Check clinical synonyms first
            val engineKey = clinicalSynonyms[injury.name.lowercase()] ?: region.engineKey

            contraindicationRules[engineKey]?.let { rule ->
                keywords.addAll(rule.keywords)
            }
        }

        return keywords.toList()
    }

    // MARK: - Pain Trend Analyzer

    /** Analyze pain trend from logs. windowSize: number of recent readings to consider. */
    fun analyzePainTrend(logs: List<PainLog>, windowSize: Int = 7): TrendResult {
        if (logs.isEmpty()) {
            return TrendResult(
                trailingAverage = 0.0,
                isImproving = false,
                latestPainLevel = null,
                readingCount = 0
            )
        }

        val sorted = logs.sortedByDescending { it.recordedAt }
        val recent = sorted.take(windowSize)
        val average = recent.sumOf { it.painLevel }.toDouble() / recent.size
        val latest = recent.firstOrNull()?.painLevel

        var improving = false
        if (recent.size >= 2) {
            val midpoint = recent.size / 2
            val newerHalf = recent.take(midpoint)
            val olderHalf = recent.drop(midpoint)
            val newerAvg = newerHalf.sumOf { it.painLevel }.toDouble() / newerHalf.size
            val olderAvg = olderHalf.sumOf { it.painLevel }.toDouble() / olderHalf.size
            improving = newerAvg < olderAvg
        }

        return TrendResult(
            trailingAverage = average,
            isImproving = improving,
            latestPainLevel = latest,
            readingCount = logs.size
        )
    }

    /** Check if a pain log has been recorded within the given hours window. */
    fun hasRecentLog(
        logs: List<PainLog>,
        referenceDate: Long = System.currentTimeMillis(),
        withinHours: Double = 24.0
    ): Boolean {
        if (logs.isEmpty()) return false
        val cutoffMs = referenceDate - TimeUnit.HOURS.toMillis(withinHours.toLong())
        return logs.any { it.recordedAt >= cutoffMs }
    }

    /** Returns the last N pain levels in chronological order (oldest first) for sparkline display. */
    fun sparklineData(logs: List<PainLog>, count: Int = 7): List<Int> {
        val sorted = logs.sortedByDescending { it.recordedAt }
        return sorted.take(count).map { it.painLevel }.reversed()
    }

    // MARK: - Phase Transition Advisor

    private data class TransitionRule(
        val from: RecoveryPhase,
        val to: RecoveryPhase,
        val count: Int,
        val maxPain: Int
    )

    private val phaseTransitionRules: List<TransitionRule> = listOf(
        TransitionRule(from = RecoveryPhase.ACUTE, to = RecoveryPhase.REHAB, count = 3, maxPain = 5),
        TransitionRule(from = RecoveryPhase.REHAB, to = RecoveryPhase.LIGHT_LOAD, count = 3, maxPain = 3),
        TransitionRule(from = RecoveryPhase.LIGHT_LOAD, to = RecoveryPhase.RETURN_TO_PLAY, count = 3, maxPain = 2),
        TransitionRule(from = RecoveryPhase.RETURN_TO_PLAY, to = RecoveryPhase.RESOLVED, count = 5, maxPain = 1),
    )

    private fun meetsThreshold(logs: List<PainLog>, count: Int, maxPain: Int): Boolean {
        if (logs.size < count) return false
        return logs.take(count).all { it.painLevel <= maxPain }
    }

    /**
     * Evaluate whether an injury is ready to advance to the next recovery phase.
     * Returns null if no transition is suggested.
     */
    fun evaluateTransition(
        injuryId: String,
        currentPhase: RecoveryPhase,
        painLogs: List<PainLog>
    ): TransitionSuggestion? {
        val sorted = painLogs.sortedByDescending { it.recordedAt }
        val recent = sorted.take(5)

        val rule = phaseTransitionRules.firstOrNull { it.from == currentPhase } ?: return null

        return if (meetsThreshold(logs = recent, count = rule.count, maxPain = rule.maxPain)) {
            TransitionSuggestion(
                injuryId = injuryId,
                currentPhase = currentPhase,
                suggestedPhase = rule.to
            )
        } else {
            null
        }
    }
}
