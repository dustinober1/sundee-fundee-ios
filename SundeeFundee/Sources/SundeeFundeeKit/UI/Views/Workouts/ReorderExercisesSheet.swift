import SwiftUI

// MARK: - ReorderExercisesSheet
//
// Allows reordering upcoming exercises or selecting a different active exercise
// mid-workout (e.g. when gym equipment is temporarily occupied).

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ReorderExercisesSheet: View {
    @ObservedObject private var viewModel: ActiveWorkoutSessionViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: ActiveWorkoutSessionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(viewModel.workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                        exerciseRow(exercise: exercise, index: index)
                    }
                    .onMove { source, destination in
                        viewModel.moveExercises(from: source, to: destination)
                    }
                } header: {
                    Text("Drag to reorder · Tap to switch active exercise")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            .environment(\.editMode, .constant(.active))
            #elseif os(macOS)
            .listStyle(.inset)
            #else
            .listStyle(.plain)
            #endif
            .navigationTitle("Reorder Exercises")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Accent.orange)
                }
            }
        }
    }

    private func exerciseRow(exercise: Exercise, index: Int) -> some View {
        let isCurrent = index == viewModel.currentExerciseIndex
        let isComplete = exercise.targetSets.allSatisfy(\.isComplete)
        let completedCount = exercise.targetSets.filter(\.isComplete).count

        return Button {
            viewModel.selectExercise(at: index)
            HapticFeedback.light()
            dismiss()
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                // Index / Status badge
                Text("\(index + 1)")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(isCurrent ? AppTheme.Text.cream : AppTheme.Text.secondary)
                    .frame(width: 28, height: 28)
                    .background(isCurrent ? AppTheme.Accent.orange : AppTheme.Background.navy.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(exercise.name)
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Text.primary)

                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text(exercise.category.rawValue)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Text.secondary)

                        Text("·")
                            .foregroundColor(AppTheme.Text.secondary)

                        if isComplete {
                            Text("Complete")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Recovery.green)
                        } else {
                            Text("\(completedCount)/\(exercise.targetSets.count) sets")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(isCurrent ? AppTheme.Accent.gold : AppTheme.Text.secondary)
                        }
                    }
                }

                Spacer()

                if isCurrent {
                    Text("ACTIVE")
                        .font(AppTheme.Typography.labelSmall)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.Accent.orange.opacity(0.15))
                        .foregroundColor(AppTheme.Accent.orange)
                        .cornerRadius(AppTheme.CornerRadius.small)
                } else if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Recovery.green)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
