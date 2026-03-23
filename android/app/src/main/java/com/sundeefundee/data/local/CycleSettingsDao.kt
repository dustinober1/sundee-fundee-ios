package com.sundeefundee.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface CycleSettingsDao {
    @Query("SELECT * FROM cycle_settings WHERE userId = :userId")
    fun getCycleSettingsForUser(userId: String): Flow<CycleSettingsEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(settings: CycleSettingsEntity)

    @Update
    suspend fun update(settings: CycleSettingsEntity)
}
