import SwiftUI

struct EditableExercise: Identifiable {
    let id = UUID()
    let index: Int
    var name: String
    var sets: Int
    var reps: Int
    var percent1RM: Double?
    var restMinutes: Double
    var bodyweightOnly: Bool

    init(from exercise: ProgramExercise, index: Int) {
        self.index = index
        self.name = exercise.exercise
        self.sets = Self.extractInt(from: exercise.sets)
        self.reps = Self.extractInt(from: exercise.reps)
        self.percent1RM = exercise.percent1RM
        self.restMinutes = exercise.restMinutes ?? 1.5
        self.bodyweightOnly = exercise.bodyweightOnly ?? false
    }

    func toProgramExercise() -> ProgramExercise {
        ProgramExercise(
            exercise: name,
            variant: nil,
            sets: .fixed(sets),
            reps: reps == 0 ? .amrap : .fixed(reps),
            percent1RM: bodyweightOnly ? nil : percent1RM,
            restMinutes: restMinutes,
            notes: nil,
            bodyweightOnly: bodyweightOnly
        )
    }

    private static func extractInt(from value: ExerciseValue) -> Int {
        switch value {
        case .fixed(let n): return n
        case .range(let lo, _): return lo
        case .amrap: return 0
        case .text: return 0
        }
    }
}

struct ExerciseEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var exercise: EditableExercise
    var onSave: (EditableExercise) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        fieldSection("EXERCISE NAME") {
                            TextField("Back Squat", text: $exercise.name)
                                .font(AppTheme.Fonts.body)
                                .padding(AppTheme.Spacing.sm)
                                .background(AppTheme.Colors.cardBackground)
                                .cornerRadius(AppTheme.CornerRadius.button)
                        }

                        HStack(spacing: AppTheme.Spacing.md) {
                            fieldSection("SETS") {
                                Stepper("\(exercise.sets)", value: $exercise.sets, in: 1...10)
                                    .font(AppTheme.Fonts.body)
                            }
                            fieldSection("REPS") {
                                Stepper(exercise.reps == 0 ? "AMRAP" : "\(exercise.reps)", value: $exercise.reps, in: 0...30)
                                    .font(AppTheme.Fonts.body)
                            }
                        }

                        fieldSection("REST (MINUTES)") {
                            Stepper(String(format: "%.1f", exercise.restMinutes), value: $exercise.restMinutes, in: 0.5...5.0, step: 0.5)
                                .font(AppTheme.Fonts.body)
                        }

                        Toggle("Bodyweight Only", isOn: $exercise.bodyweightOnly)
                            .font(AppTheme.Fonts.body)
                            .tint(AppTheme.Colors.accentOrange)

                        if !exercise.bodyweightOnly {
                            fieldSection("% OF 1RM (OPTIONAL)") {
                                Stepper(
                                    exercise.percent1RM.map { "\(Int($0 * 100))%" } ?? "None",
                                    value: Binding(
                                        get: { exercise.percent1RM ?? 0 },
                                        set: { exercise.percent1RM = $0 > 0 ? $0 : nil }
                                    ),
                                    in: 0...1.0,
                                    step: 0.05
                                )
                                .font(AppTheme.Fonts.body)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(exercise)
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.accentOrange)
                }
            }
        }
    }

    private func fieldSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                .tracking(1)
            content()
        }
    }
}
