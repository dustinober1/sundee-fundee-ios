package com.sundeefundee.core.domain.benchmark

import com.sundeefundee.core.model.CyclePhase
import kotlinx.serialization.Serializable

// MARK: - Benchmark Intensity

/// Intensity level of a benchmark (1-5)
@Serializable
enum class BenchmarkIntensity(val value: Int) {
    ONE(1),
    TWO(2),
    THREE(3),
    FOUR(4),
    FIVE(5);
}

// MARK: - Benchmark Scoring Type

/// How a benchmark is scored
@Serializable
enum class BenchmarkScoringType {
    TIME,
    ROUNDS_AND_REPS,
    LOAD,
    REPS,
    CALORIES,
    DISTANCE;

    val displayName: String
        get() = when (this) {
            TIME -> "Time"
            ROUNDS_AND_REPS -> "Rounds + Reps"
            LOAD -> "Load"
            REPS -> "Reps"
            CALORIES -> "Calories"
            DISTANCE -> "Distance"
        }
}

// MARK: - Readiness Tier

/// Readiness tier for attempting a benchmark
@Serializable
enum class ReadinessTier {
    PEAK,
    MODERATE,
    RECOVERY;

    val displayName: String
        get() = when (this) {
            PEAK -> "Peak"
            MODERATE -> "Moderate"
            RECOVERY -> "Recovery"
        }
}

// MARK: - Benchmark Category

/// Category of benchmark
@Serializable
enum class BenchmarkCategory(val displayName: String) {
    SUNDEE_FUNDEE("Sundee Fundee"),
    CLASSIC_WODS("Classic WODs"),
    STRENGTH("Strength"),
    ENDURANCE("Endurance"),
    GYMNASTICS("Gymnastics"),
    GENERAL_FITNESS("General Fitness");
}

// MARK: - Benchmark Definition

/// A predefined or custom benchmark definition
@Serializable
data class BenchmarkDefinition(
    val id: String,
    val name: String,
    val category: String,
    val workoutDescription: String,
    val scoringType: BenchmarkScoringType,
    val isPredefined: Boolean,
    val sortOrder: Int,
    val intensity: BenchmarkIntensity? = null,
    val movementTags: List<String>? = null,
    val equipment: List<String>? = null,
    val timeDomain: String? = null,
    val coachNotes: String? = null
)

// MARK: - Benchmark Result

/// Result of a benchmark attempt
@Serializable
data class BenchmarkResult(
    val id: String,
    val benchmarkId: String,
    val benchmarkName: String,
    val score: Double,
    val notes: String? = null,
    val date: String, // ISO8601
    val cyclePhase: CyclePhase? = null
)

// MARK: - Benchmark Readiness

/// Readiness assessment for attempting a benchmark
@Serializable
data class BenchmarkReadiness(
    val tier: ReadinessTier,
    val reason: String,
    val recommendation: String,
    val phaseMultiplier: Double,
    val emoji: String,
    val color: String
)

// MARK: - Attempt Window

/// Best attempt window based on cycle
@Serializable
data class AttemptWindow(
    val startDate: String, // ISO8601
    val endDate: String, // ISO8601
    val reason: String
)
