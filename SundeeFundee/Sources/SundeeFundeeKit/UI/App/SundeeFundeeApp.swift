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
    @StateObject private var cyclePhaseCache = CyclePhaseCache()
    @StateObject private var sharkWeekMonitor = SharkWeekMonitor()

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: selectedTab == .dashboard ? "chart.bar.fill" : "chart.bar")
                }
                .tag(Tab.dashboard)
                .accessibilityHint("View your dashboard overview")

            WorkoutsListView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(Tab.workouts)
                .accessibilityHint("View and manage your workouts")

            ProgramsListView()
                .tabItem {
                    Label("Programs", systemImage: selectedTab == .programs ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                }
                .tag(Tab.programs)
                .accessibilityHint("Browse training programs")

            MaxesListView()
                .tabItem {
                    Label("Maxes", systemImage: selectedTab == .maxes ? "scalemass.fill" : "scalemass")
                }
                .tag(Tab.maxes)
                .accessibilityHint("View your one-rep max lifts")

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: selectedTab == .analytics ? "chart.xyaxis.line" : "chart.xyaxis.line")
                }
                .tag(Tab.analytics)
                .accessibilityHint("View training analytics and charts")

            BenchmarksListView()
                .tabItem {
                    Label("Benchmarks", systemImage: selectedTab == .benchmarks ? "trophy.fill" : "trophy")
                }
                .tag(Tab.benchmarks)
                .accessibilityHint("View fitness benchmarks")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                }
                .tag(Tab.settings)
                .accessibilityHint("View app settings")
        }
        .tint(AppTheme.Accent.gold)
        .overlay(alignment: .bottom) {
            if sharkWeekMonitor.isSharkWeek {
                SharkWeekBanner()
                    .padding(.bottom, 54)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sharkWeekMonitor.isSharkWeek)
        .environmentObject(cyclePhaseCache)
        .environmentObject(sharkWeekMonitor)
        .task {
            await cyclePhaseCache.refreshIfNeeded()
            sharkWeekMonitor.sync(with: cyclePhaseCache)
        }
        .onReceive(NotificationCenter.default.publisher(for: .cycleDataUpdated)) { _ in
            // Optimistic state is already set by the caller (e.g. CycleSettingsView).
            // .onChange(of: cyclePhaseCache.isSharkWeek) propagates to sharkWeekMonitor.
            // Delay the server-side refresh so CloudKit has time to index.
            Task {
                try? await Task.sleep(for: .seconds(2))
                await cyclePhaseCache.refresh()
                sharkWeekMonitor.sync(with: cyclePhaseCache)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
            selectedTab = .workouts
        }
        .onChange(of: cyclePhaseCache.isSharkWeek) { _, newValue in
            sharkWeekMonitor.isSharkWeek = newValue
        }
    }

    @State private var selectedTab: Tab = .dashboard
}

// MARK: - Tab Enum

// MARK: - Notifications

public extension Notification.Name {
    static let aiWorkoutStarted = Notification.Name("aiWorkoutStarted")
    static let workoutCompleted = Notification.Name("workoutCompleted")
    static let cycleDataUpdated = Notification.Name("cycleDataUpdated")
}

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
                    .accessibilityHidden(true)

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
                .accessibilityHint("Sign in using your Apple ID")

                Button(action: {
                    authViewModel.continueAsGuest()
                }) {
                    Text("Continue as Guest")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Use the app without an account")

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
@MainActor
public class ThemeViewModel: ObservableObject {
    public init() {}

    public func applyTheme() {
        // Configure any global theme settings here
        // For example, custom navigation bar appearance
    }
}
