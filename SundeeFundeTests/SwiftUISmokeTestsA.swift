import XCTest
import SwiftUI
import SwiftData
@testable import SundeeFundee

@MainActor
final class SwiftUISmokeTestsA: XCTestCase {
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

    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeTestStore() throws -> TestStore {
        let schema = Schema(AppSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return TestStore(container: container, context: ModelContext(container))
    }

    @discardableResult
    private func host<Content: View>(_ view: Content, triggerAppearance: Bool = false) -> UIHostingController<Content> {
        let controller = UIHostingController(rootView: view)
        controller.loadViewIfNeeded()

        if triggerAppearance {
            controller.beginAppearanceTransition(true, animated: false)
            controller.endAppearanceTransition()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        return controller
    }

    private func makeExercise(
        name: String = "Back Squat",
        variant: String? = nil,
        notes: String? = nil,
        sets: ExerciseValue = .fixed(2),
        reps: ExerciseValue = .fixed(5),
        restMinutes: Double? = 2.0
    ) -> ProgramExercise {
        ProgramExercise(
            exercise: name,
            variant: variant,
            sets: sets,
            reps: reps,
            percent1RM: nil,
            restMinutes: restMinutes,
            notes: notes
        )
    }

    private func makeSession(id: String = "session-1") -> ProgramSession {
        ProgramSession(
            sessionID: id,
            sessionName: "Session \(id)",
            sessionType: "strength",
            focus: "Lower Body",
            exercises: [
                makeExercise(name: "Back Squat", variant: "Tempo", notes: "Controlled eccentric")
            ]
        )
    }

    private func makeProgram(id: String = "program-1", includePhases: Bool = false) -> Program {
        let session = makeSession()
        let phases = includePhases
            ? [ProgramPhase(id: "phase-1", name: "Base", goal: "Build consistency", weekRange: [1, 2])]
            : []

        return Program(
            id: id,
            name: "Program \(id)",
            category: "Strength",
            description: "Cycle-aware progressive overload",
            durationWeeks: 2,
            sessionsPerWeek: 1,
            difficulty: "beginner",
            phases: phases,
            weeks: [
                ProgramWeek(week: 1, phaseID: "phase-1", isTestWeek: false, sessions: [session]),
                ProgramWeek(week: 2, phaseID: "phase-1", isTestWeek: false, sessions: [session])
            ],
            cycleAdjustmentProfile: nil
        )
    }

    private func makeEnrollment(id: String = "enroll-1", programID: String) -> EnrolledProgram {
        EnrolledProgram(
            id: id,
            userID: "user-1",
            programID: programID,
            startDate: fixedDate,
            currentWeek: 1,
            currentDay: 1
        )
    }

    private func makeWorkout(id: String = "workout-1", enrollmentID: String, programID: String) -> CompletedWorkout {
        CompletedWorkout(
            id: id,
            userID: "user-1",
            activeCycleID: "",
            programID: programID,
            enrollmentID: enrollmentID,
            week: 1,
            day: 1,
            sessionID: "session-1",
            completedAt: fixedDate.addingTimeInterval(600),
            durationSeconds: 1800
        )
    }

    func testDashboardViewAndSupportingViewsHost() throws {
        let store = try makeTestStore()
        let appState = AppState()
        appState.apply(.authenticated(userID: "user-1"))
        let dashboardViewModel = DashboardViewModel(programRepo: InMemoryProgramRepository(programs: []))

        let dashboard = host(
            DashboardView(viewModel: dashboardViewModel)
                .environment(appState)
                .modelContainer(store.container),
            triggerAppearance: true
        )
        XCTAssertNotNil(dashboard.view)

        let program = makeProgram(id: "program-dashboard")
        let enrollment = makeEnrollment(programID: program.id)
        let nextSession = program.weeks[0].sessions[0]
        let workout = makeWorkout(enrollmentID: enrollment.id, programID: program.id)

        let cards = host(
            ScrollView {
                ActiveEnrollmentCard(
                    enrollment: enrollment,
                    program: program,
                    nextSession: nextSession,
                    cyclePhase: .follicular
                )
                ActiveEnrollmentCard(
                    enrollment: enrollment,
                    program: program,
                    nextSession: nil,
                    cyclePhase: nil
                )
                NoEnrollmentCard()
                WorkoutHistoryRow(workout: workout)
                ForEach(CyclePhase.allCases, id: \.rawValue) { phase in
                    CyclePhaseBadge(phase: phase)
                }
            }
            .modelContainer(store.container)
        )
        XCTAssertNotNil(cards.view)
        _ = ActiveEnrollmentCard(
            enrollment: enrollment,
            program: program,
            nextSession: nextSession,
            cyclePhase: .follicular
        ).body
        _ = ActiveEnrollmentCard(
            enrollment: enrollment,
            program: program,
            nextSession: nil,
            cyclePhase: nil
        ).body
        _ = NoEnrollmentCard().body
        _ = WorkoutHistoryRow(workout: workout).body
        for phase in CyclePhase.allCases {
            _ = CyclePhaseBadge(phase: phase).body
        }
    }

    func testProgramsListDetailAndCardsHost() throws {
        let store = try makeTestStore()
        let program = makeProgram(includePhases: true)
        let repository = InMemoryProgramRepository(programs: [program])
        let listViewModel = ProgramListViewModel(programRepo: repository)

        let list = host(
            ProgramListView(viewModel: listViewModel)
                .modelContainer(store.container),
            triggerAppearance: true
        )
        XCTAssertNotNil(list.view)

        let cards = host(
            VStack {
                ProgramCardView(program: program, isEnrolled: false)
                ProgramCardView(program: program, isEnrolled: true)
            }
            .modelContainer(store.container)
        )
        XCTAssertNotNil(cards.view)
        _ = ProgramCardView(program: program, isEnrolled: false).body
        _ = ProgramCardView(program: program, isEnrolled: true).body

        let detailSubviews = host(
            VStack {
                StatBadge(label: "Duration", value: "2 weeks")
                ProgramPhaseRow(phase: program.phases[0])
            }
            .modelContainer(store.container)
        )
        XCTAssertNotNil(detailSubviews.view)
        _ = StatBadge(label: "Duration", value: "2 weeks").body
        _ = ProgramPhaseRow(phase: program.phases[0]).body

        let activeVM = ProgramListViewModel(programRepo: repository)
        activeVM.activeEnrollment = makeEnrollment(id: "enroll-active", programID: program.id)
        XCTAssertNotNil(host(
            ProgramDetailView(program: program, viewModel: activeVM)
                .modelContainer(store.container),
            triggerAppearance: true
        ).view)
        _ = ProgramDetailView(program: program, viewModel: activeVM).body

        let switchingVM = ProgramListViewModel(programRepo: repository)
        switchingVM.activeEnrollment = makeEnrollment(id: "enroll-other", programID: "different-program")
        XCTAssertNotNil(host(
            ProgramDetailView(program: program, viewModel: switchingVM)
                .modelContainer(store.container),
            triggerAppearance: true
        ).view)
        _ = ProgramDetailView(program: program, viewModel: switchingVM).body

        let freshVM = ProgramListViewModel(programRepo: repository)
        XCTAssertNotNil(host(
            ProgramDetailView(program: program, viewModel: freshVM)
                .modelContainer(store.container),
            triggerAppearance: true
        ).view)
        _ = ProgramDetailView(program: program, viewModel: freshVM).body
    }

    func testWorkoutExecutionAndSummaryHost() throws {
        throw XCTSkip("Unstable under shared simulator load; covered by ProgramWorkoutViewCoverageTests.")
        let store = try makeTestStore()
        let appState = AppState()
        appState.apply(.authenticated(userID: "user-1"))

        let program = makeProgram(id: "program-workout")
        let enrollment = makeEnrollment(id: "enroll-workout", programID: program.id)
        let session = program.weeks[0].sessions[0]

        let restVM = WorkoutExecutionViewModel(session: session, enrollment: enrollment, program: program)
        if var sets = restVM.exerciseSets[session.exercises[0].exercise] {
            sets = sets.map { state in
                var state = state
                state.prescribedWeightKg = 100
                return state
            }
            restVM.exerciseSets[session.exercises[0].exercise] = sets
        }
        restVM.startRestTimer(seconds: 30)
        restVM.openPlateCalc(forWeight: 100)

        XCTAssertNotNil(host(
            WorkoutExecutionView(viewModel: restVM)
                .environment(appState)
                .modelContainer(store.container),
            triggerAppearance: true
        ).view)
        _ = WorkoutExecutionView(viewModel: restVM).body

        let workoutSubviews = host(
            VStack {
                ExerciseSetCard(viewModel: restVM, exercise: session.exercises[0])
                SetRow(
                    setNumber: 1,
                    state: SetExecutionState(
                        prescribedReps: "5",
                        prescribedWeightKg: 100,
                        actualReps: 5,
                        actualWeightKg: 100,
                        isCompleted: true
                    ),
                    onRepsChange: { _ in },
                    onWeightChange: { _ in },
                    onToggle: {}
                )
                RestTimerOverlay(seconds: .constant(30), onDismiss: {})
                PlateCalculatorSheet(weightKg: 20)
                PlateCalculatorSheet(weightKg: 100)
            }
            .modelContainer(store.container)
        )
        XCTAssertNotNil(workoutSubviews.view)
        _ = ExerciseSetCard(viewModel: restVM, exercise: session.exercises[0]).body
        _ = SetRow(
            setNumber: 1,
            state: SetExecutionState(
                prescribedReps: "5",
                prescribedWeightKg: 100,
                actualReps: 5,
                actualWeightKg: 100,
                isCompleted: true
            ),
            onRepsChange: { _ in },
            onWeightChange: { _ in },
            onToggle: {}
        ).body
        _ = RestTimerOverlay(seconds: .constant(30), onDismiss: {}).body
        _ = PlateCalculatorSheet(weightKg: 20).body

        let finishedVM = WorkoutExecutionViewModel(session: session, enrollment: enrollment, program: program)
        finishedVM.startTime = fixedDate
        finishedVM.finishWorkout(modelContext: store.context, userID: "user-1")

        XCTAssertNotNil(host(
            WorkoutExecutionView(viewModel: finishedVM)
                .environment(appState)
                .modelContainer(store.container),
            triggerAppearance: true
        ).view)

        let summaryWorkout = makeWorkout(id: "workout-summary", enrollmentID: enrollment.id, programID: program.id)
        store.context.insert(summaryWorkout)
        store.context.insert(
            CompletedSet(
                id: "set-summary",
                userID: "user-1",
                workoutID: summaryWorkout.id,
                exerciseName: "Back Squat",
                setIndex: 0,
                prescribedReps: "5",
                actualReps: 5,
                prescribedWeightKg: 100,
                actualWeightKg: 120
            )
        )
        store.context.insert(
            OneRepMax(
                id: "orm-existing",
                userID: "user-1",
                exerciseID: "Back Squat",
                weightKg: 100,
                date: fixedDate
            )
        )
        try store.context.save()

        XCTAssertNotNil(host(
            NavigationStack { WorkoutSummaryView(workout: summaryWorkout) }
                .modelContainer(store.container),
            triggerAppearance: true
        ).view)

        let setRows = host(
            VStack {
                SetSummaryRow(
                    set: CompletedSet(
                        id: "set-row-filled",
                        userID: "user-1",
                        workoutID: summaryWorkout.id,
                        exerciseName: "Back Squat",
                        setIndex: 0,
                        prescribedReps: "5",
                        actualReps: 5,
                        actualWeightKg: 100
                    )
                )
                SetSummaryRow(
                    set: CompletedSet(
                        id: "set-row-fallback",
                        userID: "user-1",
                        workoutID: summaryWorkout.id,
                        exerciseName: "Back Squat",
                        setIndex: 1,
                        prescribedReps: "AMRAP",
                        actualReps: nil,
                        actualWeightKg: nil
                    )
                )
            }
            .modelContainer(store.container)
        )
        XCTAssertNotNil(setRows.view)
    }
}
