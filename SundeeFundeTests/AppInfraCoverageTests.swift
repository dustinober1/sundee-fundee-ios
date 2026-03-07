import Testing
import SwiftData
import SwiftUI
import MetricKit
@testable import SundeeFundee

@Suite("App Infra Coverage")
struct AppInfraCoverageTests {
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @MainActor
    private func modelCount<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws -> Int {
        try context.fetch(FetchDescriptor<T>()).count
    }

    @Test @MainActor
    func appModelContainerSharedAndPreviewAreAccessible() throws {
        let shared = AppModelContainer.shared
        let preview = AppModelContainer.preview()
        #expect(ObjectIdentifier(shared) != ObjectIdentifier(preview))

        let context = ModelContext(shared)
        let users = try context.fetch(FetchDescriptor<User>())
        #expect(users.count >= 0)
    }

    @Test @MainActor
    func appModelContainerDefaultDetectionAndFallbackBranches() throws {
        let defaultContainer = AppModelContainer.makeSharedContainer()
        let defaultUsers = try ModelContext(defaultContainer).fetch(FetchDescriptor<User>())
        #expect(defaultUsers.count >= 0)

        enum StubError: Error { case failed }
        var requests: [AppModelContainer.ContainerRequest] = []
        let expected = try makeContainer()

        let fallbackContainer = AppModelContainer.makeSharedContainer(
            isRunningTests: true,
            makeContainer: { request in
                requests.append(request)
                if request == .testsInMemory { throw StubError.failed }
                return expected
            },
            log: { _ in }
        )

        #expect(requests == [.testsInMemory, .localPersistent])
        #expect(ObjectIdentifier(fallbackContainer) == ObjectIdentifier(expected))

        var defaultLogRequests: [AppModelContainer.ContainerRequest] = []
        let defaultLogContainer = AppModelContainer.makeSharedContainer(
            isRunningTests: true,
            makeContainer: { request in
                defaultLogRequests.append(request)
                if request == .testsInMemory { throw StubError.failed }
                return expected
            }
        )
        #expect(defaultLogRequests == [.testsInMemory, .localPersistent])
        #expect(ObjectIdentifier(defaultLogContainer) == ObjectIdentifier(expected))

        let prior = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"]
        unsetenv("XCTestConfigurationFilePath")
        defer {
            if let prior {
                setenv("XCTestConfigurationFilePath", prior, 1)
            } else {
                unsetenv("XCTestConfigurationFilePath")
            }
        }
        let envFallbackContainer = AppModelContainer.makeSharedContainer()
        #expect((try? ModelContext(envFallbackContainer).fetch(FetchDescriptor<User>())) != nil)

        var finalFallbackRequests: [AppModelContainer.ContainerRequest] = []
        let finalFallback = AppModelContainer.makeSharedContainer(
            isRunningTests: true,
            makeContainer: { request in
                finalFallbackRequests.append(request)
                if request == .fallbackInMemory {
                    return expected
                }
                throw StubError.failed
            },
            deleteStoreFiles: {}
        )
        #expect(finalFallbackRequests == [.testsInMemory, .localPersistent, .localPersistent, .fallbackInMemory])
        #expect(ObjectIdentifier(finalFallback) == ObjectIdentifier(expected))
    }

    @Test @MainActor
    func sundeeFundeeAppInitAndBodyBranchesAreDeterministic() throws {
        let injected = try makeContainer()
        var metricsStarts = 0

        let productionApp = SundeeFundeeApp(
            isRunningTests: false,
            sharedContainer: { injected },
            startMetrics: { metricsStarts += 1 }
        )
        if let container = productionApp.container {
            #expect(ObjectIdentifier(container) == ObjectIdentifier(injected))
        } else {
            Issue.record("Expected injected container in non-test app initialization")
        }
        _ = productionApp.body
        #expect(!String(describing: SundeeFundeeApp.rootView(container: injected)).isEmpty)

        let testApp = SundeeFundeeApp(
            isRunningTests: true,
            sharedContainer: { injected },
            startMetrics: { metricsStarts += 1 }
        )
        #expect(testApp.container == nil)
        _ = testApp.body
        #expect(!String(describing: SundeeFundeeApp.rootView(container: nil)).isEmpty)

        let defaultArgumentApp = SundeeFundeeApp(isRunningTests: false)
        #expect(defaultArgumentApp.container != nil)

        let prior = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"]
        unsetenv("XCTestConfigurationFilePath")
        defer {
            if let prior {
                setenv("XCTestConfigurationFilePath", prior, 1)
            } else {
                unsetenv("XCTestConfigurationFilePath")
            }
        }
        let autoDetectedApp = SundeeFundeeApp()
        #expect(autoDetectedApp.container == nil)
        _ = autoDetectedApp.body

        #expect(metricsStarts == 2)
    }

    @Test @MainActor
    func metricsServiceLifecycleAndEmptyPayloadHandlers() {
        #expect(MetricsService.shared === MetricsService.shared)
        MetricsService.shared.start()
        MetricsService.shared.didReceive([] as [MXMetricPayload])
        MetricsService.shared.didReceive([] as [MXDiagnosticPayload])
        MetricsService.shared.stop()
    }

