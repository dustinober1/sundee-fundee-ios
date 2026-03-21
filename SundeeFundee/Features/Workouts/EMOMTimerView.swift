import SwiftUI

/// Timer view for EMOM (Every Minute On the Minute) workouts.
/// Displays a running clock with per-minute exercise assignments.
struct EMOMTimerView: View {
    let exercises: [ProgramExercise]
    let totalMinutes: Int

    @State private var elapsedSeconds: Int = 0
    @State private var isRunning = false

    init(exercises: [ProgramExercise], totalMinutes: Int = 10) {
        self.exercises = exercises
        self.totalMinutes = totalMinutes
    }

    private var minute: Int {
        Self.currentMinute(elapsedSeconds: elapsedSeconds, intervalSeconds: 60)
    }

    private var activeExerciseIndex: Int {
        Self.exerciseIndex(minute: minute, exerciseCount: exercises.count)
    }

    private var intervalProgress: Double {
        guard totalMinutes > 0 else { return 0 }
        let within = Self.timeWithinInterval(elapsedSeconds: elapsedSeconds, intervalSeconds: 60)
        return Double(within) / 60.0
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // MARK: - Elapsed time
                Text(Self.formatElapsedTime(elapsedSeconds))
                    .font(AppTheme.Font.mono(48))
                    .foregroundStyle(AppTheme.Colors.navy)

                // MARK: - Minute indicator
                Text("Minute \(minute) of \(totalMinutes)")
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.7))

                // MARK: - Interval progress
                ProgressView(value: intervalProgress)
                    .tint(AppTheme.Colors.accentOrange)
                    .padding(.horizontal, AppTheme.Spacing.xl)

                // MARK: - Exercise list
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("EXERCISES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                        .tracking(1.5)

                    ForEach(exercises.indices, id: \.self) { index in
                        HStack {
                            if index == activeExerciseIndex {
                                Image(systemName: "arrowtriangle.right.fill")
                                    .foregroundStyle(AppTheme.Colors.accentOrange)
                                    .font(.system(size: 10))
                            }
                            Text(exercises[index].exercise)
                                .font(AppTheme.Fonts.body)
                                .foregroundStyle(index == activeExerciseIndex
                                    ? AppTheme.Colors.accentOrange
                                    : AppTheme.Colors.navy)
                            Spacer()
                            Text(exercises[index].reps.description)
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
        .navigationTitle("EMOM")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Static helpers

    static func currentMinute(elapsedSeconds: Int, intervalSeconds: Int) -> Int {
        guard intervalSeconds > 0 else { return 1 }
        return (elapsedSeconds / intervalSeconds) + 1
    }

    static func timeWithinInterval(elapsedSeconds: Int, intervalSeconds: Int) -> Int {
        guard intervalSeconds > 0 else { return 0 }
        return elapsedSeconds % intervalSeconds
    }

    static func exerciseIndex(minute: Int, exerciseCount: Int) -> Int {
        guard exerciseCount > 0 else { return 0 }
        return (minute - 1) % exerciseCount
    }

    static func formatElapsedTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
