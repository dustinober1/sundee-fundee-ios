package com.sundeefundee.ui.features.maxes

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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FloatingActionButton
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
import com.sundeefundee.domain.model.Max
import com.sundeefundee.ui.components.LoadingIndicator
import com.sundeefundee.ui.theme.Primary
import com.sundeefundee.ui.theme.Secondary
import com.sundeefundee.ui.theme.Tertiary
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Maxes screen showing personal records for lifts.
 */
@Composable
fun MaxesScreen(
    viewModel: MaxesViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    if (uiState.isLoading) {
        LoadingIndicator(message = "Loading maxes...")
        return
    }

    // Add/Edit max dialog
    if (uiState.showAddMaxDialog) {
        AddMaxDialog(
            editingMax = uiState.editingMax,
            selectedLiftName = uiState.selectedLiftName,
            existingLiftNames = uiState.maxes.map { it.liftName },
            weightUnit = uiState.weightUnit,
            onLiftNameSelected = { viewModel.setSelectedLiftName(it) },
            onSave = { weight, unit -> viewModel.saveMax(weight, unit) },
            onDismiss = { viewModel.hideAddMaxDialog() },
            onDelete = uiState.editingMax?.let { max -> {{ viewModel.deleteMax(max); viewModel.hideAddMaxDialog() }} }
        )
    }

    Box(modifier = Modifier.fillMaxSize()) {
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
                    text = "Maxes",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = Primary
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Track your personal records",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Quick stats
            item {
                if (uiState.maxes.isNotEmpty()) {
                    QuickStats(maxes = uiState.maxes)
                }
            }

            // Lift list
            val liftsWithMaxes = STANDARD_LIFTS.map { liftName ->
                val max = uiState.maxes.find { it.liftName == liftName }
                liftName to max
            }

            items(liftsWithMaxes) { (liftName, max) ->
                MaxCard(
                    liftName = liftName,
                    max = max,
                    onAddClick = { viewModel.showAddMaxDialog(liftName) },
                    onEditClick = { max?.let { viewModel.showEditMaxDialog(it.max) } }
                )
            }

            // Bottom spacing for FAB
            item {
                Spacer(modifier = Modifier.height(72.dp))
            }
        }

        // FAB
        FloatingActionButton(
            onClick = { viewModel.showAddMaxDialog() },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp),
            containerColor = Tertiary,
            contentColor = Color.White
        ) {
            Icon(
                imageVector = Icons.Default.Add,
                contentDescription = "Add Max"
            )
        }
    }
}

/**
 * Quick stats row showing total lifts and PR count.
 */
@Composable
private fun QuickStats(maxes: List<MaxWithLift>) {
    val prCount = maxes.count { it.isPR }

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
                    text = maxes.size.toString(),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = Primary
                )
                Text(
                    text = "Lifts Tracked",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = prCount.toString(),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = Tertiary
                )
                Text(
                    text = "PRs",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/**
 * Card displaying a single lift's max.
 */
@Composable
private fun MaxCard(
    liftName: String,
    max: MaxWithLift?,
    onAddClick: () -> Unit,
    onEditClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Secondary),
        onClick = if (max != null) onEditClick else onAddClick
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Lift icon
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(
                        if (max != null) Tertiary.copy(alpha = 0.2f)
                        else MaterialTheme.colorScheme.surfaceVariant
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.TrendingUp,
                    contentDescription = null,
                    tint = if (max != null) Tertiary else MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(28.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Lift info
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = liftName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = Primary
                    )
                    if (max?.isPR == true) {
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

                if (max != null) {
                    Text(
                        text = "${max.max.weight.toInt()} ${max.max.unitRaw}",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        color = Tertiary
                    )
                    Text(
                        text = formatDate(max.max.achievedDate),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                    Text(
                        text = "Tap to add max",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Add button if no max
            if (max == null) {
                Button(
                    onClick = onAddClick,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Primary,
                        contentColor = Color.White
                    )
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
    }
}

/**
 * Dialog for adding or editing a max.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddMaxDialog(
    editingMax: Max?,
    selectedLiftName: String,
    existingLiftNames: List<String>,
    weightUnit: String,
    onLiftNameSelected: (String) -> Unit,
    onSave: (Double, String) -> Unit,
    onDismiss: () -> Unit,
    onDelete: (() -> Unit)?
) {
    var weight by remember { mutableStateOf(editingMax?.weight?.toString() ?: "") }
    var unit by remember { mutableStateOf(editingMax?.unitRaw ?: weightUnit) }
    var liftName by remember { mutableStateOf(selectedLiftName) }
    var expanded by remember { mutableStateOf(false) }

    // Available lifts - show all standard lifts plus any existing custom ones
    val availableLifts = (STANDARD_LIFTS + existingLiftNames).distinct()

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(if (editingMax != null) "Edit Max" else "Add Max")
        },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Lift name dropdown
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = it }
                ) {
                    OutlinedTextField(
                        value = liftName,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Lift") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )

                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        availableLifts.forEach { lift ->
                            DropdownMenuItem(
                                text = { Text(lift) },
                                onClick = {
                                    liftName = lift
                                    onLiftNameSelected(lift)
                                    expanded = false
                                }
                            )
                        }
                    }
                }

                // Weight input
                OutlinedTextField(
                    value = weight,
                    onValueChange = { weight = it },
                    label = { Text("Weight") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth()
                )

                // Unit toggle
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("lb", "kg").forEach { u ->
                        Button(
                            onClick = { unit = u },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (unit == u) Primary else Secondary,
                                contentColor = if (unit == u) Color.White else Primary
                            )
                        ) {
                            Text(u)
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    weight.toDoubleOrNull()?.let { w ->
                        onSave(w, unit)
                    }
                },
                enabled = liftName.isNotEmpty() && weight.toDoubleOrNull() != null,
                colors = ButtonDefaults.buttonColors(containerColor = Tertiary)
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            Row {
                if (onDelete != null) {
                    TextButton(
                        onClick = onDelete,
                        colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)
                    ) {
                        Text("Delete")
                    }
                }
                TextButton(onClick = onDismiss) {
                    Text("Cancel")
                }
            }
        }
    )
}

/**
 * Formats a timestamp to a readable date string.
 */
private fun formatDate(timestamp: Long): String {
    val sdf = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())
    return sdf.format(Date(timestamp))
}
