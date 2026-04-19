package com.sundeefundee.app.ui.screen

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Healing
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.MonitorWeight
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.sundeefundee.app.ui.theme.ArtDecoCard
import com.sundeefundee.app.ui.theme.Spacing
import com.sundeefundee.app.ui.theme.SundeeFundeeTheme

private data class MoreItem(
    val title: String,
    val icon: ImageVector,
    val onClick: () -> Unit
)

@Composable
fun MoreScreen(
    onNavigateToPrograms: () -> Unit = {},
    onNavigateToMaxes: () -> Unit = {},
    onNavigateToPain: () -> Unit = {},
    onNavigateToAnalytics: () -> Unit = {},
    onNavigateToBenchmarks: () -> Unit = {},
    onNavigateToSettings: () -> Unit = {}
) {
    val items = listOf(
        MoreItem("Programs", Icons.Filled.List, onNavigateToPrograms),
        MoreItem("Maxes", Icons.Filled.MonitorWeight, onNavigateToMaxes),
        MoreItem("Pain & Injuries", Icons.Filled.Healing, onNavigateToPain),
        MoreItem("Analytics", Icons.Filled.BarChart, onNavigateToAnalytics),
        MoreItem("Benchmarks", Icons.Filled.EmojiEvents, onNavigateToBenchmarks),
        MoreItem("Settings", Icons.Filled.Settings, onNavigateToSettings)
    )

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(Spacing.sm),
        contentPadding = PaddingValues(
            horizontal = Spacing.md,
            vertical = Spacing.md
        )
    ) {
        item {
            Text(
                "More",
                style = SundeeFundeeTheme.typography.displayLarge,
                color = SundeeFundeeTheme.colors.navy
            )
            Spacer(Modifier.height(Spacing.md))
        }

        items(items, key = { it.title }) { item ->
            MoreRow(item = item)
        }

        item {
            Spacer(Modifier.height(Spacing.xl))
        }
    }
}

@Composable
private fun MoreRow(item: MoreItem) {
    ArtDecoCard(onClick = item.onClick) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = item.onClick)
                .padding(Spacing.md),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                item.icon,
                contentDescription = item.title,
                tint = SundeeFundeeTheme.colors.navy,
                modifier = Modifier.size(24.dp)
            )
            Spacer(Modifier.width(Spacing.md))
            Text(
                item.title,
                style = SundeeFundeeTheme.typography.bodyLarge,
                color = SundeeFundeeTheme.colors.navy,
                modifier = Modifier.weight(1f)
            )
            Icon(
                Icons.Filled.ChevronRight,
                contentDescription = null,
                tint = SundeeFundeeTheme.colors.navy.copy(alpha = 0.3f),
                modifier = Modifier.size(20.dp)
            )
        }
    }
}
