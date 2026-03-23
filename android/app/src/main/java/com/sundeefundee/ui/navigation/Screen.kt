package com.sundeefundee.ui.navigation

/**
 * Defines all navigation routes in the app.
 */
sealed class Screen(val route: String) {
    data object SignIn : Screen("sign_in")
    data object Main : Screen("main")
    data object Dashboard : Screen("dashboard")
    data object Programs : Screen("programs")
    data object ProgramDetail : Screen("program/{programId}") {
        fun createRoute(programId: String) = "program/$programId"
    }
    data object Workouts : Screen("workouts")
    data object WorkoutExecution : Screen("workout_execution/{workoutId}") {
        fun createRoute(workoutId: String) = "workout_execution/$workoutId"
    }
    data object Cycle : Screen("cycle")
    data object Maxes : Screen("maxes")
    data object Benchmarks : Screen("benchmarks")
    data object Settings : Screen("settings")
}

/**
 * Bottom navigation items for the main screen.
 */
enum class BottomNavItem(
    val route: String,
    val title: String,
    val icon: String
) {
    DASHBOARD("dashboard", "Dashboard", "home"),
    PROGRAMS("programs", "Programs", "fitness_center"),
    WORKOUTS("workouts", "Workouts", "sports_gymnastics"),
    CYCLE("cycle", "Cycle", "loop"),
    MORE("more", "More", "more_horiz")
}

/**
 * More menu items shown in a dropdown or separate screen.
 */
enum class MoreMenuItem(
    val route: String,
    val title: String,
    val icon: String
) {
    MAXES("maxes", "Maxes", "trending_up"),
    BENCHMARKS("benchmarks", "Benchmarks", "emoji_events"),
    SETTINGS("settings", "Settings", "settings")
}
