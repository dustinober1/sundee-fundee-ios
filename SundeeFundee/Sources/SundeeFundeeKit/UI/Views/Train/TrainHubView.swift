import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct TrainHubView: View {
    @State private var showingNewWorkout = false
    @State private var showingAIWorkout = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Start") {
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
