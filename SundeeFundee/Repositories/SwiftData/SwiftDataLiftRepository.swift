import Foundation
import SwiftData

final class SwiftDataLiftRepository: LiftRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - LiftMax

    func saveLiftMax(_ max: LiftMax) throws {
        context.insert(max)
        try context.save()
    }

    func fetchLiftMaxes() throws -> [LiftMax] {
        let descriptor = FetchDescriptor<LiftMax>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchLiftMax(exercise: String) throws -> LiftMax? {
        let descriptor = FetchDescriptor<LiftMax>(
            predicate: #Predicate { $0.exerciseID == exercise },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - OneRepMax

    func saveOneRepMax(_ max: OneRepMax) throws {
        context.insert(max)
        try context.save()
    }

    func fetchOneRepMaxes() throws -> [OneRepMax] {
        let descriptor = FetchDescriptor<OneRepMax>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchOneRepMax(exercise: String) throws -> OneRepMax? {
        let descriptor = FetchDescriptor<OneRepMax>(
            predicate: #Predicate { $0.exerciseID == exercise },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - PersonalRecord

    func savePersonalRecord(_ pr: PersonalRecord) throws {
        context.insert(pr)
        try context.save()
    }

    func fetchPersonalRecords() throws -> [PersonalRecord] {
        let descriptor = FetchDescriptor<PersonalRecord>(
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchPersonalRecords(exercise: String) throws -> [PersonalRecord] {
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.exerciseID == exercise },
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - ConditioningPR

    func saveConditioningPR(_ pr: ConditioningPR) throws {
        context.insert(pr)
        try context.save()
    }

    func fetchConditioningPR(exercise: String) throws -> ConditioningPR? {
        let descriptor = FetchDescriptor<ConditioningPR>(
            predicate: #Predicate { $0.exerciseID == exercise },
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).first
    }

    func fetchAllConditioningPRs() throws -> [ConditioningPR] {
        let descriptor = FetchDescriptor<ConditioningPR>(
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
