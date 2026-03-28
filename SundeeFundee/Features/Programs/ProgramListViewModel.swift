import Foundation
import SwiftData

@MainActor
@Observable
final class ProgramListViewModel {
    var programs: [Program] = []
    var customPrograms: [Program] = []
    var activeEnrollment: EnrolledProgram?
    var isLoading = false
    var errorMessage: String?

    private let programRepo: any ProgramRepository
    private var enrollmentRepo: (any EnrolledProgramRepository)?

    init(programRepo: any ProgramRepository = CloudKitProgramRepository()) {
        self.programRepo = programRepo
    }

    func load(modelContext: ModelContext? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            programs = try await programRepo.fetchPrograms()
        } catch {
            errorMessage = error.localizedDescription
        }

        if let ctx = modelContext {
            let repo = SwiftDataEnrolledProgramRepository(context: ctx)
            enrollmentRepo = repo
            activeEnrollment = try? repo.fetchActiveEnrollment()

            let customRepo = SwiftDataCustomProgramRepository(context: ctx)
            let records = (try? customRepo.fetchAll(userID: "")) ?? []
            customPrograms = records.compactMap { $0.toProgram() }
        }
    }

    var allPrograms: [Program] {
        customPrograms + programs
    }

    func deleteCustomProgram(id: String, modelContext: ModelContext) {
        let repo = SwiftDataCustomProgramRepository(context: modelContext)
        if let record = try? repo.fetch(id: id) {
            try? repo.delete(record)
            customPrograms.removeAll { $0.id == id }
        }
    }

    static func isCustomProgram(_ program: Program) -> Bool {
        program.category == "custom"
    }

    func enroll(in program: Program, modelContext: ModelContext, userID: String = "") async {
        let repo = SwiftDataEnrolledProgramRepository(context: modelContext)
        enrollmentRepo = repo

        // Cancel any existing active enrollment first
        if let current = activeEnrollment {
            try? repo.cancel(current)
        }

        let enrollment = EnrolledProgram(
            id: UUID().uuidString,
            userID: userID,
            programID: program.id,
            startDate: .now,
            currentWeek: 1,
            currentDay: 1
        )
        try? repo.save(enrollment)
        activeEnrollment = try? repo.fetchActiveEnrollment()
    }

    func cancelEnrollment(modelContext: ModelContext) async {
        guard let enrollment = activeEnrollment else { return }
        let repo = SwiftDataEnrolledProgramRepository(context: modelContext)
        try? repo.cancel(enrollment)
        activeEnrollment = nil
    }
}
