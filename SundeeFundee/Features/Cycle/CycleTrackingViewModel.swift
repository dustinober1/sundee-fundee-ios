import Foundation
import SwiftData

@MainActor
@Observable
final class CycleTrackingViewModel {
    var cycleStatus: CycleStatusResult?
    var periodLogs: [PeriodLog] = []
    var symptomLogs: [SymptomLog] = []

    // Settings state
    var avgCycleLength: Int = 28
    var avgPeriodLength: Int = 5
    var lutealPhaseLength: Int = 14
    var adaptationEnabled: Bool = true

    // Sheet flags
    var showAddPeriodLog = false
    var showAddSymptomLog = false

    private let repositoryFactory: (ModelContext) -> any CycleRepository
    private var modelContext: ModelContext?
    private var userID: String = ""

    init(
        repositoryFactory: @escaping (ModelContext) -> any CycleRepository = {
            SwiftDataCycleRepository(context: $0)
        }
    ) {
        self.repositoryFactory = repositoryFactory
    }

    func load(modelContext: ModelContext, userID: String = "") async {
        self.modelContext = modelContext
        self.userID = userID
        let repo = repositoryFactory(modelContext)

        periodLogs = (try? repo.fetchPeriodLogs()) ?? []
        symptomLogs = (try? repo.fetchSymptomLogs()) ?? []

        if let settings = try? repo.fetchCycleSettings() {
            avgCycleLength = settings.averageCycleLengthDays
            avgPeriodLength = settings.averagePeriodLengthDays
            lutealPhaseLength = settings.lutealPhaseLengthDays
        }

        if let settings = try? repo.fetchCycleSettings(), !periodLogs.isEmpty {
            cycleStatus = CycleCalculations.calculateCycleStatus(
                periodLogs: periodLogs,
                settings: settings
            )
        }
    }

    // MARK: - Period logs

    func addPeriodLog(startDate: Date, endDate: Date?, flowLevel: FlowLevel) {
        guard let ctx = modelContext else { return }
        let log = PeriodLog(
            id: UUID().uuidString,
            userID: userID,
            startDate: startDate,
            endDate: endDate,
            flowLevel: flowLevel
        )
        let repo = repositoryFactory(ctx)
        try? repo.savePeriodLog(log)
        periodLogs.insert(log, at: 0)
        refreshCycleStatus()
    }

    func deletePeriodLogs(at offsets: IndexSet) {
        guard let ctx = modelContext else { return }
        let repo = repositoryFactory(ctx)
        for idx in offsets {
            let log = periodLogs[idx]
            try? repo.deletePeriodLog(log)
        }
        periodLogs.remove(atOffsets: offsets)
        refreshCycleStatus()
    }

    // MARK: - Symptom logs

    func addSymptomLog(symptomID: String, severity: Int, date: Date, notes: String?) {
        guard let ctx = modelContext else { return }
        let log = SymptomLog(
            id: UUID().uuidString,
            userID: userID,
            date: date,
            symptomID: symptomID,
            severity: severity,
            notes: notes
        )
        let repo = repositoryFactory(ctx)
        try? repo.saveSymptomLog(log)
        symptomLogs.insert(log, at: 0)
    }

    func deleteSymptomLogs(at offsets: IndexSet) {
        guard let ctx = modelContext else { return }
        let repo = repositoryFactory(ctx)
        for idx in offsets {
            let log = symptomLogs[idx]
            try? repo.deleteSymptomLog(log)
        }
        symptomLogs.remove(atOffsets: offsets)
    }

    // MARK: - Settings

    func saveSettings() async {
        guard let ctx = modelContext else { return }
        let settings = CycleSettings(
            id: UUID().uuidString,
            userID: userID,
            averageCycleLengthDays: avgCycleLength,
            averagePeriodLengthDays: avgPeriodLength,
            lutealPhaseLengthDays: lutealPhaseLength,
            isTrackingEnabled: adaptationEnabled
        )
        let repo = repositoryFactory(ctx)
        try? repo.saveCycleSettings(settings)
        refreshCycleStatus()
    }

    // MARK: - Helpers

    private func refreshCycleStatus() {
        guard let ctx = modelContext,
              let repo = Optional(repositoryFactory(ctx)),
              let settings = try? repo.fetchCycleSettings(),
              !periodLogs.isEmpty else {
            cycleStatus = nil
            return
        }
        cycleStatus = CycleCalculations.calculateCycleStatus(
            periodLogs: periodLogs,
            settings: settings
        )
    }
}
