import Foundation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    var displayName: String = ""
    var experienceLevel: ExperienceLevel = .beginner
    var primaryGoal: PrimaryGoal = .strength
    var weightUnit: WeightUnit = .pounds
    var gender: Gender = .preferNotToSay
    var cycleTrackingEnabled: Bool = false
    var bodyWeight: Double? = nil
    var injuryProfiles: [InjuryProfile] = []
    var barbellPresets: [BarbellPresetDTO] = []

    private var modelContext: ModelContext?
    private var userID: String = ""
    private var currentUser: User?
    private var barbellRepo: (any BarbellRepository)?

    func load(modelContext: ModelContext, userID: String) async {
        self.modelContext = modelContext
        self.userID = userID

        let userRepo = SwiftDataUserRepository(context: modelContext)
        if let user = try? userRepo.fetchCurrentUser() {
            currentUser = user
            displayName = user.name
            experienceLevel = user.experienceLevel
            primaryGoal = user.primaryGoal
            weightUnit = user.weightUnit
            gender = user.gender
            cycleTrackingEnabled = user.cycleTrackingEnabled
            bodyWeight = user.bodyWeightKg
        }

        let injuryRepo = SwiftDataInjuryRepository(context: modelContext)
        injuryProfiles = (try? injuryRepo.fetchAll(userID: userID)) ?? []
        loadPainLogs()
        let repo = SwiftDataBarbellRepository(context: modelContext)
        repo.seedBuiltInPresets(userID: userID)
        barbellRepo = repo
        barbellPresets = (try? repo.fetchPresets(userID: userID)) ?? []
        evaluateTransitions()
    }

    func saveProfile() async {
        guard let ctx = modelContext else { return }
        if let user = currentUser {
            user.name = displayName
            user.experienceLevel = experienceLevel
            user.primaryGoal = primaryGoal
            user.weightUnit = weightUnit
            user.gender = gender
            user.cycleTrackingEnabled = cycleTrackingEnabled
            user.bodyWeightKg = bodyWeight
            try? ctx.save()
        }
    }

    func addInjury(location: String, limitations: String, recoveryGoal: String, locationRegions: [BodyLocation.Region] = []) {
        guard let ctx = modelContext else { return }
        let injury = InjuryProfile(
            id: UUID().uuidString,
            userID: userID,
            location: location,
            movementLimitations: limitations,
            recoveryGoal: recoveryGoal
        )
        if !locationRegions.isEmpty {
            injury.locationRegions = locationRegions
        }
        let repo = SwiftDataInjuryRepository(context: ctx)
        try? repo.save(injury)
        injuryProfiles.insert(injury, at: 0)
    }

    func updateInjury(_ injury: InjuryProfile, location: String, limitations: String, recoveryGoal: String, recoveryPhase: RecoveryPhase? = nil) {
        guard let ctx = modelContext else { return }
        injury.location = location
        injury.movementLimitations = limitations
        injury.recoveryGoal = recoveryGoal
        if let phase = recoveryPhase {
            injury.recoveryPhase = phase
        }
        injury.updatedAt = .now
        try? ctx.save()
    }

    var painLogs: [String: [PainLog]] = [:]

    func loadPainLogs() {
        guard let ctx = modelContext else { return }
        let repo = SwiftDataPainLogRepository(context: ctx)
        for injury in injuryProfiles {
            painLogs[injury.id] = (try? repo.fetchLogs(injuryProfileID: injury.id)) ?? []
        }
    }

    func logPain(injuryID: String, level: Int, workoutID: String? = nil, notes: String? = nil) {
        guard let ctx = modelContext else { return }
        let log = PainLog(injuryProfileID: injuryID, painLevel: level, workoutID: workoutID, notes: notes)
        let repo = SwiftDataPainLogRepository(context: ctx)
        try? repo.save(log)
        painLogs[injuryID, default: []].insert(log, at: 0)
    }

    var transitionSuggestions: [PhaseTransitionAdvisor.Suggestion] = []

    private static let dismissedTransitionsKey = "dismissedPhaseTransitions"

    private static func loadDismissedTransitions() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: dismissedTransitionsKey) as? [String: String] ?? [:]
    }

    private static func saveDismissedTransition(injuryID: String, phase: String) {
        var dismissed = loadDismissedTransitions()
        dismissed[injuryID] = phase
        UserDefaults.standard.set(dismissed, forKey: dismissedTransitionsKey)
    }

    private static func clearDismissedTransition(injuryID: String) {
        var dismissed = loadDismissedTransitions()
        dismissed.removeValue(forKey: injuryID)
        UserDefaults.standard.set(dismissed, forKey: dismissedTransitionsKey)
    }

    func evaluateTransitions() {
        let dismissed = Self.loadDismissedTransitions()
        transitionSuggestions = injuryProfiles.compactMap { injury in
            guard injury.isActive else { return nil }
            let logs = painLogs[injury.id] ?? []
            guard let suggestion = PhaseTransitionAdvisor.evaluateTransition(
                injuryID: injury.id,
                currentPhase: injury.recoveryPhase,
                painLogs: logs
            ) else { return nil }
            // Skip if user already dismissed this specific transition
            if dismissed[injury.id] == suggestion.suggestedPhase.rawValue {
                return nil
            }
            return suggestion
        }
    }

    func acceptTransition(_ suggestion: PhaseTransitionAdvisor.Suggestion) {
        guard let ctx = modelContext,
              let injury = injuryProfiles.first(where: { $0.id == suggestion.injuryID }) else { return }
        injury.recoveryPhase = suggestion.suggestedPhase
        injury.updatedAt = .now
        try? ctx.save()
        Self.clearDismissedTransition(injuryID: suggestion.injuryID)
        transitionSuggestions.removeAll { $0.injuryID == suggestion.injuryID }
    }

    func dismissTransition(_ suggestion: PhaseTransitionAdvisor.Suggestion) {
        Self.saveDismissedTransition(injuryID: suggestion.injuryID, phase: suggestion.suggestedPhase.rawValue)
        transitionSuggestions.removeAll { $0.injuryID == suggestion.injuryID }
    }

    func resolveInjury(_ injury: InjuryProfile) {
        guard let ctx = modelContext else { return }
        let repo = SwiftDataInjuryRepository(context: ctx)
        try? repo.resolve(injury)
        if let idx = injuryProfiles.firstIndex(where: { $0.id == injury.id }) {
            injuryProfiles[idx] = injury
        }
    }
    func addCustomBarbell(name: String, weightKg: Double) {
        guard let repo = barbellRepo else { return }
        let maxOrder = barbellPresets.map(\.sortOrder).max() ?? 0
        let preset = BarbellPresetDTO(
            id: UUID().uuidString,
            userID: userID,
            name: name,
            weightKg: weightKg,
            isBuiltIn: false,
            sortOrder: maxOrder + 1
        )
        try? repo.savePreset(preset)
        barbellPresets = (try? repo.fetchPresets(userID: userID)) ?? []
    }

    func deleteCustomBarbell(id: String) {
        guard let repo = barbellRepo else { return }
        try? repo.deletePreset(id: id)
        barbellPresets = (try? repo.fetchPresets(userID: userID)) ?? []
    }
}

// MARK: - Display name extensions

// MARK: - Display names are defined in OnboardingFlowView.swift extensions
