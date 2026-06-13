import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct TrainHubView: View {
    @State private var showingNewWorkout = false
    @State private var showingAIWorkout = false
    @State private var quickWorkout: Workout?

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Start") {
                    Button {
                        quickWorkout = QuickWorkoutBuilder.build(
                            request: QuickWorkoutRequest(
                                timeMinutes: 20,
                                focus: .fullBody,
                                energyLevel: .medium,
                                equipment: .fullGym,
                                todayDecisionKind: .modify,
                                recoveryScoreTotal: nil,
                                painLogs: []
                            )
                        ).workout
                    } label: {
                        Label("Best Next 20 Min", systemImage: "timer")
                    }

                    Button {
                        showingAIWorkout = true
                    } label: {
                        Label("Build Coach Plan", systemImage: "sparkles")
                    }

                    Button {
                        showingNewWorkout = true
                    } label: {
                        Label("Build Your Own", systemImage: "plus.circle")
                    }
                }

                Section("Continue") {
                    NavigationLink {
                        WorkoutsListView()
                    } label: {
                        Label("Workout History", systemImage: "clock.arrow.circlepath")
                    }

                    NavigationLink {
                        ProgramsListView()
                    } label: {
                        Label("Programs", systemImage: "list.bullet.rectangle")
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("During a workout")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Text.primary)
                        Text("Use workout options for equipment conversion, station swaps, warmups, technique cues, and rest guidance.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .navigationTitle("Train")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .sheet(isPresented: $showingNewWorkout) {
                NewWorkoutView {
                    showingNewWorkout = false
                }
            }
            #if os(iOS)
            .fullScreenCover(item: $quickWorkout) { workout in
                ActiveWorkoutView(
                    viewModel: ActiveWorkoutSessionViewModel(workout: workout)
                )
            }
            #else
            .sheet(item: $quickWorkout) { workout in
                ActiveWorkoutView(
                    viewModel: ActiveWorkoutSessionViewModel(workout: workout)
                )
            }
            #endif
            #if os(iOS)
            .fullScreenCover(isPresented: $showingAIWorkout) {
                AIWorkoutView {
                    showingAIWorkout = false
                }
            }
            #else
            .sheet(isPresented: $showingAIWorkout) {
                AIWorkoutView {
                    showingAIWorkout = false
                }
            }
            #endif
        }
    }
}
