import SwiftUI
import SwiftData

struct CustomWorkoutBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]

    @State private var workoutName = ""
    @State private var workoutNotes = ""
    @State private var exercises: [DraftExercise] = []
    @State private var showExercisePicker = false
    @State private var savedConfirmation = false

    private var userId: String { users.first?.id ?? "" }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Name") {
                    TextField("e.g. Upper Body Day", text: $workoutName)
                        .autocorrectionDisabled()
                }

                Section {
                    ForEach($exercises) { $entry in
                        ExerciseEntryRow(entry: $entry)
                    }
                    .onDelete { indexSet in
                        exercises.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        exercises.move(fromOffsets: from, toOffset: to)
                    }

                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Exercises")
                }

                Section("Notes (optional)") {
                    TextField("Any notes about this workout…", text: $workoutNotes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Custom Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .safeAreaInset(edge: .bottom) {
                BottomActionBar(
                    canSave: !workoutName.isEmpty && !exercises.isEmpty,
                    onLogNow: logNow,
                    onSave: saveAsProgram
                )
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerSheet { definition in
                    exercises.append(DraftExercise(exerciseId: definition.id, name: definition.name))
                }
            }
            .overlay {
                if savedConfirmation {
                    SavedToast()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Actions

    private func logNow() {
        guard !exercises.isEmpty else { return }
        let workout = CompletedWorkout(
            userId: userId,
            activeCycleId: "custom",
            programId: "custom",
            week: 1,
            day: 1,
            sessionId: workoutName.isEmpty ? "Custom Workout" : workoutName,
            notes: workoutNotes.isEmpty ? nil : workoutNotes
        )
        modelContext.insert(workout)

        for (i, entry) in exercises.enumerated() {
            for setNum in 1...max(1, entry.sets) {
                let set = CompletedSet(
                    workoutId: workout.id,
                    exerciseId: entry.exerciseId,
                    setNumber: setNum,
                    prescribedReps: entry.reps
                )
                set.workout = workout
                modelContext.insert(set)
            }
            _ = i
        }

        try? modelContext.save()
        dismiss()
    }

    private func saveAsProgram() {
        guard !workoutName.isEmpty, !exercises.isEmpty else { return }
        let program = CustomProgram(
            userId: userId,
            name: workoutName,
            notes: workoutNotes.isEmpty ? nil : workoutNotes
        )
        modelContext.insert(program)

        for (i, entry) in exercises.enumerated() {
            let ex = CustomProgramExercise(
                exerciseId: entry.exerciseId,
                sets: entry.sets,
                reps: entry.reps,
                restMinutes: entry.restMinutes,
                notes: entry.notes.isEmpty ? nil : entry.notes,
                order: i
            )
            ex.program = program
            modelContext.insert(ex)
        }

        try? modelContext.save()

        withAnimation {
            savedConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { savedConfirmation = false }
            dismiss()
        }
    }
}

// MARK: - Draft Model (in-memory only)

struct DraftExercise: Identifiable {
    let id: UUID = UUID()
    var exerciseId: String
    var name: String
    var sets: Int = 3
    var reps: Int = 8
    var restMinutes: Double = 2.0
    var notes: String = ""
}

// MARK: - Exercise Entry Row

private struct ExerciseEntryRow: View {
    @Binding var entry: DraftExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.name)
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 16) {
                Stepper("Sets: \(entry.sets)", value: $entry.sets, in: 1...20)
                    .font(.caption)
                Stepper("Reps: \(entry.reps)", value: $entry.reps, in: 1...50)
                    .font(.caption)
            }

            HStack {
                Text("Rest: \(entry.restMinutes, specifier: "%.1f") min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Stepper("", value: $entry.restMinutes, in: 0.5...10.0, step: 0.5)
                    .labelsHidden()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Bottom Action Bar

private struct BottomActionBar: View {
    let canSave: Bool
    let onLogNow: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onLogNow) {
                Label("Log Now", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(!canSave)

            Button(action: onSave) {
                Label("Save Program", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSave)
        }
        .padding()
        .background(.bar)
    }
}

// MARK: - Exercise Picker Sheet

private struct ExercisePickerSheet: View {
    let onSelect: (ExerciseDefinition) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [ExerciseDefinition] {
        if searchText.isEmpty { return Exercises.all }
        return Exercises.all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { exercise in
                Button {
                    onSelect(exercise)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Text(exercise.muscleGroups.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Choose Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Saved Toast

private struct SavedToast: View {
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Saved to Programs")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .shadow(radius: 4)
            .padding(.top, 12)
            Spacer()
        }
    }
}

#Preview {
    CustomWorkoutBuilderView()
        .modelContainer(for: [User.self, CustomProgram.self, CustomProgramExercise.self, CompletedWorkout.self, CompletedSet.self], inMemory: true)
}
