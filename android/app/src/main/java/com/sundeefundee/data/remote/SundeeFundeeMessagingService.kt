package com.sundeefundee.data.remote

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class SundeeFundeeMessagingService : FirebaseMessagingService() {

    @Inject
    lateinit var notificationService: NotificationService

    @Inject
    lateinit var fcmTokenRepository: com.sundeefundee.domain.repository.FcmTokenRepository

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        serviceScope.launch {
            try {
                fcmTokenRepository.saveToken(token)
            } catch (e: Exception) {
                // Log error but don't crash the service
            }
        }
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        // Check if the message contains data payload
        remoteMessage.data.isNotEmpty().let {
            handleDataMessage(remoteMessage.data)
        }
        
        // Check if the message contains notification payload
        remoteMessage.notification?.let { notification ->
            showNotification(
                title = notification.title ?: "Sundee Fundee",
                body = notification.body ?: "",
                data = remoteMessage.data
            )
        }
    }

    private fun handleDataMessage(data: Map<String, String>) {
        val type = data["type"] ?: return
        
        when (type) {
            "workout_reminder" -> {
                val workoutName = data["workout_name"] ?: "Workout"
                val workoutId = data["workout_id"] ?: ""
                showNotification(
                    title = "Time to Train! 🏋️‍♀️",
                    body = "Your workout \"$workoutName\" is ready",
                    data = data
                )
            }
            "cycle_phase" -> {
                val phase = data["phase"] ?: "Phase"
                showNotification(
                    title = "Cycle Update 🌸",
                    body = "You're currently in $phase phase",
                    data = data
                )
            }
            "achievement" -> {
                val achievement = data["achievement"] ?: "Achievement unlocked!"
                showNotification(
                    title = "Achievement Unlocked! 🎉",
                    body = achievement,
                    data = data
                )
            }
            "marketing" -> {
                val title = data["title"] ?: "Sundee Fundee"
                val body = data["body"] ?: ""
                showNotification(
                    title = title,
                    body = body,
                    data = data
                )
            }
        }
    }

    private fun showNotification(title: String, body: String, data: Map<String, String>) {
        notificationService.showNotification(
            title = title,
            body = body,
            data = data
        )
    }
}