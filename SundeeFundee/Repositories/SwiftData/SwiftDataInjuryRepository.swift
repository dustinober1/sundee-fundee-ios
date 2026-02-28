import Foundation
import SwiftData

final class SwiftDataInjuryRepository: InjuryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchActiveInjuries(userID: String) throws -> [InjuryProfile] {
        let active = InjuryStatus.active.rawValue
        let descriptor = FetchDescriptor<InjuryProfile>(
            predicate: #Predicate { $0.statusRaw == active },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchAll(userID: String) throws -> [InjuryProfile] {
        let descriptor = FetchDescriptor<InjuryProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func save(_ injury: InjuryProfile) throws {
        context.insert(injury)
        try context.save()
    }

    func resolve(_ injury: InjuryProfile) throws {
        injury.status = .resolved
        injury.recoveryPhase = .resolved
        injury.resolvedAt = .now
        injury.updatedAt = .now
        try context.save()
    }
}
