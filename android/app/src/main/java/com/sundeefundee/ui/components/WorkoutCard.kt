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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.SportsGymnastics
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sundeefundee.domain.WodType
import com.sundeefundee.domain.model.CompletedWorkout
import com.sundeefundee.ui.theme.Primary
import com.sundeefundee.ui.theme.Secondary
import com.sundeefundee.ui.theme.Tertiary
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Card for displaying workout summary information.
 */
@Composable
fun WorkoutCard(
    workoutName: String,
    wodType: WodType?,
    duration: Int?,
    date: Long,
    modifier: Modifier = Modifier,
    spicyRating: Int? = null,
    onClick: (() -> Unit)? = null
) {
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
            // Workout type icon
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(Tertiary.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = getWorkoutIcon(wodType),
                    contentDescription = null,
                    tint = Tertiary,
                    modifier = Modifier.size(28.dp)
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            // Workout info
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = workoutName,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = Primary
                )

                Spacer(modifier = Modifier.height(4.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = formatDate(date),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    if (wodType != null) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "•",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = wodType.displayName,
                            style = MaterialTheme.typography.labelMedium,
                            color = Tertiary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (duration != null) {
                        Icon(
                            imageVector = Icons.Default.Timer,
                            contentDescription = null,
                            modifier = Modifier.size(14.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "${duration}min",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    if (spicyRating != null) {
                        Spacer(modifier = Modifier.width(12.dp))
                        SpicyRatingIndicator(rating = spicyRating)
                    }
                }
            }
        }
    }
}

/**
 * Card for displaying a completed workout from history.
 */
@Composable
fun CompletedWorkoutCard(
    workout: CompletedWorkout,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null
) {
    val wodType = workout.wodTypeRaw?.let {
        try { WodType.valueOf(it.uppercase()) } catch (e: Exception) { null }
    }

    WorkoutCard(
        workoutName = workout.workoutName,
        wodType = wodType,
        duration = workout.duration,
        date = workout.workoutDate,
        spicyRating = workout.spicyRating,
        modifier = modifier,
        onClick = onClick
    )
}

/**
 * Card for displaying today's suggested workout (WOD).
 */
@Composable
fun TodaysWodCard(
    workoutName: String,
    wodType: WodType,
    estimatedDuration: Int?,
    recommendation: String?,
    modifier: Modifier = Modifier,
    onStartClick: () -> Unit
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = Primary
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Today's Workout",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f)
                )
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    text = wodType.displayName,
                    style = MaterialTheme.typography.labelMedium,
                    color = Tertiary
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = workoutName,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimary
            )

            Spacer(modifier = Modifier.height(8.dp))

            if (estimatedDuration != null) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Schedule,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "~$estimatedDuration min",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f)
                    )
                }
            }

            if (recommendation != null) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = recommendation,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.9f)
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            androidx.compose.material3.Button(
                onClick = onStartClick,
                colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                    containerColor = Tertiary,
                    contentColor = MaterialTheme.colorScheme.onTertiary
                )
            ) {
                Icon(
                    imageVector = Icons.Default.SportsGymnastics,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Start Workout")
            }
        }
    }
}

/**
 * Compact indicator for spicy rating.
 */
@Composable
fun SpicyRatingIndicator(
    rating: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        repeat(5) { index ->
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(
                        if (index < rating) Tertiary else Tertiary.copy(alpha = 0.3f)
                    )
            )
        }
    }
}

/**
 * Gets the appropriate icon for a workout type.
 */
fun getWorkoutIcon(wodType: WodType?): ImageVector {
    return when (wodType) {
        WodType.AMRAP -> Icons.Default.FitnessCenter
        WodType.FOR_TIME -> Icons.Default.Timer
        WodType.EMOM -> Icons.Default.Schedule
        WodType.TABATA -> Icons.Default.Timer
        WodType.STRENGTH -> Icons.Default.FitnessCenter
        WodType.CARDIO -> Icons.Default.SportsGymnastics
        WodType.CUSTOM -> Icons.Default.FitnessCenter
        null -> Icons.Default.FitnessCenter
    }
}

/**
 * Formats a timestamp to a readable date string.
 */
fun formatDate(timestamp: Long): String {
    val sdf = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())
    return sdf.format(Date(timestamp))
}

/**
 * Formats a timestamp to a short date string.
 */
fun formatShortDate(timestamp: Long): String {
    val sdf = SimpleDateFormat("MMM d", Locale.getDefault())
    return sdf.format(Date(timestamp))
}
