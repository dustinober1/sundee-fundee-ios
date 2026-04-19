package com.sundeefundee.app.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sundeefundee.app.ui.theme.*
import com.sundeefundee.app.viewmodel.CalendarDay
import com.sundeefundee.app.viewmodel.CycleViewModel
import com.sundeefundee.core.model.CyclePhase
import kotlinx.datetime.DayOfWeek
import kotlinx.datetime.LocalDate

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CycleScreen(
    viewModel: CycleViewModel = hiltViewModel()
) {
    val cyclePhase by viewModel.cyclePhase.collectAsState()
    val cycleDay by viewModel.cycleDay.collectAsState()
    val isSharkWeek by viewModel.isSharkWeek.collectAsState()
    val phaseDescription by viewModel.phaseDescription.collectAsState()
    val calendarDays by viewModel.calendarDays.collectAsState()
    val cycleSettings by viewModel.cycleSettings.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadData() }

    // Shark Week Banner
    if (isSharkWeek) {
        Surface(color = SundeeFundeeTheme.colors.navy, modifier = Modifier.fillMaxWidth()) {
            Row(Modifier.padding(Spacing.md), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.WaterDrop, contentDescription = null, tint = Color.Red)
                Spacer(Modifier.width(Spacing.sm))
                Text("Shark Week", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.cream)
                Spacer(Modifier.weight(1f))
                Text("Take it easy", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.cream.copy(alpha = 0.7f))
            }
        }
    }

    LazyColumn(
        Modifier.fillMaxSize().padding(horizontal = Spacing.md),
        verticalArrangement = Arrangement.spacedBy(Spacing.md),
        contentPadding = PaddingValues(vertical = Spacing.md)
    ) {
        // Current Phase Card
        item {
            cyclePhase?.let { phase ->
                ArtDecoCard {
                    Column(Modifier.padding(Spacing.lg)) {
                        Text("Current Phase", style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.gold)
                        Spacer(Modifier.height(Spacing.xs))
                        Text(phaseDisplayName(phase), style = SundeeFundeeTheme.typography.displayLarge, color = SundeeFundeeTheme.colors.navy)
                        cycleDay?.let { day ->
                            Text("Day $day of cycle", style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
                        }
                        phaseDescription?.let { desc ->
                            Spacer(Modifier.height(Spacing.sm))
                            Text(desc, style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.7f))
                        }
                    }
                }
            }
        }

        // Calendar
        item {
            ArtDecoCard {
                Column(Modifier.padding(Spacing.md)) {
                    Text("Cycle Calendar", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                    Spacer(Modifier.height(Spacing.sm))

                    // Day of week headers
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                        listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun").forEach { day ->
                            Text(day, modifier = Modifier.weight(1f), textAlign = TextAlign.Center, style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.4f))
                        }
                    }
                    Spacer(Modifier.height(Spacing.xs))

                    // Calendar grid
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(7),
                        modifier = Modifier.height(280.dp),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        items(calendarDays) { day ->
                            Box(
                                modifier = Modifier.size(36.dp).clip(CircleShape).then(
                                    if (day.isToday) Modifier.background(SundeeFundeeTheme.colors.orange)
                                    else if (day.isPeriod) Modifier.background(Color.Red.copy(alpha = 0.15f))
                                    else Modifier
                                ).then(
                                    if (day.date != null) Modifier.clickable { day.date?.let { viewModel.selectDate(it) } } else Modifier
                                ),
                                contentAlignment = Alignment.Center
                            ) {
                                day.date?.let { date ->
                                    Text(
                                        "${date.dayOfMonth}",
                                        style = SundeeFundeeTheme.typography.bodyMedium.copy(
                                            fontWeight = if (day.isToday) FontWeight.Bold else FontWeight.Normal
                                        ),
                                        color = when {
                                            day.isToday -> SundeeFundeeTheme.colors.cream
                                            day.isPeriod -> Color.Red
                                            else -> SundeeFundeeTheme.colors.navy
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // Log Period Button
                    Spacer(Modifier.height(Spacing.md))
                    ArtDecoAccentButton(
                        onClick = { viewModel.logPeriod(LocalDate.parse(java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault()).format(java.util.Date()))) },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Log Period Today")
                    }
                }
            }
        }

        // Cycle Settings
        item {
            ArtDecoCard {
                Column(Modifier.padding(Spacing.md)) {
                    Text("Cycle Settings", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                    Spacer(Modifier.height(Spacing.sm))
                    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Text("Average Cycle Length: ${cycleSettings.averageCycleLengthDays} days", style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy)
                        Spacer(Modifier.weight(1f))
                        Row {
                            IconButton(onClick = { viewModel.updateSettings(maxOf(21, cycleSettings.averageCycleLengthDays - 1)) }) {
                                Icon(Icons.Default.Remove, contentDescription = "Decrease")
                            }
                            IconButton(onClick = { viewModel.updateSettings(minOf(40, cycleSettings.averageCycleLengthDays + 1)) }) {
                                Icon(Icons.Default.Add, contentDescription = "Increase")
                            }
                        }
                    }
                }
            }
        }
    }
}

private fun phaseDisplayName(phase: CyclePhase) = when (phase) {
    CyclePhase.MENSTRUAL -> "Menstrual"
    CyclePhase.FOLLICULAR -> "Follicular"
    CyclePhase.OVULATION -> "Ovulation"
    CyclePhase.LUTEAL -> "Luteal"
}
