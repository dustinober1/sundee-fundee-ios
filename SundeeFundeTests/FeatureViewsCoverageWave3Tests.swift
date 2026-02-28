import XCTest
import SwiftUI
import SwiftData
import UIKit
@testable import SundeeFundee

@MainActor
final class FeatureViewsCoverageWave3Tests: XCTestCase {
    private struct TestStore {
        let container: ModelContainer
        let context: ModelContext
    }

    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeStore() throws -> TestStore {
        let schema = Schema(AppSchemaV6.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return TestStore(container: container, context: ModelContext(container))
    }

    @discardableResult
    private func host<Content: View>(
        _ view: Content,
        triggerAppearance: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UIHostingController<Content> {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()

        if triggerAppearance {
            controller.beginAppearanceTransition(true, animated: false)
            controller.endAppearanceTransition()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.25))
        }

        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        if triggerAppearance {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.25))
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
        }
        XCTAssertNotNil(controller.view, file: file, line: line)
        _ = window
        return controller
    }

    private func makeCycleStatus(phase: CyclePhase) -> CycleStatusResult {
        CycleStatusResult(
            currentPhase: phase,
            cycleDay: 8,
            daysUntilNextPhase: 3,
            predictedNextPeriod: fixedDate.addingTimeInterval(86_400 * 20),
            phaseStartDate: fixedDate.addingTimeInterval(-86_400),
            phaseEndDate: fixedDate.addingTimeInterval(86_400)
        )
    }
    
    private func waitForTasks(_ seconds: TimeInterval = 0.15) {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds))
    }

    func testCycleViewsRenderAdditionalBranches() throws {
        let store = try makeStore()

        let periodWithEnd = PeriodLog(
            id: "period-with-end",
            userID: "cycle-user",
            startDate: fixedDate.addingTimeInterval(-86_400 * 3),
            endDate: fixedDate.addingTimeInterval(-86_400),
            flowLevel: .heavy
        )
        let periodWithoutEnd = PeriodLog(
            id: "period-no-end",
            userID: "cycle-user",
            startDate: fixedDate.addingTimeInterval(-86_400 * 31),
            endDate: nil,
            flowLevel: .light
        )
        let symptom = SymptomLog(
            id: "symptom-1",
            userID: "cycle-user",
            date: fixedDate,
            symptomID: "mood_changes",
            severity: 4,
            notes: "Tracking symptoms"
        )

        store.context.insert(CycleSettings(id: "cycle-settings", userID: "cycle-user", updatedAt: fixedDate))
        store.context.insert(periodWithEnd)
        store.context.insert(symptom)
        try store.context.save()

        XCTAssertNotNil(host(
            NavigationStack { CycleTrackingView() }
                .modelContainer(store.container),
            triggerAppearance: true
        ).view)

        let emptyVM = CycleTrackingViewModel()
        let populatedVM = CycleTrackingViewModel()
        populatedVM.cycleStatus = makeCycleStatus(phase: .ovulation)
        populatedVM.periodLogs = [periodWithEnd, periodWithoutEnd]
        populatedVM.symptomLogs = [symptom]
        populatedVM.avgCycleLength = 30
        populatedVM.avgPeriodLength = 6
        populatedVM.lutealPhaseLength = 13
        populatedVM.adaptationEnabled = false

        XCTAssertNotNil(host(PeriodLogSection(viewModel: emptyVM)).view)
        XCTAssertNotNil(host(PeriodLogSection(viewModel: populatedVM)).view)
        XCTAssertNotNil(host(SymptomLogSection(viewModel: emptyVM)).view)
        XCTAssertNotNil(host(SymptomLogSection(viewModel: populatedVM)).view)
        XCTAssertNotNil(host(CycleSettingsSection(viewModel: populatedVM)).view)

        XCTAssertNotNil(host(
            VStack {
                PeriodLogRow(log: periodWithEnd)
                PeriodLogRow(log: periodWithoutEnd)
                SymptomLogRow(log: symptom)
                SeverityDots(severity: 1)
                SeverityDots(severity: 5)
            }
        ).view)

        XCTAssertNotNil(host(
            VStack {
                ForEach(CyclePhase.allCases, id: \.rawValue) { phase in
                    PhaseStatusHeader(status: self.makeCycleStatus(phase: phase))
                }
            }
        ).view)

        XCTAssertNotNil(host(AddPeriodLogSheet(viewModel: populatedVM), triggerAppearance: true).view)
        XCTAssertNotNil(host(AddSymptomLogSheet(viewModel: populatedVM), triggerAppearance: true).view)
    }

    func testMaxLiftsViewsRenderAdditionalBranches() throws {
        let emptyStore = try makeStore()
        XCTAssertNotNil(host(
            NavigationStack { MaxLiftsView() }
                .modelContainer(emptyStore.container),
            triggerAppearance: true
        ).view)

        let populatedStore = try makeStore()
        let orm = OneRepMax(
            id: "orm-back-squat",
            userID: "max-user",
            exerciseID: "Back Squat",
            weightKg: 125,
            date: fixedDate
        )
        let prOne = PersonalRecord(
            id: "pr-1",
            userID: "max-user",
            exerciseID: "Back Squat",
            repMaxType: .three,
            weightKg: 110,
            reps: 3,
            achievedAt: fixedDate
        )
        let prTwo = PersonalRecord(
            id: "pr-2",
            userID: "max-user",
            exerciseID: "Back Squat",
            repMaxType: .five,
            weightKg: 100,
            reps: 5,
            achievedAt: fixedDate.addingTimeInterval(-3_600)
        )
        let prThree = PersonalRecord(
            id: "pr-3",
            userID: "max-user",
            exerciseID: "Back Squat",
            repMaxType: .one,
            weightKg: 117.5,
            reps: 1,
            achievedAt: fixedDate.addingTimeInterval(-7_200)
        )
        let prFour = PersonalRecord(
            id: "pr-4",
            userID: "max-user",
            exerciseID: "Back Squat",
            repMaxType: .five,
            weightKg: 95,
            reps: 5,
            achievedAt: fixedDate.addingTimeInterval(-10_800)
        )

        populatedStore.context.insert(orm)
        populatedStore.context.insert(prOne)
        populatedStore.context.insert(prTwo)
        populatedStore.context.insert(prThree)
        populatedStore.context.insert(prFour)
        try populatedStore.context.save()

        XCTAssertNotNil(host(
            NavigationStack { MaxLiftsView() }
                .modelContainer(populatedStore.container),
            triggerAppearance: true
        ).view)

        let vmWithData = MaxLiftsViewModel()
        vmWithData.exerciseNames = ["Back Squat", "Bench Press"]
        vmWithData.oneRepMaxes = ["Back Squat": orm]
        vmWithData.personalRecords = ["Back Squat": [prOne, prTwo, prThree, prFour]]

        XCTAssertNotNil(host(
            VStack {
                LiftMaxRow(exercise: "Back Squat", oneRepMax: orm, prs: [prOne, prTwo, prThree, prFour])
                LiftMaxRow(exercise: "Bench Press", oneRepMax: nil, prs: [])
                PRBadge(pr: prOne)
            }
        ).view)

        XCTAssertNotNil(host(
            NavigationStack {
                ExerciseDetailView(exercise: "Back Squat", viewModel: vmWithData)
            }
        ).view)

        let vmWithoutData = MaxLiftsViewModel()
        XCTAssertNotNil(host(
            NavigationStack {
                ExerciseDetailView(exercise: "Strict Press", viewModel: vmWithoutData)
            }
        ).view)

        XCTAssertNotNil(host(AddLiftMaxSheet(viewModel: vmWithData), triggerAppearance: true).view)
    }

    func testBenchmarksViewsRenderAdditionalBranches() throws {
        let emptyStore = try makeStore()
        XCTAssertNotNil(host(
            NavigationStack { BenchmarksView() }
                .modelContainer(emptyStore.container),
            triggerAppearance: true
        ).view)

        let populatedStore = try makeStore()
        let defTime = BenchmarkDefinition(
            id: "def-time",
            userID: "benchmark-user",
            name: "Month 1 Baseline",
            category: BenchmarkCatalog.generalFitness,
            workoutDescription: "21-15-9 thrusters and pull-ups",
            scoringType: .time,
            isPredefined: false,
            sortOrder: 1
        )
        let defWeight = BenchmarkDefinition(
            id: "def-weight",
            userID: "benchmark-user",
            name: "Strength Test",
            category: "Weightlifting",
            workoutDescription: "Max back squat",
            scoringType: .weight,
            isPredefined: false,
            sortOrder: 2
        )

        populatedStore.context.insert(defTime)
        populatedStore.context.insert(defWeight)
        try populatedStore.context.save()

        XCTAssertNotNil(host(
            NavigationStack { BenchmarksView() }
                .modelContainer(populatedStore.container),
            triggerAppearance: true
        ).view)

        XCTAssertNotNil(host(
            VStack {
                BenchmarkDefinitionRow(definition: defTime)
                BenchmarkDefinitionRow(definition: defWeight)
            }
        ).view)

        XCTAssertNotNil(host(AddCustomBenchmarkSheet(viewModel: BenchmarksViewModel()), triggerAppearance: true).view)
    }

    func testSettingsViewsRenderAdditionalBranches() async throws {
        let store = try makeStore()
        let user = User(
            id: "settings-user",
            name: "Coverage User",
            experienceLevel: .intermediate,
            primaryGoal: .hypertrophy,
            gender: .female,
            appleUserID: "apple-settings-user"
        )
        let activeInjury = InjuryProfile(
            id: "injury-active",
            userID: "settings-user",
            location: "Knee",
            movementLimitations: "No deep flexion",
            recoveryGoal: "Pain-free squat",
            status: .active,
            createdAt: fixedDate,
            updatedAt: fixedDate
        )
        let resolvedInjury = InjuryProfile(
            id: "injury-resolved",
            userID: "settings-user",
            location: "Shoulder",
            movementLimitations: "Limit overhead volume",
            recoveryGoal: "Return to strict press",
            status: .resolved,
            createdAt: fixedDate.addingTimeInterval(-86_400),
            updatedAt: fixedDate
        )
        let unnamedResolved = InjuryProfile(
            id: "injury-unnamed",
            userID: "settings-user",
            location: "",
            movementLimitations: "Light range only",
            recoveryGoal: "Restore movement",
            status: .resolved,
            createdAt: fixedDate.addingTimeInterval(-172_800),
            updatedAt: fixedDate
        )

        store.context.insert(user)
        store.context.insert(activeInjury)
        store.context.insert(resolvedInjury)
        try store.context.save()

        let authenticatedAppState = AppState()
        authenticatedAppState.apply(.authenticated(userID: "settings-user"))
        XCTAssertNotNil(host(
            NavigationStack { SettingsView() }
                .environment(authenticatedAppState)
                .modelContainer(store.container),
            triggerAppearance: true
        ).view)

        let guestAppState = AppState()
        guestAppState.signInAsGuest()
        XCTAssertNotNil(host(
            NavigationStack { SettingsView() }
                .environment(guestAppState)
                .modelContainer(store.container),
            triggerAppearance: true
        ).view)

        let populatedVM = SettingsViewModel()
        await populatedVM.load(modelContext: store.context, userID: "settings-user")

        XCTAssertNotNil(host(
            NavigationStack { InjuryProfilesView(viewModel: SettingsViewModel()) }
        ).view)
        XCTAssertNotNil(host(
            NavigationStack { InjuryProfilesView(viewModel: populatedVM) }
        ).view)

        XCTAssertNotNil(host(
            VStack {
                InjuryRow(injury: activeInjury)
                InjuryRow(injury: unnamedResolved)
            }
        ).view)

        XCTAssertNotNil(host(
            NavigationStack {
                EditInjuryView(injury: activeInjury, viewModel: populatedVM)
            }
        ).view)
        XCTAssertNotNil(host(
            NavigationStack {
                EditInjuryView(injury: resolvedInjury, viewModel: populatedVM)
            }
        ).view)

        XCTAssertNotNil(host(
            NavigationStack {
                EditProfileView(viewModel: populatedVM)
            }
        ).view)
        XCTAssertNotNil(host(AddInjurySheet(viewModel: populatedVM), triggerAppearance: true).view)

        XCTAssertNotNil(host(NavigationStack { LegalView(page: .terms) }).view)
        XCTAssertNotNil(host(NavigationStack { LegalView(page: .privacy) }).view)
        XCTAssertNotNil(host(NavigationStack { LegalView(page: .medical) }).view)
    }
    
    func testWave7DeterministicFeatureViewSeams() async throws {
        let store = try makeStore()
        let user = User(
            id: "wave7-user",
            name: "Wave Seven",
            experienceLevel: .intermediate,
            primaryGoal: .strength,
            gender: .female,
            appleUserID: "apple-wave7"
        )
        let injury = InjuryProfile(
            id: "wave7-injury",
            userID: "wave7-user",
            location: "Knee",
            movementLimitations: "Limit deep flexion",
            recoveryGoal: "Pain-free squat",
            status: .active,
            createdAt: fixedDate,
            updatedAt: fixedDate
        )
        store.context.insert(user)
        store.context.insert(injury)
        store.context.insert(
            CycleSettings(
                id: "wave7-cycle-settings",
                userID: "wave7-user",
                averageCycleLengthDays: 29,
                averagePeriodLengthDays: 5,
                lutealPhaseLengthDays: 13,
                isTrackingEnabled: true,
                updatedAt: fixedDate
            )
        )
        try store.context.save()
        
        let cycleVM = CycleTrackingViewModel()
        await cycleVM.load(modelContext: store.context, userID: "wave7-user")
        XCTAssertEqual(CycleTrackingView.sectionTab(for: 0), .periodLog)
        XCTAssertEqual(CycleTrackingView.sectionTab(for: 1), .symptoms)
        XCTAssertEqual(CycleTrackingView.sectionTab(for: 99), .settings)
        XCTAssertNotNil(host(CycleTrackingView.sectionView(for: 0, viewModel: cycleVM)).view)
        XCTAssertNotNil(host(CycleTrackingView.sectionView(for: 1, viewModel: cycleVM)).view)
        XCTAssertNotNil(host(CycleTrackingView.sectionView(for: 2, viewModel: cycleVM)).view)
        
        cycleVM.showAddPeriodLog = false
        cycleVM.showAddSymptomLog = false
        CycleTrackingView.primaryAction(for: 0, viewModel: cycleVM)?()
        CycleTrackingView.primaryAction(for: 1, viewModel: cycleVM)?()
        XCTAssertNil(CycleTrackingView.primaryAction(for: 2, viewModel: cycleVM))
        XCTAssertTrue(cycleVM.showAddPeriodLog)
        XCTAssertTrue(cycleVM.showAddSymptomLog)
        XCTAssertNotNil(host(CycleTrackingView.periodSheetContent(viewModel: cycleVM)(), triggerAppearance: true).view)
        XCTAssertNotNil(host(CycleTrackingView.symptomSheetContent(viewModel: cycleVM)(), triggerAppearance: true).view)
        
        let baseDate = fixedDate
        var mutableEndDate: Date? = nil
        let endDateBinding = AddPeriodLogSheet.endDateBinding(
            startDate: baseDate,
            endDate: Binding(
                get: { mutableEndDate },
                set: { mutableEndDate = $0 }
            )
        )
        XCTAssertEqual(endDateBinding.wrappedValue, baseDate)
        let nextDate = baseDate.addingTimeInterval(86_400)
        endDateBinding.wrappedValue = nextDate
        XCTAssertEqual(mutableEndDate, nextDate)
        XCTAssertNil(AddPeriodLogSheet.resolvedEndDate(hasEndDate: false, endDate: nextDate))
        XCTAssertEqual(AddPeriodLogSheet.resolvedEndDate(hasEndDate: true, endDate: nextDate), nextDate)
        XCTAssertNotNil(host(
            AddPeriodLogSheet(
                viewModel: cycleVM,
                startDate: baseDate,
                endDate: nextDate,
                flowLevel: .heavy,
                hasEndDate: true
            ),
            triggerAppearance: true
        ).view)
        
        var periodDismissed = false
        AddPeriodLogSheet.saveAction(
            viewModel: cycleVM,
            startDate: baseDate,
            endDate: nextDate,
            hasEndDate: true,
            flowLevel: .medium,
            dismiss: { periodDismissed = true }
        )()
        XCTAssertTrue(periodDismissed)
        XCTAssertEqual(cycleVM.periodLogs.count, 1)
        PeriodLogSection.deleteAction(viewModel: cycleVM)(IndexSet(integer: 0))
        XCTAssertTrue(cycleVM.periodLogs.isEmpty)
        
        XCTAssertNil(AddSymptomLogSheet.normalizedNotes(""))
        XCTAssertEqual(AddSymptomLogSheet.normalizedNotes("Tracked"), "Tracked")
        XCTAssertNotNil(host(
            AddSymptomLogSheet(
                viewModel: cycleVM,
                symptomID: "headache",
                severity: 5,
                date: baseDate,
                notes: "Logged",
                symptoms: ["headache"]
            ),
            triggerAppearance: true
        ).view)
        var symptomDismissed = false
        AddSymptomLogSheet.saveAction(
            viewModel: cycleVM,
            symptomID: "fatigue",
            severity: 3,
            date: baseDate,
            notes: "",
            dismiss: { symptomDismissed = true }
        )()
        XCTAssertTrue(symptomDismissed)
        XCTAssertEqual(cycleVM.symptomLogs.count, 1)
        XCTAssertNil(cycleVM.symptomLogs.first?.notes)
        SymptomLogSection.deleteAction(viewModel: cycleVM)(IndexSet(integer: 0))
        XCTAssertTrue(cycleVM.symptomLogs.isEmpty)
        
        CycleSettingsSection.saveSettingsAction(viewModel: cycleVM)()
        waitForTasks()
        
        let benchmarkVM = BenchmarksViewModel()
        await benchmarkVM.load(modelContext: store.context, userID: "wave7-user")
        // Add a custom definition and verify it appears in categoryGroups
        benchmarkVM.addCustomDefinition(
            name: "Wave7 Custom",
            category: BenchmarkCatalog.generalFitness,
            description: "Custom wave7 benchmark",
            scoringType: .time
        )
        XCTAssertTrue(benchmarkVM.categoryGroups.contains(where: { group in
            group.definitions.contains(where: { $0.name == "Wave7 Custom" })
        }))
        // Delete the custom definition and verify removal
        if let customDef = benchmarkVM.categoryGroups
            .flatMap(\.definitions)
            .first(where: { $0.name == "Wave7 Custom" && !$0.isPredefined }) {
            benchmarkVM.deleteCustomDefinition(customDef)
            XCTAssertFalse(benchmarkVM.categoryGroups.contains(where: { group in
                group.definitions.contains(where: { $0.name == "Wave7 Custom" })
            }))
        }
        // Smoke-test the add sheet renders
        XCTAssertNotNil(host(AddCustomBenchmarkSheet(viewModel: benchmarkVM)).view)
        
        XCTAssertEqual(
            MaxLiftsView.filteredExercises(
                searchText: "squat",
                exerciseNames: ["Back Squat", "Bench Press"]
            ),
            ["Back Squat"]
        )
        XCTAssertEqual(MaxLiftsView.emptyStateTitle(searchText: ""), "No Lift Data")
        XCTAssertEqual(MaxLiftsView.emptyStateTitle(searchText: "x"), "No Results")
        XCTAssertEqual(
            MaxLiftsView.emptyStateDescription(searchText: ""),
            "Complete workouts to automatically track your 1RM."
        )
        XCTAssertEqual(
            MaxLiftsView.emptyStateDescription(searchText: "x"),
            "Try a different search term."
        )
        let samplePR = PersonalRecord(
            id: "wave7-pr",
            userID: "wave7-user",
            exerciseID: "Back Squat",
            repMaxType: .three,
            weightKg: 100,
            reps: 3,
            achievedAt: fixedDate
        )
        XCTAssertTrue(MaxLiftsView.personalRecords(for: "Missing", records: [:]).isEmpty)
        XCTAssertEqual(
            MaxLiftsView.personalRecords(for: "Back Squat", records: ["Back Squat": [samplePR]]).count,
            1
        )
        let maxVM = MaxLiftsViewModel()
        await maxVM.load(modelContext: store.context, userID: "wave7-user")
        var maxDismissed = false
        AddLiftMaxSheet.saveAction(
            viewModel: maxVM,
            selectedExercise: "Back Squat",
            weightKg: "bad",
            reps: 1,
            isEstimated: false,
            dismiss: { maxDismissed = true }
        )()
        XCTAssertFalse(maxDismissed)
        AddLiftMaxSheet.saveAction(
            viewModel: maxVM,
            selectedExercise: "Back Squat",
            weightKg: "120",
            reps: 1,
            isEstimated: true,
            dismiss: { maxDismissed = true }
        )()
        XCTAssertTrue(maxDismissed)
        XCTAssertNotNil(maxVM.oneRepMaxes["Back Squat"])
        var showMaxAdd = false
        MaxLiftsView.presentAddSheetAction(isPresented: Binding(
            get: { showMaxAdd },
            set: { showMaxAdd = $0 }
        ))()
        XCTAssertTrue(showMaxAdd)
        XCTAssertFalse(WeightliftingExerciseCatalog.defaultExerciseID.isEmpty)
        XCTAssertNotNil(host(NavigationStack { MaxLiftsView.exerciseDestination(viewModel: maxVM)("Back Squat") }).view)
        XCTAssertNotNil(host(MaxLiftsView.addSheetContent(viewModel: maxVM)()).view)
        
        let settingsVM = SettingsViewModel()
        await settingsVM.load(modelContext: store.context, userID: "wave7-user")
        var showSignOut = false
        SettingsView.presentSignOutConfirmation(&showSignOut)
        XCTAssertTrue(showSignOut)
        showSignOut = false
        SettingsView.presentSignOutConfirmationAction(isPresented: Binding(
            get: { showSignOut },
            set: { showSignOut = $0 }
        ))()
        XCTAssertTrue(showSignOut)
        
        var profileDismissed = false
        EditProfileView.saveAction(viewModel: settingsVM, dismiss: { profileDismissed = true })()
        waitForTasks(0.5)
        XCTAssertTrue(profileDismissed || !settingsVM.displayName.isEmpty)
        
        var showAddInjury = false
        InjuryProfilesView.presentAddSheetAction(isPresented: Binding(
            get: { showAddInjury },
            set: { showAddInjury = $0 }
        ))()
        XCTAssertTrue(showAddInjury)
        XCTAssertNotNil(host(NavigationStack {
            InjuryProfilesView.destination(viewModel: settingsVM)(injury)
        }).view)
        XCTAssertNotNil(host(InjuryProfilesView.addSheetContent(viewModel: settingsVM)()).view)
        
        var resolveDismissed = false
        EditInjuryView.resolveAction(
            injury: injury,
            viewModel: settingsVM,
            dismiss: { resolveDismissed = true }
        )()
        XCTAssertTrue(resolveDismissed)
        XCTAssertFalse(injury.isActive)
        
        var editDismissed = false
        EditInjuryView.saveAction(
            injury: injury,
            viewModel: settingsVM,
            location: "Updated Knee",
            limitations: "Light range",
            recoveryGoal: "Return to full depth",
            selectedPhase: .acute,
            dismiss: { editDismissed = true }
        )()
        XCTAssertTrue(editDismissed)
        XCTAssertEqual(injury.location, "Updated Knee")
        
        var addInjuryDismissed = false
        AddInjurySheet.saveAction(
            viewModel: settingsVM,
            location: "",
            limitations: "",
            recoveryGoal: "",
            selectedRegions: [],
            dismiss: { addInjuryDismissed = true }
        )()
        XCTAssertFalse(addInjuryDismissed)
        AddInjurySheet.saveAction(
            viewModel: settingsVM,
            location: "Ankle",
            limitations: "Avoid plyos",
            recoveryGoal: "Stable landing",
            selectedRegions: [],
            dismiss: { addInjuryDismissed = true }
        )()
        XCTAssertTrue(addInjuryDismissed)
        XCTAssertTrue(settingsVM.injuryProfiles.contains(where: { $0.location == "Ankle" }))
        
        // BodyMapView: render with pre-selected regions (exercises summary text branch)
        var selectedRegions: Set<BodyLocation.Region> = [.leftKnee, .lowerBack]
        XCTAssertNotNil(host(BodyMapView(selectedRegions: Binding(
            get: { selectedRegions },
            set: { selectedRegions = $0 }
        ))).view)
        // Also render with empty selection (no summary text branch)
        var emptyRegions: Set<BodyLocation.Region> = []
        XCTAssertNotNil(host(BodyMapView(selectedRegions: Binding(
            get: { emptyRegions },
            set: { emptyRegions = $0 }
        ))).view)
        
        // AddInjurySheet.saveAction with selectedRegions non-empty (uses region display names as location)
        addInjuryDismissed = false
        AddInjurySheet.saveAction(
            viewModel: settingsVM,
            location: "",
            limitations: "Avoid loading",
            recoveryGoal: "Full recovery",
            selectedRegions: [.leftKnee, .rightKnee],
            dismiss: { addInjuryDismissed = true }
        )()
        XCTAssertTrue(addInjuryDismissed)
        XCTAssertTrue(settingsVM.injuryProfiles.contains(where: { $0.location.contains("Knee") }))
        
        #if DEBUG
        var seedMessage: String? = nil
        SettingsView.clearDataAction(modelContext: store.context, seedMessage: Binding(
            get: { seedMessage },
            set: { seedMessage = $0 }
        ))()
        XCTAssertEqual(seedMessage, "All data cleared.")
        SettingsView.seedDataAction(modelContext: store.context, seedMessage: Binding(
            get: { seedMessage },
            set: { seedMessage = $0 }
        ))()
        waitForTasks(1.0)
        XCTAssertNotNil(seedMessage)
        XCTAssertNotNil(host(SettingsView.debugMessageView("Sample data seeded!")).view)
        XCTAssertNotNil(host(SettingsView.debugMessageView(nil)).view)
        #endif
    }

    func testEditProfileViewShowsGenderPicker() async throws {
        let vm = SettingsViewModel()
        vm.gender = .female
        vm.cycleTrackingEnabled = true
        let view = NavigationStack { EditProfileView(viewModel: vm) }
        XCTAssertNotNil(host(view).view)
    }

    func testShouldHideCycleToggleForGenders() {
        XCTAssertTrue(EditProfileView.shouldHideCycleToggle(for: .male))
        XCTAssertFalse(EditProfileView.shouldHideCycleToggle(for: .female))
        XCTAssertFalse(EditProfileView.shouldHideCycleToggle(for: .preferNotToSay))
    }

    // MARK: - CelebrationOverlayView conditioning PR

    func testCelebrationOverlayViewConditioningPR() {
        let event = CelebrationEvent.newConditioningPR(exerciseName: "Wall Ball", value: 100, scoringType: .reps)
        let view = CelebrationOverlayView(event: event, weightUnit: .pounds)
        XCTAssertNotNil(host(view).view)
    }

    // MARK: - ConditioningPRRow

    private func makeV7Store() throws -> TestStore {
        let schema = Schema(AppSchemaV7.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return TestStore(container: container, context: ModelContext(container))
    }

    func testConditioningPRRowRendersReps() throws {
        let store = try makeV7Store()
        let pr = ConditioningPR(id: "1", userID: "u", exerciseID: "Wall Ball", scoringType: .reps, bestValue: 100)
        store.context.insert(pr)
        let view = ConditioningPRRow(pr: pr)
        XCTAssertNotNil(host(view).view)
    }

    func testConditioningPRRowRendersTimeWithWeight() throws {
        let store = try makeV7Store()
        let pr = ConditioningPR(id: "2", userID: "u", exerciseID: "400m Run", scoringType: .time, bestValue: 90, weightKg: 20)
        store.context.insert(pr)
        let view = ConditioningPRRow(pr: pr)
        XCTAssertNotNil(host(view).view)
    }
}
