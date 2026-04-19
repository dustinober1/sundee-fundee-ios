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
import com.sundeefundee.app.viewmodel.SettingsViewModel
import com.sundeefundee.core.model.WeightUnit

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onSignOut: () -> Unit = {},
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val settings by viewModel.settings.collectAsState()
    val isExporting by viewModel.isExporting.collectAsState()
    val exportJson by viewModel.exportJson.collectAsState()
    val isSignedOut by viewModel.isSignedOut.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadSettings() }
    LaunchedEffect(isSignedOut) { if (isSignedOut) onSignOut() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings") },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = SundeeFundeeTheme.colors.cream)
            )
        }
    ) { padding ->
        LazyColumn(
            Modifier.fillMaxSize().padding(padding).padding(horizontal = Spacing.md),
            verticalArrangement = Arrangement.spacedBy(Spacing.md),
            contentPadding = PaddingValues(vertical = Spacing.md)
        ) {
            // Weight Unit
            item {
                ArtDecoCard {
                    Column(Modifier.padding(Spacing.md)) {
                        Text("Units", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                        Spacer(Modifier.height(Spacing.sm))
                        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                            FilterChip(
                                selected = settings.weightUnit == WeightUnit.LBS,
                                onClick = { viewModel.updateWeightUnit(WeightUnit.LBS) },
                                label = { Text("Pounds (lbs)") }
                            )
                            FilterChip(
                                selected = settings.weightUnit == WeightUnit.KG,
                                onClick = { viewModel.updateWeightUnit(WeightUnit.KG) },
                                label = { Text("Kilograms (kg)") }
                            )
                        }
                    }
                }
            }

            // Data Export
            item {
                ArtDecoCard(onClick = { if (!isExporting) viewModel.exportData() }) {
                    Row(Modifier.padding(Spacing.md).fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            if (isExporting) Icons.Default.Downloading else Icons.Default.FileDownload,
                            contentDescription = null,
                            tint = SundeeFundeeTheme.colors.navy
                        )
                        Spacer(Modifier.width(Spacing.md))
                        Column(Modifier.weight(1f)) {
                            Text("Export Data", style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy)
                            Text("Download all your data as JSON", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
                        }
                        if (isExporting) {
                            CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                        }
                    }
                }
            }

            // Sign Out
            item {
                ArtDecoCard(onClick = viewModel::signOut) {
                    Row(Modifier.padding(Spacing.md).fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Logout, contentDescription = null, tint = SundeeFundeeTheme.colors.orange)
                        Spacer(Modifier.width(Spacing.md))
                        Text("Sign Out", style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.orange)
                    }
                }
            }

            // Delete Account
            item {
                ArtDecoCard(onClick = viewModel::deleteAccount) {
                    Row(Modifier.padding(Spacing.md).fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.DeleteForever, contentDescription = null, tint = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
                        Spacer(Modifier.width(Spacing.md))
                        Column {
                            Text("Delete Account", style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.7f))
                            Text("This cannot be undone", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.4f))
                        }
                    }
                }
            }

            // App Info
            item {
                Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("Sundee Fundee v2.0", style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.4f))
                        Text("Cycle-Aware Strength Training", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.3f))
                    }
                }
            }
        }
    }
}
