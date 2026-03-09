import Foundation
import SwiftData

@MainActor
@Observable
final class ProgramListViewModel {
    var programs: [Program] = []
    var searchText: String = ""
    var activeEnrollment: EnrolledProgram?
    var isLoading = false
    var errorMessage: String?

    var filteredPrograms: [Program] {
        Self.filterPrograms(programs, searchText: searchText)
    }

    static func filterPrograms(_ programs: [Program], searchText: String) -> [Program] {
        guard !searchText.isEmpty else { return programs }
        let query = searchText.lowercased()
        return programs.filter {
            $0.name.lowercased().contains(query) ||
            $0.category.lowercased().contains(query)
        }
    }

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
        }
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
