package com.sundeefundee.core.data.room

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.sundeefundee.core.data.room.converters.Converters
import com.sundeefundee.core.data.room.dao.*
import com.sundeefundee.core.data.room.entity.*

@Database(
    entities = [
        WorkoutEntity::class,
        OneRepMaxEntity::class,
        ChallengeEntity::class,
        InjuryEntity::class,
        PainLogEntity::class,
        EnrolledProgramEntity::class,
        ProgramSessionEntity::class,
        BenchmarkResultEntity::class,
        CycleSettingsEntity::class,
        PeriodLogEntity::class,
        UserSettingsEntity::class,
        RecoveryScoreEntity::class,
        CelebrationEntity::class,
        CompletedWorkoutEntity::class,
        CyclePhaseInfoEntity::class,
        PendingMutationEntity::class,
        CoachProfileEntity::class,
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class SundeeFundeeDatabase : RoomDatabase() {
    abstract fun workoutDao(): WorkoutDao
    abstract fun oneRepMaxDao(): OneRepMaxDao
    abstract fun challengeDao(): ChallengeDao
    abstract fun injuryDao(): InjuryDao
    abstract fun painLogDao(): PainLogDao
    abstract fun enrolledProgramDao(): EnrolledProgramDao
    abstract fun programSessionDao(): ProgramSessionDao
    abstract fun benchmarkResultDao(): BenchmarkResultDao
    abstract fun cycleSettingsDao(): CycleSettingsDao
    abstract fun periodLogDao(): PeriodLogDao
    abstract fun userSettingsDao(): UserSettingsDao
    abstract fun recoveryScoreDao(): RecoveryScoreDao
    abstract fun celebrationDao(): CelebrationDao
    abstract fun completedWorkoutDao(): CompletedWorkoutDao
    abstract fun cyclePhaseInfoDao(): CyclePhaseInfoDao
    abstract fun syncQueueDao(): SyncQueueDao
    abstract fun coachProfileDao(): CoachProfileDao
}
