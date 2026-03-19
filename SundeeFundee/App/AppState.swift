import SwiftUI
import SwiftData

/// Top-level auth state that drives routing.
enum AuthState {
    case loading
    case signedOut
    case needsOnboarding(userID: String, appleUserID: String)
    case authenticated(userID: String)
    case guest
}

@Observable
@MainActor
final class AppState {
    var authState: AuthState = .loading
    var currentUserID: String?

    let authService = AuthService()

    func signInAsGuest() {
        if let existingGuestID = KeychainHelper.loadGuestUserID() {
            currentUserID = existingGuestID
        } else {
            let newGuestID = UUID().uuidString
            KeychainHelper.saveGuestUserID(newGuestID)
            currentUserID = newGuestID
        }
        authState = .guest
    }

    func signOut(modelContext: ModelContext? = nil) {
        if let modelContext {
            // Sign-out wipes workout-data models only — preferences are preserved so the user
            // returns to guest mode with their settings intact (FIX-02).
            let workoutDataTypes: [any PersistentModel.Type] = [
                CompletedWorkout.self,
                CompletedSet.self,
                OneRepMax.self,
                PersonalRecord.self,
                LiftMax.self,
                PeriodLog.self,
                SymptomLog.self,
                BenchmarkResult.self,
                ConditioningPR.self,
                GeneratedWorkoutRecord.self,
                ActiveCycle.self,
                EnrolledProgram.self,
            ]
            for modelType in workoutDataTypes {
                try? modelContext.delete(model: modelType)
            }
            try? modelContext.save()
        }
        KeychainHelper.deleteAppleUserID()
        // Return to guest mode with a stable UUID so the user can keep using the app.
        signInAsGuest()
    }

    func deleteAccountAndData(modelContext: ModelContext) {
        // Delete-account wipes ALL V12 models — including BarbellPreset and ExerciseBarMapping
        // that were added in V11/V12 and missed by the stale V10 reference (FIX-02).
        for modelType in AppSchemaV12.models {
            try? modelContext.delete(model: modelType)
        }
        try? modelContext.save()
        KeychainHelper.deleteAppleUserID()
        KeychainHelper.deleteGuestUserID()
        UserDefaults.standard.removeObject(forKey: "guestMigrationPending")
        UserDefaults.standard.removeObject(forKey: "com.sundeefundee.subscription.tier")
        UserDefaults.standard.removeObject(forKey: "dismissedPhaseTransitions")
        UserDefaults.standard.removeObject(forKey: "com.sundeefundee.ai.dataConsent")
        authState = .signedOut
        currentUserID = nil
    }

    func apply(_ state: AuthState) {
        authState = state
        if case .authenticated(let id) = state { currentUserID = id }
        else if case .needsOnboarding(let id, _) = state { currentUserID = id }
        else { currentUserID = nil }
    }
}
