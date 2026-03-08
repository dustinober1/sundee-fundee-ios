import SwiftUI

// MARK: - CircuitHelpers

/// Pure calculation helpers for circuit/superset workouts — extracted for testability.
enum CircuitHelpers {
    static func groupExercises(_ exercises: [ProgramExercise], groupSize: Int = 2) -> [[ProgramExercise]] {
        let size = max(groupSize, 1)
        return stride(from: 0, to: exercises.count, by: size).map {
            Array(exercises[$0..<min($0 + size, exercises.count)])
        }
    }

    static func roundProgressText(currentRound: Int, totalRounds: Int) -> String {
        "Round \(currentRound) of \(totalRounds)"
    }
}

// MARK: - CircuitGroupView

/// View for circuit/superset workouts.
/// Groups exercises visually and tracks rounds per group.
struct CircuitGroupView: View {
    let exercises: [ProgramExercise]
    let groupSize: Int
    let totalRounds: Int

    @State private var currentRound: Int = 1
    @State private var restSeconds: Int = 0
    @State private var showingRest = false

    init(exercises: [ProgramExercise], groupSize: Int = 2, totalRounds: Int = 3) {
        self.exercises = exercises
        self.groupSize = groupSize
        self.totalRounds = totalRounds
    }

    private var groups: [[ProgramExercise]] {
        CircuitHelpers.groupExercises(exercises, groupSize: groupSize)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // MARK: - Round tracker
                    Text(CircuitHelpers.roundProgressText(currentRound: currentRound, totalRounds: totalRounds))
                        .font(AppTheme.Fonts.heading)
                        .foregroundStyle(AppTheme.Colors.navy)

                    // MARK: - Exercise groups
                    ForEach(groups.indices, id: \.self) { groupIndex in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("GROUP \(groupIndex + 1)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.accentOrange)
                                .tracking(1.5)

                            ForEach(groups[groupIndex], id: \.exercise) { exercise in
                                HStack {
                                    Text(exercise.exercise)
                                        .font(AppTheme.Fonts.body)
                                        .foregroundStyle(AppTheme.Colors.navy)
                                    Spacer()
                                    Text("\(exercise.sets.description) x \(exercise.reps.description)")
                                        .font(AppTheme.Fonts.caption)
                                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                                }
                                .padding(.vertical, AppTheme.Spacing.xs)
                            }
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }

                    // MARK: - Round controls
                    HStack(spacing: AppTheme.Spacing.lg) {
                        Button("Next Round") {
                            if currentRound < totalRounds {
                                currentRound += 1
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(currentRound >= totalRounds)
                    }
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle("Circuit")
        .navigationBarTitleDisplayMode(.inline)
    }

}
