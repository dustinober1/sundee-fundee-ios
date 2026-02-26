import SwiftUI

/// Root tab shell — shown when user is authenticated (signed in or guest).
struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }

            NavigationStack {
                ProgramListView()
            }
            .tabItem {
                Label("Programs", systemImage: "list.bullet.rectangle.portrait.fill")
            }

            NavigationStack {
                MaxLiftsView()
            }
            .tabItem {
                Label("Maxes", systemImage: "dumbbell.fill")
            }

            NavigationStack {
                BenchmarksView()
            }
            .tabItem {
                Label("Benchmarks", systemImage: "checkmark.seal.fill")
            }

            NavigationStack {
                CycleTrackingView()
            }
            .tabItem {
                Label("Cycle", systemImage: "circle.dotted")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(AppTheme.Colors.accentOrange)
    }
}

// MARK: - Placeholder views (replaced in later phases)

struct WorkoutsPlaceholderView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            ContentUnavailableView(
                "Start from Programs",
                systemImage: "dumbbell.fill",
                description: Text("Enroll in a program and tap Start Workout from the Dashboard.")
            )
        }
        .navigationTitle("Workouts")
    }
}

struct CyclePlaceholderView: View {
    var body: some View {
        Text("Cycle Tracking").navigationTitle("Cycle")
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        Text("Settings").navigationTitle("Settings")
    }
}
