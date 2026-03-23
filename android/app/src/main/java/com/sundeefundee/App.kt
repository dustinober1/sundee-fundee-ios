package com.sundeefundee

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Main Application class for Sundee Fundee.
 * Configured with Hilt for dependency injection.
 */
@HiltAndroidApp
class App : Application() {
    override fun onCreate() {
        super.onCreate()
        // Basic app initialization
    }
}
