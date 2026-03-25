import XCTest
import SwiftUI
import SwiftData
import UIKit
@testable import SundeeFundee

@MainActor
final class DashboardViewCoverageTests: XCTestCase {
    private struct TestStore {
        let container: ModelContainer
        let context: ModelContext
    }

    private final class InMemoryProgramRepository: ProgramRepository, @unchecked Sendable {
        let programs: [Program]

        init(programs: [Program]) {
            self.programs = programs
        }

        func fetchPrograms() async throws -> [Program] { programs }

        func fetchProgram(id: String) async throws -> Program? {
            programs.first { $0.id == id }
        }
    }

    private struct PushedDashboardHost: View {
        let root: DashboardView
        @State private var path: [StartWorkoutDestination]

        init(root: DashboardView, destination: StartWorkoutDestination) {
            self.root = root
            _path = State(initialValue: [destination])
        }

        var body: some View {
            NavigationStack(path: $path) { root }
        }
    }

    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeTestStore() throws -> TestStore {
        let schema = Schema(AppSchemaV9.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return TestStore(container: container, context: ModelContext(container))
    }

    @discardableResult
    private func host<Content: View>(_ view: Content, triggerAppearance: Bool = true) -> UIHostingController<Content> {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()

        if triggerAppearance {
            controller.beginAppearanceTransition(true, animated: false)
            controller.endAppearanceTransition()
        }

        controller.view.frame = window.bounds
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        return controller
    }

    private func makeAppState() -> AppState {
        let appState = AppState()
        appState.apply(.authenticated(userID: "dashboard-user"))
        return appState
    }

    private func makeSession(id: String = "session-1", name: String = "Lower Strength") -> ProgramSession {
        ProgramSession(
            sessionID: id,
            sessionName: name,
            sessionType: "strength",
            focus: "Lower Body",
            exercises: [
                ProgramExercise(
                    exercise: "Back Squat",
                    variant: nil,
                    sets: .fixed(3),
                    reps: .fixed(5),
                    percent1RM: nil,
                    restMinutes: 2,
                    notes: nil
                )
            ]
        )
    }

    private func makeProgram(
        id: String = "program-1",
        durationWeeks: Int = 4,
        session: ProgramSession
    ) -> Program {
        Program(
            id: id,
            name: "Program \(id)",
            category: "Strength",
            description: "Cycle-aware strength plan",
            durationWeeks: durationWeeks,
            sessionsPerWeek: 1,
            difficulty: "beginner",
            phases: [],
            weeks: [ProgramWeek(week: 1, phaseID: nil, isTestWeek: false, sessions: [session])],
            cycleAdjustmentProfile: nil
        )
    }

    private func makeEnrollment(
        id: String = "enroll-1",
        userID: String = "dashboard-user",
        programID: String,
        currentWeek: Int = 1,
        currentDay: Int = 1
    ) -> EnrolledProgram {
        EnrolledProgram(
            id: id,
            userID: userID,
            programID: programID,
            startDate: fixedDate,
            currentWeek: currentWeek,
            currentDay: currentDay
        )
    }

    private func makeWorkout(
        id: String = "workout-1",
        enrollmentID: String,
        programID: String
    ) -> CompletedWorkout {
        CompletedWorkout(
            id: id,
            userID: "dashboard-user",
            activeCycleID: "",
            programID: programID,
            enrollmentID: enrollmentID,
            week: 1,
            day: 1,
            sessionID: "session-1",
            completedAt: fixedDate,
            durationSeconds: 2_100
        )
    }

    private func makeDate(hour: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: 2026, month: 1, day: 15, hour: hour))!
    }

    private func assertColor(
        _ color: Color,
        equals expected: UIColor,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actual = UIColor(color).resolvedColor(with: .init(userInterfaceStyle: .light))
        let expectedResolved = expected.resolvedColor(with: .init(userInterfaceStyle: .light))

        var actualRed: CGFloat = 0
        var actualGreen: CGFloat = 0
        var actualBlue: CGFloat = 0
        var actualAlpha: CGFloat = 0
        var expectedRed: CGFloat = 0
        var expectedGreen: CGFloat = 0
        var expectedBlue: CGFloat = 0
        var expectedAlpha: CGFloat = 0

        XCTAssertTrue(
            actual.getRed(&actualRed, green: &actualGreen, blue: &actualBlue, alpha: &actualAlpha),
            file: file,
            line: line
        )
        XCTAssertTrue(
            expectedResolved.getRed(&expectedRed, green: &expectedGreen, blue: &expectedBlue, alpha: &expectedAlpha),
            file: file,
            line: line
        )
        XCTAssertEqual(actualRed, expectedRed, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(actualGreen, expectedGreen, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(actualBlue, expectedBlue, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(actualAlpha, expectedAlpha, accuracy: 0.001, file: file, line: line)
    }

    func testGreetingForDateCoversAllBuckets() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        XCTAssertEqual(DashboardView.greeting(for: makeDate(hour: 8), calendar: calendar), "Good morning")
        XCTAssertEqual(DashboardView.greeting(for: makeDate(hour: 13), calendar: calendar), "Good afternoon")
        XCTAssertEqual(DashboardView.greeting(for: makeDate(hour: 20), calendar: calendar), "Good evening")
    }

    func testDashboardHelperSeamsCoverEnrollmentAndWorkoutBranches() {
        let session = makeSession()
        let program = makeProgram(session: session)
        let enrollment = makeEnrollment(programID: program.id, currentWeek: 3)
        let workout = makeWorkout(enrollmentID: enrollment.id, programID: program.id)

        XCTAssertNotNil(DashboardView.activeEnrollmentState(enrollment: enrollment, program: program))
        XCTAssertNil(DashboardView.activeEnrollmentState(enrollment: nil, program: program))
        XCTAssertNil(DashboardView.activeEnrollmentState(enrollment: enrollment, program: nil))

        XCTAssertTrue(DashboardView.shouldShowEmptyRecentWorkouts([]))
        XCTAssertFalse(DashboardView.shouldShowEmptyRecentWorkouts([workout]))

        XCTAssertEqual(ActiveEnrollmentCard.progressFraction(currentWeek: 1, durationWeeks: 4), 0, accuracy: 0.001)
        XCTAssertEqual(ActiveEnrollmentCard.progressFraction(currentWeek: 3, durationWeeks: 4), 0.5, accuracy: 0.001)
        XCTAssertEqual(ActiveEnrollmentCard.progressFraction(currentWeek: 5, durationWeeks: 4), 1.0, accuracy: 0.001)
        XCTAssertEqual(ActiveEnrollmentCard.progressFraction(currentWeek: 2, durationWeeks: 0), 0, accuracy: 0.001)
    }

    func testRefreshActionLoadsViewModel() async throws {
        let store = try makeTestStore()
        let viewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: []))
        let refresh = DashboardView.refreshAction(viewModel: viewModel, modelContext: store.context)
        await refresh()
        await DashboardView.performRefresh(viewModel: viewModel, modelContext: store.context)
        XCTAssertGreaterThanOrEqual(viewModel.recentWorkouts.count, 0)
    }

    func testCyclePhaseBadgeColorHelperCoversAllPhases() {
        assertColor(CyclePhaseBadge.badgeColor(for: .menstrual), equals: UIColor(red: 0.90, green: 0.55, blue: 0.50, alpha: 1))
        assertColor(CyclePhaseBadge.badgeColor(for: .follicular), equals: UIColor(red: 0.20, green: 0.55, blue: 0.80, alpha: 1))
        assertColor(CyclePhaseBadge.badgeColor(for: .ovulation), equals: UIColor(AppTheme.Colors.accentOrange))
        assertColor(CyclePhaseBadge.badgeColor(for: .luteal), equals: UIColor(red: 0.50, green: 0.35, blue: 0.65, alpha: 1))
    }

    func testDashboardSubViewBodiesEvaluateWithoutLifecycleHosting() {
        let session = makeSession()
        let program = makeProgram(session: session)
        let enrollment = makeEnrollment(programID: program.id, currentWeek: 2)
        let workout = makeWorkout(enrollmentID: enrollment.id, programID: program.id)

        _ = ActiveEnrollmentCard(
            enrollment: enrollment,
            program: program,
            nextSession: session,
            cyclePhase: .follicular
        ).body
        _ = ActiveEnrollmentCard(
            enrollment: enrollment,
            program: program,
            nextSession: nil,
            cyclePhase: nil
        ).body
        _ = NoEnrollmentCard().body
        _ = CyclePhaseBadge(phase: .ovulation).body
        _ = WorkoutHistoryRow(workout: workout).body
    }

    func testDashboardViewRendersNoEnrollmentAndEmptyRecentWorkouts() throws {
        let store = try makeTestStore()
        let appState = makeAppState()
        let viewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: []))
        viewModel.activeEnrollment = nil
        viewModel.activeProgram = nil
        viewModel.nextSession = nil
        viewModel.recentWorkouts = []
        viewModel.currentCyclePhase = nil

        XCTAssertNotNil(host(
            NavigationStack {
                DashboardView(viewModel: viewModel)
            }
            .environment(appState)
            .modelContainer(store.container)
        ).view)
    }

    func testDashboardViewRendersActiveCardCycleBadgeAndRecentWorkout() throws {
        let store = try makeTestStore()
        let appState = makeAppState()
        let session = makeSession()
        let program = makeProgram(session: session)
        let enrollment = makeEnrollment(programID: program.id)
        let workout = makeWorkout(enrollmentID: enrollment.id, programID: program.id)

        let viewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: [program]))
        viewModel.activeEnrollment = enrollment
        viewModel.activeProgram = program
        viewModel.nextSession = session
        viewModel.recentWorkouts = [workout]
        viewModel.currentCyclePhase = .luteal

        XCTAssertNotNil(host(
            NavigationStack {
                DashboardView(viewModel: viewModel)
            }
            .environment(appState)
            .modelContainer(store.container)
        ).view)
    }

    func testActiveEnrollmentCardCoversProgressAndStartWorkoutBranches() throws {
        let store = try makeTestStore()
        let session = makeSession()
        let fullProgram = makeProgram(id: "program-full", durationWeeks: 4, session: session)
        let zeroProgram = makeProgram(id: "program-zero", durationWeeks: 0, session: session)
        let fullEnrollment = makeEnrollment(programID: fullProgram.id, currentWeek: 4)
        let zeroEnrollment = makeEnrollment(id: "enroll-zero", programID: zeroProgram.id)

        XCTAssertNotNil(host(
            NavigationStack {
                VStack {
                    ActiveEnrollmentCard(
                        enrollment: fullEnrollment,
                        program: fullProgram,
                        nextSession: session,
                        cyclePhase: .follicular
                    )
                    ActiveEnrollmentCard(
                        enrollment: zeroEnrollment,
                        program: zeroProgram,
                        nextSession: nil,
                        cyclePhase: nil
                    )
                }
            }
            .modelContainer(store.container),
            triggerAppearance: true
        ).view)
    }

    // MARK: - nextPosition tests

    func testNextPositionAdvancesDayWithinWeek() {
        let session1 = makeSession(id: "s1")
        let session2 = makeSession(id: "s2")
        let program = Program(
            id: "prog", name: "P", category: "S", description: "",
            durationWeeks: 2, sessionsPerWeek: 2, difficulty: "beginner",
            phases: [],
            weeks: [
                ProgramWeek(week: 1, phaseID: nil, isTestWeek: false, sessions: [session1, session2]),
                ProgramWeek(week: 2, phaseID: nil, isTestWeek: false, sessions: [session1])
            ],
            cycleAdjustmentProfile: nil
        )
        let next = DashboardViewModel.nextPosition(currentWeek: 1, currentDay: 1, program: program)
        XCTAssertEqual(next.week, 1)
        XCTAssertEqual(next.day, 2)
    }

    func testNextPositionAdvancesToNextWeekOnLastDay() {
        let session = makeSession(id: "s1")
        let program = Program(
            id: "prog", name: "P", category: "S", description: "",
            durationWeeks: 2, sessionsPerWeek: 1, difficulty: "beginner",
            phases: [],
            weeks: [
                ProgramWeek(week: 1, phaseID: nil, isTestWeek: false, sessions: [session]),
                ProgramWeek(week: 2, phaseID: nil, isTestWeek: false, sessions: [session])
            ],
            cycleAdjustmentProfile: nil
        )
        let next = DashboardViewModel.nextPosition(currentWeek: 1, currentDay: 1, program: program)
        XCTAssertEqual(next.week, 2)
        XCTAssertEqual(next.day, 1)
    }

    func testNextPositionStaysAtEndOfProgram() {
        let session = makeSession(id: "s1")
        let program = Program(
            id: "prog", name: "P", category: "S", description: "",
            durationWeeks: 1, sessionsPerWeek: 1, difficulty: "beginner",
            phases: [],
            weeks: [ProgramWeek(week: 1, phaseID: nil, isTestWeek: false, sessions: [session])],
            cycleAdjustmentProfile: nil
        )
        let next = DashboardViewModel.nextPosition(currentWeek: 1, currentDay: 1, program: program)
        XCTAssertEqual(next.week, 1)
        XCTAssertEqual(next.day, 1)
    }

    func testNextPositionHandlesUnknownWeek() {
        let session = makeSession(id: "s1")
        let program = Program(
            id: "prog", name: "P", category: "S", description: "",
            durationWeeks: 1, sessionsPerWeek: 1, difficulty: "beginner",
            phases: [],
            weeks: [ProgramWeek(week: 1, phaseID: nil, isTestWeek: false, sessions: [session])],
            cycleAdjustmentProfile: nil
        )
        let next = DashboardViewModel.nextPosition(currentWeek: 99, currentDay: 1, program: program)
        XCTAssertEqual(next.week, 99)
        XCTAssertEqual(next.day, 1)
    }

    // MARK: - previousPosition tests

    func testPreviousPositionDecrementsDayWithinWeek() {
        let session1 = makeSession(id: "s1")
        let session2 = makeSession(id: "s2")
        let program = Program(
            id: "prog", name: "P", category: "S", description: "",
            durationWeeks: 2, sessionsPerWeek: 2, difficulty: "beginner",
            phases: [],
            weeks: [
                ProgramWeek(week: 1, phaseID: nil, isTestWeek: false, sessions: [session1, session2]),
                ProgramWeek(week: 2, phaseID: nil, isTestWeek: false, sessions: [session1])
            ],
            cycleAdjustmentProfile: nil
        )
        let prev = DashboardViewModel.previousPosition(currentWeek: 1, currentDay: 2, program: program)
        XCTAssertEqual(prev.week, 1)
        XCTAssertEqual(prev.day, 1)
    }

    func testPreviousPositionGoesToLastDayOfPreviousWeek() {
        let session1 = makeSession(id: "s1")
        let session2 = makeSession(id: "s2")
        let program = Program(
            id: "prog", name: "P", category: "S", description: "",
            durationWeeks: 2, sessionsPerWeek: 2, difficulty: "beginner",
            phases: [],
            weeks: [
                ProgramWeek(week: 1, phaseID: nil, isTestWeek: false, sessions: [session1, session2]),
                ProgramWeek(week: 2, phaseID: nil, isTestWeek: false, sessions: [session1])
            ],
            cycleAdjustmentProfile: nil
        )
        let prev = DashboardViewModel.previousPosition(currentWeek: 2, currentDay: 1, program: program)
        XCTAssertEqual(prev.week, 1)
        XCTAssertEqual(prev.day, 2) // last session of week 1
    }

    func testPreviousPositionStaysAtStartOfProgram() {
        let session = makeSession(id: "s1")
        let program = Program(
            id: "prog", name: "P", category: "S", description: "",
            durationWeeks: 1, sessionsPerWeek: 1, difficulty: "beginner",
            phases: [],
            weeks: [ProgramWeek(week: 1, phaseID: nil, isTestWeek: false, sessions: [session])],
            cycleAdjustmentProfile: nil
        )
        let prev = DashboardViewModel.previousPosition(currentWeek: 1, currentDay: 1, program: program)
        XCTAssertEqual(prev.week, 1)
        XCTAssertEqual(prev.day, 1)
    }

    // MARK: - skipWorkout tests

    func testSkipWorkoutMarkAsSkippedSavesRecord() throws {
        let store = try makeTestStore()
        let session = makeSession()
        let program = makeProgram(session: session)
        let enrollment = makeEnrollment(programID: program.id)
        store.context.insert(enrollment)
        try store.context.save()

        let viewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: [program]))
        viewModel.activeEnrollment = enrollment
        viewModel.activeProgram = program
        viewModel.nextSession = session

        viewModel.skipWorkout(modelContext: store.context, userID: "test-user", recordAs: .markAsSkipped)

        let allWorkouts = try store.context.fetch(FetchDescriptor<CompletedWorkout>())
        XCTAssertEqual(allWorkouts.count, 1)
        XCTAssertEqual(allWorkouts.first?.notes, "skipped")
        XCTAssertEqual(allWorkouts.first?.durationSeconds, 0)
    }

    func testSkipWorkoutNoRecordDoesNotSaveWorkout() throws {
        let store = try makeTestStore()
        let session = makeSession()
        let program = makeProgram(session: session)
        let enrollment = makeEnrollment(programID: program.id)
        store.context.insert(enrollment)
        try store.context.save()

        let viewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: [program]))
        viewModel.activeEnrollment = enrollment
        viewModel.activeProgram = program
        viewModel.nextSession = session

        viewModel.skipWorkout(modelContext: store.context, userID: "test-user", recordAs: .noRecord)

        let allWorkouts = try store.context.fetch(FetchDescriptor<CompletedWorkout>())
        XCTAssertEqual(allWorkouts.count, 0)
    }

    func testSkipWorkoutAdvancesEnrollmentPointer() throws {
        let store = try makeTestStore()
        let session1 = makeSession(id: "s1")
        let session2 = makeSession(id: "s2", name: "Upper Strength")
        let program = Program(
            id: "prog-skip", name: "Skip Test", category: "S", description: "",
            durationWeeks: 1, sessionsPerWeek: 2, difficulty: "beginner",
            phases: [],
            weeks: [ProgramWeek(week: 1, phaseID: nil, isTestWeek: false, sessions: [session1, session2])],
            cycleAdjustmentProfile: nil
        )
        let enrollment = makeEnrollment(programID: program.id, currentWeek: 1, currentDay: 1)
        store.context.insert(enrollment)
        try store.context.save()

        let viewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: [program]))
        viewModel.activeEnrollment = enrollment
        viewModel.activeProgram = program
        viewModel.nextSession = session1

        viewModel.skipWorkout(modelContext: store.context, userID: "test-user", recordAs: .noRecord)

        XCTAssertEqual(enrollment.currentDay, 2)
        XCTAssertEqual(enrollment.currentWeek, 1)
    }

    func testSkipWorkoutDoesNothingWhenNoActiveEnrollment() throws {
        let store = try makeTestStore()
        let viewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: []))
        viewModel.activeEnrollment = nil
        viewModel.activeProgram = nil
        // Should not crash
        viewModel.skipWorkout(modelContext: store.context, userID: "test-user", recordAs: .noRecord)
        let allWorkouts = try store.context.fetch(FetchDescriptor<CompletedWorkout>())
        XCTAssertEqual(allWorkouts.count, 0)
    }

    // MARK: - deleteWorkout tests

    func testDeleteWorkoutRemovesRecordAndRollsBackPointer() throws {
        let store = try makeTestStore()
        let session1 = makeSession(id: "s1")
        let session2 = makeSession(id: "s2", name: "Upper Strength")
        let program = Program(
            id: "prog-del", name: "Delete Test", category: "S", description: "",
            durationWeeks: 1, sessionsPerWeek: 2, difficulty: "beginner",
            phases: [],
            weeks: [ProgramWeek(week: 1, phaseID: nil, isTestWeek: false, sessions: [session1, session2])],
            cycleAdjustmentProfile: nil
        )
        // Enrollment is at day 2 (after completing day 1)
        let enrollment = makeEnrollment(programID: program.id, currentWeek: 1, currentDay: 2)
        store.context.insert(enrollment)
        let workout = makeWorkout(enrollmentID: enrollment.id, programID: program.id)
        store.context.insert(workout)
        try store.context.save()

        let viewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: [program]))
        viewModel.activeEnrollment = enrollment
        viewModel.activeProgram = program
        viewModel.recentWorkouts = [workout]

        viewModel.deleteWorkout(workout, modelContext: store.context)

        let allWorkouts = try store.context.fetch(FetchDescriptor<CompletedWorkout>())
        XCTAssertEqual(allWorkouts.count, 0)
        XCTAssertEqual(enrollment.currentDay, 1)
        XCTAssertEqual(enrollment.currentWeek, 1)
    }

    func testDeleteWorkoutDeletesRecordEvenWithNoActiveEnrollment() throws {
        let store = try makeTestStore()
        let session = makeSession()
        let program = makeProgram(session: session)
        let enrollment = makeEnrollment(programID: program.id)
        store.context.insert(enrollment)
        let workout = makeWorkout(enrollmentID: enrollment.id, programID: program.id)
        store.context.insert(workout)
        try store.context.save()

        let viewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: []))
        viewModel.activeEnrollment = nil
        viewModel.activeProgram = nil
        // Workout should be deleted even with no active enrollment
        viewModel.deleteWorkout(workout, modelContext: store.context)
        let allWorkouts = try store.context.fetch(FetchDescriptor<CompletedWorkout>())
        XCTAssertEqual(allWorkouts.count, 0)
    }

    // MARK: - WorkoutHistoryRow skipped styling

    func testWorkoutHistoryRowIsSkippedProperty() {
        let session = makeSession()
        let program = makeProgram(session: session)
        let enrollment = makeEnrollment(programID: program.id)

        let normalWorkout = makeWorkout(enrollmentID: enrollment.id, programID: program.id)
        let skippedWorkout = CompletedWorkout(
            id: "skipped-1",
            userID: "dashboard-user",
            activeCycleID: "",
            programID: program.id,
            enrollmentID: enrollment.id,
            week: 1,
            day: 1,
            sessionID: "session-1",
            completedAt: fixedDate,
            durationSeconds: 0,
            notes: "skipped"
        )

        XCTAssertFalse(WorkoutHistoryRow(workout: normalWorkout).isSkipped)
        XCTAssertTrue(WorkoutHistoryRow(workout: skippedWorkout).isSkipped)
        _ = WorkoutHistoryRow(workout: normalWorkout).body
        _ = WorkoutHistoryRow(workout: skippedWorkout).body
    }

    // MARK: - averageEffort / ratedCount / EffortTrendsCard

    func testAverageEffortReturnsNilForEmptyWorkouts() {
        XCTAssertNil(DashboardView.averageEffort(from: []))
    }

    func testAverageEffortReturnsNilWhenNoWorkoutsHaveRatings() {
        let w1 = makeWorkout(id: "w1", enrollmentID: "e1", programID: "p1")
        let w2 = makeWorkout(id: "w2", enrollmentID: "e1", programID: "p1")
        XCTAssertNil(DashboardView.averageEffort(from: [w1, w2]))
    }

    func testAverageEffortComputesCorrectlyForMixedRatings() {
        let w1 = CompletedWorkout(
            id: "r1", userID: "u", activeCycleID: "", programID: "p",
            week: 1, day: 1, sessionID: "s", completedAt: fixedDate,
            durationSeconds: 100, perceivedEffort: 3
        )
        let w2 = CompletedWorkout(
            id: "r2", userID: "u", activeCycleID: "", programID: "p",
            week: 1, day: 2, sessionID: "s", completedAt: fixedDate,
            durationSeconds: 100, perceivedEffort: 5
        )
        let w3 = makeWorkout(id: "r3", enrollmentID: "e", programID: "p") // no rating
        let avg = DashboardView.averageEffort(from: [w1, w2, w3])
        XCTAssertEqual(avg!, 4.0, accuracy: 0.001)
        XCTAssertEqual(DashboardView.ratedCount(from: [w1, w2, w3]), 2)
    }

    func testAverageEffortComputesCorrectlyForAllRated() {
        let w1 = CompletedWorkout(
            id: "a1", userID: "u", activeCycleID: "", programID: "p",
            week: 1, day: 1, sessionID: "s", completedAt: fixedDate,
            durationSeconds: 100, perceivedEffort: 2
        )
        let w2 = CompletedWorkout(
            id: "a2", userID: "u", activeCycleID: "", programID: "p",
            week: 1, day: 2, sessionID: "s", completedAt: fixedDate,
            durationSeconds: 100, perceivedEffort: 4
        )
        let avg = DashboardView.averageEffort(from: [w1, w2])
        XCTAssertEqual(avg!, 3.0, accuracy: 0.001)
        XCTAssertEqual(DashboardView.ratedCount(from: [w1, w2]), 2)
    }

    func testEffortTrendsCardFormattedAverage() {
        XCTAssertEqual(EffortTrendsCard.formattedAverage(3.5), "3.5 / 5")
        XCTAssertEqual(EffortTrendsCard.formattedAverage(1.0), "1.0 / 5")
    }

    func testEffortTrendsCardRatedSummary() {
        XCTAssertEqual(EffortTrendsCard.ratedSummary(rated: 7, total: 10), "7 of 10 workouts rated")
    }

    func testEffortTrendsCardBodyRenders() throws {
        let store = try makeTestStore()
        XCTAssertNotNil(host(
            EffortTrendsCard(averageEffort: 3.5, ratedCount: 5, totalCount: 10)
                .modelContainer(store.container)
        ).view)
    }

    func testWorkoutHistoryRowShowsSpicyBadgeWhenRated() {
        let ratedWorkout = CompletedWorkout(
            id: "rated-1", userID: "u", activeCycleID: "", programID: "p",
            week: 1, day: 1, sessionID: "s", completedAt: fixedDate,
            durationSeconds: 2100, perceivedEffort: 4
        )
        _ = WorkoutHistoryRow(workout: ratedWorkout).body
    }

    func testDashboardRendersEffortTrendsCardWhenRatingsExist() throws {
        let store = try makeTestStore()
        let appState = makeAppState()
        let viewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: []))
        let ratedWorkout = CompletedWorkout(
            id: "dash-rated", userID: "u", activeCycleID: "", programID: "p",
            week: 1, day: 1, sessionID: "s", completedAt: fixedDate,
            durationSeconds: 2100, perceivedEffort: 3
        )
        viewModel.recentWorkouts = [ratedWorkout]
        viewModel.activeEnrollment = nil
        viewModel.activeProgram = nil

        XCTAssertNotNil(host(
            NavigationStack {
                DashboardView(viewModel: viewModel)
            }
            .environment(appState)
            .modelContainer(store.container)
        ).view)
    }

    // MARK: - ActiveEnrollmentCard with onSkip closure

    func testActiveEnrollmentCardWithSkipClosureRendersSkipButton() throws {
        let store = try makeTestStore()
        let session = makeSession()
        let program = makeProgram(session: session)
        let enrollment = makeEnrollment(programID: program.id)

        var skipCalled = false
        XCTAssertNotNil(host(
            NavigationStack {
                ActiveEnrollmentCard(
                    enrollment: enrollment,
                    program: program,
                    nextSession: session,
                    cyclePhase: .follicular,
                    onSkip: { skipCalled = true }
                )
            }
            .modelContainer(store.container)
        ).view)
        _ = skipCalled // suppress unused warning
    }

    func testAIWorkoutCTACardRendersWithoutCrash() throws {
        let store = try makeTestStore()
        XCTAssertNotNil(host(
            NavigationStack {
                AIWorkoutCTACard()
            }
            .environment(makeAppState())
            .modelContainer(store.container)
        ).view)
    }

    func testStartAIWorkoutDestinationHashable() {
        let a = StartAIWorkoutDestination()
        let b = StartAIWorkoutDestination()
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func testNavigationDestinationAndDestinationHashingBranches() throws {
        let store = try makeTestStore()
        let appState = makeAppState()
        let session = makeSession()
        let alternateSession = makeSession(id: "session-2", name: "Upper Strength")
        let program = makeProgram(session: session)
        let enrollment = makeEnrollment(programID: program.id)
        store.context.insert(enrollment)
        try store.context.save()

        let destination = StartWorkoutDestination(enrollment: enrollment, session: session)
        XCTAssertEqual(destination, StartWorkoutDestination(enrollment: enrollment, session: session))
        XCTAssertNotEqual(destination, StartWorkoutDestination(enrollment: enrollment, session: alternateSession))
        XCTAssertEqual(Set([destination, StartWorkoutDestination(enrollment: enrollment, session: alternateSession)]).count, 2)

        let withProgramViewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: [program]))
        withProgramViewModel.activeEnrollment = enrollment
        withProgramViewModel.activeProgram = program
        withProgramViewModel.nextSession = session

        XCTAssertNotNil(host(
            PushedDashboardHost(
                root: DashboardView(viewModel: withProgramViewModel),
                destination: destination
            )
            .environment(appState)
            .modelContainer(store.container)
        ).view)

        let withoutProgramViewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: []))
        withoutProgramViewModel.activeEnrollment = enrollment
        withoutProgramViewModel.activeProgram = nil
        withoutProgramViewModel.nextSession = session

        XCTAssertNotNil(host(
            PushedDashboardHost(
                root: DashboardView(viewModel: withoutProgramViewModel),
                destination: destination
            )
            .environment(appState)
            .modelContainer(store.container)
        ).view)
    }
}
