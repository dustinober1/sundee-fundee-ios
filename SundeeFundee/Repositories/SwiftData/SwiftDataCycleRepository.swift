import Foundation
import SwiftData

final class SwiftDataCycleRepository: CycleRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - ActiveCycle

    func save(_ cycle: ActiveCycle) throws {
        context.insert(cycle)
        try context.save()
    }

    func fetchActiveCycles() throws -> [ActiveCycle] {
        let descriptor = FetchDescriptor<ActiveCycle>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchCurrentActiveCycle() throws -> ActiveCycle? {
        let statusActive = CycleStatus.active.rawValue
        let descriptor = FetchDescriptor<ActiveCycle>(
            predicate: #Predicate { $0.statusRaw == statusActive }
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - PeriodLog

    func savePeriodLog(_ log: PeriodLog) throws {
        context.insert(log)
        try context.save()
    }

    func deletePeriodLog(_ log: PeriodLog) throws {
        context.delete(log)
        try context.save()
    }

    func fetchPeriodLogs() throws -> [PeriodLog] {
        let descriptor = FetchDescriptor<PeriodLog>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - SymptomLog

    func saveSymptomLog(_ log: SymptomLog) throws {
        context.insert(log)
        try context.save()
    }

    func deleteSymptomLog(_ log: SymptomLog) throws {
        context.delete(log)
        try context.save()
    }

    func fetchSymptomLogs() throws -> [SymptomLog] {
        let descriptor = FetchDescriptor<SymptomLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - CycleSettings

    func saveCycleSettings(_ settings: CycleSettings) throws {
        context.insert(settings)
        try context.save()
    }

    func fetchCycleSettings() throws -> CycleSettings? {
        let descriptor = FetchDescriptor<CycleSettings>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - CycleAdaptationPreferences

    func saveCycleAdaptationPreferences(_ prefs: CycleAdaptationPreferences) throws {
        context.insert(prefs)
        try context.save()
    }

    func fetchCycleAdaptationPreferences() throws -> CycleAdaptationPreferences? {
        let descriptor = FetchDescriptor<CycleAdaptationPreferences>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).first
    }
}
