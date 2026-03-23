package com.sundeefundee.data.remote

import android.Manifest
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.sundeefundee.MainActivity
import com.sundeefundee.R
import com.sundeefundee.domain.CyclePhase
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NotificationServiceImpl @Inject constructor(
    @ApplicationContext private val context: Context
) : NotificationService {

    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        createNotificationChannels()
    }

    override fun requestPermission(): Flow<NotificationPermissionStatus> = callbackFlow {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val status = when {
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED -> NotificationPermissionStatus.GRANTED
                else -> NotificationPermissionStatus.DENIED
            }
            trySend(status)
        } else {
            // For Android 12 and below, notifications are enabled by default
            trySend(NotificationPermissionStatus.GRANTED)
        }
        awaitClose()
    }

    override fun hasPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    override fun showNotification(title: String, body: String, data: Map<String, String>) {
        val notificationId = data["notification_id"]?.toIntOrNull() ?: System.currentTimeMillis().toInt()
        val channelId = data["channel"] ?: NotificationChannels.GENERAL
        
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            data.forEach { (key, value) -> putExtra(key, value) }
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setColor(ContextCompat.getColor(context, R.color.primary))
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .build()

        notificationManager.notify(notificationId, notification)
    }

    override fun showWorkoutReminder(workoutName: String, scheduledTime: Long) {
        val notificationId = NotificationIds.workoutId(workoutName.hashCode())
        
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("type", "workout_reminder")
            putExtra("workout_name", workoutName)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, NotificationChannels.WORKOUTS)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Time to Train! 🏋️‍♀️")
            .setContentText("Your workout \"$workoutName\" is ready. Let's crush it!")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("Your workout \"$workoutName\" is ready. Let's crush it! Tap to start your session.")
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setColor(ContextCompat.getColor(context, R.color.primary))
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .build()

        notificationManager.notify(notificationId, notification)
    }

    override fun showCyclePhaseReminder(phase: CyclePhase) {
        val notificationId = NotificationIds.cycleId(phase.ordinal)
        
        val (title, body, emoji) = when (phase) {
            CyclePhase.MENSTRUAL -> Triple(
                "Cycle Tracking ${emoji("🌸")}",
                "Log your symptoms to track your menstrual phase",
                "🌸"
            )
            CyclePhase.FOLLICULAR -> Triple(
                "Cycle Update ${emoji("🌱")}",
                "You're in the follicular phase. Great time for moderate training!",
                "🌱"
            )
            CyclePhase.OVULATION -> Triple(
                "Cycle Update ${emoji("✨")}",
                "You're ovulating. Consider a lighter workout today.",
                "✨"
            )
            CyclePhase.LUTEAL -> Triple(
                "Cycle Tracking ${emoji("🌿")}",
                "You're in the luteal phase. Listen to your body.",
                "🌿"
            )
        }
        
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("type", "cycle_phase")
            putExtra("phase", phase.name)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, NotificationChannels.CYCLE)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setColor(ContextCompat.getColor(context, R.color.tertiary))
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .build()

        notificationManager.notify(notificationId, notification)
    }

    override fun cancelNotification(notificationId: Int) {
        notificationManager.cancel(notificationId)
    }

    override fun cancelAllNotifications() {
        notificationManager.cancelAll()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val workoutChannel = android.app.NotificationChannel(
                NotificationChannels.WORKOUTS,
                context.getString(R.string.notification_channel_workouts),
                android.app.NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = context.getString(R.string.notification_channel_workouts_desc)
                enableVibration(true)
                setShowBadge(true)
            }

            val cycleChannel = android.app.NotificationChannel(
                NotificationChannels.CYCLE,
                context.getString(R.string.notification_channel_cycle),
                android.app.NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = context.getString(R.string.notification_channel_cycle_desc)
                enableVibration(true)
                setShowBadge(true)
            }

            val generalChannel = android.app.NotificationChannel(
                NotificationChannels.GENERAL,
                context.getString(R.string.notification_channel_general),
                android.app.NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = context.getString(R.string.notification_channel_general_desc)
                enableVibration(true)
                setShowBadge(true)
            }

            val achievementChannel = android.app.NotificationChannel(
                NotificationChannels.ACHIEVEMENTS,
                "Achievements",
                android.app.NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Achievement and milestone notifications"
                enableVibration(true)
                setShowBadge(true)
            }

            notificationManager.createNotificationChannels(
                listOf(workoutChannel, cycleChannel, generalChannel, achievementChannel)
            )
        }
    }

    private fun emoji(text: String): String = text
}