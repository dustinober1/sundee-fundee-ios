import SwiftUI

/// Timer view for AMRAP (As Many Rounds As Possible) workouts.
/// Displays a countdown from the time cap, with round and rep tracking.
struct AMRAPTimerView: View {
    let exercises: [ProgramExercise]

    @State private var secondsRemaining: Int
    @State private var currentRound: Int = 1
    @State private var currentReps: Int = 0
    @State private var isRunning = false

    init(exercises: [ProgramExercise]) {
        self.exercises = exercises
        let cap = Self.extractTimeCap(from: exercises)
        _secondsRemaining = State(initialValue: cap * 60)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // MARK: - Timer display
                Text(Self.formatTimeRemaining(secondsRemaining))
                    .font(AppTheme.Font.mono(48))
                    .foregroundStyle(secondsRemaining <= 30 ? AppTheme.Colors.error : AppTheme.Colors.navy)

                // MARK: - Round/rep display
                Text(Self.roundDisplayText(round: currentRound, reps: currentReps))
                    .font(AppTheme.Fonts.heading)
                    .foregroundStyle(AppTheme.Colors.navy)

                // MARK: - Controls
                HStack(spacing: AppTheme.Spacing.lg) {
                    Button {
                        currentReps += 1
                    } label: {
                        Label("Rep", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        currentRound += 1
                        currentReps = 0
                    } label: {
                        Label("Round", systemImage: "arrow.clockwise.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                // MARK: - Exercise list
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("EXERCISES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                        .tracking(1.5)

                    ForEach(exercises, id: \.exercise) { exercise in
                        HStack {
                            Text(exercise.exercise)
                                .font(AppTheme.Fonts.body)
                                .foregroundStyle(AppTheme.Colors.navy)
                            Spacer()
                            Text(exercise.reps.description)
                                .font(AppTheme.Fonts.caption)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                        }
                        .padding(.vertical, AppTheme.Spacing.xs)
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            }
            .padding(AppTheme.Spacing.md)
        }
        .navigationTitle("AMRAP")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Static helpers

    static func formatTimeRemaining(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    static func roundDisplayText(round: Int, reps: Int) -> String {
        reps > 0 ? "Round \(round) + \(reps) reps" : "Round \(round)"
    }

    static func extractTimeCap(from exercises: [ProgramExercise]) -> Int {
        for exercise in exercises {
            if case .text(let text) = exercise.reps {
                if let minutes = Int(text.replacingOccurrences(of: "min", with: "").trimmingCharacters(in: .whitespaces)) {
                    return minutes
                }
            }
        }
        return 12
    }
}
