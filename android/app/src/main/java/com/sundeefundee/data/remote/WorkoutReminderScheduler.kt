package com.sundeefundee.data.remote

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WorkoutReminderScheduler @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun scheduleWorkoutReminder(
        workoutId: String,
        workoutName: String,
        scheduledTime: Long
    ) {
        val intent = Intent(context, WorkoutReminderReceiver::class.java).apply {
            action = ACTION_WORKOUT_REMINDER
            putExtra(EXTRA_WORKOUT_ID, workoutId)
            putExtra(EXTRA_WORKOUT_NAME, workoutName)
            putExtra(EXTRA_SCHEDULED_TIME, scheduledTime)
        }
        
        val requestCode = workoutId.hashCode()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Check if we can schedule exact alarms
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                scheduleExactAlarm(pendingIntent, scheduledTime)
            } else {
                // Fall back to inexact alarm
                scheduleInexactAlarm(pendingIntent, scheduledTime)
            }
        } else {
            scheduleExactAlarm(pendingIntent, scheduledTime)
        }
    }

    private fun scheduleExactAlarm(pendingIntent: PendingIntent, scheduledTime: Long) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                scheduledTime,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                scheduledTime,
                pendingIntent
            )
        }
    }

    private fun scheduleInexactAlarm(pendingIntent: PendingIntent, scheduledTime: Long) {
        alarmManager.set(
            AlarmManager.RTC_WAKEUP,
            scheduledTime,
            pendingIntent
        )
    }

    fun cancelWorkoutReminder(workoutId: String) {
        val intent = Intent(context, WorkoutReminderReceiver::class.java).apply {
            action = ACTION_WORKOUT_REMINDER
        }
        
        val requestCode = workoutId.hashCode()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    fun snoozeReminder(
        workoutId: String,
        workoutName: String,
        snoozeTimeMillis: Long = SNOOZE_DURATION_MILLIS
    ) {
        scheduleWorkoutReminder(
            workoutId = workoutId,
            workoutName = workoutName,
            scheduledTime = System.currentTimeMillis() + snoozeTimeMillis
        )
    }

    fun cancelAllWorkoutReminders() {
        // Note: This requires storing all workout IDs somewhere to cancel them
        // For now, we'll rely on the WorkManager to handle batch cancellation
    }

    companion object {
        const val ACTION_WORKOUT_REMINDER = "com.sundeefundee.ACTION_WORKOUT_REMINDER"
        const val EXTRA_WORKOUT_ID = "workout_id"
        const val EXTRA_WORKOUT_NAME = "workout_name"
        const val EXTRA_SCHEDULED_TIME = "scheduled_time"
        
        const val SNOOZE_DURATION_MILLIS = 15 * 60 * 1000L // 15 minutes
    }
}