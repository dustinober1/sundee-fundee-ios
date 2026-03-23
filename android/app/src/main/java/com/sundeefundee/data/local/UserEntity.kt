package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "users",
    indices = [
        Index(value = ["google_user_id"], unique = true)
    ]
)
data class UserEntity(
    @PrimaryKey
    val id: String,
    
    val name: String,
    
    @ColumnInfo(name = "experience_level_raw")
    val experienceLevelRaw: String,
    
    @ColumnInfo(name = "primary_goal_raw")
    val primaryGoalRaw: String,
    
    @ColumnInfo(name = "gender_raw")
    val genderRaw: String,
    
    @ColumnInfo(name = "weight_unit_raw")
    val weightUnitRaw: String?,
    
    @ColumnInfo(name = "google_user_id")
    val googleUserID: String,
    
    @ColumnInfo(name = "cycle_tracking_enabled")
    val cycleTrackingEnabled: Boolean,
    
    @ColumnInfo(name = "onboarding_complete")
    val onboardingComplete: Boolean,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Long,
    
    @ColumnInfo(name = "profile_updated_at")
    val profileUpdatedAt: Long?
) {
    companion object {
        const val TABLE_NAME = "users"
    }
}
