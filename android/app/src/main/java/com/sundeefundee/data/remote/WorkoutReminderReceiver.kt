package com.sundeefundee.data.remote

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class WorkoutReminderReceiver : BroadcastReceiver() {

    @Inject
    lateinit var notificationService: NotificationService

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == WorkoutReminderScheduler.ACTION_WORKOUT_REMINDER) {
            val workoutId = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_WORKOUT_ID) ?: return
            val workoutName = intent.getStringExtra(WorkoutReminderScheduler.EXTRA_WORKOUT_NAME) ?: "Workout"
            val scheduledTime = intent.getLongExtra(WorkoutReminderScheduler.EXTRA_SCHEDULED_TIME, System.currentTimeMillis())

            notificationService.showWorkoutReminder(workoutName, scheduledTime)
        }
    }
}