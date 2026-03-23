package com.sundeefundee.ui.features.dashboard

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.SportsGymnastics
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sundeefundee.domain.WodType
import com.sundeefundee.ui.components.CompletedWorkoutCard
import com.sundeefundee.ui.components.CyclePhaseCard
import com.sundeefundee.ui.components.LoadingIndicator
import com.sundeefundee.ui.components.TodaysWodCard
import com.sundeefundee.ui.components.formatShortDate
import com.sundeefundee.ui.theme.Primary
import com.sundeefundee.ui.theme.Secondary
import com.sundeefundee.ui.theme.Tertiary

/**
 * Dashboard screen displaying overview of user's fitness status.
 */
@Composable
fun DashboardScreen(
    viewModel: DashboardViewModel = hiltViewModel(),
    onNavigateToWorkoutExecution: (String) -> Unit,
    onNavigateToPrograms: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    if (uiState.isLoading) {
        LoadingIndicator(message = "Loading dashboard...")
        return
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        // Header with greeting
        DashboardHeader(userName = uiState.user?.name)

        Spacer(modifier = Modifier.height(20.dp))

        // Cycle phase card (if enabled)
        if (uiState.cycleTrackingEnabled) {
            CyclePhaseCard(
                phase = uiState.currentPhase,
                recommendation = uiState.phaseRecommendation
            )
            Spacer(modifier = Modifier.height(20.dp))
        }

        // Today's workout card
        uiState.todaysSuggestedWorkout?.let { suggestion ->
            TodaysWodCard(
                workoutName = suggestion.name,
                wodType = try { WodType.valueOf(suggestion.wodType.uppercase()) } catch (e: Exception) { WodType.CUSTOM },
                estimatedDuration = suggestion.estimatedDuration,
                recommendation = suggestion.recommendation,
                onStartClick = { onNavigateToWorkoutExecution(suggestion.id) }
            )
            Spacer(modifier = Modifier.height(20.dp))
        }

        // Quick stats row
        QuickStatsRow(
            weeklyWorkouts = uiState.weeklyWorkoutCount,
            currentStreak = uiState.currentStreak,
            recentWorkoutsCount = uiState.recentWorkouts.size
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Recent workouts section
        if (uiState.recentWorkouts.isNotEmpty()) {
            SectionHeader(
                title = "Recent Workouts",
                actionText = "See All",
                onActionClick = { /* Navigate to workouts */ }
            )

            Spacer(modifier = Modifier.height(12.dp))

            uiState.recentWorkouts.forEach { workout ->
                CompletedWorkoutCard(
                    workout = workout,
                    onClick = { onNavigateToWorkoutExecution(workout.id) }
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
        }

        // Programs quick access
        Spacer(modifier = Modifier.height(16.dp))
        ProgramsQuickAccess(onClick = onNavigateToPrograms)
    }
}

/**
 * Dashboard header with greeting.
 */
@Composable
private fun DashboardHeader(userName: String?) {
    Column {
        Text(
            text = "Welcome back,",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = userName ?: "Athlete",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = Primary
        )
    }
}

/**
 * Quick stats row showing key metrics.
 */
@Composable
private fun QuickStatsRow(
    weeklyWorkouts: Int,
    currentStreak: Int,
    recentWorkoutsCount: Int
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        StatCard(
            modifier = Modifier.weight(1f),
            icon = Icons.Default.SportsGymnastics,
            value = weeklyWorkouts.toString(),
            label = "This Week",
            iconTint = Tertiary
        )
        StatCard(
            modifier = Modifier.weight(1f),
            icon = Icons.Default.LocalFireDepartment,
            value = "$currentStreak",
            label = "Day Streak",
            iconTint = androidx.compose.ui.graphics.Color(0xFFFF5722)
        )
        StatCard(
            modifier = Modifier.weight(1f),
            icon = Icons.Default.TrendingUp,
            value = recentWorkoutsCount.toString(),
            label = "Recent",
            iconTint = Primary
        )
    }
}

/**
 * Individual stat card.
 */
@Composable
private fun StatCard(
    modifier: Modifier = Modifier,
    icon: ImageVector,
    value: String,
    label: String,
    iconTint: androidx.compose.ui.graphics.Color
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Secondary)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(iconTint.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = iconTint,
                    modifier = Modifier.size(20.dp)
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = value,
                style = MaterialTheme.typography.headlineSmall,
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
}

/**
 * Section header with optional action button.
 */
@Composable
private fun SectionHeader(
    title: String,
    actionText: String? = null,
    onActionClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = Primary
        )

        if (actionText != null && onActionClick != null) {
            TextButton(onClick = onActionClick) {
                Text(
                    text = actionText,
                    style = MaterialTheme.typography.labelMedium,
                    color = Tertiary
                )
            }
        }
    }
}

/**
 * Quick access card to programs.
 */
@Composable
private fun ProgramsQuickAccess(onClick: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Primary.copy(alpha = 0.1f)),
        onClick = onClick
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.SportsGymnastics,
                contentDescription = null,
                tint = Primary,
                modifier = Modifier.size(32.dp)
            )

            Spacer(modifier = Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Training Programs",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = Primary
                )
                Text(
                    text = "Browse and enroll in programs",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
