import SwiftData
import SwiftUI

/// Root tab shell — shown when user is authenticated (signed in or guest).
struct MainTabView: View {
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
        TabView {
            ForEach(Self.orderedTabs(for: currentGender), id: \.self) { tab in
                NavigationStack {
                    destinationBuilder(tab)
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
            HistoryTabWrapper()
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

// MARK: - History Tab Wrapper

/// Wraps WorkoutHistoryView with environment-derived dependencies.
private struct HistoryTabWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    var body: some View {
        let userID = users.first?.appleUserID ?? ""
        let aiService = SwiftDataAIWorkoutService(modelContext: modelContext)
        WorkoutHistoryView(userID: userID, aiService: aiService)
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
