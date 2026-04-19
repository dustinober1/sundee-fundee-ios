package com.sundeefundee.app.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sundeefundee.app.ui.theme.*
import com.sundeefundee.app.viewmodel.WorkoutsViewModel
import com.sundeefundee.core.model.Workout

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorkoutsScreen(
    onStartWorkout: () -> Unit = {},
    onWorkoutClick: (String) -> Unit = {},
    viewModel: WorkoutsViewModel = hiltViewModel()
) {
    val workouts by viewModel.workouts.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadWorkouts() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Workouts") },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = SundeeFundeeTheme.colors.cream)
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = onStartWorkout,
                containerColor = SundeeFundeeTheme.colors.orange
            ) {
                Icon(Icons.Default.Add, contentDescription = "Start Workout", tint = SundeeFundeeTheme.colors.cream)
            }
        }
    ) { padding ->
        if (isLoading) {
            Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = SundeeFundeeTheme.colors.navy)
            }
        } else if (workouts.isEmpty()) {
            Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Default.FitnessCenter, contentDescription = null, modifier = Modifier.size(64.dp), tint = SundeeFundeeTheme.colors.navy.copy(alpha = 0.3f))
                    Spacer(Modifier.height(Spacing.md))
                    Text("No workouts yet", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
                    Spacer(Modifier.height(Spacing.sm))
                    Text("Tap + to start your first workout", style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.4f))
                }
            }
        } else {
            LazyColumn(
                Modifier.fillMaxSize().padding(padding).padding(horizontal = Spacing.md),
                verticalArrangement = Arrangement.spacedBy(Spacing.sm),
                contentPadding = PaddingValues(vertical = Spacing.md)
            ) {
                items(workouts, key = { it.id }) { workout ->
                    WorkoutCard(workout = workout, onClick = { onWorkoutClick(workout.id) })
                }
            }
        }
    }
}

@Composable
private fun WorkoutCard(workout: Workout, onClick: () -> Unit) {
    ArtDecoCard(onClick = onClick) {
        Row(Modifier.padding(Spacing.md).fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(
                    workout.exercises.firstOrNull()?.name ?: "Workout",
                    style = SundeeFundeeTheme.typography.headlineMedium,
                    color = SundeeFundeeTheme.colors.navy
                )
                Text(
                    "${workout.exercises.size} exercises",
                    style = SundeeFundeeTheme.typography.bodySmall,
                    color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f)
                )
                if (workout.totalVolume > 0) {
                    Text(
                        "${"%,.0f".format(workout.totalVolume)} lbs volume",
                        style = SundeeFundeeTheme.typography.monoMedium,
                        color = SundeeFundeeTheme.colors.gold
                    )
                }
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(workout.date.take(10), style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
                if (workout.completedAt != null) {
                    Icon(Icons.Default.CheckCircle, contentDescription = "Complete", tint = SundeeFundeeTheme.colors.orange, modifier = Modifier.size(20.dp))
                }
            }
        }
    }
}
