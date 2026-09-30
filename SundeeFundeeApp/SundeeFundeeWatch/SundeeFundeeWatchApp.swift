// SundeeFundeeWatchApp.swift
// SundeeFundeeWatch
//
// Native watchOS 11 companion app for Sundee Fundee.

import Combine
import SundeeFundeeKit
import SwiftUI
import WatchKit

@main
struct SundeeFundeeWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}

struct WatchContentView: View {
    @ObservedObject private var workoutManager = WatchWorkoutManager.shared
    @State private var activeState: ActiveWorkoutState?
    @State private var cycleSnapshot: CyclePhaseSnapshot?
    @State private var readinessSnapshot: DailyReadinessSnapshot?
    @State private var timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if workoutManager.isTrackingStandalone {
                WatchStandaloneWorkoutView(manager: workoutManager)
            } else if let state = activeState, state.status != .completed {
                WatchLiveMirrorView(state: state)
            } else {
                WatchIdleDashboardView(
                    cycle: cycleSnapshot,
                    readiness: readinessSnapshot,
                    manager: workoutManager
                )
            }
        }
        .onAppear {
            refreshData()
        }
        .onReceive(timer) { _ in
            refreshData()
        }
    }

    private func refreshData() {
        activeState = SharedSnapshotStore.readActiveWorkoutState()
        cycleSnapshot = SharedSnapshotStore.readCycle()
        readinessSnapshot = SharedSnapshotStore.readReadiness()
    }
}

// MARK: - Watch Live Mirror View

private struct WatchLiveMirrorView: View {
    let state: ActiveWorkoutState

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xs) {
                if state.status == .resting, let rest = state.rest {
                    WatchRestTimerView(rest: rest, nextExerciseName: state.current?.exerciseName)
                } else if let current = state.current {
                    liftingView(current: current)
                } else {
                    Text(state.workoutName)
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Text.primary)
                }

                // Progress Bar
                ProgressView(
                    value: Double(state.progress.completedSets),
                    total: Double(max(1, state.progress.totalSets))
                )
                .tint(AppTheme.Accent.orange)
                .padding(.top, AppTheme.Spacing.xs)

                Text("\(state.progress.completedSets) of \(state.progress.totalSets) sets")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
            .padding(.horizontal, AppTheme.Spacing.xs)
        }
    }

    private func liftingView(current: ActiveWorkoutState.Current) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(current.exerciseName)
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Text.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("Set \(current.setIndex + 1) of \(current.totalExerciseSets)")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Accent.gold)

            HStack(spacing: AppTheme.Spacing.sm) {
                VStack {
                    Text("WEIGHT")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Text.secondary)
                    Text(current.prescribedWeight == 0 ? "BW" : "\(Int(current.prescribedWeight))")
                        .font(AppTheme.Typography.monoLarge)
                        .foregroundColor(AppTheme.Text.primary)
                }

                Divider()
                    .frame(height: 24)

                VStack {
                    Text("REPS")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Text.secondary)
                    Text(current.prescribedRepsText)
                        .font(AppTheme.Typography.monoLarge)
                        .foregroundColor(AppTheme.Text.primary)
                }
            }
            .padding(.vertical, 2)

            Button {
                WKInterfaceDevice.current().play(.success)
                Task {
                    _ = try? await CompleteSetAppIntent().perform()
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Done Set")
                }
                .font(AppTheme.Typography.labelMedium)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(AppTheme.Accent.orange)
                .foregroundColor(AppTheme.Text.cream)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }
}

// MARK: - Watch Rest Timer View with Wrist Haptics

private struct WatchRestTimerView: View {
    let rest: ActiveWorkoutState.Rest
    let nextExerciseName: String?

    @State private var lastHapticSecond: Int?

