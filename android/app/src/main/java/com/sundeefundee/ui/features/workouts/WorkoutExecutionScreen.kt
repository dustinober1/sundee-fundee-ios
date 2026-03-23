package com.sundeefundee.ui.features.workouts

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sundeefundee.ui.theme.Primary
import com.sundeefundee.ui.theme.Secondary
import com.sundeefundee.ui.theme.Tertiary
import kotlinx.coroutines.delay

/**
 * Screen for executing a workout with timer and exercise tracking.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorkoutExecutionScreen(
    workoutId: String,
    viewModel: WorkoutExecutionViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit,
    onWorkoutComplete: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(workoutId) {
        viewModel.loadWorkout(workoutId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(uiState.workoutName.ifEmpty { "Workout" }) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Secondary,
                    titleContentColor = Primary
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(MaterialTheme.colorScheme.background)
        ) {
            // Progress bar
            val progress = if (uiState.totalExercises > 0) {
                uiState.currentExerciseIndex.toFloat() / uiState.totalExercises.toFloat()
            } else 0f

            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(4.dp),
                color = Tertiary,
                trackColor = Secondary
            )

            // Main content
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Exercise list
                itemsIndexed(uiState.exercises) { index, exercise ->
                    ExerciseCard(
                        exercise = exercise,
                        isCurrentExercise = index == uiState.currentExerciseIndex,
                        isCompleted = index < uiState.currentExerciseIndex,
                        isLastCompleted = index == uiState.currentExerciseIndex - 1,
                        onComplete = { viewModel.completeExercise(index) }
                    )
                }
            }

            // Bottom timer and controls
            WorkoutControls(
                isWorkoutActive = uiState.isWorkoutActive,
                elapsedTime = uiState.elapsedTime,
                currentRestTime = uiState.currentRestTime,
                isResting = uiState.isResting,
                onStartWorkout = { viewModel.startWorkout() },
                onPauseWorkout = { viewModel.pauseWorkout() },
                onResumeWorkout = { viewModel.resumeWorkout() },
                onSkipRest = { viewModel.skipRest() },
                onCompleteWorkout = {
                    viewModel.completeWorkout()
                    onWorkoutComplete()
                }
            )
        }
    }
}

/**
 * Card displaying an exercise in the workout.
 */
@Composable
private fun ExerciseCard(
    exercise: ExerciseItem,
    isCurrentExercise: Boolean,
    isCompleted: Boolean,
    isLastCompleted: Boolean,
    onComplete: () -> Unit
) {
    val backgroundColor = when {
        isCurrentExercise -> Primary
        isCompleted -> Primary.copy(alpha = 0.15f)
        else -> Secondary
    }

    val contentColor = when {
        isCurrentExercise -> Color.White
        isCompleted -> Primary
        else -> MaterialTheme.colorScheme.onSurface
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = backgroundColor),
        onClick = if (isCurrentExercise) onComplete else {}
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Status indicator
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(
                        if (isCompleted) Tertiary
                        else if (isCurrentExercise) Color.White.copy(alpha = 0.2f)
                        else MaterialTheme.colorScheme.surfaceVariant
                    ),
                contentAlignment = Alignment.Center
            ) {
                if (isCompleted) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(24.dp)
                    )
                } else {
                    Text(
                        text = exercise.reps,
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = contentColor
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Exercise details
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = exercise.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = contentColor
                )
                Text(
                    text = exercise.sets,
                    style = MaterialTheme.typography.bodySmall,
                    color = contentColor.copy(alpha = 0.8f)
                )
            }

            // Complete button for current exercise
            if (isCurrentExercise && !isCompleted) {
                Button(
                    onClick = onComplete,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Tertiary,
                        contentColor = Color.White
                    )
                ) {
                    Text("Done")
                }
            }
        }
    }
}

/**
 * Bottom controls for the workout including timer.
 */
@Composable
private fun WorkoutControls(
    isWorkoutActive: Boolean,
    elapsedTime: Int,
    currentRestTime: Int,
    isResting: Boolean,
    onStartWorkout: () -> Unit,
    onPauseWorkout: () -> Unit,
    onResumeWorkout: () -> Unit,
    onSkipRest: () -> Unit,
    onCompleteWorkout: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp),
        colors = CardDefaults.cardColors(containerColor = Primary)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Timer display
            if (isWorkoutActive || isResting) {
                Text(
                    text = formatTime(elapsedTime),
                    style = MaterialTheme.typography.displayMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }

            // Rest timer
            if (isResting) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Rest: ${currentRestTime}s",
                    style = MaterialTheme.typography.titleMedium,
                    color = Tertiary
                )
                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    onClick = onSkipRest,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.White.copy(alpha = 0.2f),
                        contentColor = Color.White
                    )
                ) {
                    Icon(
                        imageVector = Icons.Default.SkipNext,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Skip Rest")
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Control buttons
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                when {
                    !isWorkoutActive && !isResting -> {
                        Button(
                            onClick = onStartWorkout,
                            modifier = Modifier.height(56.dp),
                            shape = RoundedCornerShape(16.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Tertiary,
                                contentColor = Color.White
                            )
                        ) {
                            Icon(
                                imageVector = Icons.Default.PlayArrow,
                                contentDescription = null,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Start Workout",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                    isResting -> {
                        // Just show skip button in row
                    }
                    else -> {
                        FilledIconButton(
                            onClick = onPauseWorkout,
                            colors = IconButtonDefaults.filledIconButtonColors(
                                containerColor = Color.White.copy(alpha = 0.2f),
                                contentColor = Color.White
                            )
                        ) {
                            Icon(
                                imageVector = Icons.Default.Pause,
                                contentDescription = "Pause",
                                modifier = Modifier.size(32.dp)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Complete workout button
            Button(
                onClick = onCompleteWorkout,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Tertiary,
                    contentColor = Color.White
                )
            ) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Complete Workout",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}

/**
 * Formats seconds to MM:SS string.
 */
private fun formatTime(seconds: Int): String {
    val minutes = seconds / 60
    val secs = seconds % 60
    return "%02d:%02d".format(minutes, secs)
}

/**
 * Exercise item data class.
 */
data class ExerciseItem(
    val name: String,
    val sets: String,
    val reps: String,
    val restSeconds: Int = 60
)
