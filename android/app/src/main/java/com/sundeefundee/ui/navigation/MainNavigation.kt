package com.sundeefundee.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Loop
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SportsGymnastics
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.sundeefundee.ui.features.benchmarks.BenchmarksScreen
import com.sundeefundee.ui.features.cycle.CycleScreen
import com.sundeefundee.ui.features.dashboard.DashboardScreen
import com.sundeefundee.ui.features.maxes.MaxesScreen
import com.sundeefundee.ui.features.programs.ProgramDetailScreen
import com.sundeefundee.ui.features.programs.ProgramsScreen
import com.sundeefundee.ui.features.settings.SettingsScreen
import com.sundeefundee.ui.features.workouts.WorkoutExecutionScreen
import com.sundeefundee.ui.features.workouts.WorkoutsScreen
import com.sundeefundee.ui.theme.Primary
import com.sundeefundee.ui.theme.Secondary
import com.sundeefundee.ui.theme.Tertiary

/**
 * Main navigation host composable that sets up the bottom navigation
 * and the navigation graph for all app screens.
 */
@Composable
fun MainNavigation(
    navController: NavHostController = rememberNavController(),
    onSignOut: () -> Unit
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    // Routes that should show the bottom navigation bar
    val showBottomBar = currentDestination?.route in listOf(
        Screen.Dashboard.route,
        Screen.Programs.route,
        Screen.Workouts.route,
        Screen.Cycle.route,
        Screen.Maxes.route,
        Screen.Benchmarks.route,
        Screen.Settings.route
    )

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                MainBottomNavigation(
                    currentRoute = currentDestination?.route,
                    onNavigate = { route ->
                        navController.navigate(route) {
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
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = Screen.Dashboard.route,
            modifier = Modifier.padding(paddingValues)
        ) {
            // Dashboard
            composable(Screen.Dashboard.route) {
                DashboardScreen(
                    onNavigateToWorkoutExecution = { workoutId ->
                        navController.navigate(Screen.WorkoutExecution.createRoute(workoutId))
                    },
                    onNavigateToPrograms = {
                        navController.navigate(Screen.Programs.route)
                    }
                )
            }

            // Programs
            composable(Screen.Programs.route) {
                ProgramsScreen(
                    onNavigateToProgramDetail = { programId ->
                        navController.navigate(Screen.ProgramDetail.createRoute(programId))
                    }
                )
            }

            composable(
                route = Screen.ProgramDetail.route,
                arguments = listOf(navArgument("programId") { type = NavType.StringType })
            ) { backStackEntry ->
                val programId = backStackEntry.arguments?.getString("programId") ?: ""
                ProgramDetailScreen(
                    programId = programId,
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToWorkoutExecution = { workoutId ->
                        navController.navigate(Screen.WorkoutExecution.createRoute(workoutId))
                    }
                )
            }

            // Workouts
            composable(Screen.Workouts.route) {
                WorkoutsScreen(
                    onNavigateToWorkoutExecution = { workoutId ->
                        navController.navigate(Screen.WorkoutExecution.createRoute(workoutId))
                    }
                )
            }

            composable(
                route = Screen.WorkoutExecution.route,
                arguments = listOf(navArgument("workoutId") { type = NavType.StringType })
            ) { backStackEntry ->
                val workoutId = backStackEntry.arguments?.getString("workoutId") ?: ""
                WorkoutExecutionScreen(
                    workoutId = workoutId,
                    onNavigateBack = { navController.popBackStack() },
                    onWorkoutComplete = {
                        navController.popBackStack(Screen.Workouts.route, inclusive = false)
                    }
                )
            }

            // Cycle
            composable(Screen.Cycle.route) {
                CycleScreen()
            }

            // More section
            composable(Screen.Maxes.route) {
                MaxesScreen()
            }

            composable(Screen.Benchmarks.route) {
                BenchmarksScreen()
            }

            composable(Screen.Settings.route) {
                SettingsScreen(onSignOut = onSignOut)
            }
        }
    }
}

/**
 * Bottom navigation bar with 5 main tabs.
 */
@Composable
fun MainBottomNavigation(
    currentRoute: String?,
    onNavigate: (String) -> Unit
) {
    val items = listOf(
        BottomNavItem.DASHBOARD,
        BottomNavItem.PROGRAMS,
        BottomNavItem.WORKOUTS,
        BottomNavItem.CYCLE,
        BottomNavItem.MORE
    )

    // Determine selected index based on current route
    val selectedIndex = when {
        currentRoute == BottomNavItem.DASHBOARD.route -> 0
        currentRoute == BottomNavItem.PROGRAMS.route -> 1
        currentRoute == BottomNavItem.WORKOUTS.route -> 2
        currentRoute == BottomNavItem.CYCLE.route -> 3
        currentRoute in listOf(
            BottomNavItem.MORE.route,
            Screen.Maxes.route,
            Screen.Benchmarks.route,
            Screen.Settings.route
        ) -> 4
        else -> 0
    }

    NavigationBar(
        containerColor = Secondary
    ) {
        items.forEachIndexed { index, item ->
            val icon = getIconForNavItem(item)
            val selected = index == selectedIndex

            NavigationBarItem(
                icon = { Icon(icon, contentDescription = item.title) },
                label = { Text(item.title) },
                selected = selected,
                onClick = {
                    if (item == BottomNavItem.MORE) {
                        // Navigate to maxes as default for "More" section
                        onNavigate(Screen.Maxes.route)
                    } else {
                        onNavigate(item.route)
                    }
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = Primary,
                    selectedTextColor = Primary,
                    indicatorColor = Tertiary.copy(alpha = 0.2f)
                )
            )
        }
    }
}

/**
 * Gets the appropriate icon for a bottom nav item.
 */
private fun getIconForNavItem(item: BottomNavItem): ImageVector {
    return when (item) {
        BottomNavItem.DASHBOARD -> Icons.Default.Home
        BottomNavItem.PROGRAMS -> Icons.Default.FitnessCenter
        BottomNavItem.WORKOUTS -> Icons.Default.SportsGymnastics
        BottomNavItem.CYCLE -> Icons.Default.Loop
        BottomNavItem.MORE -> Icons.Default.MoreHoriz
    }
}

/**
 * Gets icon for more menu items.
 */
fun getIconForMoreMenuItem(item: MoreMenuItem): ImageVector {
    return when (item) {
        MoreMenuItem.MAXES -> Icons.Default.TrendingUp
        MoreMenuItem.BENCHMARKS -> Icons.Default.EmojiEvents
        MoreMenuItem.SETTINGS -> Icons.Default.Settings
    }
}