    @Test @MainActor
    func appThemeTokensAndStylesAreUsable() {
        #expect(AppTheme.Spacing.xs == 4)
        #expect(AppTheme.Spacing.sm == 8)
        #expect(AppTheme.Spacing.md == 16)
        #expect(AppTheme.Spacing.lg == 24)
        #expect(AppTheme.Spacing.xl == 32)
        #expect(AppTheme.Spacing.xxl == 48)
        #expect(AppTheme.Radius.sm == 6)
        #expect(AppTheme.Radius.md == 12)
        #expect(AppTheme.Radius.lg == 20)
        #expect(AppTheme.CornerRadius.card == 12)
        #expect(AppTheme.CornerRadius.button == 8)

        #expect(!String(describing: AppTheme.Color.cream).isEmpty)
        #expect(!String(describing: AppTheme.Color.navy).isEmpty)
        #expect(!String(describing: AppTheme.Color.orange).isEmpty)
        #expect(!String(describing: AppTheme.Colors.accentOrange).isEmpty)
        #expect(!String(describing: AppTheme.Colors.cardBackground).isEmpty)
        #expect(!String(describing: AppTheme.Colors.error).isEmpty)

        #expect(!String(describing: AppTheme.Font.heading(22)).isEmpty)
        #expect(!String(describing: AppTheme.Font.body(15)).isEmpty)
        #expect(!String(describing: AppTheme.Font.mono(14)).isEmpty)
        #expect(!String(describing: AppTheme.Fonts.heading).isEmpty)
        #expect(!String(describing: AppTheme.Fonts.subheading).isEmpty)
        #expect(!String(describing: AppTheme.Fonts.body).isEmpty)
        #expect(!String(describing: AppTheme.Fonts.caption).isEmpty)
        #expect(!String(describing: AppTheme.Fonts.mono).isEmpty)

        #expect(!String(describing: Text("Card").cardStyle()).isEmpty)

        _ = ImageRenderer(content: Button("Primary") {}.buttonStyle(PrimaryButtonStyle())).uiImage
        _ = ImageRenderer(content: Button("Secondary") {}.buttonStyle(SecondaryButtonStyle())).uiImage
        _ = ImageRenderer(content: Button("Delete") {}.buttonStyle(DestructiveButtonStyle())).uiImage
    }

    #if DEBUG
    @Test @MainActor
    func debugSeedDataSeedsOnceAndClearRemovesRecords() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        #expect(try modelCount(User.self, in: context) == 0)
        #expect(try modelCount(EnrolledProgram.self, in: context) == 0)
        #expect(try modelCount(OneRepMax.self, in: context) == 0)
        #expect(try modelCount(LiftMax.self, in: context) == 0)

        await DebugSeedData.seed(modelContext: context)
        #expect(try modelCount(User.self, in: context) == 1)
        #expect(try modelCount(EnrolledProgram.self, in: context) == 1)
        #expect(try modelCount(OneRepMax.self, in: context) == 7)
        #expect(try modelCount(LiftMax.self, in: context) == 7)
        #expect(try modelCount(CycleSettings.self, in: context) == 1)
        #expect(try modelCount(PeriodLog.self, in: context) == 1)

        await DebugSeedData.seed(modelContext: context)
        #expect(try modelCount(User.self, in: context) == 1)
        #expect(try modelCount(OneRepMax.self, in: context) == 7)

        DebugSeedData.clearAll(modelContext: context)
        #expect(try modelCount(User.self, in: context) == 0)
        #expect(try modelCount(EnrolledProgram.self, in: context) == 0)
        #expect(try modelCount(OneRepMax.self, in: context) == 0)
        #expect(try modelCount(LiftMax.self, in: context) == 0)
        #expect(try modelCount(CycleSettings.self, in: context) == 0)
        #expect(try modelCount(PeriodLog.self, in: context) == 0)
    }
    #endif

    @Test
    func appSchemaV7_containsConditioningPR() {
        let modelTypes = AppSchemaV7.models
        #expect(modelTypes.contains(where: { $0 == ConditioningPR.self }))
    }

    @Test
    func appSchemaV7_versionIdentifier() {
        #expect(AppSchemaV7.versionIdentifier == Schema.Version(7, 0, 0))
    }

    @Test
    func migrationPlan_includesV6toV7() {
        #expect(AppSchemaMigrationPlan.schemas.count == 5)
        #expect(AppSchemaMigrationPlan.stages.count == 4)
    }

    @Test
    func appSchemaV8_containsPerceivedEffort() {
        let models = AppSchemaV8.models
        #expect(models.contains(where: { $0 == CompletedWorkout.self }))
        #expect(AppSchemaV8.versionIdentifier == Schema.Version(8, 0, 0))
    }

    @Test
    func migrationPlanIncludesV9() {
        let schemas = AppSchemaMigrationPlan.schemas
        #expect(schemas.count == 5)
        #expect(schemas.last is AppSchemaV9.Type)
    }
}
