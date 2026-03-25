import Testing
import Foundation
@testable import SundeeFundee

@Suite("AIWorkoutServiceRemote")
struct AIWorkoutServiceRemoteTests {

    static let validGeminiResponse = """
    {
      "candidates": [{
        "content": {
          "parts": [{
            "text": "{\\"coachingSummary\\":\\"AI-powered session.\\",\\"exercises\\":[{\\"name\\":\\"Back Squat\\",\\"sets\\":4,\\"reps\\":\\"5\\",\\"weightKg\\":80,\\"restMinutes\\":3,\\"notes\\":null,\\"reasoning\\":null,\\"bodyweightOnly\\":false}]}"
          }]
        }
      }]
    }
    """.data(using: .utf8)!

    @Test func parsesGeminiProxyResponse() throws {
        let text = try GeminiResponseParser.extractText(from: Self.validGeminiResponse)
        #expect(text.contains("coachingSummary"))
    }

    @Test func parsesGeminiResponseWithMarkdownFences() throws {
        let fenced = """
        {
          "candidates": [{
            "content": {
              "parts": [{
                "text": "```json\\n{\\"coachingSummary\\":\\"test\\",\\"exercises\\":[]}\\n```"
              }]
            }
          }]
        }
        """.data(using: .utf8)!

        let text = try GeminiResponseParser.extractText(from: fenced)
        let cleaned = RemoteWorkoutResponse.stripMarkdownFences(text)
        let response = try JSONDecoder().decode(RemoteWorkoutResponse.self, from: Data(cleaned.utf8))
        #expect(response.coachingSummary == "test")
    }

    @Test func extractTextThrowsOnMissingCandidates() {
        let bad = "{}".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try GeminiResponseParser.extractText(from: bad)
        }
    }
}
