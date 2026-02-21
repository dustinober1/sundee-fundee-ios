import SwiftUI
import SwiftData

struct CustomProgramDetailView: View {
    let program: CustomProgram

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]

    private var userId: String { users.first?.id ?? "" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let notes = program.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises")
                        .font(.headline)

                    ForEach(program.sortedExercises, id: \.id) { ex in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(Exercises.find(byId: ex.exerciseId)?.name ?? ex.exerciseId)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack(spacing: 12) {
                                Text("\(ex.sets) sets")
                                Text("\(ex.reps) reps")
                                Text("Rest \(ex.restMinutes, specifier: "%.1f")m")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            if let note = ex.notes, !note.isEmpty {
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                logWorkout()
            } label: {
                Label("Log This Workout", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .background(.bar)
            .disabled(userId.isEmpty || program.sortedExercises.isEmpty)
        }
    }

    private func logWorkout() {
        guard !userId.isEmpty else { return }

        let workout = CompletedWorkout(
            userId: userId,
            activeCycleId: "custom",
            programId: program.id,
            week: 1,
            day: 1,
            sessionId: program.name,
            notes: program.notes
        )
        modelContext.insert(workout)

        for ex in program.sortedExercises {
            for setNum in 1...max(1, ex.sets) {
                let set = CompletedSet(
                    workoutId: workout.id,
                    exerciseId: ex.exerciseId,
                    setNumber: setNum,
                    prescribedReps: ex.reps,
                    restSeconds: Int(ex.restMinutes * 60)
                )
                set.workout = workout
                modelContext.insert(set)
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CustomProgramDetailView(program: CustomProgram(userId: "preview-user", name: "Upper Body"))
    }
    .modelContainer(
        for: [User.self, CustomProgram.self, CustomProgramExercise.self, CompletedWorkout.self, CompletedSet.self],
        inMemory: true
    )
}