import Foundation

// MARK: - CoachMemoryService

/// Manages reading and writing coach memory through the data layer.
///
/// This actor coordinates persistence of coach profiles, workout edits,
/// substitution decisions, and weekly summaries. It uses the existing
/// DataClientProtocol so memory automatically syncs via CloudKit
/// (for authenticated users) or stays local (for guests).
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor CoachMemoryService {
    private let dataClient: DataClientProtocol

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    // MARK: - Profile

    /// Loads the current coach profile, or creates a default one.
    public func getProfile() async -> CoachProfile {
        do {
            let records = try await dataClient.fetchAll(
                recordType: "CoachProfile"
            ) as [CoachProfile]
            return records.first ?? CoachProfile()
        } catch {
            return CoachProfile()
        }
    }

    /// Saves the coach profile.
    public func saveProfile(_ profile: CoachProfile) async {
        do {
            try await dataClient.save(profile, recordType: "CoachProfile")
        } catch {
            print("Error saving coach profile: \(error)")
        }
    }

    // MARK: - Workout Events

    /// Records a completed workout and updates the coach profile.
    ///
    /// Call this after the user finishes a workout.
    public func recordWorkoutCompletion(
        questionnaire: QuestionnaireAnswers,
        exerciseNames: [String]
    ) async {
        var profile = await getProfile()

        // Update energy distribution
        switch questionnaire.energyLevel {
        case .low: profile.energyDistribution.lowCount += 1
        case .medium: profile.energyDistribution.mediumCount += 1
        case .high: profile.energyDistribution.highCount += 1
        }

        profile.totalWorkoutsObserved += 1
        profile.lastUpdated = Date()

        await saveProfile(profile)
    }

    /// Records a workout edit for preference learning.
    public func recordWorkoutEdit(_ edit: WorkoutEdit) async {
        do {
            try await dataClient.save(edit, recordType: "WorkoutEdit")
        } catch {
            print("Error saving workout edit: \(error)")
        }
    }

    // MARK: - Substitution Decisions

    /// Records whether the user accepted or rejected a substitution.
    public func recordSubstitutionDecision(_ decision: AcceptedSubstitution) async {
        do {
            try await dataClient.save(decision, recordType: "AcceptedSubstitution")
        } catch {
            print("Error saving substitution decision: \(error)")
        }
    }

    // MARK: - Weekly Summaries

    /// Generates and saves a weekly summary for the given week.
    ///
    /// Call this at the end of each week (e.g., Sunday evening or Monday morning).
    public func generateAndSaveWeeklySummary(weekStart: Date) async -> CoachWeeklySummary? {
        let profile = await getProfile()

        do {
            let workouts = try await dataClient.fetchAll(
                recordType: "CompletedWorkoutRecord"
            ) as [CompletedWorkoutRecord]

            guard let summary = PreferenceLearner.generateWeeklySummary(
                workouts: workouts,
                weekStart: weekStart,
                profile: profile
            ) else {
                return nil
            }

            try await dataClient.save(summary, recordType: "CoachWeeklySummary")
            return summary
        } catch {
            print("Error generating weekly summary: \(error)")
            return nil
        }
    }

    /// Loads recent weekly summaries.
    public func getRecentSummaries(limit: Int = 4) async -> [CoachWeeklySummary] {
        do {
            let summaries = try await dataClient.fetchAll(
                recordType: "CoachWeeklySummary"
            ) as [CoachWeeklySummary]
            return Array(summaries.sorted { $0.weekStartDate > $1.weekStartDate }.prefix(limit))
        } catch {
            return []
        }
    }

    // MARK: - Full Profile Refresh

    /// Runs the full preference learning pipeline and updates the profile.
    ///
    /// Call this periodically (e.g., weekly) to refresh learned preferences
    /// from all available data.
    public func refreshProfile() async {
        let profile = await getProfile()

        do {
            let workouts = try await dataClient.fetchAll(
                recordType: "CompletedWorkoutRecord"
            ) as [CompletedWorkoutRecord]
            let edits = try await dataClient.fetchAll(
                recordType: "WorkoutEdit"
            ) as [WorkoutEdit]
            let subs = try await dataClient.fetchAll(
                recordType: "AcceptedSubstitution"
            ) as [AcceptedSubstitution]

            let updated = PreferenceLearner.learn(
                existingProfile: profile,
                workouts: workouts,
                edits: edits,
                substitutions: subs
            )

            await saveProfile(updated)
        } catch {
            print("Error refreshing coach profile: \(error)")
        }
    }
}
