import XCTest
@testable import SundeeFundeeKit

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    func testMinimalOnboardingDefaultsExperienceToBeginner() {
        let viewModel = OnboardingViewModel(dataClient: MockCloudKitClient())

        XCTAssertEqual(viewModel.experienceLevel, .beginner)
        XCTAssertEqual(viewModel.totalSteps, 2)
    }

    func testCompleteOnboardingSavesMinimalPreferences() async {
        let dataClient = MockCloudKitClient()
        let viewModel = OnboardingViewModel(dataClient: dataClient)
        viewModel.primaryGoal = .strength
        viewModel.defaultEquipment = .resistanceBands
        viewModel.weightUnit = .lbs
        viewModel.cycleTrackingEnabled = true

        await viewModel.completeOnboarding()

        XCTAssertEqual(dataClient.recordCount(for: "UserSettings"), 1)
    }

    func testCompleteOnboardingSavesSelectedExperienceLevel() async throws {
        let dataClient = MockCloudKitClient()
        let viewModel = OnboardingViewModel(dataClient: dataClient)
        viewModel.experienceLevel = .advanced

        await viewModel.completeOnboarding()

        let saved: [UserSettingsRecord] = try await dataClient.fetchAll(recordType: "UserSettings")
        XCTAssertEqual(saved.last?.experienceLevel, ExperienceLevel.advanced.rawValue)
    }
}
