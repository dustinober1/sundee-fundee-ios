package com.sundeefundee.app.service

import android.app.Service
import android.content.Intent
import android.os.IBinder

// Foreground service for active workout notification (Phase 8)
// Replaces iOS ActivityKit Live Activity
class WorkoutNotificationService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // TODO: Create and show foreground notification with workout progress
        return START_STICKY
    }
}
