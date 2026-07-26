import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("Workout completion provenance")
struct WorkoutCompletionEventTests {
    @Test func legacyWorkoutWithoutKindDecodesAsStandard() throws {
        let json = """
        {
          "id":"workout-1",
          "date":"2026-07-26T12:00:00Z",
          "name":"Strength",
          "duration":45
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let workout = try decoder.decode(Workout.self, from: Data(json.utf8))

        #expect(workout.kind == .standard)
    }

    @Test func regularCompletionRoutesToTrainingPresence() {
        let event = WorkoutCompletionEvent(
            workoutID: "workout-1",
            kind: .standard,
            operationDate: Date(timeIntervalSince1970: 1_753_528_400)
        )

        #expect(event.presenceStatus == .trained)
        #expect(event.presenceEvidence == .trained)
    }

    @Test func activeRecoveryCompletionRoutesToRecoveryPresenceAtCompletionDate() {
        let completedAt = Date(timeIntervalSince1970: 1_753_528_400)
        let event = WorkoutCompletionEvent(
            workoutID: "recovery-1",
            kind: .activeRecovery,
            operationDate: completedAt
        )

        #expect(event.presenceStatus == .resting)
        #expect(event.presenceEvidence == .recovered)
        #expect(event.operationDate == completedAt)
    }

    @Test func untypedNotificationDoesNotBecomeAWorkoutCompletion() {
        let notification = Notification(name: .workoutCompleted, object: nil)

        #expect(WorkoutCompletionEvent.from(notification: notification) == nil)
    }
}
