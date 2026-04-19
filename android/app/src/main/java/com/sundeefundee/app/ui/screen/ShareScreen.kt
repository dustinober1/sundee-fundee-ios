package com.sundeefundee.app.ui.screen

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sundeefundee.app.ui.theme.*
import com.sundeefundee.core.model.Workout

// Workout share card — generates a shareable text summary
// Compose → text summary → Share Intent (mirrors iOS WorkoutShareCardView)
object WorkoutShareCard {

    fun generateShareText(workout: Workout): String {
        val sb = StringBuilder()
        sb.appendLine("Sundee Fundee Workout")
        sb.appendLine("─".repeat(24))
        workout.exercises.forEach { exercise ->
            sb.appendLine("${exercise.name}")
            exercise.sets.filter { it.completed }.forEachIndexed { i, set ->
                val reps = set.actualReps ?: set.targetReps
                val weight = set.actualWeight ?: set.targetWeight
                sb.appendLine("  Set ${i + 1}: ${reps} reps @ ${"%.0f".format(weight)} lbs")
            }
        }
        sb.appendLine("─".repeat(24))
        if (workout.totalVolume > 0) {
            sb.appendLine("Total Volume: ${"%,.0f".format(workout.totalVolume)} lbs")
        }
        val duration = workout.totalDuration
        if (duration > 0) {
            val mins = duration / 60
            val secs = duration % 60
            sb.appendLine("Duration: ${mins}m ${secs}s")
        }
        sb.appendLine()
        sb.append("#SundeeFundee")
        return sb.toString()
    }

    fun share(context: Context, workout: Workout) {
        val text = generateShareText(workout)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(Intent.createChooser(intent, "Share Workout").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }
}
