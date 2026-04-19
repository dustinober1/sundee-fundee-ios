package com.sundeefundee.app.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.sundeefundee.app.MainActivity
import com.sundeefundee.app.R

// Foreground service for active workout notification
// Replaces iOS ActivityKit Live Activity
class WorkoutNotificationService : Service() {

    companion object {
        const val CHANNEL_ID = "workout_active"
        const val NOTIFICATION_ID = 1
        const val ACTION_UPDATE = "com.sundeefundee.app.UPDATE_WORKOUT"
        const val ACTION_STOP = "com.sundeefundee.app.STOP_WORKOUT"
        const val EXTRA_EXERCISE = "exercise_name"
        const val EXTRA_SET = "current_set"
        const val EXTRA_TOTAL_SETS = "total_sets"
        const val EXTRA_ELAPSED = "elapsed_time"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_UPDATE -> {
                val exercise = intent.getStringExtra(EXTRA_EXERCISE) ?: "Workout"
                val currentSet = intent.getIntExtra(EXTRA_SET, 0)
                val totalSets = intent.getIntExtra(EXTRA_TOTAL_SETS, 0)
                val elapsed = intent.getStringExtra(EXTRA_ELAPSED) ?: "0:00"
                updateNotification(exercise, currentSet, totalSets, elapsed)
            }
            else -> {
                val exercise = intent?.getStringExtra(EXTRA_EXERCISE) ?: "Workout"
                startForeground(NOTIFICATION_ID, buildNotification(exercise, 0, 0, "0:00"))
            }
        }
        return START_STICKY
    }

    private fun buildNotification(exercise: String, currentSet: Int, totalSets: Int, elapsed: String): Notification {
        val contentIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = PendingIntent.getService(
            this, 1,
            Intent(this, WorkoutNotificationService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val setInfo = if (totalSets > 0) "Set $currentSet/$totalSets" else "In Progress"
        val title = "$exercise — $setInfo"

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText("Elapsed: $elapsed")
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setContentIntent(contentIntent)
            .addAction(0, "Finish", stopIntent)
            .build()
    }

    private fun updateNotification(exercise: String, currentSet: Int, totalSets: Int, elapsed: String) {
        val notification = buildNotification(exercise, currentSet, totalSets, elapsed)
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Active Workout",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows current workout progress"
            setShowBadge(false)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }
}
