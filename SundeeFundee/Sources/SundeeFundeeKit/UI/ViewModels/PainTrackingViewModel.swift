import Foundation

// MARK: - Pain Tracking View Model

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public class PainTrackingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var painLogs: [DailyPainLog] = []
    @Published var injuries: [Injury] = []
    @Published var selectedBodyRegions: Set<String> = []
    @Published var painIntensity: Int = 5
    @Published var selectedPainType: PainType = .soreness
    @Published var notes: String = ""
    @Published var substitutionSuggestions: [CoachSubstitutionResponse] = []

    // MARK: - Dependencies

    private let dataClient: DataClientProtocol

    // MARK: - Initialization

    public init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.dataClient = dataClient
    }

    // MARK: - Public Methods - Pain Logs

    /// Load all pain logs
    public func loadPainLogs() async {
        isLoading = true

        do {
            let records = try await dataClient.fetchAll(
                recordType: "DailyPainLog"
            ) as [DailyPainLog]

            painLogs = records.sorted { $0.date > $1.date }
        } catch {
            errorMessage = "Failed to load pain logs: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Save a new pain log entry
    public func logPain() async {
        guard !selectedBodyRegions.isEmpty else {
            errorMessage = "Please select at least one body region"
            return
        }

        guard (1...10).contains(painIntensity) else {
            errorMessage = "Pain intensity must be between 1 and 10"
            return
        }

        isLoading = true

        let locationIds = selectedBodyRegions.sorted().joined(separator: ",")
        let painLog = DailyPainLog(
            id: UUID().uuidString,
            locationIds: locationIds,
            intensity: painIntensity,
            painType: selectedPainType,
            date: Date(),
            notes: notes.isEmpty ? nil : notes
        )

        do {
            try await dataClient.save([painLog], recordType: "DailyPainLog")

            // Reset form
            selectedBodyRegions = []
            painIntensity = 5
            selectedPainType = .soreness
            notes = ""

            // Reload logs
            await loadPainLogs()
        } catch {
            errorMessage = "Failed to save pain log: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Delete a pain log
    public func deletePainLog(id: String) async {
        isLoading = true

        // In a full implementation, we'd need to track CKRecord.ID
        // For now, just remove from local array
        painLogs.removeAll { $0.id == id }

        isLoading = false
    }

    /// Get pain level for display
    public func painLevel(for intensity: Int) -> PainLevel {
        return PainLevel.from(intensity: intensity)
    }

    // MARK: - Public Methods - Injuries

    /// Load all injuries
    public func loadInjuries() async {
        isLoading = true

        do {
            let records = try await dataClient.fetchAll(
                recordType: "Injury"
            ) as [Injury]

            injuries = records.sorted { $0.phaseUpdated > $1.phaseUpdated }
        } catch {
            errorMessage = "Failed to load injuries: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Save or update an injury
    public func saveInjury(
        id: String? = nil,
        locationIds: String,
        name: String,
        recoveryPhase: RecoveryPhase,
        notes: String?
    ) async {
        isLoading = true

        let injury = Injury(
            id: id ?? UUID().uuidString,
            locationIds: locationIds,
            name: name,
            recoveryPhase: recoveryPhase,
            dateCreated: Date(),
            phaseUpdated: Date(),
            notes: notes
        )

        do {
            try await dataClient.save([injury], recordType: "Injury")
            await loadInjuries()
        } catch {
            errorMessage = "Failed to save injury: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Resolve an injury (mark as healed)
    public func resolveInjury(id: String) async {
        guard let injury = injuries.first(where: { $0.id == id }) else { return }
        await saveInjury(
            id: injury.id,
            locationIds: injury.locationIds,
            name: injury.name,
            recoveryPhase: .resolved,
            notes: injury.notes
        )
    }

    /// Delete an injury
    public func deleteInjury(id: String) async {
        isLoading = true

        // In a full implementation, we'd need to track CKRecord.ID
        // For now, just remove from local array
        injuries.removeAll { $0.id == id }

        isLoading = false
    }

    /// Get active injuries (not resolved)
    public var activeInjuries: [Injury] {
        return injuries.filter { $0.recoveryPhase != .resolved }
    }

    /// Get most severe injury (earliest in recovery)
    public var mostSevereInjury: Injury? {
        return activeInjuries.min { $0.recoveryPhase < $1.recoveryPhase }
    }

    // MARK: - Exercise Adaptation

    /// Check if an exercise is contraindicated
    public func isExerciseContraindicated(
        exerciseName: String,
        exerciseCategory: String? = nil
    ) -> Bool {
        return InjuryAdaptationEngine.isContraindicated(
            exerciseName: exerciseName,
            exerciseCategory: exerciseCategory,
            injuries: activeInjuries
        )
    }

    /// Get regressions for an exercise
    public func getRegressions(for exerciseName: String) -> [String] {
        return InjuryAdaptationEngine.getRegressions(
            exerciseName: exerciseName,
            injuries: activeInjuries
        )
    }

    /// Calculate appropriate load for an exercise
    public func calculateAdaptedLoad(baseLoad: Double) -> Double {
        return InjuryAdaptationEngine.calculateLoadMultiplier(
            baseLoad: baseLoad,
            injuries: activeInjuries
        )
    }

    // MARK: - Smart Substitutions (Pro)

    /// Loads substitution suggestions for contraindicated exercises.
    /// Only available for Pro tier users with active injuries.
    public func loadSubstitutionSuggestions() async {
        guard !activeInjuries.isEmpty else {
            substitutionSuggestions = []
            return
        }

        let coachService = CoachServiceFactory.makeService()
        let context = CoachContext(
            tier: .premium,
            injuries: activeInjuries,
            equipment: .fullGym
        )

        // Find contraindicated exercises from the catalog and suggest alternatives
        let contraindicatedExercises = weightliftingExercises.filter { entry in
            InjuryAdaptationEngine.isContraindicated(
                exerciseName: entry.id,
                exerciseCategory: nil,
                injuries: activeInjuries
            )
        }

        var suggestions: [CoachSubstitutionResponse] = []
        for exercise in contraindicatedExercises.prefix(5) {
            do {
                let response = try await coachService.suggestSubstitutions(
                    for: exercise.id,
                    context: context
                )
                if !response.substitutions.isEmpty {
                    suggestions.append(response)
                }
            } catch {
                continue
            }
        }

        substitutionSuggestions = suggestions
    }
}
