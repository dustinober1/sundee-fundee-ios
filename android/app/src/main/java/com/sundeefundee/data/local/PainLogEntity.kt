package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "pain_logs",
    indices = [
        Index(value = ["user_id"]),
        Index(value = ["body_location_raw"]),
        Index(value = ["logged_at"])
    ]
)
data class PainLogEntity(
    @PrimaryKey
    val id: String,
    
    @ColumnInfo(name = "user_id")
    val odUserID: String,
    
    @ColumnInfo(name = "body_location_raw")
    val bodyLocationRaw: String,
    
    @ColumnInfo(name = "pain_level")
    val painLevel: Int,
    
    @ColumnInfo(name = "logged_at")
    val loggedAt: Long,
    
    val notes: String?
) {
    companion object {
        const val TABLE_NAME = "pain_logs"
    }
}
