package com.sundeefundee.app.ui.screen

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sundeefundee.app.ui.theme.*
import com.sundeefundee.app.ui.theme.MonoMedium
import com.sundeefundee.app.viewmodel.PainTrackingViewModel
import com.sundeefundee.core.domain.injury.BodyRegions

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PainScreen(
    viewModel: PainTrackingViewModel = hiltViewModel()
) {
    val painLogs by viewModel.painLogs.collectAsState()
    val injuries by viewModel.injuries.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val selectedRegion by viewModel.selectedRegion.collectAsState()
    val painIntensity by viewModel.painIntensity.collectAsState()
    val substitutions by viewModel.substitutions.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadData() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Pain & Injuries") },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = SundeeFundeeTheme.colors.cream)
            )
        }
    ) { padding ->
        LazyColumn(
            Modifier.fillMaxSize().padding(padding).padding(horizontal = Spacing.md),
            verticalArrangement = Arrangement.spacedBy(Spacing.md),
            contentPadding = PaddingValues(vertical = Spacing.md)
        ) {
            // Body Region Selector
            item {
                Text("Where does it hurt?", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                Spacer(Modifier.height(Spacing.sm))
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    modifier = Modifier.height(200.dp),
                    horizontalArrangement = Arrangement.spacedBy(Spacing.xs),
                    verticalArrangement = Arrangement.spacedBy(Spacing.xs)
                ) {
                    items(BodyRegions.allRegions) { region ->
                        val isSelected = selectedRegion == region.id
                        Surface(
                            modifier = Modifier.clip(MaterialTheme.shapes.small).clickable { viewModel.selectRegion(region.id) },
                            color = if (isSelected) SundeeFundeeTheme.colors.orange.copy(alpha = 0.2f) else SundeeFundeeTheme.colors.cream,
                            shape = MaterialTheme.shapes.small
                        ) {
                            Text(
                                region.displayName,
                                modifier = Modifier.padding(Spacing.xs),
                                style = SundeeFundeeTheme.typography.bodySmall,
                                color = if (isSelected) SundeeFundeeTheme.colors.orange else SundeeFundeeTheme.colors.navy
                            )
                        }
                    }
                }
            }

            // Pain Intensity Slider
            if (selectedRegion != null) {
                item {
                    ArtDecoCard {
                        Column(Modifier.padding(Spacing.md)) {
                            Text("Pain Intensity: $painIntensity/10", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                            Slider(
                                value = painIntensity.toFloat(),
                                onValueChange = { viewModel.setIntensity(it.toInt()) },
                                valueRange = 1f..10f,
                                steps = 9,
                                colors = SliderDefaults.colors(
                                    activeTrackColor = SundeeFundeeTheme.colors.orange,
                                    thumbColor = SundeeFundeeTheme.colors.orange
                                )
                            )
                            Spacer(Modifier.height(Spacing.md))
                            ArtDecoPrimaryButton(text = "Log Pain", onClick = viewModel::savePainLog, modifier = Modifier.fillMaxWidth())
                        }
                    }
                }
            }

            // Substitutions
            if (substitutions.isNotEmpty()) {
                item {
                    ArtDecoCard {
                        Column(Modifier.padding(Spacing.md)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.SwapHoriz, contentDescription = null, tint = SundeeFundeeTheme.colors.gold)
                                Spacer(Modifier.width(Spacing.sm))
                                Text("Suggested Substitutions", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                            }
                            Spacer(Modifier.height(Spacing.sm))
                            substitutions.forEach { sub ->
                                Text("  $sub", style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy)
                            }
                        }
                    }
                }
            }

            // Active Injuries
            if (injuries.isNotEmpty()) {
                item {
                    Text("Active Injuries", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                }
                items(injuries, key = { it.id }) { injury ->
                    ArtDecoCard {
                        Row(Modifier.padding(Spacing.md).fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Healing, contentDescription = null, tint = SundeeFundeeTheme.colors.orange)
                            Spacer(Modifier.width(Spacing.sm))
                            Column(Modifier.weight(1f)) {
                                Text(injury.name, style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy)
                                Text(injury.locationIds, style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
                            }
                        }
                    }
                }
            }

            // Recent Pain Logs
            if (painLogs.isNotEmpty()) {
                item {
                    Text("Recent Pain Logs", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                }
                items(painLogs.take(10), key = { it.id }) { log ->
                    ArtDecoCard {
                        Row(Modifier.padding(Spacing.sm).fillMaxWidth()) {
                            Column(Modifier.weight(1f)) {
                                Text(log.locationIds, style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy)
                                Text(log.painType, style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
                            }
                            Text("${log.intensity}/10", style = MonoMedium, color = SundeeFundeeTheme.colors.orange)
                        }
                    }
                }
            }
        }
    }
}
