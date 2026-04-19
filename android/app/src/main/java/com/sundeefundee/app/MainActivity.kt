package com.sundeefundee.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.sundeefundee.app.navigation.MainNavHost
import com.sundeefundee.app.ui.theme.SundeeFundeeTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            SundeeFundeeTheme {
                MainNavHost()
            }
        }
    }
}
