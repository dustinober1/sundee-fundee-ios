import SwiftUI

// MARK: - SundeeFundeeApp
//
// Main app entry point for Sundee Fundee.
// Sets up the tab-based navigation and applies the Art Deco theme.
//
// This file should be placed in an Xcode project's main app target.

// NOTE: @main entry point is in the Xcode app project (SundeeFundeeApp/SundeeFundee/App.swift).
// This file provides the reusable views that the app wraps.

// MARK: - MainTabView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: selectedTab == .dashboard ? "chart.bar.fill" : "chart.bar")
                }
                .tag(Tab.dashboard)

            WorkoutsListView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
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

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: selectedTab == .analytics ? "chart.xyaxis.line" : "chart.xyaxis.line")
                }
                .tag(Tab.analytics)

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

public enum Tab: String {
    case dashboard
    case workouts
    case programs
    case maxes
    case analytics
    case benchmarks
    case settings
}

// MARK: - AuthView Placeholder

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct AuthView: View {
    public init() {}
    @EnvironmentObject var authViewModel: AuthViewModel

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 90))
                    .foregroundColor(AppTheme.Accent.gold)

                Text("Sundee Fundee")
                    .font(AppTheme.Typography.displayLarge)
                    .foregroundColor(AppTheme.Text.primary)

                Text("Cycle-Aware Strength Training")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
            }

            Spacer()

            VStack(spacing: AppTheme.Spacing.lg) {
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .background(AppTheme.Text.primary)
                    .cornerRadius(AppTheme.CornerRadius.large)
                }
                .buttonStyle(.plain)

                Button(action: {
                    authViewModel.continueAsGuest()
                }) {
                    Text("Continue as Guest")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                }
                .buttonStyle(.plain)

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Semantic.error)
                }
            }
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .artDecoBackground()
    }
}

// MARK: - ThemeViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public class ThemeViewModel: ObservableObject {
    public init() {}

    public func applyTheme() {
        // Configure any global theme settings here
        // For example, custom navigation bar appearance
    }
}
