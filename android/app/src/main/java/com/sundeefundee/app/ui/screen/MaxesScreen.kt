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
import com.sundeefundee.app.viewmodel.MaxesViewModel
import com.sundeefundee.core.model.OneRepMaxRecord

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MaxesScreen(
    viewModel: MaxesViewModel = hiltViewModel()
) {
    val maxes by viewModel.maxes.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val unit by viewModel.unit.collectAsState()
    var showAddDialog by remember { mutableStateOf(false) }
    var exerciseName by remember { mutableStateOf("") }
    var weight by remember { mutableStateOf("") }
    var reps by remember { mutableStateOf("") }

    LaunchedEffect(Unit) { viewModel.loadMaxes() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Maxes") },
                actions = {
                    IconButton(onClick = viewModel::toggleUnit) {
                        Text(if (unit.name == "LBS") "kg" else "lb", style = SundeeFundeeTheme.typography.labelMedium)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = SundeeFundeeTheme.colors.cream)
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showAddDialog = true },
                containerColor = SundeeFundeeTheme.colors.orange
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add Max", tint = SundeeFundeeTheme.colors.cream)
            }
        }
    ) { padding ->
        if (isLoading) {
            Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = SundeeFundeeTheme.colors.navy)
            }
        } else {
            LazyColumn(
                Modifier.fillMaxSize().padding(padding).padding(horizontal = Spacing.md),
                verticalArrangement = Arrangement.spacedBy(Spacing.sm),
                contentPadding = PaddingValues(vertical = Spacing.md)
            ) {
                items(maxes, key = { it.id }) { max ->
                    MaxCard(max = max, unit = unit, onDelete = { viewModel.deleteMax(max.id) })
                }
            }
        }
    }

    if (showAddDialog) {
        AlertDialog(
            onDismissRequest = { showAddDialog = false },
            title = { Text("Log New Max") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                    OutlinedTextField(value = exerciseName, onValueChange = { exerciseName = it }, label = { Text("Exercise") })
                    OutlinedTextField(value = weight, onValueChange = { weight = it }, label = { Text("Weight") })
                    OutlinedTextField(value = reps, onValueChange = { reps = it }, label = { Text("Reps") })
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    val w = weight.toDoubleOrNull() ?: 0.0
                    val r = reps.toIntOrNull() ?: 1
                    if (exerciseName.isNotBlank() && w > 0) {
                        viewModel.saveMax(exerciseName, w, r, unit)
                        showAddDialog = false
                        exerciseName = ""
                        weight = ""
                        reps = ""
                    }
                }) { Text("Save") }
            },
            dismissButton = { TextButton(onClick = { showAddDialog = false }) { Text("Cancel") } }
        )
    }
}

@Composable
private fun MaxCard(max: OneRepMaxRecord, unit: com.sundeefundee.core.model.WeightUnit, onDelete: () -> Unit) {
    ArtDecoCard {
        Row(Modifier.padding(Spacing.md).fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(max.exerciseName, style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                Text("${max.weight} x ${max.reps} reps", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
            }
            Column(horizontalAlignment = Alignment.End) {
                Text("${"%.1f".format(max.oneRepMax)} ${unit.name}", style = SundeeFundeeTheme.typography.monoMedium, color = SundeeFundeeTheme.colors.gold)
                Text("1RM", style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
            }
            IconButton(onClick = onDelete) {
                Icon(Icons.Default.Delete, contentDescription = "Delete", tint = SundeeFundeeTheme.colors.navy.copy(alpha = 0.3f))
            }
        }
    }
}
