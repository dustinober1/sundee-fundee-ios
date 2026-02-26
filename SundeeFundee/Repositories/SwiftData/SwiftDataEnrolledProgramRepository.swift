import Foundation
import SwiftData

final class SwiftDataEnrolledProgramRepository: EnrolledProgramRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ enrollment: EnrolledProgram) throws {
        context.insert(enrollment)
        try context.save()
    }

    func fetchAllEnrollments() throws -> [EnrolledProgram] {
        let descriptor = FetchDescriptor<EnrolledProgram>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchActiveEnrollment() throws -> EnrolledProgram? {
        let activeStatus = EnrollmentStatus.active.rawValue
        let descriptor = FetchDescriptor<EnrolledProgram>(
            predicate: #Predicate { $0.statusRaw == activeStatus }
        )
        return try context.fetch(descriptor).first
    }

    func fetchLatestCanceledEnrollment(programId: String) throws -> EnrolledProgram? {
        let canceledStatus = EnrollmentStatus.canceled.rawValue
        let descriptor = FetchDescriptor<EnrolledProgram>(
            predicate: #Predicate { $0.programID == programId && $0.statusRaw == canceledStatus },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try context.fetch(descriptor).first
    }

    func updateProgress(enrollment: EnrolledProgram, week: Int, day: Int) throws {
        enrollment.currentWeek = week
        enrollment.currentDay = day
        try context.save()
    }

    func complete(_ enrollment: EnrolledProgram) throws {
        enrollment.statusRaw = EnrollmentStatus.completed.rawValue
        enrollment.completedAt = .now
        try context.save()
    }

    func cancel(_ enrollment: EnrolledProgram) throws {
        enrollment.statusRaw = EnrollmentStatus.canceled.rawValue
        enrollment.canceledAt = .now
        try context.save()
    }

    func delete(_ enrollment: EnrolledProgram) throws {
        context.delete(enrollment)
        try context.save()
    }
}
