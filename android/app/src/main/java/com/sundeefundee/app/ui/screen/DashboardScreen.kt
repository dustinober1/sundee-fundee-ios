package com.sundeefundee.app.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sundeefundee.app.ui.theme.*
import com.sundeefundee.app.ui.theme.MonoMedium
import com.sundeefundee.app.viewmodel.DashboardViewModel
import com.sundeefundee.core.model.CyclePhase
import com.sundeefundee.core.model.Challenge
import com.sundeefundee.core.model.ChallengeProgress
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun DashboardScreen(
    onNavigateToWorkouts: () -> Unit = {},
    onNavigateToMaxes: () -> Unit = {},
    onNavigateToPain: () -> Unit = {},
    onNavigateToBenchmarks: () -> Unit = {},
    onNavigateToChallenges: () -> Unit = {},
    onNavigateToCycle: () -> Unit = {},
    onNavigateToInsights: () -> Unit = {},
    onNavigateToAIWorkout: () -> Unit = {},
    viewModel: DashboardViewModel = hiltViewModel()
) {
    val isLoading by viewModel.isLoading.collectAsState()
    val workoutsThisWeek by viewModel.workoutsThisWeek.collectAsState()
    val prsThisMonth by viewModel.prsThisMonth.collectAsState()
    val activeProgramName by viewModel.activeProgramName.collectAsState()
    val cyclePhase by viewModel.cyclePhase.collectAsState()
    val cycleConfidence by viewModel.cycleConfidence.collectAsState()
    val recentWins by viewModel.recentWins.collectAsState()
    val insightsSummary by viewModel.insightsSummary.collectAsState()
    val insightsActions by viewModel.insightsActions.collectAsState()
    val activeChallengeData by viewModel.activeChallengeData.collectAsState()
    val userName by viewModel.userName.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadData() }

    if (isLoading) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = SundeeFundeeTheme.colors.navy)
        }
    } else {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.lg, vertical = Spacing.md)
        ) {
            // Welcome Header
            Text(
                "Welcome Back",
                style = SundeeFundeeTheme.typography.labelMedium,
                color = SundeeFundeeTheme.colors.gold
            )
            Text(
                "Hey, $userName",
                style = SundeeFundeeTheme.typography.headlineLarge,
                color = SundeeFundeeTheme.colors.navy
            )
            Text(
                SimpleDateFormat("MMMM d, yyyy", Locale.getDefault()).format(Date()),
                style = SundeeFundeeTheme.typography.bodyMedium,
                color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f)
            )

            Spacer(Modifier.height(Spacing.lg))

            // Cycle Phase Banner
            cyclePhase?.let { phase ->
                CyclePhaseBanner(
                    phase = phase,
                    confidence = cycleConfidence,
                    onClick = onNavigateToCycle
                )
                Spacer(Modifier.height(Spacing.md))
            }

            // Stat Cards
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Spacing.md)
            ) {
                StatCard(
                    value = "$workoutsThisWeek",
                    label = "This Week",
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    value = "$prsThisMonth",
                    label = "PRs Month",
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    value = activeProgramName ?: "None",
                    label = "Program",
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(Modifier.height(Spacing.lg))

            // Challenge Progress
            activeChallengeData?.let { (challenge, progress) ->
                ChallengeProgressCard(
                    challenge = challenge,
                    progress = progress,
                    onClick = onNavigateToChallenges
                )
                Spacer(Modifier.height(Spacing.lg))
            }

            HorizontalDivider(color = SundeeFundeeTheme.colors.gold.copy(alpha = 0.3f))

            Spacer(Modifier.height(Spacing.lg))

            // Suggested Workout
            ArtDecoCard {
                Column(Modifier.padding(Spacing.lg)) {
                    Text("Suggested Workout", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                    Spacer(Modifier.height(Spacing.sm))
                    Text("Generate a workout based on your cycle phase and energy level", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
                    Spacer(Modifier.height(Spacing.md))
                    ArtDecoAccentButton(text = "Generate Workout", onClick = onNavigateToAIWorkout)
                }
            }

            Spacer(Modifier.height(Spacing.lg))

            // Coaching Insights
            insightsSummary?.let { summary ->
                ArtDecoCard {
                    Column(Modifier.padding(Spacing.lg)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Psychology, contentDescription = null, tint = SundeeFundeeTheme.colors.orange)
                            Spacer(Modifier.width(Spacing.sm))
                            Text("Your Coach", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                        }
                        Spacer(Modifier.height(Spacing.sm))
                        Text(summary, style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.7f))
                        insightsActions.take(2).forEach { action ->
                            Row(Modifier.padding(top = Spacing.xs)) {
                                Icon(Icons.Default.ArrowRight, contentDescription = null, modifier = Modifier.size(12.dp), tint = SundeeFundeeTheme.colors.gold)
                                Spacer(Modifier.width(Spacing.xs))
                                Text(action, style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy)
                            }
                        }
                        Spacer(Modifier.height(Spacing.sm))
                        TextButton(onClick = onNavigateToInsights) {
                            Text("View All Insights", color = SundeeFundeeTheme.colors.orange)
                        }
                    }
                }
                Spacer(Modifier.height(Spacing.lg))
            }

            // Quick Actions
            ArtDecoCard {
                Column(Modifier.padding(Spacing.lg)) {
                    Text("Shortcuts", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                    Spacer(Modifier.height(Spacing.md))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                        QuickActionTile("Log Max", Icons.Default.MonitorWeight, true, onNavigateToMaxes, Modifier.weight(1f))
                        QuickActionTile("Pain Log", Icons.Default.Healing, false, onNavigateToPain, Modifier.weight(1f))
                        QuickActionTile("Bench", Icons.Default.EmojiEvents, false, onNavigateToBenchmarks, Modifier.weight(1f))
                    }
                }
            }

            Spacer(Modifier.height(Spacing.lg))

            // Recent Wins
            if (recentWins.isNotEmpty()) {
                ArtDecoCard {
                    Column(Modifier.padding(Spacing.lg)) {
                        Text("Recent Wins", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                        recentWins.take(3).forEach { win ->
                            Row(Modifier.padding(top = Spacing.sm), verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.CheckCircle, contentDescription = null, tint = SundeeFundeeTheme.colors.gold, modifier = Modifier.size(20.dp))
                                Spacer(Modifier.width(Spacing.sm))
                                Text(win, style = SundeeFundeeTheme.typography.bodyMedium, color = SundeeFundeeTheme.colors.navy)
                            }
                        }
                    }
                }
            }

            Spacer(Modifier.height(Spacing.xl))
        }
    }
}

