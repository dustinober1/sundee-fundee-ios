package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "maxes",
    indices = [
        Index(value = ["user_id"]),
        Index(value = ["lift_name"])
    ]
)
data class MaxEntity(
    @PrimaryKey
    val id: String,
    
    @ColumnInfo(name = "user_id")
    val odUserID: String,
    
    @ColumnInfo(name = "lift_name")
    val liftName: String,
    
    val weight: Double,
    
    @ColumnInfo(name = "unit_raw")
    val unitRaw: String,
    
    @ColumnInfo(name = "achieved_date")
    val achievedDate: Long,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Long
) {
    companion object {
        const val TABLE_NAME = "maxes"
    }
}
