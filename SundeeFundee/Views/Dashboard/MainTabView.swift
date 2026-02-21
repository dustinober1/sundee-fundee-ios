import SwiftUI
import SwiftData

struct MainTabView: View {
    @Query private var users: [User]

    private var showCycleTab: Bool {
        users.first?.gender == .female
    }

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            ProgramsListView()
                .tabItem {
                    Label("Programs", systemImage: "list.bullet.rectangle.fill")
                }

            ProgressDashboardView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            if showCycleTab {
                CycleTrackerView()
                    .tabItem {
                        Label("Cycle", systemImage: "drop.fill")
                    }
            }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: User.self, inMemory: true)
}
