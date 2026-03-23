package com.sundeefundee

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import com.sundeefundee.domain.model.AuthState
import com.sundeefundee.ui.features.auth.AuthViewModel
import com.sundeefundee.ui.features.auth.SignInScreen
import com.sundeefundee.ui.navigation.MainNavigation
import com.sundeefundee.ui.theme.SundeeFundeeTheme
import dagger.hilt.android.AndroidEntryPoint

/**
 * Main entry point for Sundee Fundee Android app.
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            SundeeFundeeTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    SundeeFundeeApp()
                }
            }
        }
    }
}

@Composable
fun SundeeFundeeApp(
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val authState by authViewModel.authState.collectAsState()

    // Restore session on app start
    LaunchedEffect(Unit) {
        authViewModel.restoreSession()
    }

    when (authState) {
        is AuthState.Loading -> {
            // Show loading state while checking auth
            LoadingScreen()
        }
        is AuthState.SignedIn, is AuthState.Guest -> {
            // User is authenticated, show main screen with navigation
            MainNavigation(
                onSignOut = { authViewModel.signOut() }
            )
        }
        is AuthState.SignedOut -> {
            // User is not authenticated, show sign in screen
            SignInScreen(
                onSignInClick = { authViewModel.signIn() },
                onGuestClick = { authViewModel.enterGuestMode() },
                isLoading = false
            )
        }
    }
}

@Composable
fun LoadingScreen() {
    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        androidx.compose.foundation.layout.Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = androidx.compose.ui.Alignment.Center
        ) {
            androidx.compose.material3.CircularProgressIndicator(
                color = com.sundeefundee.ui.theme.Tertiary
            )
        }
    }
}
