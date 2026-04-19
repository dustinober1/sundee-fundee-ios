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
import com.sundeefundee.app.viewmodel.BenchmarksViewModel
import com.sundeefundee.core.domain.benchmark.BenchmarkCategory
import com.sundeefundee.core.domain.benchmark.BenchmarkDefinition

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BenchmarksScreen(
    viewModel: BenchmarksViewModel = hiltViewModel()
) {
    val isLoading by viewModel.isLoading.collectAsState()
    val benchmarks by viewModel.benchmarks.collectAsState()
    val selectedCategory by viewModel.selectedCategory.collectAsState()
    val userResults by viewModel.userResults.collectAsState()
    val showScoreEntry by viewModel.showScoreEntry.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadData() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Benchmarks") },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = SundeeFundeeTheme.colors.cream)
            )
        }
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            // Category Filter
            ScrollableTabRow(
                selectedTabIndex = BenchmarkCategory.entries.indexOfFirst { it.rawValue == selectedCategory }.coerceAtLeast(0),
                containerColor = SundeeFundeeTheme.colors.cream,
                contentColor = SundeeFundeeTheme.colors.navy,
                edgePadding = Spacing.md
            ) {
                BenchmarkCategory.entries.forEach { category ->
                    Tab(
                        selected = selectedCategory == category.rawValue,
                        onClick = { viewModel.selectCategory(category.rawValue) },
                        text = { Text(category.displayName, style = SundeeFundeeTheme.typography.labelMedium) }
                    )
                }
            }

            if (isLoading) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = SundeeFundeeTheme.colors.navy)
                }
            } else {
                LazyColumn(
                    Modifier.fillMaxSize().padding(horizontal = Spacing.md),
                    verticalArrangement = Arrangement.spacedBy(Spacing.sm),
                    contentPadding = PaddingValues(vertical = Spacing.md)
                ) {
                    items(benchmarks, key = { it.id }) { benchmark ->
                        BenchmarkCard(
                            benchmark = benchmark,
                            bestScore = viewModel.getBestResult(benchmark.id)?.let { viewModel.formatScore(benchmark.scoringType, it.score) },
                            hasCompleted = userResults[benchmark.id]?.isNotEmpty() == true,
                            onClick = { viewModel.showScoreEntry(benchmark.id) }
                        )
                    }
                }
            }
        }
    }

    // Score Entry Dialog
    showScoreEntry?.let { benchmarkId ->
        val benchmark = benchmarks.find { it.id == benchmarkId }
        var scoreInput by remember { mutableStateOf("") }
        var notesInput by remember { mutableStateOf("") }

        AlertDialog(
            onDismissRequest = { viewModel.dismissScoreEntry() },
            title = { Text(benchmark?.name ?: "Log Score") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                    Text(benchmark?.workoutDescription ?: "", style = SundeeFundeeTheme.typography.bodySmall)
                    OutlinedTextField(value = scoreInput, onValueChange = { scoreInput = it }, label = { Text("Score") })
                    OutlinedTextField(value = notesInput, onValueChange = { notesInput = it }, label = { Text("Notes (optional)") })
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    scoreInput.toDoubleOrNull()?.let { score ->
                        viewModel.saveResult(benchmarkId, score, notesInput.ifBlank { null })
                    }
                }) { Text("Save") }
            },
            dismissButton = { TextButton(onClick = { viewModel.dismissScoreEntry() }) { Text("Cancel") } }
        )
    }
}

@Composable
private fun BenchmarkCard(
    benchmark: BenchmarkDefinition,
    bestScore: String?,
    hasCompleted: Boolean,
    onClick: () -> Unit
) {
    ArtDecoCard(onClick = onClick) {
        Row(Modifier.padding(Spacing.md).fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (hasCompleted) {
                        Icon(Icons.Default.CheckCircle, contentDescription = null, tint = SundeeFundeeTheme.colors.orange, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(Spacing.xs))
                    }
                    Text(benchmark.name, style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy)
                }
                Text(benchmark.scoringType, style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
            }
            bestScore?.let { score ->
                Text(score, style = SundeeFundeeTheme.typography.monoMedium, color = SundeeFundeeTheme.colors.gold)
            }
        }
    }
}

private val BenchmarkCategory.displayName: String
    get() = when (this) {
        BenchmarkCategory.SUNDEE_FUNDEE -> "Sundee Fundee"
        BenchmarkCategory.CLASSIC_WOD -> "Classic WODs"
        BenchmarkCategory.STRENGTH -> "Strength"
        BenchmarkCategory.ENDURANCE -> "Endurance"
        BenchmarkCategory.GYMNASTICS -> "Gymnastics"
        BenchmarkCategory.GENERAL_FITNESS -> "General"
    }
