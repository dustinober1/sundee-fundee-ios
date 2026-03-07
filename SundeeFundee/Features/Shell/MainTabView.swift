import SwiftData
import SwiftUI

// MARK: - MainTabView

/// Root tab shell — shown when user is authenticated (signed in or guest).
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    enum TabRoute: String, CaseIterable {
        case dashboard
        case programs
        case history
        case maxes
        case benchmarks
        case cycle
        case settings

        var title: String {
            switch self {
            case .dashboard: "Dashboard"
            case .programs: "Programs"
            case .history: "History"
            case .maxes: "Maxes"
            case .benchmarks: "Benchmarks"
            case .cycle: "Cycle"
            case .settings: "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .dashboard: "house.fill"
            case .programs: "list.bullet.rectangle.portrait.fill"
            case .history: "clock.fill"
            case .maxes: "dumbbell.fill"
            case .benchmarks: "checkmark.seal.fill"
            case .cycle: "circle.dotted"
            case .settings: "gearshape.fill"
            }
        }
    }

    static var orderedTabs: [TabRoute] { orderedTabs(for: nil) }

    static func orderedTabs(for gender: Gender?) -> [TabRoute] {
        var tabs: [TabRoute] = [.dashboard, .history, .maxes, .benchmarks]
        if gender != .male {
            tabs.append(.cycle)
        }
        tabs.append(.settings)
        return tabs
    }
    @Query private var users: [User]

    private var currentGender: Gender? {
        users.first?.gender
    }

    private let destinationBuilder: (TabRoute) -> AnyView

    init(destinationBuilder: @escaping (TabRoute) -> AnyView = { tab in
        AnyView(Self.destination(for: tab))
    }) {
        self.destinationBuilder = destinationBuilder
    }

    var body: some View {
        let aiService = SwiftDataAIWorkoutService(modelContext: modelContext)
        TabView {
            ForEach(Self.orderedTabs(for: currentGender), id: \.self) { tab in
                NavigationStack {
                    if tab == .history {
                        WorkoutHistoryView(
                            userID: users.first?.id ?? "",
                            aiService: aiService
                        )
                    } else {
                        destinationBuilder(tab)
                    }
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
            }
        }
        .tint(AppTheme.Colors.accentOrange)
    }

    @ViewBuilder
    static func destination(for tab: TabRoute) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .programs:
            ProgramListView()
        case .history:
            // WorkoutHistoryView requires a modelContext-aware service;
            // use AIWorkoutHistoryPlaceholderView as the static destination.
            // The real WorkoutHistoryView is composed in MainTabView.body where modelContext is available.
            AIWorkoutHistoryPlaceholderView()
        case .maxes:
            MaxLiftsView()
        case .benchmarks:
            BenchmarksView()
        case .cycle:
            CycleTrackingView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Placeholder views (replaced in later phases)

struct AIWorkoutHistoryPlaceholderView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            ContentUnavailableView(
                "No Workouts Yet",
                systemImage: "dumbbell",
                description: Text("Generate your first AI workout to see it here.")
            )
        }
        .navigationTitle("History")
    }
}

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
