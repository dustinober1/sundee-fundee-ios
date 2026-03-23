package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "injury_profiles",
    indices = [
        Index(value = ["user_id"]),
        Index(value = ["body_location_raw"])
    ]
)
data class InjuryProfileEntity(
    @PrimaryKey
    val id: String,
    
    @ColumnInfo(name = "user_id")
    val odUserID: String,
    
    @ColumnInfo(name = "body_location_raw")
    val bodyLocationRaw: String,
    
    val severity: Int,
    
    val description: String,
    
    @ColumnInfo(name = "is_resolved")
    val isResolved: Boolean,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Long,
    
    @ColumnInfo(name = "resolved_at")
    val resolvedAt: Long?
) {
    companion object {
        const val TABLE_NAME = "injury_profiles"
    }
}
