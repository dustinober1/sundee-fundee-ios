import SwiftUI

// MARK: - ProgressHubView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ProgressHubView: View {
    @State private var destinations: [ProgressDestination] = [.export]
    @State private var isLoading = true

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    NavigationLink {
                        MonthlyReviewDetailView()
                    } label: {
                        Label("Monthly Review", systemImage: "calendar.badge.clock")
                    }
                }

                if isLoading {
                    Section {
                        ProgressView("Loading progress...")
                    }
                }

                if destinations.contains(.analytics) {
                    Section("Review") {
                        NavigationLink {
                            AnalyticsView()
                        } label: {
                            Label("Analytics", systemImage: "chart.xyaxis.line")
                        }
                    }
                }

                if destinations.contains(.maxes) || destinations.contains(.benchmarks) {
                    Section("Track") {
                        if destinations.contains(.maxes) {
                            NavigationLink {
                                MaxesListView()
                            } label: {
                                Label("One-Rep Maxes", systemImage: "scalemass")
                            }
                        }

                        if destinations.contains(.benchmarks) {
                            NavigationLink {
                                BenchmarksListView()
                            } label: {
                                Label("Benchmarks", systemImage: "trophy")
                            }
                        }
                    }
                }

                if destinations.contains(.challenges) || destinations.contains(.buddyCheckIns) {
                    Section("Community") {
                        if destinations.contains(.challenges) {
                            NavigationLink {
                                ChallengesView()
                            } label: {
                                Label("Challenges", systemImage: "flag")
                            }
                        }

                        if destinations.contains(.buddyCheckIns) {
                            NavigationLink {
                                BuddyCheckInHistoryView()
                            } label: {
                                Label("Buddy Check-Ins", systemImage: "person.2.checkmark")
                            }
                        }
                    }
                }

                if destinations.contains(.export) {
                    Section("Data") {
                        NavigationLink {
                            ExportView()
                        } label: {
                            Label("Export My Data", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .navigationTitle("Progress")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .task {
                await loadDestinations()
            }
            .refreshable {
                await loadDestinations()
            }
        }
    }

    @MainActor
    private func loadDestinations() async {
        isLoading = true
        let dataClient = DataClientFactory.shared.client

        async let maxesTask: [OneRepMaxRecord] = dataClient.fetchAll(recordType: "OneRepMaxRecord")
        async let benchmarksTask: [BenchmarkResult] = dataClient.fetchAll(recordType: "BenchmarkResult")
        async let challengesTask: [Challenge] = dataClient.fetchAll(recordType: "Challenge")
        async let checkInsTask: [BuddyCheckInRecord] = dataClient.fetchAll(recordType: "BuddyCheckInRecord")
        async let workoutsTask: [Workout] = dataClient.fetchAll(recordType: "Workout")

        let maxes = (try? await maxesTask) ?? []
        let benchmarks = (try? await benchmarksTask) ?? []
        let challenges = (try? await challengesTask) ?? []
        let checkIns = (try? await checkInsTask) ?? []
        let workouts = (try? await workoutsTask) ?? []

        destinations = MinimalSurfacePolicy.progressDestinations(
            input: ProgressDestinationInput(
                hasMaxes: !maxes.isEmpty,
                hasBenchmarks: !benchmarks.isEmpty,
                hasChallenges: !challenges.isEmpty,
                hasBuddyCheckIns: !checkIns.isEmpty,
                hasMonthlyReview: !workouts.isEmpty,
                hasAnalytics: workouts.count >= 2,
                alwaysShowExport: true
            )
        )
        isLoading = false
    }
}
