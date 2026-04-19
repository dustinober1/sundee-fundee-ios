package com.sundeefundee.app.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sundeefundee.app.ui.theme.*

@Composable
fun AuthScreen(
    onGoogleSignIn: () -> Unit,
    onGuestMode: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Spacing.xxl),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.lg)
        ) {
            // App title
            Text(
                text = "Sundee Fundee",
                style = MaterialTheme.typography.displayLarge,
                color = TextPrimary
            )

            Text(
                text = "Cycle-aware strength training",
                style = MaterialTheme.typography.bodyLarge,
                color = TextSecondary,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(Spacing.xl))

            // Google Sign-In button
            ArtDecoPrimaryButton(
                text = "Sign in with Google",
                onClick = onGoogleSignIn,
                modifier = Modifier.fillMaxWidth()
            )

            // Guest mode
            ArtDecoSecondaryButton(
                text = "Continue as Guest",
                onClick = onGuestMode,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(Spacing.md))

            Text(
                text = "Guest mode stores data locally only.\nSign in to sync across devices.",
                style = MaterialTheme.typography.bodySmall,
                color = TextSecondary,
                textAlign = TextAlign.Center
            )
        }
    }
}
