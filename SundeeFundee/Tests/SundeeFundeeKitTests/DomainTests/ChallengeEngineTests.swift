import XCTest
@testable import SundeeFundeeKit

final class ChallengeEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeWorkout(
        exerciseName: String = "Back Squat",
        sets: Int = 4,
        reps: Int = 8,
        weight: Double = 200,
        daysAgo: Int = 0
    ) -> Workout {
        let exerciseSets = (0..<sets).map { _ in
            ExerciseSet(
                reps: reps,
                prescribedWeight: weight,
                type: .fixed,
                completedWeight: weight,
                actualReps: reps,
                isComplete: true
            )
        }
        let exercise = Exercise(
            id: UUID().uuidString,
            name: exerciseName,
            category: .compound,
            bodyweight: 0,
            targetSets: exerciseSets
        )
        return Workout(
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            name: "Workout",
            exercises: [exercise],
            completedAt: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        )
    }

    // MARK: - Default Tiers

    func testDefaultLifetimeTiers() {
        let tiers = ChallengeEngine.defaultLifetimeTiers()
        XCTAssertEqual(tiers.count, 3)
        XCTAssertEqual(tiers[0].name, "Bronze")
        XCTAssertEqual(tiers[0].targetVolumeLbs, 250_000)
        XCTAssertEqual(tiers[1].name, "Silver")
        XCTAssertEqual(tiers[2].name, "Gold")
        XCTAssertEqual(tiers[2].targetVolumeLbs, 1_000_000)
    }

    // MARK: - Challenge Creation

    func testCreateLifetimeChallenge() {
        let challenge = ChallengeEngine.createLifetimeChallenge()
        XCTAssertEqual(challenge.type, .lifetimeVolume)
        XCTAssertEqual(challenge.tiers.count, 3)
        XCTAssertEqual(challenge.status, .active)
        XCTAssertNil(challenge.endDate)
    }

    func testCreateExerciseChallenge() {
        let tiers = [ChallengeTier(name: "Goal", targetVolumeLbs: 50_000, ordinal: 0)]
        let challenge = ChallengeEngine.createExerciseChallenge(
            exerciseName: "Back Squat",
            tiers: tiers
        )
        XCTAssertEqual(challenge.type, .exerciseVolume)
        XCTAssertEqual(challenge.exerciseName, "Back Squat")
        XCTAssertEqual(challenge.title, "Back Squat Volume")
    }

    func testCreateCustomChallenge_WithEndDate() {
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        let challenge = ChallengeEngine.createCustomChallenge(
            title: "March Madness",
            targetVolumeLbs: 100_000,
            endDate: endDate
        )
        XCTAssertEqual(challenge.type, .custom)
        XCTAssertEqual(challenge.title, "March Madness")
        XCTAssertNotNil(challenge.endDate)
        XCTAssertEqual(challenge.tiers.count, 1)
        XCTAssertEqual(challenge.tiers[0].targetVolumeLbs, 100_000)
    }

    // MARK: - Progress Computation

    func testComputeProgress_MidTier_CorrectPercentage() {
        var challenge = ChallengeEngine.createLifetimeChallenge()
        challenge.accumulatedVolumeLbs = 125_000 // 50% of Bronze (250K)
        let progress = ChallengeEngine.computeProgress(challenge: challenge)
        XCTAssertEqual(progress.currentTierName, "Bronze")
        XCTAssertEqual(progress.percentComplete, 0.5, accuracy: 0.01)
        XCTAssertEqual(progress.volumeRemaining, 125_000, accuracy: 1)
        XCTAssertFalse(progress.isFullyComplete)
    }

    func testComputeProgress_TierComplete_AdvancesToNext() {
        var challenge = ChallengeEngine.createLifetimeChallenge()
        challenge.accumulatedVolumeLbs = 250_000
        challenge.currentTierIndex = 1 // Advanced to Silver
        let progress = ChallengeEngine.computeProgress(challenge: challenge)
        XCTAssertEqual(progress.currentTierName, "Silver")
        XCTAssertEqual(progress.percentComplete, 0.0, accuracy: 0.01)
    }

    // MARK: - Volume Update

    func testUpdateVolume_CrossesTier_AdvancesToNext() {
        var challenge = ChallengeEngine.createLifetimeChallenge()
        challenge.accumulatedVolumeLbs = 249_000
        let (updated, progress) = ChallengeEngine.updateVolume(
            challenge: challenge,
            additionalVolumeLbs: 2_000
        )
        XCTAssertEqual(updated.currentTierIndex, 1, "Should advance past Bronze")
        XCTAssertNotNil(progress.justCompletedTier)
        XCTAssertEqual(progress.justCompletedTier?.name, "Bronze")
    }

    func testUpdateVolume_FinalTier_MarksCompleted() {
        var challenge = ChallengeEngine.createLifetimeChallenge()
        challenge.accumulatedVolumeLbs = 999_000
        challenge.currentTierIndex = 2 // On Gold tier
        let (updated, progress) = ChallengeEngine.updateVolume(
            challenge: challenge,
            additionalVolumeLbs: 2_000
        )
        XCTAssertEqual(updated.status, .completed)
        XCTAssertTrue(progress.isFullyComplete)
        XCTAssertEqual(progress.justCompletedTier?.name, "Gold")
    }

    // MARK: - Retroactive Volume

    func testRetroactiveVolume_SumsCorrectly() {
        let workouts = [
            makeWorkout(sets: 4, reps: 8, weight: 200, daysAgo: 5),
            makeWorkout(sets: 4, reps: 8, weight: 200, daysAgo: 3),
        ]
        // Each workout: 4 sets × 8 reps × 200 lbs = 6,400 lbs
        // Total: 12,800 lbs
        let volume = ChallengeEngine.retroactiveVolume(from: workouts)
        XCTAssertEqual(volume, 12_800, accuracy: 1)
    }

    func testRetroactiveVolume_FiltersByExercise() {
        let workout = Workout(
            date: Date(),
            name: "Mixed",
            exercises: [
                Exercise(
                    id: UUID().uuidString,
                    name: "Back Squat",
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(reps: 5, prescribedWeight: 300, type: .fixed,
                                    completedWeight: 300, actualReps: 5, isComplete: true)
                    ]
                ),
                Exercise(
                    id: UUID().uuidString,
                    name: "Bench Press",
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(reps: 5, prescribedWeight: 200, type: .fixed,
                                    completedWeight: 200, actualReps: 5, isComplete: true)
                    ]
                ),
            ],
            completedAt: Date()
        )
        let squatVolume = ChallengeEngine.retroactiveVolume(
            from: [workout],
            exerciseName: "Back Squat"
        )
        XCTAssertEqual(squatVolume, 1_500, accuracy: 1) // 5 × 300
    }

    // MARK: - Expiration

    func testCheckExpiration_PastEndDate_MarksExpired() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let challenge = ChallengeEngine.createCustomChallenge(
            title: "Test",
            targetVolumeLbs: 50_000,
            endDate: pastDate
        )
        let result = ChallengeEngine.checkExpiration(challenge: challenge)
        XCTAssertEqual(result.status, .expired)
    }

    func testCheckExpiration_FutureEndDate_StaysActive() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let challenge = ChallengeEngine.createCustomChallenge(
            title: "Test",
            targetVolumeLbs: 50_000,
            endDate: futureDate
        )
        let result = ChallengeEngine.checkExpiration(challenge: challenge)
        XCTAssertEqual(result.status, .active)
    }

    func testCheckExpiration_NoEndDate_StaysActive() {
        let challenge = ChallengeEngine.createLifetimeChallenge()
        let result = ChallengeEngine.checkExpiration(challenge: challenge)
        XCTAssertEqual(result.status, .active)
    }
}
