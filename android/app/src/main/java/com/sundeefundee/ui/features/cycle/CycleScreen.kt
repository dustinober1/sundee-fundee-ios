package com.sundeefundee.ui.features.cycle

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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
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
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sundeefundee.domain.CyclePhase
import com.sundeefundee.domain.getPhaseRecommendation
import com.sundeefundee.ui.components.CyclePhaseCard
import com.sundeefundee.ui.components.LoadingIndicator
import com.sundeefundee.ui.components.getPhaseColor
import com.sundeefundee.ui.theme.Primary
import com.sundeefundee.ui.theme.Secondary
import com.sundeefundee.ui.theme.Tertiary
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Cycle tracking screen showing current phase and period history.
 */
@Composable
fun CycleScreen(
    viewModel: CycleViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    if (uiState.isLoading) {
        LoadingIndicator(message = "Loading cycle data...")
        return
    }

    // Log period dialog
    if (uiState.showLogPeriodDialog) {
        LogPeriodDialog(
            onDismiss = { viewModel.hideLogPeriodDialog() },
            onConfirm = { startDate, endDate, notes ->
                viewModel.logPeriod(startDate, endDate, notes)
            }
        )
    }

    // Phase warning dialog
    if (uiState.showPhaseWarning && uiState.phaseWarningMessage != null) {
        PhaseWarningDialog(
            message = uiState.phaseWarningMessage!!,
            onDismiss = { viewModel.hidePhaseWarning() }
        )
    }

    Box(modifier = Modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header
            item {
                Text(
                    text = "Cycle Tracking",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = Primary
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Track your cycle for personalized workouts",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Current phase card
            item {
                CyclePhaseCard(
                    phase = uiState.currentPhase,
                    recommendation = uiState.phaseRecommendation,
                    dayInPhase = uiState.dayInPhase
                )
            }

            // Cycle info card
            item {
                CycleInfoCard(
                    cycleLength = uiState.cycleLength,
                    periodLength = uiState.periodLength,
                    daysUntilNextPhase = uiState.daysUntilNextPhase
                )
            }

            // Phase overview
            item {
                PhaseOverview(
                    currentPhase = uiState.currentPhase,
                    dayInPhase = uiState.dayInPhase
                )
            }

            // Period history header
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Period History",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = Primary
                    )
                    OutlinedButton(
                        onClick = { viewModel.showLogPeriodDialog() }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Log Period")
                    }
                }
            }

            // Period logs
            if (uiState.periodLogs.isEmpty()) {
                item {
                    EmptyPeriodHistory()
                }
            } else {
                items(uiState.periodLogs) { log ->
                    PeriodLogCard(
                        startDate = log.startDate,
                        endDate = log.endDate,
                        notes = log.notes
                    )
                }
            }

            // Bottom spacing
            item {
                Spacer(modifier = Modifier.height(72.dp))
            }
        }
    }
}

/**
 * Card showing cycle information.
 */
@Composable
private fun CycleInfoCard(
    cycleLength: Int,
    periodLength: Int,
    daysUntilNextPhase: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Secondary)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            InfoItem(label = "Cycle Length", value = "$cycleLength days")
            InfoItem(label = "Period Length", value = "$periodiodLength days")
            InfoItem(label = "Next Phase In", value = "$daysUntilNextPhase days")
        }
    }
}

private val periodLength: Int
    get() = 5

/**
 * Info item for cycle info card.
 */
@Composable
private fun InfoItem(label: String, value: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = Primary
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * Phase overview showing all phases.
 */
@Composable
private fun PhaseOverview(
    currentPhase: CyclePhase,
    dayInPhase: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Secondary)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = "Cycle Phases",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = Primary
            )

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                CyclePhase.values().forEach { phase ->
                    PhaseIndicator(
                        phase = phase,
                        isActive = phase == currentPhase
                    )
                }
            }
        }
    }
}

/**
 * Individual phase indicator.
 */
@Composable
private fun PhaseIndicator(
    phase: CyclePhase,
    isActive: Boolean
) {
    val phaseColor = getPhaseColor(phase)

    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier
                .size(if (isActive) 40.dp else 32.dp)
                .clip(CircleShape)
                .background(
                    if (isActive) phaseColor else phaseColor.copy(alpha = 0.3f)
                ),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = phase.emoji,
                style = if (isActive) MaterialTheme.typography.titleMedium
                else MaterialTheme.typography.bodySmall
            )
        }

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = phase.displayName.take(4),
            style = MaterialTheme.typography.labelSmall,
            color = if (isActive) phaseColor else MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * Card showing a period log entry.
 */
@Composable
private fun PeriodLogCard(
    startDate: Long,
    endDate: Long?,
    notes: String?
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
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(Tertiary.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.CalendarMonth,
                    contentDescription = null,
                    tint = Tertiary,
                    modifier = Modifier.size(24.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = formatDate(startDate) + (endDate?.let { " - ${formatDate(it)}" } ?: ""),
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                if (!notes.isNullOrEmpty()) {
                    Text(
                        text = notes,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

/**
 * Empty state for period history.
 */
@Composable
private fun EmptyPeriodHistory() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Secondary)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.Info,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(48.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = "No periods logged yet",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "Tap 'Log Period' to get started",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * Dialog for logging a period.
 */
@Composable
private fun LogPeriodDialog(
    onDismiss: () -> Unit,
    onConfirm: (startDate: Long, endDate: Long?, notes: String?) -> Unit
) {
    var notes by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text("Log Period")
        },
        text = {
            Column {
                Text(
                    text = "Mark the start of your period. This helps us track your cycle and provide personalized workout recommendations.",
                    style = MaterialTheme.typography.bodyMedium
                )
                Spacer(modifier = Modifier.height(16.dp))
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
                onClick = { onConfirm(System.currentTimeMillis(), null, notes.ifEmpty { null }) },
                colors = ButtonDefaults.buttonColors(containerColor = Tertiary)
            ) {
                Text("Log Today")
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
 * Dialog for phase transition warning.
 */
@Composable
private fun PhaseWarningDialog(
    message: String,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                imageVector = Icons.Default.Warning,
                contentDescription = null,
                tint = Tertiary
            )
        },
        title = {
            Text("Phase Transition")
        },
        text = {
            Text(message)
        },
        confirmButton = {
            Button(
                onClick = onDismiss,
                colors = ButtonDefaults.buttonColors(containerColor = Tertiary)
            ) {
                Text("Got It")
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