    var body: some View {
        let remaining = max(0, Int(rest.startedAt.addingTimeInterval(rest.targetDurationSeconds).timeIntervalSince(Date())))
        let m = remaining / 60
        let s = remaining % 60
        let timeString = String(format: "%d:%02d", m, s)

        VStack(spacing: AppTheme.Spacing.xs) {
            Text("REST")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Accent.gold)

            Text(timeString)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundColor(AppTheme.Text.primary)

            if let next = nextExerciseName {
                Text("Next: \(next)")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                Button {
                    WKInterfaceDevice.current().play(.click)
                    Task {
                        _ = try? await AddRestAppIntent().perform()
                    }
                } label: {
                    Text("+30s")
                        .font(AppTheme.Typography.labelSmall)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(AppTheme.Background.card)
                        .foregroundColor(AppTheme.Text.primary)
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
                .buttonStyle(.plain)

                Button {
                    WKInterfaceDevice.current().play(.click)
                    Task {
                        _ = try? await CompleteSetAppIntent().perform()
                    }
                } label: {
                    Text("Skip")
                        .font(AppTheme.Typography.labelSmall)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(AppTheme.Accent.orange)
                        .foregroundColor(AppTheme.Text.cream)
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .onAppear {
            checkHaptics(remaining: remaining)
        }
        .onChange(of: remaining) { _, newVal in
            checkHaptics(remaining: newVal)
        }
    }

    private func checkHaptics(remaining: Int) {
        guard lastHapticSecond != remaining else { return }
        lastHapticSecond = remaining

        switch remaining {
        case 3, 2, 1:
            WKInterfaceDevice.current().play(.click)
        case 0:
            WKInterfaceDevice.current().play(.stop)
        default:
            break
        }
    }
}

// MARK: - Watch Standalone Workout View

private struct WatchStandaloneWorkoutView: View {
    @ObservedObject var manager: WatchWorkoutManager

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xs) {
                // Live Metrics Bar (Heart Rate & Calories)
                HStack {
                    if manager.currentHeartRate > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(AppTheme.Accent.orange)
                            Text("\(Int(manager.currentHeartRate))")
                                .font(AppTheme.Typography.monoSmall)
                                .foregroundColor(AppTheme.Text.primary)
                        }
                    }

                    Spacer()

                    if manager.activeCalories > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundColor(AppTheme.Accent.gold)
                            Text("\(Int(manager.activeCalories)) cal")
                                .font(AppTheme.Typography.monoSmall)
                                .foregroundColor(AppTheme.Text.primary)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xs)

                if manager.isResting {
                    // Resting state
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("REST")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Accent.gold)

                        let m = manager.restRemainingSeconds / 60
                        let s = manager.restRemainingSeconds % 60
                        Text(String(format: "%d:%02d", m, s))
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.Text.primary)

                        HStack(spacing: AppTheme.Spacing.xs) {
                            Button("+30s") {
                                manager.addRest(seconds: 30)
                            }
                            .buttonStyle(.bordered)

                            Button("Skip") {
                                manager.skipRest()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.Accent.orange)
                        }
                    }
                } else {
                    // Lifting state
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("Standalone Lift")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Text.primary)

                        Text("Completed: \(manager.completedSets) sets")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Accent.gold)

                        Button {
                            manager.logSetCompleted()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Log Set")
                            }
                            .font(AppTheme.Typography.labelMedium)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(AppTheme.Accent.orange)
                            .foregroundColor(AppTheme.Text.cream)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }

                // End Workout button
                Button("End Workout") {
                    Task {
                        await manager.endStandaloneWorkout()
                    }
                }
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.secondary)
                .padding(.top, AppTheme.Spacing.sm)
            }
            .padding(.horizontal, AppTheme.Spacing.xs)
        }
    }
}

// MARK: - Watch Idle Dashboard View

private struct WatchIdleDashboardView: View {
    let cycle: CyclePhaseSnapshot?
    let readiness: DailyReadinessSnapshot?
    let manager: WatchWorkoutManager

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.sm) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .foregroundColor(AppTheme.Accent.orange)
                    Text("Sundee Fundee")
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Text.primary)
                }
                .padding(.top, 4)

                if let readiness {
                    VStack(spacing: 2) {
                        Text("READINESS")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Text.secondary)
                        Text("\(readiness.totalScore)")
                            .font(AppTheme.Typography.monoLarge)
                            .foregroundColor(AppTheme.Accent.gold)
                        Text(readiness.stateRaw.capitalized)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Text.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.Background.card)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }

                if let cycle, let phase = cycle.phaseRaw {
                    VStack(spacing: 2) {
                        Text("CYCLE PHASE")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Text.secondary)
                        Text(phase.capitalized)
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Text.primary)
                        if let day = cycle.cycleDay {
                            Text("Day \(day)")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Accent.gold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.Background.card)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }

                // Quick Launch Standalone Workout
                Button {
                    Task {
                        await manager.startStandaloneWorkout()
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Quick Workout")
                    }
                    .font(AppTheme.Typography.labelSmall)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(AppTheme.Accent.orange)
                    .foregroundColor(AppTheme.Text.cream)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(.horizontal, AppTheme.Spacing.xs)
        }
    }
}
