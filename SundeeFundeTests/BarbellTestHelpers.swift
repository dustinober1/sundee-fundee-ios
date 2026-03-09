import Testing
import Foundation
@testable import SundeeFundee

// MARK: - Shared Mock BarbellRepository

final class MockBarbellRepository: BarbellRepository {
    private var presets: [BarbellPresetDTO] = []
    private var mappings: [ExerciseBarMappingDTO] = []

    func fetchPresets(userID: String) throws -> [BarbellPresetDTO] {
        presets.filter { $0.userID == userID }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func savePreset(_ preset: BarbellPresetDTO) throws {
        presets.removeAll { $0.id == preset.id }
        presets.append(preset)
    }

    func deletePreset(id: String) throws {
        presets.removeAll { $0.id == id }
    }

    func fetchMapping(exerciseName: String, userID: String) throws -> ExerciseBarMappingDTO? {
        mappings.first { $0.exerciseName == exerciseName && $0.userID == userID }
    }

    func saveMapping(_ mapping: ExerciseBarMappingDTO) throws {
        mappings.removeAll { $0.exerciseName == mapping.exerciseName && $0.userID == mapping.userID }
        mappings.append(mapping)
    }

    func seedBuiltInPresets(userID: String) {
        let existing = (try? fetchPresets(userID: userID)) ?? []
        guard existing.isEmpty else { return }
        for def in BarbellDefaults.builtInPresets {
            try? savePreset(BarbellPresetDTO(
                id: UUID().uuidString,
                userID: userID,
                name: def.name,
                weightKg: def.weightKg,
                isBuiltIn: true,
                sortOrder: def.sortOrder
            ))
        }
    }
}

// MARK: - Shared Workout Test Helpers

func makeBarbellTestExercise(
    name: String = "Back Squat",
    sets: ExerciseValue = .fixed(3),
    reps: ExerciseValue = .fixed(5),
    percent1RM: Double? = nil,
    restMinutes: Double? = 2
) -> ProgramExercise {
    ProgramExercise(
        exercise: name,
        variant: nil,
        sets: sets,
        reps: reps,
        percent1RM: percent1RM,
        restMinutes: restMinutes,
        notes: nil
    )
}

func makeBarbellTestSession(id: String = "s1") -> ProgramSession {
    ProgramSession(
        sessionID: id,
        sessionName: "Session \(id)",
        sessionType: "strength",
        focus: "Lower",
        exercises: [makeBarbellTestExercise()]
    )
}

func makeBarbellTestWeek(_ week: Int, sessions: [ProgramSession]) -> ProgramWeek {
    ProgramWeek(week: week, phaseID: "", isTestWeek: false, sessions: sessions)
}

func makeBarbellTestProgram(id: String = "p1", weeks: [ProgramWeek]) -> Program {
    Program(
        id: id,
        name: "Program \(id)",
        category: "Strength",
        description: "",
        durationWeeks: weeks.count,
        sessionsPerWeek: weeks.first?.sessions.count ?? 1,
        difficulty: "beginner",
        phases: [],
        cycleAdjustmentProfile: nil,
        weeks: weeks
    )
}

@MainActor
func makeBarbellTestVM(
    barbellRepo: BarbellRepository? = nil,
    userID: String = "",
    gender: Gender? = nil
) -> WorkoutExecutionViewModel {
    let session = makeBarbellTestSession()
    let program = makeBarbellTestProgram(weeks: [makeBarbellTestWeek(1, sessions: [session])])
    let enrollment = EnrolledProgram(id: "e1", userID: "u1", programID: "p1", startDate: .now)
    return WorkoutExecutionViewModel(
        session: session,
        enrollment: enrollment,
        program: program,
        barbellRepo: barbellRepo,
        userID: userID,
        gender: gender
    )
}
