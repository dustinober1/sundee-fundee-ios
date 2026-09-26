// WatchWorkoutSessionView.swift
// SundeeFundeeKit
//
// Native watchOS workout tracking view designed for wrist interaction.

import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WatchWorkoutSessionView: View {
    @ObservedObject var viewModel: ActiveWorkoutSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var actualReps: Int = 10
    @State private var completedWeight: Double = 0
    @State private var showAbandonConfirmation = false

    public init(viewModel: ActiveWorkoutSessionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.isComplete {
                completionView
            } else if viewModel.isResting {
                restingView
            } else {
                activeLiftingView
            }
        }
        .onAppear {
            syncInputsWithCurrentSet()
        }
        .onChange(of: viewModel.currentSetIndex) { _, _ in
            syncInputsWithCurrentSet()
        }
        .onChange(of: viewModel.currentExerciseIndex) { _, _ in
            syncInputsWithCurrentSet()
        }
        .confirmationDialog(
            "Abandon Workout?",
            isPresented: $showAbandonConfirmation,
            titleVisibility: .visible
        ) {
            Button("Abandon", role: .destructive) {
                Task {
                    await viewModel.abandonWorkout()
                    dismiss()
                }
            }
            Button("Keep Going", role: .cancel) { }
        }
    }

    private var activeLiftingView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xs) {
                if let exercise = viewModel.currentExercise {
                    Text(exercise.name)
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Text.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text("Set \(viewModel.currentSetIndex + 1) of \(exercise.targetSets.count)")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Accent.gold)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        VStack {
                            Text("WEIGHT")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Text.secondary)
                            Text(completedWeight == 0 ? "BW" : "\(Int(completedWeight))")
                                .font(AppTheme.Typography.monoLarge)
                                .foregroundColor(AppTheme.Text.primary)
                        }

                        Divider()
                            .frame(height: 24)

                        VStack {
                            Text("REPS")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Text.secondary)
                            HStack(spacing: 4) {
                                Button {
                                    if actualReps > 1 { actualReps -= 1 }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)

                                Text("\(actualReps)")
                                    .font(AppTheme.Typography.monoLarge)
                                    .foregroundColor(AppTheme.Text.primary)

                                Button {
                                    actualReps += 1
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    Button {
                        Task {
                            await viewModel.completeSet(
                                actualReps: actualReps,
                                completedWeight: completedWeight
                            )
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

                    Button {
                        showAbandonConfirmation = true
                    } label: {
                        Text("End Workout")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Semantic.warning)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                } else {
                    Text("No Exercise")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xs)
        }
    }

    private var restingView: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("REST")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Accent.gold)

            Text(formattedRestTime)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundColor(AppTheme.Text.primary)

            if let nextExercise = viewModel.currentExercise {
                Text("Next: \(nextExercise.name)")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                Button {
                    viewModel.addRest(seconds: 30)
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
                    viewModel.skipRest()
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
        .padding(.horizontal, AppTheme.Spacing.xs)
    }

    private var completionView: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundColor(AppTheme.Accent.gold)

            Text("Workout Finished!")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Text.primary)

            Text("\(viewModel.completedSets) sets completed")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.secondary)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(AppTheme.Typography.labelMedium)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(AppTheme.Accent.orange)
                    .foregroundColor(AppTheme.Text.cream)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Spacing.xs)
    }

    private func syncInputsWithCurrentSet() {
        if let current = viewModel.currentSet {
            actualReps = current.reps
            completedWeight = current.prescribedWeight
        }
    }

    private var formattedRestTime: String {
        let seconds = Int(max(0, viewModel.restTimeRemaining))
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
