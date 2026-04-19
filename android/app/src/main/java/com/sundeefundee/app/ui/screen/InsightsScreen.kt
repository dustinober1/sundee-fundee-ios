package com.sundeefundee.app.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sundeefundee.app.ui.theme.*

@Composable
fun InsightsScreen() {
    Column(
        Modifier.fillMaxSize().padding(horizontal = Spacing.md),
        verticalArrangement = Arrangement.spacedBy(Spacing.md)
    ) {
        Spacer(Modifier.height(Spacing.md))

        // Plateau Detection
        ArtDecoCard {
            Column(Modifier.padding(Spacing.md)) {
                Text("Plateau Detection", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                Spacer(Modifier.height(Spacing.sm))
                Text("No plateaus detected — keep pushing!", style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.7f))
            }
        }

        // Weekly Load Analysis
        ArtDecoCard {
            Column(Modifier.padding(Spacing.md)) {
                Text("Weekly Load Analysis", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                Spacer(Modifier.height(Spacing.sm))
                Text("Your training is consistent. No imbalances detected.", style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.7f))
            }
        }

        // Substitution Suggestions
        ArtDecoCard {
            Column(Modifier.padding(Spacing.md)) {
                Text("Smart Substitutions", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                Spacer(Modifier.height(Spacing.sm))
                Text("Suggestions appear when you log pain or miss exercises.", style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.7f))
            }
        }

        // Schedule Optimization
        ArtDecoCard {
            Column(Modifier.padding(Spacing.md)) {
                Text("Schedule Optimization", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                Spacer(Modifier.height(Spacing.sm))
                Text("Log more workouts for schedule insights.", style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.7f))
            }
        }
    }
}
