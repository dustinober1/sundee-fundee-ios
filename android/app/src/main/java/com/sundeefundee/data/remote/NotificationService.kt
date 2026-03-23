package com.sundeefundee.data.remote

import com.sundeefundee.domain.CyclePhase
import kotlinx.coroutines.flow.Flow

interface NotificationService {
    /**
     * Request notification permission from the user.
     * Returns a Flow that emits the permission status.
     */
    fun requestPermission(): Flow<NotificationPermissionStatus>
    
    /**
     * Check if the app currently has notification permission.
     */
    fun hasPermission(): Boolean
    
    /**
     * Show a basic notification with title and body.
     */
    fun showNotification(title: String, body: String, data: Map<String, String> = emptyMap())
    
    /**
     * Show a notification for a scheduled workout reminder.
     */
    fun showWorkoutReminder(workoutName: String, scheduledTime: Long)
    
    /**
     * Show a notification for cycle phase tracking.
     */
    fun showCyclePhaseReminder(phase: CyclePhase)
    
    /**
     * Cancel a specific notification by ID.
     */
    fun cancelNotification(notificationId: Int)
    
    /**
     * Cancel all notifications.
     */
    fun cancelAllNotifications()
}

enum class NotificationPermissionStatus {
    GRANTED,
    DENIED,
    PROVISIONAL,
    UNKNOWN
}

/**
 * Notification channel IDs for Android 8+
 */
object NotificationChannels {
    const val WORKOUTS = "workout_reminders"
    const val CYCLE = "cycle_tracking"
    const val GENERAL = "general"
    const val ACHIEVEMENTS = "achievements"
}

/**
 * Notification IDs for unique identification
 */
object NotificationIds {
    const val WORKOUT_BASE = 1000
    const val CYCLE_BASE = 2000
    const val ACHIEVEMENT_BASE = 3000
    const val GENERAL_BASE = 4000
    
    fun workoutId(workoutIndex: Int) = WORKOUT_BASE + workoutIndex
    fun cycleId(phaseIndex: Int) = CYCLE_BASE + phaseIndex
    fun achievementId(achievementIndex: Int) = ACHIEVEMENT_BASE + achievementIndex
}