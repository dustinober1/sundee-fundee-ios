import SwiftUI

/// Root tab shell — shown when user is authenticated (signed in or guest).
struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardPlaceholderView()
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
                WorkoutsPlaceholderView()
            }
            .tabItem {
                Label("Workouts", systemImage: "dumbbell.fill")
            }

            NavigationStack {
                CyclePlaceholderView()
            }
            .tabItem {
                Label("Cycle", systemImage: "circle.dotted")
            }

            NavigationStack {
                SettingsPlaceholderView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(AppTheme.Colors.accentOrange)
    }
}

// MARK: - Placeholder views (replaced in later phases)

struct DashboardPlaceholderView: View {
    var body: some View {
        Text("Dashboard").navigationTitle("Dashboard")
    }
}

struct WorkoutsPlaceholderView: View {
    var body: some View {
        Text("Workouts").navigationTitle("Workouts")
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
