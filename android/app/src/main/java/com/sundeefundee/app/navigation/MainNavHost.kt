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
import com.sundeefundee.app.ui.screen.*

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

// Routes that should hide the bottom bar
private val fullScreenRoutes = setOf(
    TabRoutes.ACTIVE_WORKOUT,
    TabRoutes.AI_WORKOUT
)

@Composable
fun MainNavHost() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    Scaffold(
        bottomBar = {
            if (currentDestination?.route !in fullScreenRoutes) {
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
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = TabRoutes.DASHBOARD,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(TabRoutes.DASHBOARD) {
                DashboardScreen(
                    onNavigateToWorkouts = { navController.navigate(TabRoutes.WORKOUTS) },
                    onNavigateToMaxes = { navController.navigate(TabRoutes.MAXES) },
                    onNavigateToPain = { navController.navigate(TabRoutes.PAIN) },
                    onNavigateToBenchmarks = { navController.navigate(TabRoutes.BENCHMARKS) },
                    onNavigateToChallenges = { navController.navigate(TabRoutes.BENCHMARKS) },
                    onNavigateToCycle = { navController.navigate(TabRoutes.CYCLE) },
                    onNavigateToInsights = { navController.navigate(TabRoutes.INSIGHTS) },
                    onNavigateToAIWorkout = { navController.navigate(TabRoutes.AI_WORKOUT) }
                )
            }
            composable(TabRoutes.WORKOUTS) {
                WorkoutsScreen(
                    onStartWorkout = { navController.navigate(TabRoutes.ACTIVE_WORKOUT) },
                    onWorkoutClick = { /* TODO: workout detail */ }
                )
            }
            composable(TabRoutes.ACTIVE_WORKOUT) {
                ActiveWorkoutScreen(
                    onFinish = { navController.popBackStack() }
                )
            }
            composable(TabRoutes.PROGRAMS) {
                ProgramsScreen(
                    onEnroll = { /* TODO: enroll in program */ }
                )
            }
            composable(TabRoutes.MAXES) { MaxesScreen() }
            composable(TabRoutes.PAIN) { PainScreen() }
            composable(TabRoutes.CYCLE) { CycleScreen() }
            composable(TabRoutes.ANALYTICS) { AnalyticsScreen() }
            composable(TabRoutes.BENCHMARKS) { BenchmarksScreen() }
            composable(TabRoutes.SETTINGS) {
                SettingsScreen(
                    onSignOut = { /* TODO: navigate to auth */ }
                )
            }
            composable(TabRoutes.INSIGHTS) { InsightsScreen() }
            composable(TabRoutes.AI_WORKOUT) {
                // TODO: AI Workout generation screen
                PlaceholderScreen("AI Workout")
            }
        }
    }
}
