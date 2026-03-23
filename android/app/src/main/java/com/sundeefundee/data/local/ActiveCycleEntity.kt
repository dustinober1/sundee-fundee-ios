package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "active_cycles",
    indices = [
        Index(value = ["user_id"], unique = true)
    ]
)
data class ActiveCycleEntity(
    @PrimaryKey
    val id: String,
    
    @ColumnInfo(name = "user_id")
    val odUserID: String,
    
    @ColumnInfo(name = "start_date")
    val startDate: Long,
    
    @ColumnInfo(name = "current_phase_raw")
    val currentPhaseRaw: String,
    
    @ColumnInfo(name = "predicted_end_date")
    val predictedEndDate: Long?
) {
    companion object {
        const val TABLE_NAME = "active_cycles"
    }
}
