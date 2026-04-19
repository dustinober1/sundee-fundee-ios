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
import com.sundeefundee.app.ui.theme.MonoMedium
import com.sundeefundee.app.viewmodel.ChallengesViewModel
import com.sundeefundee.core.model.Challenge
import com.sundeefundee.core.model.ChallengeProgress
import com.sundeefundee.core.model.ChallengeType

@Composable
fun ChallengesScreen(
    viewModel: ChallengesViewModel = hiltViewModel()
) {
    val challenges by viewModel.challenges.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val showCreate by viewModel.showCreateDialog.collectAsState()

    var createTitle by remember { mutableStateOf("") }
    var createTarget by remember { mutableStateOf("") }
    var createType by remember { mutableStateOf(ChallengeType.CUSTOM) }

    LaunchedEffect(Unit) { viewModel.loadData() }

    Box(Modifier.fillMaxSize()) {
        if (isLoading) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = SundeeFundeeTheme.colors.navy)
            }
        } else if (challenges.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Default.Flag, contentDescription = null, modifier = Modifier.size(64.dp), tint = SundeeFundeeTheme.colors.navy.copy(alpha = 0.3f))
                    Spacer(Modifier.height(Spacing.md))
                    Text("No challenges yet", style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
                }
            }
        } else {
            LazyColumn(
                Modifier.fillMaxSize().padding(horizontal = Spacing.md),
                verticalArrangement = Arrangement.spacedBy(Spacing.md),
                contentPadding = PaddingValues(vertical = Spacing.md)
            ) {
                items(challenges, key = { it.first.id }) { (challenge, progress) ->
                    ChallengeCard(challenge = challenge, progress = progress)
                }
            }
        }

        FloatingActionButton(
            onClick = { viewModel.showCreate() },
            containerColor = SundeeFundeeTheme.colors.orange,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(Spacing.md)
        ) {
            Icon(Icons.Default.Add, contentDescription = "Create Challenge", tint = SundeeFundeeTheme.colors.cream)
        }
    }

    // Create Challenge Dialog
    if (showCreate) {
        AlertDialog(
            onDismissRequest = { viewModel.dismissCreate() },
            title = { Text("Create Challenge") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                    OutlinedTextField(value = createTitle, onValueChange = { createTitle = it }, label = { Text("Title") })
                    OutlinedTextField(value = createTarget, onValueChange = { createTarget = it }, label = { Text("Target Volume (lbs)") })
                    Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                        ChallengeType.entries.forEach { type ->
                            FilterChip(
                                selected = createType == type,
                                onClick = { createType = type },
                                label = { Text(type.name.lowercase().replaceFirstChar { it.uppercase() }) }
                            )
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    if (createTitle.isNotBlank()) {
                        viewModel.createChallenge(createTitle, createTarget.toDoubleOrNull() ?: 100000.0, createType)
                        createTitle = ""
                        createTarget = ""
                    }
                }) { Text("Create") }
            },
            dismissButton = { TextButton(onClick = { viewModel.dismissCreate() }) { Text("Cancel") } }
        )
    }
}

@Composable
private fun ChallengeCard(challenge: Challenge, progress: ChallengeProgress) {
    ArtDecoCard {
        Column(Modifier.padding(Spacing.md)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.EmojiEvents, contentDescription = null, tint = SundeeFundeeTheme.colors.gold)
                Spacer(Modifier.width(Spacing.sm))
                Column(Modifier.weight(1f)) {
                    Text(challenge.title, style = SundeeFundeeTheme.typography.headlineMedium, color = SundeeFundeeTheme.colors.navy)
                    Text(challenge.type.name.lowercase().replaceFirstChar { it.uppercase() }, style = SundeeFundeeTheme.typography.bodySmall, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
                }
                Text(progress.currentTierName, style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.gold)
            }
            Spacer(Modifier.height(Spacing.sm))
            LinearProgressIndicator(
                progress = { progress.percentComplete.toFloat().coerceIn(0f, 1f) },
                modifier = Modifier.fillMaxWidth().height(6.dp),
                color = SundeeFundeeTheme.colors.gold,
                trackColor = SundeeFundeeTheme.colors.navy.copy(alpha = 0.1f)
            )
            Spacer(Modifier.height(Spacing.xs))
            Row(Modifier.fillMaxWidth()) {
                Text("${(progress.percentComplete * 100).toInt()}%", style = MonoMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
                Spacer(Modifier.weight(1f))
                Text("${"%,.0f".format(progress.volumeRemaining)} lbs to go", style = SundeeFundeeTheme.typography.labelMedium, color = SundeeFundeeTheme.colors.navy.copy(alpha = 0.5f))
            }
        }
    }
}
