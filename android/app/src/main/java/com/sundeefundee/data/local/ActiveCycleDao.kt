package com.sundeefundee.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface ActiveCycleDao {
    @Query("SELECT * FROM active_cycles WHERE userId = :userId LIMIT 1")
    fun getActiveCycleForUser(userId: String): Flow<ActiveCycleEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(cycle: ActiveCycleEntity)

    @Update
    suspend fun update(cycle: ActiveCycleEntity)

    @Delete
    suspend fun delete(cycle: ActiveCycleEntity)
}
