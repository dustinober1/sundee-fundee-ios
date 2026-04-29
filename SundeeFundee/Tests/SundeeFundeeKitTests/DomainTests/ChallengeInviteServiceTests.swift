import XCTest
@testable import SundeeFundeeKit

final class ChallengeInviteServiceTests: XCTestCase {
    func testTemplateAndInviteTextIncludeChallengeDetails() async {
        let challenge = ChallengeEngine.createCustomChallenge(
            title: "April Push",
            targetVolumeLbs: 50_000,
            endDate: nil
        )
        let service = ChallengeInviteService()

        let template = await service.template(from: challenge, userID: "user")
        let text = await service.inviteText(template: template, inviteToken: "ABCD1234")

        XCTAssertEqual(template.title, "April Push")
        XCTAssertTrue(text.contains("April Push"))
        XCTAssertTrue(text.contains("50K"))
        XCTAssertTrue(text.contains("ABCD1234"))
    }
}
