import XCTest
@testable import SundeeFundeeKit

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    func testMinimalOnboardingDefaultsExperienceToIntermediate() {
        let viewModel = OnboardingViewModel(dataClient: MockCloudKitClient())

        XCTAssertEqual(viewModel.experienceLevel, .intermediate)
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
}
