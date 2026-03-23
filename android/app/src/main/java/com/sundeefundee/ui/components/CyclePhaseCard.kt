package com.sundeefundee.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sundeefundee.domain.CyclePhase
import com.sundeefundee.ui.theme.Primary
import com.sundeefundee.ui.theme.Secondary
import com.sundeefundee.ui.theme.Tertiary

/**
 * Card displaying the current cycle phase with icon, color, and recommendation.
 */
@Composable
fun CyclePhaseCard(
    phase: CyclePhase,
    recommendation: String,
    modifier: Modifier = Modifier,
    dayInPhase: Int? = null,
    onClick: (() -> Unit)? = null
) {
    val phaseColor = getPhaseColor(phase)

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = Secondary
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        onClick = onClick ?: {}
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Phase icon
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(phaseColor.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = phase.emoji,
                    style = MaterialTheme.typography.headlineMedium
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            // Phase info
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Current Phase",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    if (dayInPhase != null) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Day $dayInPhase",
                            style = MaterialTheme.typography.labelSmall,
                            color = phaseColor
                        )
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = phase.displayName,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = Primary
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = recommendation,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/**
 * Gets the color associated with a cycle phase.
 */
@Composable
fun getPhaseColor(phase: CyclePhase): Color {
    return when (phase) {
        CyclePhase.MENSTRUAL -> Color(0xFF6B7FD7) // Calm blue
        CyclePhase.FOLLICULAR -> Color(0xFF7CB342) // Fresh green
        CyclePhase.OVULATION -> Color(0xFFFFB300) // Energetic gold
        CyclePhase.LUTEAL -> Color(0xFF8D6E63) // Grounding brown
    }
}

/**
 * Gets the workout intensity recommendation for a cycle phase.
 */
fun getPhaseRecommendation(phase: CyclePhase): String {
    return when (phase) {
        CyclePhase.MENSTRUAL -> "Rest and recovery. Gentle stretching and light walking recommended."
        CyclePhase.FOLLICULAR -> "High energy! Great for strength training and HIIT workouts."
        CyclePhase.OVULATION -> "Peak performance time. Go for PRs and intense workouts."
        CyclePhase.LUTEAL -> "Moderate intensity. Focus on steady-state cardio and controlled lifts."
    }
}

/**
 * Compact cycle phase indicator for use in lists or headers.
 */
@Composable
fun CyclePhaseIndicator(
    phase: CyclePhase,
    modifier: Modifier = Modifier,
    showLabel: Boolean = true
) {
    val phaseColor = getPhaseColor(phase)

    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Start
    ) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .clip(CircleShape)
                .background(phaseColor)
        )

        if (showLabel) {
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = phase.displayName,
                style = MaterialTheme.typography.labelMedium,
                color = phaseColor
            )
        }
    }
}
