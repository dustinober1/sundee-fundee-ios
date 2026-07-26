import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
final class QuickCheckInViewModel: ObservableObject {
    @Published var energy = 5
    @Published var fatigue = 5
    @Published var soreness = 3
    @Published var cramps = 0
    @Published var hasPain = false
    @Published var painIntensity = 1
    @Published var painType: PainType = .soreness
    @Published var painLocationID = BodyRegions.allRegions.first?.id ?? "lower_back"
    @Published var isPeriodActive = false
    @Published var notes = ""
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    func save(date: Date = Date()) async {
        isSaving = true
        errorMessage = nil

        do {
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let noteValue = trimmedNotes.isEmpty ? nil : trimmedNotes

            let symptomRecord = SymptomCheckInRecord(
                symptomDate: date,
                cramps: cramps,
                fatigue: fatigue,
                soreness: soreness,
                energy: energy,
                notes: noteValue
            )
            try await dataClient.save(symptomRecord, recordType: "SymptomCheckInRecord")

            if hasPain {
                let painLog = DailyPainLog(
                    id: UUID().uuidString,
                    locationIds: painLocationID,
                    intensity: painIntensity,
                    painType: painType,
                    date: date,
                    notes: noteValue
                )
                try await dataClient.save(painLog, recordType: "DailyPainLog")
            }

            if isPeriodActive {
                let periodRecord = PeriodLogRecord(
                    startDate: Calendar.current.startOfDay(for: date),
                    endDate: nil
                )
                try await dataClient.save(periodRecord, recordType: "PeriodLogRecord")
                NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
            }

            NotificationCenter.default.post(name: .dailyCheckInCompleted, object: nil)
        } catch {
            errorMessage = "We couldn't save your check-in. Check your connection and try again."
        }

        isSaving = false
    }
}
