package com.sundeefundee.data.remote

import com.sundeefundee.domain.model.ExerciseEntry
import com.sundeefundee.domain.model.HeartRateEntry

interface HealthConnectService {
    
    enum class HealthConnectAvailability {
        INSTALLED,        // Health Connect app is installed
        NOT_INSTALLED,    // Needs to be installed from Play Store
        NOT_SUPPORTED     // Device doesn't support Health Connect
    }
    
    /**
     * Check if Health Connect is available on this device
     */
    suspend fun checkAvailability(): HealthConnectAvailability
    
    /**
     * Request permissions from the user for Health Connect
     * @return Result containing true if permissions were granted
     */
    suspend fun requestPermissions(): Result<Boolean>
    
    /**
     * Check if all required permissions have been granted
     */
    suspend fun hasAllPermissions(): Boolean
    
    /**
     * Get the set of required permissions for Health Connect
     */
    fun getRequiredPermissions(): Set<String>
    
    // Read data
    
    /**
     * Read exercise entries within a time range
     * @param startTime Start time in epoch millis
     * @param endTime End time in epoch millis
     * @return Result containing list of exercise entries
     */
    suspend fun readExercises(startTime: Long, endTime: Long): Result<List<ExerciseEntry>>
    
    /**
     * Read heart rate entries within a time range
     * @param startTime Start time in epoch millis
     * @param endTime End time in epoch millis
     * @return Result containing list of heart rate entries
     */
    suspend fun readHeartRate(startTime: Long, endTime: Long): Result<List<HeartRateEntry>>
    
    // Write data
    
    /**
     * Write an exercise session to Health Connect
     * @param exercise The exercise to write
     * @return Result containing true if successful
     */
    suspend fun writeExercise(exercise: Exercise): Result<Boolean>
}

/**
 * Represents an exercise session to be written to Health Connect
 */
data class Exercise(
    val startTime: Long,
    val endTime: Long,
    val exerciseType: ExerciseType,
    val title: String? = null,
    val caloriesBurned: Double? = null
)

/**
 * Supported exercise types for Health Connect
 */
enum class ExerciseType(val healthConnectType: Int) {
    RUNNING(1),
    WALKING(7),
    STRENGTH_TRAINING(20),
    FLEXIBILITY(22),
    CROSS_TRAINING(23),
    CIRCUIT_TRAINING(24),
    FUNCTIONAL_TRAINING(25),
    SPORTS(48),
    OTHER(0);
    
    companion object {
        fun fromHealthConnectType(type: Int): ExerciseType {
            return entries.find { it.healthConnectType == type } ?: OTHER
        }
    }
}
