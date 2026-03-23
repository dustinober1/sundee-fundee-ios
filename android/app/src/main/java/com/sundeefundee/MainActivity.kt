package com.sundeefundee

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.Text

/**
 * Main entry point for Sundee Fundee Android app.
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // TODO: Implement MainActivity with Compose UI
        setContent {
            Text("Sundee Fundee")
        }
    }
}
