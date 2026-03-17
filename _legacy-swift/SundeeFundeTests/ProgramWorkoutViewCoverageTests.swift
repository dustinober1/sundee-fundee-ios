import XCTest
import SwiftUI
import SwiftData
import UIKit
import Testing
@testable import SundeeFundee

@MainActor
final class ProgramWorkoutViewCoverageTests: XCTestCase {
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

    private struct ProgramNavigationHarness: View {
        let viewModel: ProgramListViewModel
        let selectedProgram: Program
        @State private var path: [Program]

        init(viewModel: ProgramListViewModel, selectedProgram: Program) {
            self.viewModel = viewModel
            self.selectedProgram = selectedProgram
            _path = State(initialValue: [selectedProgram])
        }

        var body: some View {
            NavigationStack(path: $path) {
                ProgramListView(viewModel: viewModel)
            }
        }
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV10.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @discardableResult
    private func host<Content: View>(
        _ view: Content,
        container: ModelContainer,
        appState: AppState? = nil,
        triggerAppearance: Bool = true
    ) -> (UIHostingController<AnyView>, UIWindow) {
        let state = appState ?? AppState()
        var root = AnyView(view.modelContainer(container).environment(state))

        let controller = UIHostingController(rootView: root)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()

        if triggerAppearance {
            controller.beginAppearanceTransition(true, animated: false)
            controller.endAppearanceTransition()
        }

        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        return (controller, window)
    }

    private func waitForTasks(_ seconds: TimeInterval = 0.15) {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds))
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

