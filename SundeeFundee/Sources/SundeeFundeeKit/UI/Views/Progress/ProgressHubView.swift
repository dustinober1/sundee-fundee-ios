import SwiftUI

// MARK: - ProgressHubView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ProgressHubView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Track") {
                    NavigationLink {
                        MaxesListView()
                    } label: {
                        Label("One-Rep Maxes", systemImage: "scalemass")
                    }

                    NavigationLink {
                        BenchmarksListView()
                    } label: {
                        Label("Benchmarks", systemImage: "trophy")
                    }
                }

                Section("Review") {
                    NavigationLink {
                        MonthlyReviewDetailView()
                    } label: {
                        Label("This Month", systemImage: "calendar.badge.clock")
                    }

                    NavigationLink {
                        AnalyticsView()
                    } label: {
                        Label("Analytics", systemImage: "chart.xyaxis.line")
                    }

                    NavigationLink {
                        ChallengesView()
                    } label: {
                        Label("Challenges", systemImage: "flag")
                    }

                    NavigationLink {
                        BuddyCheckInHistoryView()
                    } label: {
                        Label("Buddy Check-Ins", systemImage: "person.2.checkmark")
                    }
                }

                Section("Data") {
                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Progress")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
}
