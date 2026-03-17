import SwiftUI

/// Timer view for "For Time" workouts.
/// Displays a stopwatch counting up with an exercise checklist and optional time cap.
struct ForTimeTimerView: View {
    let exercises: [ProgramExercise]
    let timeCapMinutes: Int?

    @State private var elapsedSeconds: Int = 0
    @State private var isRunning = false
    @State private var completedExercises: Set<String> = []
    @State private var isFinished = false

    init(exercises: [ProgramExercise], timeCapMinutes: Int? = nil) {
        self.exercises = exercises
        self.timeCapMinutes = timeCapMinutes
    }

    private var timerColor: SwiftUI.Color {
        if Self.isOverTimeCap(elapsed: elapsedSeconds, capMinutes: timeCapMinutes) {
            return AppTheme.Colors.error
        } else if Self.isNearTimeCap(elapsed: elapsedSeconds, capMinutes: timeCapMinutes) {
            return AppTheme.Colors.accentOrange
        }
        return AppTheme.Colors.navy
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // MARK: - Stopwatch
                Text(Self.formatElapsed(elapsedSeconds))
                    .font(AppTheme.Font.mono(48))
                    .foregroundStyle(timerColor)

                if let cap = timeCapMinutes {
                    Text("Time cap: \(cap) min")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                }

                // MARK: - Exercise checklist
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("CHECKLIST")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                        .tracking(1.5)

                    ForEach(exercises, id: \.exercise) { exercise in
                        HStack {
                            let done = completedExercises.contains(exercise.exercise)
                            Button {
                                if done {
                                    completedExercises.remove(exercise.exercise)
                                } else {
                                    completedExercises.insert(exercise.exercise)
                                }
                            } label: {
                                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(done ? AppTheme.Colors.accentOrange : AppTheme.Colors.navy.opacity(0.3))
                            }

                            Text(exercise.exercise)
                                .font(AppTheme.Fonts.body)
                                .foregroundStyle(done ? AppTheme.Colors.navy.opacity(0.4) : AppTheme.Colors.navy)
                                .strikethrough(done)

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

                // MARK: - Done button
                Button("Done") {
                    isRunning = false
                    isFinished = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isFinished)
            }
            .padding(AppTheme.Spacing.md)
        }
        .navigationTitle("For Time")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Static helpers

    static func formatElapsed(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    static func isOverTimeCap(elapsed: Int, capMinutes: Int?) -> Bool {
        guard let cap = capMinutes else { return false }
        return elapsed >= cap * 60
    }

    static func isNearTimeCap(elapsed: Int, capMinutes: Int?, thresholdSeconds: Int = 30) -> Bool {
        guard let cap = capMinutes else { return false }
        let remaining = (cap * 60) - elapsed
        return remaining > 0 && remaining <= thresholdSeconds
    }
}
