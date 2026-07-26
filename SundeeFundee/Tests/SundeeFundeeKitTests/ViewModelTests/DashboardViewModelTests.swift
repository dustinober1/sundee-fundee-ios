import CloudKit
import Foundation
import Testing
@testable import SundeeFundeeKit

@MainActor
@Suite("Dashboard view model")
struct DashboardViewModelTests {
    @Test func recoveryQuickWorkoutPublishesRecoveryProvenance() async {
        let healthClient = MockHealthKitClient()
        healthClient.isAvailable = false
        let viewModel = DashboardViewModel(
            healthClient: healthClient,
            dataClient: EmptyDashboardDataClient()
        )
        viewModel.todayTrainingDecision = TodayTrainingDecision(
            kind: .recover,
            title: "Recover",
            subtitle: "Keep it gentle",
            reasons: ["Recovery is the useful choice today."],
            primaryActionTitle: "Start recovery",
            systemImage: "leaf"
        )

        let workout = await viewModel.buildQuickWorkout()
        let event = WorkoutCompletionEvent(
            workout: workout,
            operationDate: Date(timeIntervalSince1970: 1_753_528_123)
        )

        #expect(workout.kind == .activeRecovery)
        #expect(event.presenceStatus == .resting)
        #expect(event.presenceEvidence == .recovered)
    }
}

private actor EmptyDashboardDataClient: DataClientProtocol {
    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        []
    }

    func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {}

    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws {}

    func deleteAllData() async throws {}
}
