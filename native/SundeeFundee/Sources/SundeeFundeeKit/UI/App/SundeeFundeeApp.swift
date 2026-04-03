import SwiftUI

// MARK: - SundeeFundeeApp
//
// Main app entry point for Sundee Fundee.
// Sets up the tab-based navigation and applies the Art Deco theme.
//
// This file should be placed in an Xcode project's main app target.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct SundeeFundeeApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeViewModel = ThemeViewModel()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeViewModel)
                } else {
                    AuthView()
                        .environmentObject(authViewModel)
                }
            }
            .artDecoBackground()
            .onAppear {
                themeViewModel.applyTheme()
            }
        }
    }
}

// MARK: - MainTabView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: selectedTab == .dashboard ? "chart.bar.fill" : "chart.bar")
                }
                .tag(Tab.dashboard)

            WorkoutsListView()
                .tabItem {
                    Label("Workouts", systemImage: selectedTab == .workouts ? "figure.strengthtraining.traditional.fill" : "figure.strengthtraining.traditional")
                }
                .tag(Tab.workouts)

            ProgramsListView()
                .tabItem {
                    Label("Programs", systemImage: selectedTab == .programs ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                }
                .tag(Tab.programs)

            MaxesListView()
                .tabItem {
                    Label("Maxes", systemImage: selectedTab == .maxes ? "scalemass.fill" : "scalemass")
                }
                .tag(Tab.maxes)

            BenchmarksListView()
                .tabItem {
                    Label("Benchmarks", systemImage: selectedTab == .benchmarks ? "trophy.fill" : "trophy")
                }
                .tag(Tab.benchmarks)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(AppTheme.Accent.gold)
    }

    @State private var selectedTab: Tab = .dashboard
}

// MARK: - Tab Enum

enum Tab: String {
    case dashboard
    case workouts
    case programs
    case maxes
    case benchmarks
    case settings
}

// MARK: - AuthView Placeholder

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Accent.gold)

            Text("Sundee Fundee")
                .font(AppTheme.Typography.displayMedium)
                .foregroundColor(AppTheme.Text.primary)

            Text("Cycle-Aware Strength Training")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)

            Button(action: {
                Task {
                    await authViewModel.signInWithApple()
                }
            }) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 20))
                    Text("Sign in with Apple")
                        .font(AppTheme.Typography.labelLarge)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(AppTheme.Text.primary)
                .cornerRadius(AppTheme.CornerRadius.large)
            }
            .buttonStyle(.plain)

            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Semantic.error)
                    .padding()
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .artDecoBackground()
    }
}

// MARK: - ThemeViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
class ThemeViewModel: ObservableObject {
    func applyTheme() {
        // Configure any global theme settings here
        // For example, custom navigation bar appearance
    }
}
