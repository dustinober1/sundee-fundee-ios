import SwiftUI

struct SessionEditorView: View {
    @Binding var program: Program
    let weekIndex: Int
    let sessionIndex: Int
    @State private var editingExercise: EditableExercise?

    private var session: ProgramSession {
        program.weeks[weekIndex].sessions[sessionIndex]
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("Week \(program.weeks[weekIndex].week)")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))

                    VStack(spacing: 0) {
                        ForEach(Array(session.exercises.enumerated()), id: \.offset) { exIndex, exercise in
                            Button {
                                editingExercise = EditableExercise(from: exercise, index: exIndex)
                            } label: {
                                exerciseRow(exercise: exercise)
                            }
                            .buttonStyle(.plain)

                            if exIndex < session.exercises.count - 1 {
                                Divider().padding(.leading, AppTheme.Spacing.md)
                            }
                        }
                    }
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.card)

                    Button {
                        addExercise()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Add Exercise", systemImage: "plus")
                                .font(AppTheme.Fonts.subheading)
                                .foregroundStyle(AppTheme.Colors.accentOrange)
                            Spacer()
                        }
                        .padding(AppTheme.Spacing.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .foregroundStyle(AppTheme.Colors.separator)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle(session.sessionName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingExercise) { editable in
            ExerciseEditorSheet(exercise: editable) { updated in
                applyExerciseEdit(updated)
            }
        }
    }

    private func exerciseRow(exercise: ProgramExercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exercise)
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text(Self.exerciseSubtitle(exercise))
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }
            Spacer()
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.3))
        }
        .padding(AppTheme.Spacing.md)
    }

    static func exerciseSubtitle(_ exercise: ProgramExercise) -> String {
        var parts: [String] = ["\(exercise.sets) × \(exercise.reps)"]
        if let pct = exercise.percent1RM, pct > 0 {
            parts.append("@ \(Int(pct * 100))%")
        }
        if let rest = exercise.restMinutes {
            if rest == floor(rest) {
                parts.append("\(Int(rest)) min rest")
            } else {
                let seconds = Int(rest * 60)
                parts.append("\(seconds) sec rest")
            }
        }
        return parts.joined(separator: " · ")
    }

    private func addExercise() {
        let newExercise = ProgramExercise(
            exercise: "New Exercise",
            variant: nil,
            sets: .fixed(3),
            reps: .fixed(10),
            percent1RM: nil,
            restMinutes: 1.5,
            notes: nil,
            bodyweightOnly: false
        )
        var weeks = program.weeks
        var sessions = weeks[weekIndex].sessions
        var exercises = sessions[sessionIndex].exercises
        exercises.append(newExercise)

        let updatedSession = ProgramSession(
            sessionID: session.sessionID,
            sessionName: session.sessionName,
            sessionType: session.sessionType,
            focus: session.focus,
            exercises: exercises
        )
        sessions[sessionIndex] = updatedSession
        weeks[weekIndex] = ProgramWeek(
            week: weeks[weekIndex].week,
            phaseID: weeks[weekIndex].phaseID,
            isTestWeek: weeks[weekIndex].isTestWeek,
            sessions: sessions
        )
        program = Program(
            id: program.id, name: program.name, category: program.category,
            description: program.description, durationWeeks: program.durationWeeks,
            sessionsPerWeek: program.sessionsPerWeek, difficulty: program.difficulty,
            phases: program.phases, weeks: weeks,
            cycleAdjustmentProfile: program.cycleAdjustmentProfile
        )
    }

    private func applyExerciseEdit(_ editable: EditableExercise) {
        let updated = editable.toProgramExercise()
        var weeks = program.weeks
        var sessions = weeks[weekIndex].sessions
        var exercises = sessions[sessionIndex].exercises
        exercises[editable.index] = updated

        let updatedSession = ProgramSession(
            sessionID: session.sessionID,
            sessionName: session.sessionName,
            sessionType: session.sessionType,
            focus: session.focus,
            exercises: exercises
        )
        sessions[sessionIndex] = updatedSession
        weeks[weekIndex] = ProgramWeek(
            week: weeks[weekIndex].week,
            phaseID: weeks[weekIndex].phaseID,
            isTestWeek: weeks[weekIndex].isTestWeek,
            sessions: sessions
        )
        program = Program(
            id: program.id, name: program.name, category: program.category,
            description: program.description, durationWeeks: program.durationWeeks,
            sessionsPerWeek: program.sessionsPerWeek, difficulty: program.difficulty,
            phases: program.phases, weeks: weeks,
            cycleAdjustmentProfile: program.cycleAdjustmentProfile
        )
    }
}
