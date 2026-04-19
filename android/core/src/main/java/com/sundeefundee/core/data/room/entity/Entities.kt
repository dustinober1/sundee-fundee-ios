package com.sundeefundee.core.data.room.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.sundeefundee.core.model.*

// Room entities — one table per record type, mirrors iOS CloudKit record types

@Entity(tableName = "workouts")
data class WorkoutEntity(
    @PrimaryKey val id: String,
    val date: String,
    val name: String,
    val exercisesJson: String, // serialized List<Exercise>
    val notes: String?,
    val duration: Int,
    val completedAt: String?
)

@Entity(tableName = "one_rep_max_records")
data class OneRepMaxEntity(
    @PrimaryKey val id: String,
    val exerciseName: String,
    val weight: Double,
    val unit: String,
    val date: String
)

@Entity(tableName = "challenges")
data class ChallengeEntity(
    @PrimaryKey val id: String,
    val type: String,
    val title: String,
    val exerciseName: String?,
    val tiersJson: String, // serialized List<ChallengeTier>
    val currentTierIndex: Int,
    val accumulatedVolumeLbs: Double,
    val status: String,
    val challengeStartDate: String,
    val challengeEndDate: String?,
    val dateCreated: String
)

@Entity(tableName = "injuries")
data class InjuryEntity(
    @PrimaryKey val id: String,
    val locationIds: String, // comma-separated
    val name: String,
    val recoveryPhase: String,
    val dateCreated: String,
    val phaseUpdated: String,
    val notes: String?
)

@Entity(tableName = "daily_pain_logs")
data class PainLogEntity(
    @PrimaryKey val id: String,
    val locationIds: String, // comma-separated
    val intensity: Int,
    val painType: String,
    val date: String,
    val notes: String?
)

@Entity(tableName = "enrolled_programs")
data class EnrolledProgramEntity(
    @PrimaryKey val id: String,
    val name: String,
    val isActive: Boolean
)

@Entity(tableName = "program_session_records")
data class ProgramSessionEntity(
    @PrimaryKey val id: String,
    val programId: String,
    val sessionId: String,
    val workoutId: String,
    val week: Int
)

@Entity(tableName = "benchmark_results")
data class BenchmarkResultEntity(
    @PrimaryKey val id: String,
    val benchmarkId: String,
    val benchmarkName: String,
    val score: Double,
    val notes: String?,
    val date: String,
    val cyclePhase: String?
)

@Entity(tableName = "cycle_settings")
data class CycleSettingsEntity(
    @PrimaryKey val id: String,
    val averageCycleLengthDays: Int,
    val averagePeriodLengthDays: Int,
    val lutealPhaseLengthDays: Int
)

@Entity(tableName = "period_log_records")
data class PeriodLogEntity(
    @PrimaryKey val id: String,
    val startDate: String,
    val endDate: String?
)

@Entity(tableName = "user_settings")
data class UserSettingsEntity(
    @PrimaryKey val id: String,
    val weightUnit: String,
    val experienceLevel: String,
    val primaryGoal: String,
    val cycleTrackingEnabled: Boolean
)

@Entity(tableName = "recovery_score_records")
data class RecoveryScoreEntity(
    @PrimaryKey val id: String,
    val scoreDate: String,
    val totalScore: Int,
    val hrvSubScore: Int?,
    val sleepSubScore: Int?,
    val loadSubScore: Int?,
    val cyclePhaseSubScore: Int?,
    val painSubScore: Int?,
    val presentInputCount: Int,
    val cyclePhaseRaw: String?,
    val recommendationRaw: String,
    val dateCreated: String
)

@Entity(tableName = "celebration_events")
data class CelebrationEntity(
    @PrimaryKey val id: String,
    val description: String,
    val date: String
)

@Entity(tableName = "completed_workout_records")
data class CompletedWorkoutEntity(
    @PrimaryKey val id: String,
    val name: String,
    val date: String,
    val duration: Int?,
    val exerciseNamesJson: String, // serialized List<String>
    val isComplete: Boolean
)

@Entity(tableName = "cycle_phase_info")
data class CyclePhaseInfoEntity(
    @PrimaryKey val id: String,
    val phase: String,
    val confidence: Double,
    val startDate: String,
    val endDate: String
)

// Sync queue persistence
@Entity(tableName = "sync_queue")
data class PendingMutationEntity(
    @PrimaryKey(autoGenerate = true) val rowId: Long = 0,
    val recordType: String,
    val operation: String, // "save" or "delete"
    val encodedData: String,
    val recordIdsJson: String?, // for delete operations
    val attempts: Int,
    val enqueuedAt: String
)

// Coach memory
@Entity(tableName = "coach_profiles")
data class CoachProfileEntity(
    @PrimaryKey val id: String = "coach_profile",
    val preferredSessionMinutes: Int?,
    val preferredFocusAreasJson: String?,
    val preferredEquipmentJson: String?,
    val favoriteExercisesJson: String?,
    val avoidedExercisesJson: String?,
    val avgWorkoutsPerWeek: Double?,
    val energyDistributionJson: String?,
    val totalWorkoutsObserved: Int?,
    val lastUpdated: String?
)
