// SundeeFundeeWatchApp.swift
// SundeeFundeeWatch
//
// Native watchOS 11 companion app for Sundee Fundee.

import SwiftUI
import SundeeFundeeKit

@main
struct SundeeFundeeWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}

struct WatchContentView: View {
    @State private var activeState: ActiveWorkoutState?
    @State private var cycleSnapshot: CyclePhaseSnapshot?
    @State private var readinessSnapshot: DailyReadinessSnapshot?
    @State private var timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let state = activeState, state.status != .completed {
                WatchLiveMirrorView(state: state)
            } else {
                WatchIdleDashboardView(
                    cycle: cycleSnapshot,
                    readiness: readinessSnapshot
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
                    restView(rest: rest)
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
                HapticFeedback.light()
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

    private func restView(rest: ActiveWorkoutState.Rest) -> some View {
        let remaining = max(0, Int(rest.startedAt.addingTimeInterval(rest.targetDurationSeconds).timeIntervalSince(Date())))
        let m = remaining / 60
        let s = remaining % 60
        let timeString = String(format: "%d:%02d", m, s)

        return VStack(spacing: AppTheme.Spacing.xs) {
            Text("REST")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Accent.gold)

            Text(timeString)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundColor(AppTheme.Text.primary)

            if let current = state.current {
                Text("Next: \(current.exerciseName)")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                Button {
                    HapticFeedback.light()
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
                    HapticFeedback.light()
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
    }
}

// MARK: - Watch Idle Dashboard View

private struct WatchIdleDashboardView: View {
    let cycle: CyclePhaseSnapshot?
    let readiness: DailyReadinessSnapshot?

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

                Text("Start workout on iPhone to track on watch")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, AppTheme.Spacing.xs)
        }
    }
}
