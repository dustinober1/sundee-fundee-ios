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
import com.sundeefundee.core.domain.program.ProgramTemplate
import com.sundeefundee.core.domain.program.ProgramTemplateGenerator

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProgramsScreen(
    onEnroll: (String) -> Unit = {},
    viewModel: ProgramsViewModel = hiltViewModel()
) {
    val enrolledPrograms by viewModel.enrolledPrograms.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadData() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Programs") },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = SundeeFundeeTheme.colors.cream)
            )
        }
    ) { padding ->
        LazyColumn(
            Modifier.fillMaxSize().padding(padding).padding(horizontal = Spacing.md),
            verticalArrangement = Arrangement.spacedBy(Spacing.md),
            contentPadding = PaddingValues(vertical = Spacing.md)
        ) {
            // Active Program
            enrolledPrograms.firstOrNull()?.let { program ->
                item {
                    ArtDecoCard {
                        Column(Modifier.padding(Spacing.md)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.FitnessCenter, contentDescription = null, tint = SundeeFundeeTheme.colors.orange)
                                Spacer(Modifier.width(Spacing.sm))
                                Text("Active Program", style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.orange)
                            }
                            Spacer(Modifier.height(Spacing.sm))
                            Text(program.programName, style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                            if (program.isActive) {
                                Text("In Progress", style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.gold)
                            }
                        }
                    }
                }
            }

            // Available Templates
            item {
                Text("Available Programs", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                Spacer(Modifier.height(Spacing.sm))
            }

            items(ProgramTemplate.entries.toList()) { template ->
                ProgramTemplateCard(template = template, onEnroll = { onEnroll(template.name) })
            }
        }
    }
}

@Composable
private fun ProgramTemplateCard(template: ProgramTemplate, onEnroll: () -> Unit) {
    ArtDecoCard {
        Column(Modifier.padding(Spacing.md)) {
            Text(template.displayName, style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
            Text(template.description, style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.6f))
            Spacer(Modifier.height(Spacing.sm))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                Text("${template.defaults.durationWeeks} weeks", style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.gold)
                Text("${template.defaults.sessionsPerWeek}x/week", style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.gold)
            }
            Spacer(Modifier.height(Spacing.md))
            ArtDecoAccentButton(onClick = onEnroll) {
                Text("Enroll")
            }
        }
    }
}

private val ProgramTemplate.displayName: String
    get() = name.replace("_", " ").lowercase().replaceFirstChar { it.uppercase() }

private val ProgramTemplate.description: String
    get() = when (this) {
        ProgramTemplate.FIRST_MARGARITA -> "The perfect beginner program — 8 weeks of progressive overload"
        ProgramTemplate.STRENGTH -> "Heavy compound focus for maximal strength gains"
        ProgramTemplate.HYPERTROPHY -> "Higher volume for muscle growth"
        ProgramTemplate.FULL_BODY -> "3x/week full body training"
        ProgramTemplate.LINEAR -> "Classic linear periodization"
        ProgramTemplate.DUP -> "Daily undulating periodization for advanced lifters"
        ProgramTemplate.BLOCK -> "Block periodization for peaking"
    }