        XCTAssertTrue(actual.getRed(&actualRed, green: &actualGreen, blue: &actualBlue, alpha: &actualAlpha), file: file, line: line)
        XCTAssertTrue(expectedResolved.getRed(&expectedRed, green: &expectedGreen, blue: &expectedBlue, alpha: &expectedAlpha), file: file, line: line)
        XCTAssertEqual(actualRed, expectedRed, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(actualGreen, expectedGreen, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(actualBlue, expectedBlue, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(actualAlpha, expectedAlpha, accuracy: 0.001, file: file, line: line)
    }

    private func makeProgram(id: String = "program-1", includePhases: Bool = true) -> Program {
        let exercises = [
            ProgramExercise(
                exercise: "Back Squat",
                variant: "Tempo",
                sets: .fixed(2),
                reps: .fixed(5),
                percent1RM: nil,
                restMinutes: 1.5,
                notes: "Control the eccentric"
            ),
            ProgramExercise(
                exercise: "RDL",
                variant: nil,
                sets: .fixed(1),
                reps: .range(8, 10),
                percent1RM: nil,
                restMinutes: 2.0,
                notes: nil
            )
        ]

        let session = ProgramSession(
            sessionID: "session-\(id)",
            sessionName: "Session \(id)",
            sessionType: "strength",
            focus: "Lower Body",
            exercises: exercises
        )

        let phases = includePhases
            ? [ProgramPhase(id: "phase-\(id)", name: "Base", goal: "Build consistency", weekRange: [1, 2])]
            : []

        return Program(
            id: id,
            name: "Program \(id)",
            category: "Strength",
            description: "Cycle-aware progressive overload",
            durationWeeks: 2,
            sessionsPerWeek: 2,
            difficulty: "beginner",
            phases: phases,
            cycleAdjustmentProfile: nil,
            weeks: [
                ProgramWeek(week: 1, phaseID: phases.first?.id ?? "", isTestWeek: false, sessions: [session]),
                ProgramWeek(week: 2, phaseID: phases.first?.id ?? "", isTestWeek: false, sessions: [session])
            ]
        )
    }

    private func makeEnrollment(programID: String, id: String = UUID().uuidString) -> EnrolledProgram {
        EnrolledProgram(
            id: id,
            userID: "user-coverage",
            programID: programID,
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            currentWeek: 1,
            currentDay: 1
        )
    }

    private func makeWorkout(id: String = UUID().uuidString, programID: String, enrollmentID: String?) -> CompletedWorkout {
        CompletedWorkout(
            id: id,
            userID: "user-coverage",
            activeCycleID: "",
            programID: programID,
            enrollmentID: enrollmentID,
            week: 1,
            day: 1,
            sessionID: "session-\(programID)",
            completedAt: Date(timeIntervalSince1970: 1_700_000_000),
            durationSeconds: 1_980
        )
    }

    func testProgramListAndDetailBranchesRenderAndHelpersExecute() throws {
        let container = try makeContainer()
        let primaryProgram = makeProgram(id: "program-primary")
        let secondaryProgram = makeProgram(id: "program-secondary", includePhases: false)
        let repository = InMemoryProgramRepository(programs: [primaryProgram, secondaryProgram])

        XCTAssertEqual(ProgramListView.contentState(isLoading: true, errorMessage: nil, programCount: 0), .loading)
        XCTAssertEqual(ProgramListView.contentState(isLoading: false, errorMessage: "Oops", programCount: 0), .error("Oops"))
        XCTAssertEqual(ProgramListView.contentState(isLoading: false, errorMessage: nil, programCount: 0), .empty)
        XCTAssertEqual(ProgramListView.contentState(isLoading: false, errorMessage: nil, programCount: 2), .loaded)
        XCTAssertTrue(ProgramCardView.showsActiveBadge(isEnrolled: true))
        XCTAssertFalse(ProgramCardView.showsActiveBadge(isEnrolled: false))
        _ = ProgramListView.detailDestination(program: primaryProgram, viewModel: ProgramListViewModel(programRepo: repository))

        var showCancelConfirm = false
        ProgramDetailView.presentCancelConfirmation(&showCancelConfirm)
        XCTAssertTrue(showCancelConfirm)
        ProgramDetailView.presentCancelConfirmation(Binding(
            get: { showCancelConfirm },
            set: { showCancelConfirm = $0 }
        ))
        XCTAssertTrue(showCancelConfirm)
        ProgramDetailView.presentCancelConfirmationAction(isPresented: Binding(
            get: { showCancelConfirm },
            set: { showCancelConfirm = $0 }
        ))()
        XCTAssertTrue(showCancelConfirm)

        let activeVM = ProgramListViewModel(programRepo: repository)
        activeVM.programs = [primaryProgram, secondaryProgram]
        activeVM.activeEnrollment = makeEnrollment(programID: primaryProgram.id, id: "enrolled-active")
        XCTAssertNotNil(host(NavigationStack { ProgramDetailView(program: primaryProgram, viewModel: activeVM) }, container: container).0.view)
        XCTAssertNotNil(host(NavigationStack {
            ProgramDetailView(program: primaryProgram, viewModel: activeVM, showCancelConfirm: true)
        }, container: container).0.view)

        let switchVM = ProgramListViewModel(programRepo: repository)
        switchVM.programs = [primaryProgram, secondaryProgram]
        switchVM.activeEnrollment = makeEnrollment(programID: secondaryProgram.id, id: "enrolled-other")
        XCTAssertNotNil(host(NavigationStack { ProgramDetailView(program: primaryProgram, viewModel: switchVM) }, container: container).0.view)
        ProgramDetailView.performEnrollAction(switchVM, in: primaryProgram, modelContext: container.mainContext, userID: "")()
        waitForTasks()
        XCTAssertEqual(switchVM.activeEnrollment?.programID, primaryProgram.id)
        ProgramDetailView.performCancelEnrollmentAction(switchVM, modelContext: container.mainContext)()
        waitForTasks()
        XCTAssertNil(switchVM.activeEnrollment)

        let startVM = ProgramListViewModel(programRepo: repository)
        startVM.programs = [primaryProgram]
        XCTAssertNotNil(host(NavigationStack { ProgramDetailView(program: primaryProgram, viewModel: startVM) }, container: container).0.view)

        let errorVM = ProgramListViewModel(programRepo: repository)
        errorVM.errorMessage = "Network unavailable"
        XCTAssertNotNil(host(NavigationStack { ProgramListView(viewModel: errorVM) }, container: container, triggerAppearance: false).0.view)
        let emptyVM = ProgramListViewModel(programRepo: repository)
        emptyVM.isLoading = false
        emptyVM.errorMessage = nil
        emptyVM.programs = []
        XCTAssertNotNil(host(NavigationStack { ProgramListView(viewModel: emptyVM) }, container: container, triggerAppearance: false).0.view)
        XCTAssertNotNil(host(ProgramListView.emptyStateView(), container: container).0.view)
        XCTAssertNotNil(host(ProgramCardView(program: primaryProgram, isEnrolled: true), container: container).0.view)

        let navVM = ProgramListViewModel(programRepo: repository)
        navVM.programs = [primaryProgram]
        XCTAssertNotNil(host(ProgramNavigationHarness(viewModel: navVM, selectedProgram: primaryProgram), container: container).0.view)
        XCTAssertNotNil(host(
            VStack {
                ProgramPhaseRow(phase: ProgramPhase(id: "phase-valid", name: "Base", goal: "Build", weekRange: [1, 2]))
                ProgramPhaseRow(phase: ProgramPhase(id: "phase-invalid", name: "Taper", goal: "Recover", weekRange: [3]))
            },
            container: container
        ).0.view)
    }

    func testWorkoutExecutionBranchesAndHelperPaths() throws {
        let container = try makeContainer()
        let program = makeProgram(id: "program-workout")
        let enrollment = makeEnrollment(programID: program.id, id: "enroll-workout")
        let session = program.weeks[0].sessions[0]

        XCTAssertEqual(WorkoutExecutionView.finishButtonTitle(isSaving: false), "Finish Workout")
        XCTAssertEqual(WorkoutExecutionView.finishButtonTitle(isSaving: true), "Saving…")

        var showFinishConfirm = false
        WorkoutExecutionView.presentFinishConfirmation(&showFinishConfirm)
        XCTAssertTrue(showFinishConfirm)

        var showFinishFromAction = false
        let finishButtonAction = WorkoutExecutionView.finishButtonAction(
            isPresented: Binding(
                get: { showFinishFromAction },
                set: { showFinishFromAction = $0 }
            )
        )
        finishButtonAction()
        XCTAssertTrue(showFinishFromAction)

        let authenticatedAppState = AppState()
        authenticatedAppState.apply(.authenticated(userID: "user-coverage"))
        let authenticatedFinishVM = WorkoutExecutionViewModel(session: session, enrollment: enrollment, program: program)
        WorkoutExecutionView.finishWorkout(
            viewModel: authenticatedFinishVM,
            appState: authenticatedAppState,
            modelContext: container.mainContext
        )
        XCTAssertTrue(authenticatedFinishVM.isFinished)
        XCTAssertEqual(authenticatedFinishVM.completedWorkout?.userID, "user-coverage")

        let confirmationActionVM = WorkoutExecutionViewModel(session: session, enrollment: enrollment, program: program)
        let finishConfirmationAction = WorkoutExecutionView.finishConfirmationAction(
            viewModel: confirmationActionVM,
            appState: authenticatedAppState,
            modelContext: container.mainContext
        )
        finishConfirmationAction()
        XCTAssertTrue(confirmationActionVM.isFinished)

        WorkoutExecutionView.cancelFinishAction()

        let guestAppState = AppState()
        guestAppState.signInAsGuest()
        let guestFinishVM = WorkoutExecutionViewModel(session: session, enrollment: enrollment, program: program)
        WorkoutExecutionView.finishWorkout(viewModel: guestFinishVM, appState: guestAppState, modelContext: container.mainContext)
        XCTAssertTrue(guestFinishVM.isFinished)
        XCTAssertEqual(guestFinishVM.completedWorkout?.userID, "")
        XCTAssertEqual(
            WorkoutExecutionView.summaryDestinationState(workout: guestFinishVM.completedWorkout),
            .summary
        )
        XCTAssertEqual(WorkoutExecutionView.summaryDestinationState(workout: nil), .fallback)
        _ = WorkoutExecutionView.summaryDestinationView(workout: guestFinishVM.completedWorkout)
        _ = WorkoutExecutionView.summaryDestinationView(workout: nil)

        let plateVM = WorkoutExecutionViewModel(session: session, enrollment: enrollment, program: program)
        XCTAssertEqual(
            ExerciseSetCard.plateCalculatorWeight(
                for: [SetExecutionState(prescribedReps: "5", prescribedWeightKg: 95, actualReps: nil, actualWeightKg: nil)]
            ),
            95
        )
        XCTAssertNil(ExerciseSetCard.plateCalculatorWeight(for: []))
        ExerciseSetCard.openPlateCalculator(viewModel: plateVM, weightKg: 95)
        XCTAssertTrue(plateVM.showPlateCalc)
        XCTAssertEqual(plateVM.plateCalcWeightKg, 95, accuracy: 0.001)
        ExerciseSetCard.plateCalculatorAction(viewModel: plateVM, weightKg: 85)()
        XCTAssertEqual(plateVM.plateCalcWeightKg, 85, accuracy: 0.001)

        let actionVM = WorkoutExecutionViewModel(session: session, enrollment: enrollment, program: program)
        let exerciseName = session.exercises[0].exercise
        ExerciseSetCard.repsChangeAction(viewModel: actionVM, exerciseName: exerciseName, setIndex: 0)(9)
        XCTAssertEqual(actionVM.exerciseSets[exerciseName]?[0].actualReps, 9)
        ExerciseSetCard.weightChangeAction(viewModel: actionVM, exerciseName: exerciseName, setIndex: 0)(92.5)
        XCTAssertEqual((actionVM.exerciseSets[exerciseName]?[0].actualWeightKg ?? nil) ?? 0, 92.5, accuracy: 0.001)
        ExerciseSetCard.toggleAction(viewModel: actionVM, exerciseName: exerciseName, setIndex: 0)()
        XCTAssertTrue(actionVM.exerciseSets[exerciseName]?[0].isCompleted ?? false)
        let missingExercise = ProgramExercise(
            exercise: "Missing Exercise",
            variant: nil,
            sets: .fixed(1),
            reps: .fixed(5),
            percent1RM: nil,
            restMinutes: 2,
            notes: nil
        )
        XCTAssertTrue(ExerciseSetCard(viewModel: actionVM, exercise: missingExercise).sets.isEmpty)

        XCTAssertEqual(SetRow.parseReps("8"), 8)
        XCTAssertNil(SetRow.parseReps("x"))
        XCTAssertEqual(SetRow.parseWeight("82.5", weightUnit: .kilograms) ?? 0, 82.5, accuracy: 0.001)
        XCTAssertNil(SetRow.parseWeight("x", weightUnit: .kilograms))
        XCTAssertEqual(SetRow.formatWeight(80, weightUnit: .kilograms), "80")
        XCTAssertEqual(SetRow.formatWeight(80.5, weightUnit: .kilograms), "80.5")
        let initialTexts = SetRow.initialTextValues(
            for: SetExecutionState(
                prescribedReps: "5",
                prescribedWeightKg: 100,
                actualReps: 6,
                actualWeightKg: 102.5
            ),
            weightUnit: .kilograms
        )
        XCTAssertEqual(initialTexts.repsText, "6")
        XCTAssertEqual(initialTexts.weightText, "102.5")
        let emptyInitialTexts = SetRow.initialTextValues(
            for: SetExecutionState(
                prescribedReps: "AMRAP",
                prescribedWeightKg: nil,
                actualReps: nil,
                actualWeightKg: nil
            ),
            weightUnit: .kilograms
        )
        XCTAssertEqual(emptyInitialTexts.repsText, "")
        XCTAssertEqual(emptyInitialTexts.weightText, "")

        var parsedReps: [Int] = []
        let repsHandler = SetRow.repsTextChangeHandler(onRepsChange: { parsedReps.append($0) })
        repsHandler("", "11")
        repsHandler("11", "bad")
        XCTAssertEqual(parsedReps, [11])

        var parsedWeights: [Double] = []
        let weightHandler = SetRow.weightTextChangeHandler(onWeightChange: { parsedWeights.append($0) }, weightUnit: .kilograms)
        weightHandler("", "75.5")
        weightHandler("75.5", "bad")
        XCTAssertEqual(parsedWeights.count, 1)
        XCTAssertEqual(parsedWeights.first ?? 0, 75.5, accuracy: 0.001)

        XCTAssertEqual(RestTimerOverlay.timeString(for: 125), "2:05")
        assertColor(RestTimerOverlay.timerColor(timeLeft: 11), equals: .white)
        assertColor(RestTimerOverlay.timerColor(timeLeft: 10), equals: UIColor(AppTheme.Colors.accentOrange))
        var dismissed = false
        let processedTick = RestTimerOverlay.processTick(
            timeLeft: 0,
            invalidateTimer: {},
            onDismiss: { dismissed = true }
        )
        XCTAssertEqual(processedTick, 0)
        XCTAssertTrue(dismissed)
        let continuedTick = RestTimerOverlay.processTick(
            timeLeft: 2,
            invalidateTimer: { XCTFail("Timer should not invalidate yet") },
            onDismiss: { XCTFail("Should not dismiss yet") }
        )
        XCTAssertEqual(continuedTick, 1)
        let dismissFromTick = RestTimerOverlay.nextTick(timeLeft: 0)
        XCTAssertEqual(dismissFromTick.timeLeft, 0)
        var overlayDismissed = false
        XCTAssertNotNil(host(RestTimerOverlay(seconds: .constant(1), onDismiss: { overlayDismissed = true }), container: container).0.view)
        waitForTasks(2.3)
        XCTAssertTrue(overlayDismissed)

        XCTAssertFalse(PlateCalculatorSheet.hasPlates([]))
        _ = PlateCalculatorSheet.hasPlates([(weight: 45, count: 1)])
        XCTAssertEqual(PlateCalculatorSheet.formatWeight(15, weightUnit: .kilograms), "15")
        XCTAssertEqual(PlateCalculatorSheet.formatWeight(2.5, weightUnit: .kilograms), "2.5")
        // standardBar is 45 lb → ~20.4 kg; displayed in kg it should contain the numeric value
        let barOnlyKg = PlateCalculatorSheet.barOnlyText(barKg: PlateCalculation.standardBarKg, weightUnit: .kilograms)
        XCTAssertTrue(barOnlyKg.hasPrefix("Bar only ("))
        XCTAssertTrue(barOnlyKg.contains("kg"))

        let tickDown = RestTimerOverlay.nextTick(timeLeft: 3)
        XCTAssertEqual(tickDown.timeLeft, 2)
        XCTAssertFalse(tickDown.shouldDismiss)
        let dismissTick = RestTimerOverlay.nextTick(timeLeft: 0)
        XCTAssertEqual(dismissTick.timeLeft, 0)
        XCTAssertTrue(dismissTick.shouldDismiss)

        let renderVM = WorkoutExecutionViewModel(session: session, enrollment: enrollment, program: program)
        if var sets = renderVM.exerciseSets[session.exercises[0].exercise], !sets.isEmpty {
            sets[0].prescribedWeightKg = 100
            sets[0].actualWeightKg = 82.5
            renderVM.exerciseSets[session.exercises[0].exercise] = sets
        }
        renderVM.showRestTimer = true
        renderVM.restTimerSeconds = 30
        renderVM.showPlateCalc = true

        XCTAssertNotNil(
            host(
                WorkoutExecutionView(viewModel: renderVM),
                container: container,
                appState: authenticatedAppState
            ).0.view
        )
        _ = ExerciseSetCard(viewModel: renderVM, exercise: session.exercises[0]).body
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
        _ = PlateCalculatorSheet(weightKg: PlateCalculation.standardBarKg).body
        _ = PlateCalculatorSheet(weightKg: 100).body
    }

    func testWorkoutSummaryBranchesAndHelpers() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let program = makeProgram(id: "program-summary")
        let enrollment = makeEnrollment(programID: program.id, id: "enroll-summary")
        let workout = makeWorkout(id: "workout-summary", programID: program.id, enrollmentID: enrollment.id)

        let completed = CompletedSet(
            id: "set-completed",
            userID: "user-coverage",
            workoutID: workout.id,
            exerciseName: "Back Squat",
            setIndex: 0,
            prescribedReps: "5",
            actualReps: 5,
            prescribedWeightKg: 100,
            actualWeightKg: 120
        )
        let fallback = CompletedSet(
            id: "set-fallback",
            userID: "user-coverage",
            workoutID: workout.id,
            exerciseName: "Back Squat",
            setIndex: 1,
            prescribedReps: "AMRAP",
            actualReps: nil,
            prescribedWeightKg: nil,
            actualWeightKg: nil
        )

        context.insert(workout)
        context.insert(completed)
        context.insert(fallback)
        context.insert(
            OneRepMax(
                id: "orm-summary",
                userID: "user-coverage",
                exerciseID: "Back Squat",
                weightKg: 100,
                date: Date(timeIntervalSince1970: 1_700_000_000)
            )
        )
        try context.save()

        let fallbackDisplay = SetSummaryRow.repsDisplay(for: fallback)
        XCTAssertEqual(fallbackDisplay.text, "AMRAP")
        XCTAssertTrue(fallbackDisplay.isFallback)
        let completedDisplay = SetSummaryRow.repsDisplay(for: completed)
        XCTAssertEqual(completedDisplay.text, "5 reps")
        XCTAssertFalse(completedDisplay.isFallback)

        XCTAssertNotNil(host(
            NavigationStack { WorkoutSummaryView(workout: workout) },
            container: container
        ).0.view)
        waitForTasks()
    }
}

@Suite("SpicyRatingView Coverage")
struct SpicyRatingViewCoverageTests {
    @Test
    func spicyLabelReturnsCorrectText() {
        #expect(SpicyRatingView.label(for: 1) == "Mild")
        #expect(SpicyRatingView.label(for: 2) == "Warm")
        #expect(SpicyRatingView.label(for: 3) == "Medium")
        #expect(SpicyRatingView.label(for: 4) == "Hot")
        #expect(SpicyRatingView.label(for: 5) == "Inferno")
        #expect(SpicyRatingView.label(for: 0) == "")
        #expect(SpicyRatingView.label(for: 6) == "")
    }
}
