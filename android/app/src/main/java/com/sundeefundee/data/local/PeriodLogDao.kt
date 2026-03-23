package com.sundeefundee.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface PeriodLogDao {
    @Query("SELECT * FROM period_logs WHERE userId = :userId ORDER BY startDate DESC")
    fun getPeriodLogsForUser(userId: String): Flow<List<PeriodLogEntity>>

    @Query("SELECT * FROM period_logs WHERE id = :id")
    fun getPeriodLogById(id: String): Flow<PeriodLogEntity?>

    @Query("SELECT * FROM period_logs WHERE userId = :userId ORDER BY startDate DESC LIMIT :limit")
    fun getRecentPeriodLogs(userId: String, limit: Int): Flow<List<PeriodLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(periodLog: PeriodLogEntity)

    @Update
    suspend fun update(periodLog: PeriodLogEntity)

    @Delete
    suspend fun delete(periodLog: PeriodLogEntity)
}
