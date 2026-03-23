package com.sundeefundee.di

import android.content.Context
import androidx.room.Room
import com.sundeefundee.data.local.ActiveCycleDao
import com.sundeefundee.data.local.BenchmarkDao
import com.sundeefundee.data.local.BenchmarkDefinitionDao
import com.sundeefundee.data.local.CompletedWorkoutDao
import com.sundeefundee.data.local.CycleSettingsDao
import com.sundeefundee.data.local.EnrolledProgramDao
import com.sundeefundee.data.local.GeneratedWorkoutRecordDao
import com.sundeefundee.data.local.InjuryProfileDao
import com.sundeefundee.data.local.MaxDao
import com.sundeefundee.data.local.PainLogDao
import com.sundeefundee.data.local.PeriodLogDao
import com.sundeefundee.data.local.ProgramDao
import com.sundeefundee.data.local.SundeeFundeeDatabase
import com.sundeefundee.data.local.UserDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(
        @ApplicationContext context: Context
    ): SundeeFundeeDatabase {
        return Room.databaseBuilder(
            context,
            SundeeFundeeDatabase::class.java,
            "sundee_fundee.db"
        )
            .fallbackToDestructiveMigration()
            .build()
    }

    @Provides
    fun provideUserDao(database: SundeeFundeeDatabase): UserDao = database.userDao()

    @Provides
    fun providePeriodLogDao(database: SundeeFundeeDatabase): PeriodLogDao = database.periodLogDao()

    @Provides
    fun provideCycleSettingsDao(database: SundeeFundeeDatabase): CycleSettingsDao = database.cycleSettingsDao()

    @Provides
    fun provideCompletedWorkoutDao(database: SundeeFundeeDatabase): CompletedWorkoutDao = database.completedWorkoutDao()

    @Provides
    fun provideMaxDao(database: SundeeFundeeDatabase): MaxDao = database.maxDao()

    @Provides
    fun provideBenchmarkDao(database: SundeeFundeeDatabase): BenchmarkDao = database.benchmarkDao()

    @Provides
    fun provideBenchmarkDefinitionDao(database: SundeeFundeeDatabase): BenchmarkDefinitionDao = database.benchmarkDefinitionDao()

    @Provides
    fun provideProgramDao(database: SundeeFundeeDatabase): ProgramDao = database.programDao()

    @Provides
    fun provideEnrolledProgramDao(database: SundeeFundeeDatabase): EnrolledProgramDao = database.enrolledProgramDao()

    @Provides
    fun provideInjuryProfileDao(database: SundeeFundeeDatabase): InjuryProfileDao = database.injuryProfileDao()

    @Provides
    fun providePainLogDao(database: SundeeFundeeDatabase): PainLogDao = database.painLogDao()

    @Provides
    fun provideActiveCycleDao(database: SundeeFundeeDatabase): ActiveCycleDao = database.activeCycleDao()

    @Provides
    fun provideGeneratedWorkoutRecordDao(database: SundeeFundeeDatabase): GeneratedWorkoutRecordDao = database.generatedWorkoutRecordDao()
}
