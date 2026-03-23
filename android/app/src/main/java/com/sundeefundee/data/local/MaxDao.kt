package com.sundeefundee.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface MaxDao {
    @Query("SELECT * FROM maxes WHERE userId = :userId ORDER BY recordedAt DESC")
    fun getMaxesForUser(userId: String): Flow<List<MaxEntity>>

    @Query("SELECT * FROM maxes WHERE id = :id")
    fun getMaxById(id: String): Flow<MaxEntity?>

    @Query("SELECT * FROM maxes WHERE userId = :userId AND liftName = :liftName ORDER BY recordedAt DESC LIMIT 1")
    fun getMaxByLiftName(userId: String, liftName: String): Flow<MaxEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(max: MaxEntity)

    @Update
    suspend fun update(max: MaxEntity)

    @Delete
    suspend fun delete(max: MaxEntity)
}
