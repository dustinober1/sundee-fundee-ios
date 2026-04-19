package com.sundeefundee.app.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sundeefundee.app.ui.theme.*
import com.sundeefundee.app.viewmodel.ActiveWorkoutViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ActiveWorkoutScreen(
    onFinish: () -> Unit = {},
    viewModel: ActiveWorkoutViewModel = hiltViewModel()
) {
    val exercises by viewModel.exercises.collectAsState()
    val currentExerciseIndex by viewModel.currentExerciseIndex.collectAsState()
    val currentSetIndex by viewModel.currentSetIndex.collectAsState()
    val isResting by viewModel.isResting.collectAsState()
    val restTimeRemaining by viewModel.restTimeRemaining.collectAsState()
    val elapsedSeconds by viewModel.elapsedSeconds.collectAsState()
    val isComplete by viewModel.isComplete.collectAsState()
    val isPaused by viewModel.isPaused.collectAsState()

    if (isComplete) {
        WorkoutCompleteScreen(onFinish = onFinish)
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(viewModel.formatElapsedTime()) },
                navigationIcon = {
                    IconButton(onClick = viewModel::togglePause) {
                        Icon(
                            if (isPaused) Icons.Default.PlayArrow else Icons.Default.Pause,
                            contentDescription = if (isPaused) "Resume" else "Pause"
                        )
                    }
                },
                actions = {
                    TextButton(onClick = viewModel::completeWorkout) {
                        Text("Finish", color = SundeeFundeeTheme.colors.orange)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = SundeeFundeeTheme.colors.cream)
            )
        }
    ) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).padding(horizontal = Spacing.md),
            verticalArrangement = Arrangement.spacedBy(Spacing.md)
        ) {
            // Rest Timer Overlay
            if (isResting) {
                Card(
                    colors = CardDefaults.cardColors(containerColor = SundeeFundeeTheme.colors.navy),
                    shape = SundeeFundeeTheme.shapes.medium
                ) {
                    Column(
                        Modifier.fillMaxWidth().padding(Spacing.lg),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("REST", style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.gold)
                        Text(
                            viewModel.formatTime(restTimeRemaining),
                            style = SundeeFundeeTheme.typography.displayLarge.copy(fontSize = 48.sp),
                            color = SundeeFundeeTheme.colors.cream
                        )
                        ArtDecoGhostButton(onClick = viewModel::skipRest) {
                            Text("Skip Rest", color = SundeeFundeeTheme.colors.cream)
                        }
                    }
                }
            }

            // Current Exercise
            val currentExercise = exercises.getOrNull(currentExerciseIndex)
            currentExercise?.let { exercise ->
                ArtDecoCard {
                    Column(Modifier.padding(Spacing.md)) {
                        Text(
                            exercise.name,
                            style = SundeeFundeeTheme.typography.headlineMedium,
                            color = SundeeFundeeTheme.colors.navy
                        )
                        Text(
                            "Set ${currentSetIndex + 1} of ${exercise.sets.size}",
                            style = SundeeFundeeTheme.typography.bodyMedium,
                            color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f)
                        )

                        Spacer(Modifier.height(Spacing.md))

                        // Set input
                        val currentSet = exercise.sets.getOrNull(currentSetIndex)
                        var repsInput by remember(currentSetIndex) { mutableIntStateOf(currentSet?.targetReps ?: 0) }
                        var weightInput by remember(currentSetIndex) { mutableDoubleStateOf(currentSet?.targetWeight ?: 0.0) }

                        Row(
                            Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(Spacing.md),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(Modifier.weight(1f)) {
                                Text("Reps", style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
                                OutlinedTextField(
                                    value = repsInput.toString(),
                                    onValueChange = { repsInput = it.toIntOrNull() ?: 0 },
                                    modifier = Modifier.fillMaxWidth(),
                                    singleLine = true
                                )
                            }
                            Column(Modifier.weight(1f)) {
                                Text("Weight (lbs)", style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
                                OutlinedTextField(
                                    value = if (weightInput > 0) weightInput.toString() else "",
                                    onValueChange = { weightInput = it.toDoubleOrNull() ?: 0.0 },
                                    modifier = Modifier.fillMaxWidth(),
                                    singleLine = true
                                )
                            }
                        }

                        Spacer(Modifier.height(Spacing.md))

                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                            ArtDecoPrimaryButton(
                                onClick = { viewModel.logSet(repsInput, weightInput) },
                                modifier = Modifier.weight(1f)
                            ) {
                                Text("Log Set")
                            }
                            ArtDecoGhostButton(onClick = viewModel::skipSet) {
                                Text("Skip")
                            }
                        }
                    }
                }
            }

            // Exercise Progress
            LazyColumn {
                itemsIndexed(exercises) { index, exercise ->
                    val isCurrent = index == currentExerciseIndex
                    val isComplete = exercise.sets.all { it.completed }

                    Surface(
                        color = when {
                            isCurrent -> SundeeFundeeTheme.colors.gold.copy(alpha = 0.1f)
                            isComplete -> SundeeFundeeTheme.colors.cream
                            else -> SundeeFundeeTheme.colors.cream.copy(alpha = 0.5f)
                        },
                        shape = SundeeFundeeTheme.shapes.small
                    ) {
                        Row(
                            Modifier.fillMaxWidth().padding(Spacing.sm),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            if (isComplete) {
                                Icon(Icons.Default.CheckCircle, contentDescription = null, tint = SundeeFundeeTheme.colors.orange, modifier = Modifier.size(20.dp))
                            } else {
                                Text("${index + 1}", style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
                            }
                            Spacer(Modifier.width(Spacing.sm))
                            Text(exercise.name, style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy)
                            Spacer(Modifier.weight(1f))
                            Text("${exercise.sets.count { it.completed }}/${exercise.sets.size}", style = SundeeFundeeTheme.typography.monoMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun WorkoutCompleteScreen(onFinish: () -> Unit) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(Icons.Default.EmojiEvents, contentDescription = null, modifier = Modifier.size(80.dp), tint = SundeeFundeeTheme.colors.gold)
            Spacer(Modifier.height(Spacing.lg))
            Text("Workout Complete!", style = SundeeFundeeTheme.typography.displayLarge, color = SundeeFundeeTheme.colors.navy)
            Spacer(Modifier.height(Spacing.xl))
            ArtDecoPrimaryButton(onClick = onFinish) {
                Text("Done")
            }
        }
    }
}
