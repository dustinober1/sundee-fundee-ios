import Foundation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    var displayName: String = ""
    var experienceLevel: ExperienceLevel = .beginner
    var primaryGoal: PrimaryGoal = .strength
    var weightUnit: WeightUnit = .pounds
    var injuryProfiles: [InjuryProfile] = []

    private var modelContext: ModelContext?
    private var userID: String = ""
    private var currentUser: User?

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
        }

        let injuryRepo = SwiftDataInjuryRepository(context: modelContext)
        injuryProfiles = (try? injuryRepo.fetchAll(userID: userID)) ?? []
        loadPainLogs()
        evaluateTransitions()
    }

    func saveProfile() async {
        guard let ctx = modelContext else { return }
        if let user = currentUser {
            user.name = displayName
            user.experienceLevel = experienceLevel
            user.primaryGoal = primaryGoal
            user.weightUnit = weightUnit
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

    func evaluateTransitions() {
        transitionSuggestions = injuryProfiles.compactMap { injury in
            guard injury.isActive else { return nil }
            let logs = painLogs[injury.id] ?? []
            return PhaseTransitionAdvisor.evaluateTransition(
                injuryID: injury.id,
                currentPhase: injury.recoveryPhase,
                painLogs: logs
            )
        }
    }

    func acceptTransition(_ suggestion: PhaseTransitionAdvisor.Suggestion) {
        guard let ctx = modelContext,
              let injury = injuryProfiles.first(where: { $0.id == suggestion.injuryID }) else { return }
        injury.recoveryPhase = suggestion.suggestedPhase
        injury.updatedAt = .now
        try? ctx.save()
        transitionSuggestions.removeAll { $0.injuryID == suggestion.injuryID }
    }

    func dismissTransition(_ suggestion: PhaseTransitionAdvisor.Suggestion) {
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
}

// MARK: - Display name extensions

// MARK: - Display names are defined in OnboardingFlowView.swift extensions
