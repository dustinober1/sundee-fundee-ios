import Foundation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    var displayName: String = ""
    var experienceLevel: ExperienceLevel = .beginner
    var primaryGoal: PrimaryGoal = .strength
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
        }

        let injuryDescriptor = FetchDescriptor<InjuryProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        injuryProfiles = try! modelContext.fetch(injuryDescriptor)
    }

    func saveProfile() async {
        guard let ctx = modelContext else { return }
        if let user = currentUser {
            user.name = displayName
            user.experienceLevel = experienceLevel
            user.primaryGoal = primaryGoal
            try? ctx.save()
        }
    }

    func addInjury(location: String, limitations: String, recoveryGoal: String) {
        guard let ctx = modelContext else { return }
        let injury = InjuryProfile(
            id: UUID().uuidString,
            userID: userID,
            location: location,
            movementLimitations: limitations,
            recoveryGoal: recoveryGoal
        )
        ctx.insert(injury)
        try? ctx.save()
        injuryProfiles.insert(injury, at: 0)
    }

    func updateInjury(_ injury: InjuryProfile, location: String, limitations: String, recoveryGoal: String) {
        guard let ctx = modelContext else { return }
        injury.location = location
        injury.movementLimitations = limitations
        injury.recoveryGoal = recoveryGoal
        injury.updatedAt = .now
        try? ctx.save()
    }

    func resolveInjury(_ injury: InjuryProfile) {
        guard let ctx = modelContext else { return }
        injury.status = .resolved
        injury.resolvedAt = .now
        injury.updatedAt = .now
        try? ctx.save()
        if let idx = injuryProfiles.firstIndex(where: { $0.id == injury.id }) {
            injuryProfiles[idx] = injury
        }
    }
}

// MARK: - Display name extensions

// MARK: - Display names are defined in OnboardingFlowView.swift extensions
