package com.sundeefundee.app.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.NightsStay
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
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
import com.sundeefundee.app.ui.theme.SundeeFundeeTheme

data class TabItem(
    val route: String,
    val labelResId: Int,
    val icon: ImageVector
)

val tabs = listOf(
    TabItem(TabRoutes.DASHBOARD, R.string.tab_dashboard, Icons.Filled.ShowChart),
    TabItem(TabRoutes.WORKOUTS, R.string.tab_workouts, Icons.Filled.FitnessCenter),
    TabItem(TabRoutes.CYCLE, R.string.tab_cycle, Icons.Filled.NightsStay),
    TabItem(TabRoutes.MORE, R.string.tab_more, Icons.Filled.Menu),
)

// Routes that should hide the bottom bar
private val fullScreenRoutes = setOf(
    TabRoutes.ACTIVE_WORKOUT,
    TabRoutes.AI_WORKOUT
)

private val routeTitleMap = mapOf(
    TabRoutes.DASHBOARD to "Dashboard",
    TabRoutes.WORKOUTS to "Workouts",
    TabRoutes.CYCLE to "Cycle",
    TabRoutes.MORE to "More",
    TabRoutes.PROGRAMS to "Programs",
    TabRoutes.MAXES to "Maxes",
    TabRoutes.PAIN to "Pain & Injuries",
    TabRoutes.ANALYTICS to "Analytics",
    TabRoutes.BENCHMARKS to "Benchmarks",
    TabRoutes.SETTINGS to "Settings",
    TabRoutes.INSIGHTS to "Insights",
    TabRoutes.ACTIVE_WORKOUT to "Active Workout",
    TabRoutes.AI_WORKOUT to "AI Workout"
)

@Composable
fun MainNavHost() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    val currentRoute = currentDestination?.route
    val showBottomBar = currentRoute !in fullScreenRoutes
    val topBarTitle = routeTitleMap[currentRoute] ?: ""

    Scaffold(
        topBar = {
            if (currentRoute !in fullScreenRoutes && topBarTitle.isNotEmpty()) {
                TopAppBar(
                    title = {
                        Text(
                            topBarTitle,
                            style = SundeeFundeeTheme.typography.headlineLarge
                        )
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = SundeeFundeeTheme.colors.cream
                    )
                )
            }
        },
        bottomBar = {
            if (showBottomBar) {
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
            composable(TabRoutes.MORE) {
                MoreScreen(
                    onNavigateToPrograms = { navController.navigate(TabRoutes.PROGRAMS) },
                    onNavigateToMaxes = { navController.navigate(TabRoutes.MAXES) },
                    onNavigateToPain = { navController.navigate(TabRoutes.PAIN) },
                    onNavigateToAnalytics = { navController.navigate(TabRoutes.ANALYTICS) },
                    onNavigateToBenchmarks = { navController.navigate(TabRoutes.BENCHMARKS) },
                    onNavigateToSettings = { navController.navigate(TabRoutes.SETTINGS) }
                )
            }
        }
    }
}
