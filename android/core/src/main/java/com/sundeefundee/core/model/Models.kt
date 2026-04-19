package com.sundeefundee.core.model

import kotlinx.serialization.Serializable

// Shared data models — mirrors iOS Models/ and UI/Models/SharedModels.swift

// MARK: - Weight Unit

@Serializable
enum class WeightUnit(val displayName: String) {
    LBS("lbs"),
    KG("kg")
}

// MARK: - Exercise Category

@Serializable
enum class ExerciseCategory(val displayName: String) {
    COMPOUND("Compound"),
    ISOLATION("Isolation"),
    ACCESSORY("Accessory"),
    WARMUP("Warm-up"),
    COOLDOWN("Cool-down")
}

// MARK: - Exercise Set

@Serializable
data class ExerciseSet(
    val id: String,
    val reps: Int,
    val prescribedWeight: Double,
    val prescribedPercentage: Double? = null,
    val type: String = "fixed", // fixed, amrap, range, text
    val rangeMin: Int? = null,
    val rangeMax: Int? = null,
    val textValue: String? = null,
    val completedWeight: Double? = null,
    val actualReps: Int? = null,
    val isComplete: Boolean = false
)

// MARK: - Exercise

@Serializable
data class Exercise(
    val id: String,
    val name: String,
    val category: ExerciseCategory,
    val bodyweight: Double,
    val targetSets: List<ExerciseSet>,
    val notes: String? = null,
    val restMinutes: Double = 2.5
)

// MARK: - Workout

@Serializable
data class Workout(
    val id: String,
    val date: String, // ISO8601
    val name: String,
    val exercises: List<Exercise> = emptyList(),
    val notes: String? = null,
    val duration: Int = 0, // minutes
    val completedAt: String? = null // ISO8601
) {
    val isComplete: Boolean get() = completedAt != null

    val totalVolume: Double
        get() = exercises.flatMap { exercise ->
            exercise.targetSets.map { set ->
                val reps = set.actualReps ?: set.reps
                val weight = if ((set.completedWeight ?: 0.0) > 0) {
                    set.completedWeight!!
                } else if (set.prescribedWeight > 0) {
                    set.prescribedWeight
                } else {
                    0.0
                }
                reps.toDouble() * weight
            }
        }.sum()
}

// MARK: - One Rep Max Record

@Serializable
data class OneRepMaxRecord(
    val id: String,
    val exerciseName: String,
    val weight: Double,
    val unit: WeightUnit,
    val date: String // ISO8601
)

// MARK: - Enrolled Program Record

@Serializable
data class EnrolledProgramRecord(
    val id: String,
    val name: String,
    val isActive: Boolean
)

// MARK: - Program Session Record

@Serializable
data class ProgramSessionRecord(
    val id: String,
    val programId: String,
    val sessionId: String,
    val workoutId: String,
    val week: Int
)

// MARK: - Completed Workout Record

@Serializable
data class CompletedWorkoutRecord(
    val id: String,
    val name: String,
    val date: String, // ISO8601
    val duration: Int? = null,
    val exerciseNames: List<String> = emptyList(),
    val isComplete: Boolean = true
)

// MARK: - Celebration Event Record

@Serializable
data class CelebrationEventRecord(
    val id: String,
    val description: String,
    val date: String // ISO8601
)

// MARK: - Recovery Score Record

@Serializable
data class RecoveryScoreRecord(
    val id: String,
    val scoreDate: String, // ISO8601
    val totalScore: Int,
    val hrvSubScore: Int? = null,
    val sleepSubScore: Int? = null,
    val loadSubScore: Int? = null,
    val cyclePhaseSubScore: Int? = null,
    val painSubScore: Int? = null,
    val presentInputCount: Int,
    val cyclePhaseRaw: String? = null,
    val recommendationRaw: String,
    val dateCreated: String // ISO8601
)

// MARK: - User Settings

@Serializable
data class UserSettings(
    val id: String = "user_settings",
    val weightUnit: WeightUnit = WeightUnit.LBS,
    val experienceLevel: String = "intermediate",
    val primaryGoal: String = "strength",
    val cycleTrackingEnabled: Boolean = false
)

// MARK: - Cycle Phase Info

@Serializable
data class CyclePhaseInfo(
    val phase: CyclePhase,
    val confidence: Double,
    val startDate: String, // ISO8601
    val endDate: String // ISO8601
)

// MARK: - Cycle Phase

@Serializable
enum class CyclePhase {
    MENSTRUAL,
    FOLLICULAR,
    OVULATION,
    LUTEAL;

    val displayName: String
        get() = when (this) {
            MENSTRUAL -> "Menstrual"
            FOLLICULAR -> "Follicular"
            OVULATION -> "Ovulation"
            LUTEAL -> "Luteal"
        }
}

// MARK: - Cycle Settings

@Serializable
data class CycleSettings(
    val id: String = "cycle_settings",
    val averageCycleLengthDays: Int = 28,
    val averagePeriodLengthDays: Int = 5,
    val lutealPhaseLengthDays: Int = 14
)

// MARK: - Period Log

@Serializable
data class PeriodLogRecord(
    val id: String,
    val startDate: String, // ISO8601
    val endDate: String? = null // ISO8601, null = still active
)

// MARK: - Challenge Types

@Serializable
enum class ChallengeType {
    LIFETIME_VOLUME,
    EXERCISE_VOLUME,
    CUSTOM
}

@Serializable
enum class ChallengeStatus {
    ACTIVE,
    COMPLETED,
    EXPIRED
}

@Serializable
data class ChallengeTier(
    val name: String,
    val targetVolumeLbs: Double,
    val ordinal: Int
)

@Serializable
data class Challenge(
    val id: String,
    val type: ChallengeType,
    val title: String,
    val exerciseName: String? = null,
    val tiers: List<ChallengeTier>,
    val currentTierIndex: Int = 0,
    val accumulatedVolumeLbs: Double = 0.0,
    val status: ChallengeStatus = ChallengeStatus.ACTIVE,
    val challengeStartDate: String, // ISO8601
    val challengeEndDate: String? = null, // ISO8601
    val dateCreated: String // ISO8601
)

data class ChallengeProgress(
    val currentTierName: String,
    val percentComplete: Double,
    val volumeRemaining: Double,
    val justCompletedTier: ChallengeTier? = null,
    val isFullyComplete: Boolean = false
)

// MARK: - Injury Models

@Serializable
data class Injury(
    val id: String,
    val locationIds: String, // comma-separated region IDs
    val name: String,
    val recoveryPhase: String,
    val dateCreated: String, // ISO8601
    val phaseUpdated: String, // ISO8601
    val notes: String? = null
)

// MARK: - Pain Log Models

@Serializable
data class DailyPainLog(
    val id: String,
    val locationIds: String, // comma-separated region IDs
    val intensity: Int, // 1-10
    val painType: String,
    val date: String, // ISO8601
    val notes: String? = null
)

// MARK: - Benchmark Result

@Serializable
data class BenchmarkResult(
    val id: String,
    val benchmarkId: String,
    val benchmarkName: String,
    val score: Double,
    val notes: String? = null,
    val date: String, // ISO8601
    val cyclePhase: String? = null
)
