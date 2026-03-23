package com.sundeefundee.ui.features.programs

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
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sundeefundee.domain.model.Program
import com.sundeefundee.ui.components.LoadingIndicator
import com.sundeefundee.ui.theme.Primary
import com.sundeefundee.ui.theme.Secondary
import com.sundeefundee.ui.theme.Tertiary

/**
 * Programs screen with tabs for Available and Enrolled programs.
 */
@Composable
fun ProgramsScreen(
    viewModel: ProgramsViewModel = hiltViewModel(),
    onNavigateToProgramDetail: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    if (uiState.isLoading) {
        LoadingIndicator(message = "Loading programs...")
        return
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Tab Row
        TabRow(
            selectedTabIndex = uiState.selectedTab,
            containerColor = Secondary,
            contentColor = Primary
        ) {
            Tab(
                selected = uiState.selectedTab == 0,
                onClick = { viewModel.selectTab(0) },
                text = { Text("Available") }
            )
            Tab(
                selected = uiState.selectedTab == 1,
                onClick = { viewModel.selectTab(1) },
                text = { Text("Enrolled") }
            )
        }

        // Content
        when (uiState.selectedTab) {
            0 -> AvailableProgramsTab(
                programs = uiState.availablePrograms,
                enrolledProgramIds = uiState.enrolledPrograms.map { it.program.id },
                onProgramClick = onNavigateToProgramDetail,
                onEnrollClick = { viewModel.enrollInProgram(it) }
            )
            1 -> EnrolledProgramsTab(
                enrolledPrograms = uiState.enrolledPrograms,
                onProgramClick = onNavigateToProgramDetail
            )
        }
    }
}

/**
 * Available programs tab.
 */
@Composable
private fun AvailableProgramsTab(
    programs: List<Program>,
    enrolledProgramIds: List<String>,
    onProgramClick: (String) -> Unit,
    onEnrollClick: (String) -> Unit
) {
    if (programs.isEmpty()) {
        EmptyState(message = "No programs available")
    } else {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(programs) { program ->
                ProgramCard(
                    program = program,
                    isEnrolled = program.id in enrolledProgramIds,
                    onClick = { onProgramClick(program.id) },
                    onEnrollClick = { onEnrollClick(program.id) }
                )
            }
        }
    }
}

/**
 * Enrolled programs tab.
 */
@Composable
private fun EnrolledProgramsTab(
    enrolledPrograms: List<EnrolledProgramWithProgram>,
    onProgramClick: (String) -> Unit
) {
    if (enrolledPrograms.isEmpty()) {
        EmptyState(message = "Not enrolled in any programs.\nBrowse Available to enroll!")
    } else {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(enrolledPrograms) { enrolled ->
                EnrolledProgramCard(
                    enrolledWithProgram = enrolled,
                    onClick = { onProgramClick(enrolled.program.id) }
                )
            }
        }
    }
}

/**
 * Card displaying a program.
 */
@Composable
private fun ProgramCard(
    program: Program,
    isEnrolled: Boolean,
    onClick: () -> Unit,
    onEnrollClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Secondary),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        onClick = onClick
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(Tertiary.copy(alpha = 0.2f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.FitnessCenter,
                        contentDescription = null,
                        tint = Tertiary,
                        modifier = Modifier.size(28.dp)
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = program.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = Primary
                    )
                    Text(
                        text = program.targetAudience,
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                DifficultyBadge(difficulty = program.difficultyLevelRaw)
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = program.programDescription,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 2
            )

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.CalendarMonth,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "${program.estimatedDurationWeeks} weeks",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.weight(1f))

                if (isEnrolled) {
                    Button(
                        onClick = { },
                        enabled = false,
                        colors = ButtonDefaults.buttonColors(
                            disabledContainerColor = Tertiary.copy(alpha = 0.3f),
                            disabledContentColor = Tertiary
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Enrolled")
                    }
                } else {
                    Button(
                        onClick = onEnrollClick,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Tertiary,
                            contentColor = Color.White
                        )
                    ) {
                        Text("Enroll")
                    }
                }
            }
        }
    }
}

/**
 * Card displaying an enrolled program with progress.
 */
@Composable
private fun EnrolledProgramCard(
    enrolledWithProgram: EnrolledProgramWithProgram,
    onClick: () -> Unit
) {
    val program = enrolledWithProgram.program
    val enrollment = enrolledWithProgram.enrollment

    val totalDays = program.estimatedDurationWeeks * 7
    val currentDay = ((enrollment.currentWeek - 1) * 7) + enrollment.currentDay
    val progress = currentDay.toFloat() / totalDays.toFloat()

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Primary),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        onClick = onClick
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = program.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    Text(
                        text = "Week ${enrollment.currentWeek}, Day ${enrollment.currentDay}",
                        style = MaterialTheme.typography.labelMedium,
                        color = Color.White.copy(alpha = 0.8f)
                    )
                }

                if (enrollment.isActive) {
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .background(Tertiary)
                            .padding(horizontal = 12.dp, vertical = 6.dp)
                    ) {
                        Text(
                            text = "Active",
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = Color.White
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .clip(RoundedCornerShape(4.dp)),
                color = Tertiary,
                trackColor = Color.White.copy(alpha = 0.3f)
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "$currentDay of $totalDays days",
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.White.copy(alpha = 0.8f)
                )
                Text(
                    text = "${enrollment.completedWorkouts} workouts completed",
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.White.copy(alpha = 0.8f)
                )
            }
        }
    }
}

/**
 * Difficulty badge.
 */
@Composable
private fun DifficultyBadge(difficulty: String) {
    val (color, text) = when (difficulty.lowercase()) {
        "beginner" -> androidx.compose.ui.graphics.Color(0xFF4CAF50) to "Beginner"
        "intermediate" -> androidx.compose.ui.graphics.Color(0xFFFF9800) to "Intermediate"
        "advanced" -> androidx.compose.ui.graphics.Color(0xFFF44336) to "Advanced"
        else -> Tertiary to difficulty
    }

    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(color.copy(alpha = 0.15f))
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = color
        )
    }
}

/**
 * Empty state composable.
 */
@Composable
private fun EmptyState(message: String) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.FitnessCenter,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = message,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
