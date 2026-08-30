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

    @Test func loadProgramInfoRoutesToTheNextIncompleteSession() async {
        let template = ProgramTemplate.beginnerStrength
        let generated = generateProgram(template: template, name: "Beginner Strength")
        let sessions = generated.weeks.flatMap(\.sessions)
        #expect(sessions.count > 1)

        let enrolled = EnrolledProgramRecord(id: template.stableID, name: "Beginner Strength", isActive: true)
        let completedWorkout = Workout(
            id: "workout-1",
            date: Date(),
            name: sessions[0].sessionName,
            exercises: [],
            completedAt: Date()
        )
        let completedSessionRecord = ProgramSessionRecord(
            id: "session-record-1",
            programId: template.stableID,
            sessionId: sessions[0].sessionId,
            workoutId: completedWorkout.id,
            week: 1
        )

        let dataClient = ProgramProgressDashboardDataClient(
            enrolledPrograms: [enrolled],
            sessionRecords: [completedSessionRecord],
            workouts: [completedWorkout]
        )
        let viewModel = DashboardViewModel(
            healthClient: MockHealthKitClient(),
            dataClient: dataClient
        )

        await viewModel.loadProgramInfo()

        #expect(viewModel.activeProgramName == "Beginner Strength")
        #expect(viewModel.nextWorkout == sessions[1].sessionName)
        #expect(viewModel.nextProgramListItem?.isEnrolled == true)
        #expect(viewModel.nextProgramListItem?.template == template)
    }

    @Test func loadProgramInfoFallsBackToFirstSessionWhenNoneAreComplete() async {
        let template = ProgramTemplate.beginnerStrength
        let generated = generateProgram(template: template, name: "Beginner Strength")
        let sessions = generated.weeks.flatMap(\.sessions)

        let enrolled = EnrolledProgramRecord(id: template.stableID, name: "Beginner Strength", isActive: true)
        let dataClient = ProgramProgressDashboardDataClient(
            enrolledPrograms: [enrolled],
            sessionRecords: [],
            workouts: []
        )
        let viewModel = DashboardViewModel(
            healthClient: MockHealthKitClient(),
            dataClient: dataClient
        )

        await viewModel.loadProgramInfo()

        #expect(viewModel.nextWorkout == sessions.first?.sessionName)
    }

    @Test func loadProgramInfoClearsStateWithNoActiveProgram() async {
        let viewModel = DashboardViewModel(
            healthClient: MockHealthKitClient(),
            dataClient: EmptyDashboardDataClient()
        )

        await viewModel.loadProgramInfo()

        #expect(viewModel.activeProgramName == nil)
        #expect(viewModel.nextWorkout == nil)
        #expect(viewModel.nextProgramListItem == nil)
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

private actor ProgramProgressDashboardDataClient: DataClientProtocol {
    private let enrolledPrograms: [EnrolledProgramRecord]
    private let sessionRecords: [ProgramSessionRecord]
    private let workouts: [Workout]

    init(
        enrolledPrograms: [EnrolledProgramRecord],
        sessionRecords: [ProgramSessionRecord],
        workouts: [Workout]
    ) {
        self.enrolledPrograms = enrolledPrograms
        self.sessionRecords = sessionRecords
        self.workouts = workouts
    }

    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        switch recordType {
        case "EnrolledProgramRecord":
            return enrolledPrograms as? [T] ?? []
        case "ProgramSessionRecord":
            return sessionRecords as? [T] ?? []
        case "Workout":
            return workouts as? [T] ?? []
        default:
            return []
        }
    }

    func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {}

    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws {}

    func deleteAllData() async throws {}
}