@Composable
private fun CyclePhaseBanner(phase: CyclePhase, confidence: Double?, onClick: () -> Unit) {
    val icon = when (phase) {
        CyclePhase.MENSTRUAL -> Icons.Default.WaterDrop
        CyclePhase.FOLLICULAR -> Icons.Default.WbSunny
        CyclePhase.OVULATION -> Icons.Default.AutoAwesome
        CyclePhase.LUTEAL -> Icons.Default.Nightlight
    }
    val title = when (phase) {
        CyclePhase.MENSTRUAL -> "Menstrual Phase"
        CyclePhase.FOLLICULAR -> "Follicular Phase"
        CyclePhase.OVULATION -> "Ovulation Phase"
        CyclePhase.LUTEAL -> "Luteal Phase"
    }
    val description = when (phase) {
        CyclePhase.MENSTRUAL -> "Lower energy, focus on recovery"
        CyclePhase.FOLLICULAR -> "Rising energy, great for progress"
        CyclePhase.OVULATION -> "Peak strength potential"
        CyclePhase.LUTEAL -> "Higher energy, but may need more rest"
    }
    val color = when (phase) {
        CyclePhase.MENSTRUAL -> SundeeFundeeTheme.colors.navy.copy(red = 0.8f, green = 0.2f, blue = 0.2f)
        CyclePhase.FOLLICULAR -> SundeeFundeeTheme.colors.gold
        CyclePhase.OVULATION -> SundeeFundeeTheme.colors.orange
        CyclePhase.LUTEAL -> SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f)
    }

    ArtDecoCard(onClick = onClick) {
        Row(Modifier.padding(Spacing.md).fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(24.dp))
            Spacer(Modifier.width(Spacing.md))
            Column(Modifier.weight(1f)) {
                Text(title, style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                Text(description, style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
            }
            confidence?.let { conf ->
                Text("${(conf * 100).toInt()}%", style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
            }
        }
    }
}

@Composable
private fun ChallengeProgressCard(challenge: Challenge, progress: ChallengeProgress, onClick: () -> Unit) {
    ArtDecoCard(onClick = onClick) {
        Column(Modifier.padding(Spacing.md)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.EmojiEvents, contentDescription = null, tint = SundeeFundeeTheme.colors.gold)
                Spacer(Modifier.width(Spacing.sm))
                Text(challenge.title, style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy, modifier = Modifier.weight(1f))
                Text(progress.currentTierName, style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.gold)
            }
            Spacer(Modifier.height(Spacing.sm))
            LinearProgressIndicator(
                progress = { progress.percentComplete.toFloat() },
                modifier = Modifier.fillMaxWidth().height(6.dp),
                color = SundeeFundeeTheme.colors.gold,
                trackColor = SundeeFundeeTheme.colors.navy.copy(alpha = 0.1f)
            )
            Spacer(Modifier.height(Spacing.xs))
            Row(Modifier.fillMaxWidth()) {
                Text("${(progress.percentComplete * 100).toInt()}%", style = MonoMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
                Spacer(Modifier.weight(1f))
                val remaining = progress.volumeRemaining
                val text = if (remaining >= 1000) "${"%.0f".format(remaining / 1000)}K lbs to go" else "${remaining.toInt()} lbs to go"
                Text(text, style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
            }
        }
    }
}

@Composable
private fun QuickActionTile(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    isPrimary: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        onClick = onClick,
        modifier = modifier,
        color = if (isPrimary) SundeeFundeeTheme.colors.navy else SundeeFundeeTheme.colors.cream.copy(alpha = 0.5f),
        shape = MaterialTheme.shapes.small
    ) {
        Column(
            Modifier.padding(Spacing.md),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(icon, contentDescription = title, tint = if (isPrimary) SundeeFundeeTheme.colors.cream else SundeeFundeeTheme.colors.navy, modifier = Modifier.size(20.dp))
            Spacer(Modifier.height(Spacing.xs))
            Text(title, style = SundeeFundeeTheme.typography.labelMedium, color = if (isPrimary) SundeeFundeeTheme.colors.cream else SundeeFundeeTheme.colors.navy)
        }
    }
}
