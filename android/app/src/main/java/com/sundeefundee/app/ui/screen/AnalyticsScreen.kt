package com.sundeefundee.app.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sundeefundee.app.ui.theme.*
import com.sundeefundee.app.viewmodel.AnalyticsViewModel
import com.sundeefundee.core.domain.analytics.TimeRange

@Composable
fun AnalyticsScreen(
    viewModel: AnalyticsViewModel = hiltViewModel()
) {
    val isLoading by viewModel.isLoading.collectAsState()
    val selectedRange by viewModel.selectedRange.collectAsState()
    val exerciseNames by viewModel.exerciseNames.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadData() }

    if (isLoading) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = SundeeFundeeTheme.colors.navy)
        }
    } else {
        LazyColumn(
            Modifier.fillMaxSize().padding(horizontal = Spacing.md),
            verticalArrangement = Arrangement.spacedBy(Spacing.md),
            contentPadding = PaddingValues(vertical = Spacing.md)
        ) {
            // Time Range Selector
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                    TimeRange.entries.forEach { range ->
                        FilterChip(
                            selected = selectedRange == range,
                            onClick = { viewModel.selectRange(range) },
                            label = { Text(range.displayName, style = SundeeFundeeTheme.typography.labelMedium) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = SundeeFundeeTheme.colors.navy,
                                selectedLabelColor = SundeeFundeeTheme.colors.cream
                            )
                        )
                    }
                }
            }

            // Strength Progression Chart
            item {
                ArtDecoCard {
                    Column(Modifier.padding(Spacing.md)) {
                        Text("Strength Progression", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                        Spacer(Modifier.height(Spacing.sm))
                        Text("1RM trends over time", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
                        Spacer(Modifier.height(Spacing.lg))
                        // Vico chart placeholder — will render with real data
                        Box(Modifier.fillMaxWidth().height(200.dp), contentAlignment = Alignment.Center) {
                            Text("Chart requires Vico integration", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.4f))
                        }
                    }
                }
            }

            // Training Volume Chart
            item {
                ArtDecoCard {
                    Column(Modifier.padding(Spacing.md)) {
                        Text("Training Volume", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                        Spacer(Modifier.height(Spacing.sm))
                        Text("Weekly volume trends", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
                        Spacer(Modifier.height(Spacing.lg))
                        Box(Modifier.fillMaxWidth().height(200.dp), contentAlignment = Alignment.Center) {
                            Text("Chart requires Vico integration", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.4f))
                        }
                    }
                }
            }

            // Workout Frequency Chart
            item {
                ArtDecoCard {
                    Column(Modifier.padding(Spacing.md)) {
                        Text("Workout Frequency", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                        Spacer(Modifier.height(Spacing.sm))
                        Text("Sessions per week", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
                        Spacer(Modifier.height(Spacing.lg))
                        Box(Modifier.fillMaxWidth().height(200.dp), contentAlignment = Alignment.Center) {
                            Text("Chart requires Vico integration", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.4f))
                        }
                    }
                }
            }

            // Cycle Correlation Chart
            item {
                ArtDecoCard {
                    Column(Modifier.padding(Spacing.md)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = SundeeFundeeTheme.colors.gold)
                            Spacer(Modifier.width(Spacing.sm))
                            Text("Cycle Correlation", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                        }
                        Spacer(Modifier.height(Spacing.sm))
                        Text("Performance across cycle phases", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
                        Spacer(Modifier.height(Spacing.lg))
                        Box(Modifier.fillMaxWidth().height(200.dp), contentAlignment = Alignment.Center) {
                            Text("Chart requires Vico integration", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.4f))
                        }
                    }
                }
            }
        }
    }
}

private val TimeRange.displayName: String
    get() = when (this) {
        TimeRange.LAST_MONTH -> "1M"
        TimeRange.LAST_THREE_MONTHS -> "3M"
        TimeRange.LAST_SIX_MONTHS -> "6M"
        TimeRange.LAST_YEAR -> "1Y"
        TimeRange.ALL_TIME -> "All"
    }
