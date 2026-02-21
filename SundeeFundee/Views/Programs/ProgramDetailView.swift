import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    let program: ProgramV2
    @State private var showStartCycle = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(program.description)
                        .font(.body)

                    HStack(spacing: 16) {
                        Label("\(program.durationWeeks) weeks", systemImage: "calendar")
                        Label("\(program.sessionsPerWeek)×/week", systemImage: "figure.run")
                        Label(program.difficulty.capitalized, systemImage: "chart.bar.fill")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                // Phases
                VStack(alignment: .leading, spacing: 12) {
                    Text("Phases")
                        .font(.title3)
                        .fontWeight(.semibold)

                    ForEach(program.phases) { phase in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phase.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Weeks \(phase.weekRange[0])-\(phase.weekRange.last ?? phase.weekRange[0]) — \(phase.goal)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Weekly Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Sessions")
                        .font(.title3)
                        .fontWeight(.semibold)

                    ForEach(program.weeks.prefix(2), id: \.week) { week in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Week \(week.week)")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            ForEach(week.sessions) { session in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.sessionName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(session.focus)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    ForEach(session.exercises, id: \.exercise) { exercise in
                                        let exerciseName = Exercises.find(byId: exercise.exercise)?.name ?? exercise.exercise
                                        Text("• \(exerciseName): \(exercise.sets.displayString)×\(exercise.reps.displayString)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                Button("Start This Program") {
                    showStartCycle = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showStartCycle) {
            StartCycleView(program: program)
        }
    }
}
