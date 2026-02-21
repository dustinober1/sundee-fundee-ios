import SwiftUI
import SwiftData

struct StartCycleView: View {
    let program: ProgramV2
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var cycleName = ""
    @State private var oneRepMaxes: [String: String] = [:]

    private var requiredExercises: [String] {
        let exercises = Set(
            program.weeks
                .flatMap(\.sessions)
                .flatMap(\.exercises)
                .filter { $0.percent1RM != nil }
                .map(\.exercise)
        )
        return exercises.sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cycle Name") {
                    TextField("e.g., Spring 2026", text: $cycleName)
                }

                if !requiredExercises.isEmpty {
                    Section("Enter Your 1RM (lbs)") {
                        ForEach(requiredExercises, id: \.self) { exerciseId in
                            HStack {
                                Text(Exercises.find(byId: exerciseId)?.name ?? exerciseId)
                                    .font(.subheadline)
                                Spacer()
                                TextField("lbs", text: binding(for: exerciseId))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                        }
                    }
                }

                Section {
                    Button("Start Cycle") {
                        startCycle()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Start \(program.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                cycleName = "\(program.name) Cycle"
            }
        }
    }

    private var isValid: Bool {
        !cycleName.trimmingCharacters(in: .whitespaces).isEmpty &&
        requiredExercises.allSatisfy { id in
            guard let val = oneRepMaxes[id], let num = Double(val) else { return false }
            return num > 0
        }
    }

    private func binding(for exerciseId: String) -> Binding<String> {
        Binding(
            get: { oneRepMaxes[exerciseId] ?? "" },
            set: { oneRepMaxes[exerciseId] = $0 }
        )
    }

    private func startCycle() {
        guard let firstSession = program.weeks.first?.sessions.first else { return }

        // Fetch or create user ID
        let userDescriptor = FetchDescriptor<User>()
        guard let user = try? modelContext.fetch(userDescriptor).first else { return }

        let cycle = ActiveCycle(
            userId: user.id,
            programId: program.id,
            cycleName: cycleName,
            currentSessionId: firstSession.sessionId,
            currentPhase: program.phases.first?.id
        )
        modelContext.insert(cycle)

        // Save 1RM entries
        for (exerciseId, valueStr) in oneRepMaxes {
            guard let weight = Double(valueStr), weight > 0 else { continue }
            let orm = OneRepMax(
                userId: user.id,
                exerciseId: exerciseId,
                weight: weight
            )
            modelContext.insert(orm)
        }

        try? modelContext.save()
        dismiss()
    }
}
