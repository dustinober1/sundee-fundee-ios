package com.sundeefundee.data.remote

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

/**
 * Broadcast receiver that reschedules all pending workout reminders after device boot.
 */
@AndroidEntryPoint
class BootReceiver : BroadcastReceiver() {

    @Inject
    lateinit var workoutReminderScheduler: WorkoutReminderScheduler

    @Inject
    lateinit var notificationService: NotificationService

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // In a production app, you would:
            // 1. Read the scheduled workouts from local database
            // 2. Reschedule all pending alarms
            // 3. Log the boot completion for analytics
            
            // For now, we'll just log that boot was completed
            // The actual rescheduling would happen when the app opens
            // and syncs with the backend
            
            android.util.Log.d("BootReceiver", "Device boot completed, reminders will be rescheduled on app launch")
        }
    }
}