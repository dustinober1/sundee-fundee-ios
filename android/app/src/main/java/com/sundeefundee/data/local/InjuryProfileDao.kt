package com.sundeefundee.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface InjuryProfileDao {
    @Query("SELECT * FROM injury_profiles WHERE userId = :userId ORDER BY recordedAt DESC")
    fun getInjuriesForUser(userId: String): Flow<List<InjuryProfileEntity>>

    @Query("SELECT * FROM injury_profiles WHERE userId = :userId AND isResolved = 0 ORDER BY recordedAt DESC")
    fun getActiveInjuries(userId: String): Flow<List<InjuryProfileEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(injury: InjuryProfileEntity)

    @Update
    suspend fun update(injury: InjuryProfileEntity)

    @Delete
    suspend fun delete(injury: InjuryProfileEntity)
}
