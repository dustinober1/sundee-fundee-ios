package com.sundeefundee.app.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Healing
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.MonitorWeight
import androidx.compose.material.icons.filled.NightsStay
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.sundeefundee.app.R
import com.sundeefundee.app.ui.screen.PlaceholderScreen

data class TabItem(
    val route: String,
    val labelResId: Int,
    val icon: ImageVector
)

val tabs = listOf(
    TabItem(TabRoutes.DASHBOARD, R.string.tab_dashboard, Icons.Filled.ShowChart),
    TabItem(TabRoutes.WORKOUTS, R.string.tab_workouts, Icons.Filled.FitnessCenter),
    TabItem(TabRoutes.PROGRAMS, R.string.tab_programs, Icons.Filled.List),
    TabItem(TabRoutes.MAXES, R.string.tab_maxes, Icons.Filled.MonitorWeight),
    TabItem(TabRoutes.PAIN, R.string.tab_pain, Icons.Filled.Healing),
    TabItem(TabRoutes.CYCLE, R.string.tab_cycle, Icons.Filled.NightsStay),
    TabItem(TabRoutes.ANALYTICS, R.string.tab_analytics, Icons.Filled.BarChart),
    TabItem(TabRoutes.BENCHMARKS, R.string.tab_benchmarks, Icons.Filled.EmojiEvents),
    TabItem(TabRoutes.SETTINGS, R.string.tab_settings, Icons.Filled.Settings),
)

@Composable
fun MainNavHost() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    Scaffold(
        bottomBar = {
            NavigationBar {
                tabs.forEach { tab ->
                    NavigationBarItem(
                        icon = { Icon(tab.icon, contentDescription = stringResource(tab.labelResId)) },
                        label = { Text(stringResource(tab.labelResId), maxLines = 1) },
                        selected = currentDestination?.hierarchy?.any { it.route == tab.route } == true,
                        onClick = {
                            navController.navigate(tab.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = TabRoutes.DASHBOARD,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(TabRoutes.DASHBOARD) { PlaceholderScreen("Dashboard") }
            composable(TabRoutes.WORKOUTS) { PlaceholderScreen("Workouts") }
            composable(TabRoutes.PROGRAMS) { PlaceholderScreen("Programs") }
            composable(TabRoutes.MAXES) { PlaceholderScreen("Maxes") }
            composable(TabRoutes.PAIN) { PlaceholderScreen("Pain") }
            composable(TabRoutes.CYCLE) { PlaceholderScreen("Cycle") }
            composable(TabRoutes.ANALYTICS) { PlaceholderScreen("Analytics") }
            composable(TabRoutes.BENCHMARKS) { PlaceholderScreen("Benchmarks") }
            composable(TabRoutes.SETTINGS) { PlaceholderScreen("Settings") }
        }
    }
}
