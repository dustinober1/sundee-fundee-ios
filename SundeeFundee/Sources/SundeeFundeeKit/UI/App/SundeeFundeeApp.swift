import StoreKit
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
    @Environment(\.requestReview) private var requestReview
    @StateObject private var cyclePhaseCache = CyclePhaseCache()
    @StateObject private var sharkWeekMonitor = SharkWeekMonitor()

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: selectedTab == .today ? "sun.max.fill" : "sun.max")
                }
                .tag(Tab.today)
                .accessibilityHint("View today's training plan")

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

            CycleTrackingView()
                .tabItem {
                    Label("Cycle", systemImage: selectedTab == .cycle ? "moon.circle.fill" : "moon.circle")
                }
                .tag(Tab.cycle)
                .accessibilityHint("Track cycle, pain, and recovery")

            ProgressHubView()
                .tabItem {
                    Label("Progress", systemImage: "chart.xyaxis.line")
                }
                .tag(Tab.progress)
                .accessibilityHint("View maxes, analytics, benchmarks, challenges, and data export")
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
        .onReceive(NotificationCenter.default.publisher(for: .appReviewPromptRequested)) { _ in
            requestReview()
        }
        .onReceive(NotificationCenter.default.publisher(for: .startWorkoutFromIntent)) { _ in
            selectedTab = .workouts
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutReminderOpened)) { notification in
            if let route = notification.object as? String, route == "workouts" {
                selectedTab = .workouts
            } else {
                selectedTab = .today
            }
        }
        .onChange(of: cyclePhaseCache.isSharkWeek) { _, newValue in
            sharkWeekMonitor.isSharkWeek = newValue
        }
    }

    @State private var selectedTab: Tab = .today
}

// MARK: - Tab Enum

// MARK: - Notifications

public extension Notification.Name {
    static let aiWorkoutStarted = Notification.Name("aiWorkoutStarted")
    static let workoutCompleted = Notification.Name("workoutCompleted")
    static let appReviewPromptRequested = Notification.Name("appReviewPromptRequested")
    static let workoutReminderOpened = Notification.Name("workoutReminderOpened")
    static let cycleDataUpdated = Notification.Name("cycleDataUpdated")
}

public enum Tab: String {
    case today
    case workouts
    case programs
    case cycle
    case progress
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
                    .font(.system(.largeTitle))
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
                            .font(.headline)
                        Text("Sign in with Apple")
                            .font(AppTheme.Typography.labelLarge)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .background(AppTheme.Background.navy)
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
