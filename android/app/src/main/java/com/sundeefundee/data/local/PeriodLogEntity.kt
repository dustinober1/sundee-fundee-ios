package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "period_logs",
    indices = [
        Index(value = ["user_id"]),
        Index(value = ["start_date"])
    ]
)
data class PeriodLogEntity(
    @PrimaryKey
    val id: String,
    
    @ColumnInfo(name = "user_id")
    val odUserID: String,
    
    @ColumnInfo(name = "start_date")
    val startDate: Long,
    
    @ColumnInfo(name = "end_date")
    val endDate: Long?,
    
    @ColumnInfo(name = "flow_intensity_raw")
    val flowIntensityRaw: String?
) {
    companion object {
        const val TABLE_NAME = "period_logs"
    }
}
