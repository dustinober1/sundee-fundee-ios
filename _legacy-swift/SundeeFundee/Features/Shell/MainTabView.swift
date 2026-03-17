import SwiftData
import SwiftUI

// MARK: - MainTabView

/// Root tab shell — shown when user is authenticated (signed in or guest).
/// Uses exactly 5 tabs to avoid UIKit's auto-generated "More" tab,
/// which nests its own UINavigationController and causes double back buttons.
struct MainTabView: View {
    enum TabRoute: String, CaseIterable {
        case dashboard
        case programs
        case wods
        case history
        case more

        var title: String {
            switch self {
            case .dashboard: "Dashboard"
            case .programs: "Programs"
            case .wods: "WODs"
            case .history: "History"
            case .more: "More"
            }
        }

        var systemImage: String {
            switch self {
            case .dashboard: "house.fill"
            case .programs: "list.bullet.rectangle.portrait.fill"
            case .wods: "flame.fill"
            case .history: "clock.fill"
            case .more: "ellipsis.circle.fill"
            }
        }
    }

    /// Routes available inside the "More" tab.
    enum MoreRoute: String, Hashable {
        case maxes
        case benchmarks
        case cycle
        case settings

        var title: String {
            switch self {
            case .maxes: "Maxes"
            case .benchmarks: "Benchmarks"
            case .cycle: "Cycle"
            case .settings: "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .maxes: "dumbbell.fill"
            case .benchmarks: "checkmark.seal.fill"
            case .cycle: "circle.dotted"
            case .settings: "gearshape.fill"
            }
        }
    }

    static let primaryTabs: [TabRoute] = [.dashboard, .programs, .wods, .history, .more]

    static func moreRoutes(for gender: Gender?) -> [MoreRoute] {
        var routes: [MoreRoute] = [.maxes, .benchmarks]
        if gender != .male {
            routes.append(.cycle)
        }
        routes.append(.settings)
        return routes
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
            ForEach(Self.primaryTabs, id: \.self) { tab in
                NavigationStack {
                    if tab == .more {
                        MoreTabView(gender: currentGender)
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
        case .wods:
            WODsView()
        case .history:
            HistoryTabView()
        case .more:
            EmptyView()
        }
    }

    @ViewBuilder
    static func moreDestination(for route: MoreRoute) -> some View {
        switch route {
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

// MARK: - MoreTabView

/// Custom "More" list that lives inside a single NavigationStack,
/// avoiding the double-navigation-controller issue.
struct MoreTabView: View {
    let gender: Gender?

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            List {
                ForEach(MainTabView.moreRoutes(for: gender), id: \.self) { route in
                    NavigationLink(value: route) {
                        Label(route.title, systemImage: route.systemImage)
                            .font(AppTheme.Fonts.body)
                            .foregroundStyle(AppTheme.Colors.navy)
                    }
                    .listRowBackground(AppTheme.Colors.cream)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("More")
        .navigationDestination(for: MainTabView.MoreRoute.self) { route in
            MainTabView.moreDestination(for: route)
        }
    }
}

// MARK: - Placeholder views (replaced in later phases)

/// Wrapper that defers `SwiftDataAIWorkoutService` construction until the view
/// renders, so it can capture `modelContext` from the environment.
struct HistoryTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    private var currentUser: User? { users.first }

    var body: some View {
        UnifiedHistoryView(
            viewModel: UnifiedHistoryViewModel(
                userID: currentUser?.id ?? "",
                aiService: SwiftDataAIWorkoutService(
                    modelContext: modelContext,
                    sharedRepository: FileManager.default.ubiquityIdentityToken != nil
                        ? CloudKitSharedWorkoutRepository(modelContext: modelContext)
                        : nil
                ),
                workoutRepo: SwiftDataWorkoutRepository(context: modelContext),
                programRepo: CloudKitProgramRepository()
            )
        )
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
