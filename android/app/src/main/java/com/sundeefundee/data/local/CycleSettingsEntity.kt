package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "cycle_settings",
    indices = [
        Index(value = ["user_id"], unique = true)
    ]
)
data class CycleSettingsEntity(
    @PrimaryKey
    val id: String,
    
    @ColumnInfo(name = "user_id")
    val odUserID: String,
    
    @ColumnInfo(name = "average_cycle_length")
    val averageCycleLength: Int,
    
    @ColumnInfo(name = "average_period_length")
    val averagePeriodLength: Int,
    
    @ColumnInfo(name = "last_period_start_date")
    val lastPeriodStartDate: Long?
) {
    companion object {
        const val TABLE_NAME = "cycle_settings"
    }
}
