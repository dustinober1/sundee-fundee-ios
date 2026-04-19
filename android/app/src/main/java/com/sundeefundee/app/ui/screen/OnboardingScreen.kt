package com.sundeefundee.app.ui.screen

import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import com.sundeefundee.app.ui.theme.*

@Composable
fun OnboardingScreen(
    onComplete: (experienceLevel: String, primaryGoal: String, weightUnit: String, cycleTrackingEnabled: Boolean) -> Unit
) {
    var step by remember { mutableIntStateOf(0) }
    var experienceLevel by remember { mutableStateOf("intermediate") }
    var primaryGoal by remember { mutableStateOf("strength") }
    var weightUnit by remember { mutableStateOf("lbs") }
    var cycleTrackingEnabled by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(Spacing.xxl),
        verticalArrangement = Arrangement.Center
    ) {
        AnimatedContent(targetState = step) { currentStep ->
            when (currentStep) {
                0 -> WelcomeStep()
                1 -> ExperienceStep(
                    selected = experienceLevel,
                    onSelect = { experienceLevel = it }
                )
                2 -> GoalStep(
                    selected = primaryGoal,
                    onSelect = { primaryGoal = it }
                )
                3 -> PreferencesStep(
                    weightUnit = weightUnit,
                    onWeightUnitChange = { weightUnit = it },
                    cycleTrackingEnabled = cycleTrackingEnabled,
                    onCycleTrackingChange = { cycleTrackingEnabled = it }
                )
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            if (step > 0) {
                ArtDecoGhostButton(text = "Back", onClick = { step-- })
            } else {
                Spacer(modifier = Modifier.width(1.dp))
            }

            ArtDecoPrimaryButton(
                text = if (step < 3) "Next" else "Get Started",
                onClick = {
                    if (step < 3) {
                        step++
                    } else {
                        onComplete(experienceLevel, primaryGoal, weightUnit, cycleTrackingEnabled)
                    }
                }
            )
        }

        Spacer(modifier = Modifier.height(Spacing.xxxl))
    }
}

@Composable
private fun WelcomeStep() {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text("Welcome to", style = MaterialTheme.typography.headlineMedium, color = TextSecondary)
        Text("Sundee Fundee", style = MaterialTheme.typography.displayLarge, color = TextPrimary)
        Spacer(modifier = Modifier.height(Spacing.lg))
        Text(
            "Cycle-aware strength training personalized for your body.",
            style = MaterialTheme.typography.bodyLarge,
            color = TextSecondary
        )
        Spacer(modifier = Modifier.height(Spacing.md))
        Text(
            "This app is not a substitute for professional medical advice. Consult your healthcare provider before starting any exercise program.",
            style = MaterialTheme.typography.bodySmall,
            color = TextSecondary
        )
    }
}

@Composable
private fun ExperienceStep(selected: String, onSelect: (String) -> Unit) {
    val options = listOf(
        "beginner" to "Beginner (< 1 year)",
        "intermediate" to "Intermediate (1-3 years)",
        "advanced" to "Advanced (3+ years)"
    )
    Column {
        Text("Experience Level", style = MaterialTheme.typography.displayMedium, color = TextPrimary)
        Spacer(modifier = Modifier.height(Spacing.lg))
        options.forEach { (value, label) ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .selectable(
                        selected = selected == value,
                        onClick = { onSelect(value) },
                        role = Role.RadioButton
                    )
                    .padding(vertical = Spacing.sm),
                verticalAlignment = Alignment.CenterVertically
            ) {
                RadioButton(selected = selected == value, onClick = { onSelect(value) })
                Spacer(modifier = Modifier.width(Spacing.md))
                Text(label, style = MaterialTheme.typography.bodyLarge, color = TextPrimary)
            }
        }
    }
}

@Composable
private fun GoalStep(selected: String, onSelect: (String) -> Unit) {
    val options = listOf(
        "strength" to "Strength",
        "hypertrophy" to "Muscle Growth",
        "endurance" to "Endurance",
        "weight_loss" to "Weight Loss"
    )
    Column {
        Text("Primary Goal", style = MaterialTheme.typography.displayMedium, color = TextPrimary)
        Spacer(modifier = Modifier.height(Spacing.lg))
        options.forEach { (value, label) ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .selectable(
                        selected = selected == value,
                        onClick = { onSelect(value) },
                        role = Role.RadioButton
                    )
                    .padding(vertical = Spacing.sm),
                verticalAlignment = Alignment.CenterVertically
            ) {
                RadioButton(selected = selected == value, onClick = { onSelect(value) })
                Spacer(modifier = Modifier.width(Spacing.md))
                Text(label, style = MaterialTheme.typography.bodyLarge, color = TextPrimary)
            }
        }
    }
}

@Composable
private fun PreferencesStep(
    weightUnit: String,
    onWeightUnitChange: (String) -> Unit,
    cycleTrackingEnabled: Boolean,
    onCycleTrackingChange: (Boolean) -> Unit
) {
    Column {
        Text("Preferences", style = MaterialTheme.typography.displayMedium, color = TextPrimary)
        Spacer(modifier = Modifier.height(Spacing.xl))

        Text("Weight Unit", style = MaterialTheme.typography.headlineMedium, color = TextPrimary)
        Spacer(modifier = Modifier.height(Spacing.sm))
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.md)) {
            FilterChip(
                selected = weightUnit == "lbs",
                onClick = { onWeightUnitChange("lbs") },
                label = { Text("lbs") }
            )
            FilterChip(
                selected = weightUnit == "kg",
                onClick = { onWeightUnitChange("kg") },
                label = { Text("kg") }
            )
        }

        Spacer(modifier = Modifier.height(Spacing.xl))

        Text("Cycle Tracking", style = MaterialTheme.typography.headlineMedium, color = TextPrimary)
        Spacer(modifier = Modifier.height(Spacing.sm))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Enable cycle tracking", style = MaterialTheme.typography.bodyLarge, color = TextPrimary)
            Switch(checked = cycleTrackingEnabled, onCheckedChange = onCycleTrackingChange)
        }
    }
}
