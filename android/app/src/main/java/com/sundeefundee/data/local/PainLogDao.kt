package com.sundeefundee.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface PainLogDao {
    @Query("SELECT * FROM pain_logs WHERE userId = :userId ORDER BY loggedAt DESC")
    fun getPainLogsForUser(userId: String): Flow<List<PainLogEntity>>

    @Query("SELECT * FROM pain_logs WHERE userId = :userId AND loggedAt >= :startDate AND loggedAt <= :endDate ORDER BY loggedAt DESC")
    fun getPainLogsForDateRange(userId: String, startDate: Long, endDate: Long): Flow<List<PainLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(painLog: PainLogEntity)

    @Delete
    suspend fun delete(painLog: PainLogEntity)
}
