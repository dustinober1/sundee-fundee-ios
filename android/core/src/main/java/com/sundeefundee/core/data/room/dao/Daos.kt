package com.sundeefundee.core.data.room.dao

import androidx.room.*
import com.sundeefundee.core.data.room.entity.*

// Generic DAO pattern — each entity gets insert/update/delete/query

@Dao
interface WorkoutDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: WorkoutEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entities: List<WorkoutEntity>)

    @Query("SELECT * FROM workouts ORDER BY date DESC")
    suspend fun getAll(): List<WorkoutEntity>

    @Query("SELECT * FROM workouts WHERE id = :id")
    suspend fun getById(id: String): WorkoutEntity?

    @Query("DELETE FROM workouts WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM workouts")
    suspend fun deleteAll()
}

@Dao
interface OneRepMaxDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: OneRepMaxEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entities: List<OneRepMaxEntity>)

    @Query("SELECT * FROM one_rep_max_records ORDER BY date DESC")
    suspend fun getAll(): List<OneRepMaxEntity>

    @Query("SELECT * FROM one_rep_max_records WHERE id = :id")
    suspend fun getById(id: String): OneRepMaxEntity?

    @Query("DELETE FROM one_rep_max_records WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM one_rep_max_records")
    suspend fun deleteAll()
}

@Dao
interface ChallengeDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: ChallengeEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entities: List<ChallengeEntity>)

    @Query("SELECT * FROM challenges ORDER BY dateCreated DESC")
    suspend fun getAll(): List<ChallengeEntity>

    @Query("SELECT * FROM challenges WHERE id = :id")
    suspend fun getById(id: String): ChallengeEntity?

    @Query("DELETE FROM challenges WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM challenges")
    suspend fun deleteAll()
}

@Dao
interface InjuryDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: InjuryEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entities: List<InjuryEntity>)

    @Query("SELECT * FROM injuries ORDER BY dateCreated DESC")
    suspend fun getAll(): List<InjuryEntity>

    @Query("SELECT * FROM injuries WHERE id = :id")
    suspend fun getById(id: String): InjuryEntity?

    @Query("DELETE FROM injuries WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM injuries")
    suspend fun deleteAll()
}

@Dao
interface PainLogDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: PainLogEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entities: List<PainLogEntity>)

    @Query("SELECT * FROM daily_pain_logs ORDER BY date DESC")
    suspend fun getAll(): List<PainLogEntity>

    @Query("SELECT * FROM daily_pain_logs WHERE id = :id")
    suspend fun getById(id: String): PainLogEntity?

    @Query("DELETE FROM daily_pain_logs WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM daily_pain_logs")
    suspend fun deleteAll()
}

@Dao
interface EnrolledProgramDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: EnrolledProgramEntity)

    @Query("SELECT * FROM enrolled_programs")
    suspend fun getAll(): List<EnrolledProgramEntity>

    @Query("DELETE FROM enrolled_programs WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM enrolled_programs")
    suspend fun deleteAll()
}

@Dao
interface ProgramSessionDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: ProgramSessionEntity)

    @Query("SELECT * FROM program_session_records WHERE programId = :programId")
    suspend fun getByProgram(programId: String): List<ProgramSessionEntity>

    @Query("DELETE FROM program_session_records")
    suspend fun deleteAll()
}

@Dao
interface BenchmarkResultDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: BenchmarkResultEntity)

    @Query("SELECT * FROM benchmark_results ORDER BY date DESC")
    suspend fun getAll(): List<BenchmarkResultEntity>

    @Query("DELETE FROM benchmark_results WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM benchmark_results")
    suspend fun deleteAll()
}

@Dao
interface CycleSettingsDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: CycleSettingsEntity)

    @Query("SELECT * FROM cycle_settings LIMIT 1")
    suspend fun get(): CycleSettingsEntity?

    @Query("DELETE FROM cycle_settings")
    suspend fun deleteAll()
}

@Dao
interface PeriodLogDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: PeriodLogEntity)

    @Query("SELECT * FROM period_log_records ORDER BY startDate DESC")
    suspend fun getAll(): List<PeriodLogEntity>

    @Query("DELETE FROM period_log_records WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM period_log_records")
    suspend fun deleteAll()
}

@Dao
interface UserSettingsDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: UserSettingsEntity)

    @Query("SELECT * FROM user_settings LIMIT 1")
    suspend fun get(): UserSettingsEntity?

    @Query("DELETE FROM user_settings")
    suspend fun deleteAll()
}

@Dao
interface RecoveryScoreDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: RecoveryScoreEntity)

    @Query("SELECT * FROM recovery_score_records ORDER BY scoreDate DESC")
    suspend fun getAll(): List<RecoveryScoreEntity>

    @Query("DELETE FROM recovery_score_records")
    suspend fun deleteAll()
}

@Dao
interface CelebrationDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: CelebrationEntity)

    @Query("SELECT * FROM celebration_events ORDER BY date DESC")
    suspend fun getAll(): List<CelebrationEntity>

    @Query("DELETE FROM celebration_events")
    suspend fun deleteAll()
}

@Dao
interface CompletedWorkoutDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: CompletedWorkoutEntity)

    @Query("SELECT * FROM completed_workout_records ORDER BY date DESC")
    suspend fun getAll(): List<CompletedWorkoutEntity>

    @Query("DELETE FROM completed_workout_records")
    suspend fun deleteAll()
}

@Dao
interface CyclePhaseInfoDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: CyclePhaseInfoEntity)

    @Query("SELECT * FROM cycle_phase_info ORDER BY startDate DESC")
    suspend fun getAll(): List<CyclePhaseInfoEntity>

    @Query("DELETE FROM cycle_phase_info")
    suspend fun deleteAll()
}

@Dao
interface SyncQueueDao {
    @Insert
    suspend fun insert(entity: PendingMutationEntity): Long

    @Query("SELECT * FROM sync_queue ORDER BY enqueuedAt ASC")
    suspend fun getAll(): List<PendingMutationEntity>

    @Query("DELETE FROM sync_queue WHERE rowId = :rowId")
    suspend fun deleteById(rowId: Long)

    @Query("UPDATE sync_queue SET attempts = :attempts WHERE rowId = :rowId")
    suspend fun updateAttempts(rowId: Long, attempts: Int)

    @Query("DELETE FROM sync_queue")
    suspend fun deleteAll()
}

@Dao
interface CoachProfileDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: CoachProfileEntity)

    @Query("SELECT * FROM coach_profiles LIMIT 1")
    suspend fun get(): CoachProfileEntity?

    @Query("DELETE FROM coach_profiles")
    suspend fun deleteAll()
}
