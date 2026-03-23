package com.sundeefundee.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [
        UserEntity::class,
        PeriodLogEntity::class,
        CycleSettingsEntity::class,
        CompletedWorkoutEntity::class,
        MaxEntity::class,
        BenchmarkEntity::class,
        BenchmarkDefinitionEntity::class,
        ProgramEntity::class,
        EnrolledProgramEntity::class,
        InjuryProfileEntity::class,
        PainLogEntity::class,
        ActiveCycleEntity::class,
        GeneratedWorkoutRecordEntity::class
    ],
    version = 1,
    exportSchema = true
)
abstract class SundeeFundeeDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun periodLogDao(): PeriodLogDao
    abstract fun cycleSettingsDao(): CycleSettingsDao
    abstract fun completedWorkoutDao(): CompletedWorkoutDao
    abstract fun maxDao(): MaxDao
    abstract fun benchmarkDao(): BenchmarkDao
    abstract fun benchmarkDefinitionDao(): BenchmarkDefinitionDao
    abstract fun programDao(): ProgramDao
    abstract fun enrolledProgramDao(): EnrolledProgramDao
    abstract fun injuryProfileDao(): InjuryProfileDao
    abstract fun painLogDao(): PainLogDao
    abstract fun activeCycleDao(): ActiveCycleDao
    abstract fun generatedWorkoutRecordDao(): GeneratedWorkoutRecordDao
}
