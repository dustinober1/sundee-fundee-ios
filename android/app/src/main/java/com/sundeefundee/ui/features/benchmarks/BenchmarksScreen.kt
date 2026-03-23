package com.sundeefundee.ui.features.benchmarks

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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.SportsGymnastics
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sundeefundee.domain.ScoringType
import com.sundeefundee.domain.WodType
import com.sundeefundee.domain.model.BenchmarkDefinition
import com.sundeefundee.ui.components.LoadingIndicator
import com.sundeefundee.ui.theme.Primary
import com.sundeefundee.ui.theme.Secondary
import com.sundeefundee.ui.theme.Tertiary
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Benchmarks screen showing CrossFit benchmark workouts and user's PRs.
 */
@Composable
fun BenchmarksScreen(
    viewModel: BenchmarksViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    if (uiState.isLoading) {
        LoadingIndicator(message = "Loading benchmarks...")
        return
    }

    // Log score dialog
    if (uiState.showLogScoreDialog && uiState.selectedBenchmark != null) {
        LogScoreDialog(
            benchmark = uiState.selectedBenchmark!!,
            existingScore = uiState.userBenchmark?.score,
            onSave = { score, notes -> viewModel.logBenchmarkScore(score, notes) },
            onDismiss = { viewModel.hideLogScoreDialog() }
        )
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Header
        item {
            Text(
                text = "Benchmarks",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = Primary
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Classic CrossFit workouts",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        // Stats row
        item {
            BenchmarksStatsRow(
                totalBenchmarks = uiState.benchmarks.size,
                completedBenchmarks = uiState.benchmarks.count { it.userBenchmark != null }
            )
        }

        // Benchmark cards
        items(uiState.benchmarks) { benchmarkWithDef ->
            BenchmarkCard(
                benchmarkWithDef = benchmarkWithDef,
                onLogScoreClick = { viewModel.showLogScoreDialog(benchmarkWithDef.definition) }
            )
        }
    }
}

/**
 * Stats row showing benchmark progress.
 */
@Composable
private fun BenchmarksStatsRow(
    totalBenchmarks: Int,
    completedBenchmarks: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Secondary)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = totalBenchmarks.toString(),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = Primary
                )
                Text(
                    text = "Total Workouts",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = completedBenchmarks.toString(),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = Tertiary
                )
                Text(
                    text = "Completed",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/**
 * Card displaying a single benchmark workout.
 */
@Composable
private fun BenchmarkCard(
    benchmarkWithDef: BenchmarkWithDefinition,
    onLogScoreClick: () -> Unit
) {
    val definition = benchmarkWithDef.definition
    val wodType = try { WodType.valueOf(definition.wodTypeRaw.uppercase()) } catch (e: Exception) { WodType.CUSTOM }
    val scoringType = try { ScoringType.valueOf(definition.scoringTypeRaw.uppercase()) } catch (e: Exception) { ScoringType.TIME }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (benchmarkWithDef.userBenchmark != null) Secondary else Secondary.copy(alpha = 0.7f)
        ),
        onClick = onLogScoreClick
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Icon
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(
                            if (benchmarkWithDef.userBenchmark != null) Tertiary.copy(alpha = 0.2f)
                            else MaterialTheme.colorScheme.surfaceVariant
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = getWorkoutIconForBenchmark(scoringType),
                        contentDescription = null,
                        tint = if (benchmarkWithDef.userBenchmark != null) Tertiary else MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(28.dp)
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = definition.name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = Primary
                        )
                        if (benchmarkWithDef.isPR) {
                            Spacer(modifier = Modifier.width(8.dp))
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(Tertiary)
                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        imageVector = Icons.Default.EmojiEvents,
                                        contentDescription = null,
                                        tint = Color.White,
                                        modifier = Modifier.size(12.dp)
                                    )
                                    Spacer(modifier = Modifier.width(2.dp))
                                    Text(
                                        text = "PR",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color.White,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                            }
                        }
                    }
                    Text(
                        text = wodType.displayName,
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                if (benchmarkWithDef.userBenchmark == null) {
                    Button(
                        onClick = onLogScoreClick,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Primary,
                            contentColor = Color.White
                        )
                    ) {
                        Text("Log")
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Workout details
            Text(
                text = definition.description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Exercises
            Text(
                text = definition.exercises,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            // Target time or rounds
            definition.targetTime?.let { time ->
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Timer,
                        contentDescription = null,
                        modifier = Modifier.size(14.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Target: ${time / 60}:${String.format("%02d", time % 60)}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            definition.roundsAndReps?.let { rounds ->
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = rounds,
                    style = MaterialTheme.typography.labelSmall,
                    color = Tertiary
                )
            }

            // User's PR if exists
            benchmarkWithDef.userBenchmark?.let { benchmark ->
                Spacer(modifier = Modifier.height(12.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .background(Primary.copy(alpha = 0.1f))
                        .padding(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "Your PR",
                                style = MaterialTheme.typography.labelSmall,
                                color = Primary
                            )
                            Text(
                                text = formatScore(benchmark.score, scoringType),
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.Bold,
                                color = Primary
                            )
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Text(
                                text = formatDate(benchmark.achievedDate),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }
    }
}

/**
 * Dialog for logging a benchmark score.
 */
@Composable
private fun LogScoreDialog(
    benchmark: BenchmarkDefinition,
    existingScore: Double?,
    onSave: (Double, String?) -> Unit,
    onDismiss: () -> Unit
) {
    var score by remember { mutableStateOf(existingScore?.toString() ?: "") }
    var notes by remember { mutableStateOf("") }
    val scoringType = try { ScoringType.valueOf(benchmark.scoringTypeRaw.uppercase()) } catch (e: Exception) { ScoringType.TIME }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(if (existingScore != null) "Update PR" else "Log ${benchmark.name}")
        },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = benchmark.description,
                    style = MaterialTheme.typography.bodyMedium
                )

                OutlinedTextField(
                    value = score,
                    onValueChange = { score = it },
                    label = { Text(getScoreLabel(scoringType)) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = notes,
                    onValueChange = { notes = it },
                    label = { Text("Notes (optional)") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    score.toDoubleOrNull()?.let { s ->
                        onSave(s, notes.ifEmpty { null })
                    }
                },
                enabled = score.toDoubleOrNull() != null,
                colors = ButtonDefaults.buttonColors(containerColor = Tertiary)
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

/**
 * Gets the appropriate icon for a benchmark scoring type.
 */
private fun getWorkoutIconForBenchmark(scoringType: ScoringType) = when (scoringType) {
    ScoringType.TIME -> Icons.Default.Timer
    ScoringType.REPS_AND_LOAD, ScoringType.ROUNDS_AND_REPS -> Icons.Default.SportsGymnastics
    ScoringType.DISTANCE -> Icons.Default.EmojiEvents
    ScoringType.CALORIES -> Icons.Default.EmojiEvents
    else -> Icons.Default.Timer
}

/**
 * Gets the label for a scoring type.
 */
private fun getScoreLabel(scoringType: ScoringType): String = when (scoringType) {
    ScoringType.TIME -> "Time (seconds)"
    ScoringType.REPS_AND_LOAD -> "Total Reps"
    ScoringType.ROUNDS_AND_REPS -> "Score"
    ScoringType.DISTANCE -> "Distance"
    ScoringType.CALORIES -> "Calories"
    else -> "Score"
}

/**
 * Formats a score for display.
 */
private fun formatScore(score: Double, scoringType: ScoringType): String = when (scoringType) {
    ScoringType.TIME -> {
        val minutes = (score / 60).toInt()
        val seconds = (score % 60).toInt()
        "${minutes}:${String.format("%02d", seconds)}"
    }
    ScoringType.REPS_AND_LOAD, ScoringType.ROUNDS_AND_REPS -> score.toInt().toString()
    ScoringType.DISTANCE -> "${score.toInt()}m"
    ScoringType.CALORIES -> "${score.toInt()} cal"
    else -> score.toString()
}

/**
 * Formats a timestamp to a readable date string.
 */
private fun formatDate(timestamp: Long): String {
    val sdf = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())
    return sdf.format(Date(timestamp))
}
