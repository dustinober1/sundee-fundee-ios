import Foundation
import Testing

@testable import SundeeFundee

// MARK: - MockURLProtocol

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - GeminiWorkoutServiceTests

@Suite("GeminiWorkoutServiceTests", .serialized)
struct GeminiWorkoutServiceTests {

    // MARK: - Helpers

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func makeContext() -> WorkoutGenerationContext {
        WorkoutGenerationContext(
            userID: "user-1",
            timeMinutes: 45,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .fullGym,
            maxes: [ExerciseMax(name: "Back Squat", weightKg: 100)],
            recentWorkouts: [],
            cyclePhase: "follicular",
            readinessTier: nil,
            activeInjuries: [],
            experienceLevel: "intermediate",
            primaryGoal: "strength",
            gender: "female",
            weightUnit: "kg"
        )
    }

    private func geminiResponse(summary: String = "AI session", exerciseName: String = "Back Squat") -> Data {
        let json = """
        {"candidates":[{"content":{"parts":[{"text":"{\\"coachingSummary\\":\\"\(summary)\\",\\"exercises\\":[{\\"name\\":\\"\(exerciseName)\\",\\"sets\\":4,\\"reps\\":\\"5\\",\\"weightKg\\":80,\\"restMinutes\\":3.0,\\"bodyweightOnly\\":false}]}"}]}}]}
        """
        return Data(json.utf8)
    }

    // MARK: - Tests

    @Test("Successful generation returns parsed workout")
    func successfulGeneration() async throws {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: GeminiWorkoutService.proxyURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, geminiResponse())
        }

        let service = GeminiWorkoutService(session: makeSession())
        let workout = try await service.generate(from: makeContext())

        #expect(workout.coachingSummary == "AI session")
        #expect(workout.exercises.count == 1)
        #expect(workout.exercises[0].name == "Back Squat")
        #expect(workout.exercises[0].sets == 4)
        #expect(workout.exercises[0].reps == "5")
        #expect(workout.exercises[0].weightKg == 80)
        #expect(workout.questionnaire.timeMinutes == 45)
        #expect(workout.questionnaire.focus == .fullBody)
        #expect(workout.questionnaire.energyLevel == .medium)
        #expect(workout.questionnaire.equipment == .fullGym)
    }

    @Test("Sends POST with Content-Type application/json")
    func sendsPostWithContentType() async throws {
        MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let response = HTTPURLResponse(
                url: GeminiWorkoutService.proxyURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, geminiResponse())
        }

        let service = GeminiWorkoutService(session: makeSession())
        _ = try await service.generate(from: makeContext())
    }

    @Test("Request body contains user prompt content")
    func requestBodyContainsPromptContent() async throws {
        MockURLProtocol.requestHandler = { request in
            var bodyString = ""
            if let httpBody = request.httpBody {
                bodyString = String(data: httpBody, encoding: .utf8) ?? ""
            } else if let stream = request.httpBodyStream {
                stream.open()
                let bufferSize = 4096
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { buffer.deallocate(); stream.close() }
                var data = Data()
                while stream.hasBytesAvailable {
                    let read = stream.read(buffer, maxLength: bufferSize)
                    if read > 0 { data.append(buffer, count: read) }
                }
                bodyString = String(data: data, encoding: .utf8) ?? ""
            }
            #expect(bodyString.contains("Back Squat"))
            let response = HTTPURLResponse(
                url: GeminiWorkoutService.proxyURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, geminiResponse())
        }

        let service = GeminiWorkoutService(session: makeSession())
        _ = try await service.generate(from: makeContext())
    }

    @Test("Throws httpError on HTTP 500")
    func throwsOnHTTP500() async throws {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: GeminiWorkoutService.proxyURL,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let service = GeminiWorkoutService(session: makeSession())
        await #expect(throws: GeminiServiceError.httpError(statusCode: 500)) {
            try await service.generate(from: makeContext())
        }
    }

    @Test("Throws httpError on HTTP 429")
    func throwsOnHTTP429() async throws {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: GeminiWorkoutService.proxyURL,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let service = GeminiWorkoutService(session: makeSession())
        await #expect(throws: GeminiServiceError.httpError(statusCode: 429)) {
            try await service.generate(from: makeContext())
        }
    }

    @Test("Throws on malformed response body")
    func throwsOnMalformedResponse() async throws {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: GeminiWorkoutService.proxyURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("not json".utf8))
        }

        let service = GeminiWorkoutService(session: makeSession())
        await #expect(throws: (any Error).self) {
            try await service.generate(from: makeContext())
        }
    }

    @Test("proxyURL contains generate-workout")
    func proxyURLContainsPath() {
        #expect(GeminiWorkoutService.proxyURL.absoluteString.contains("generate-workout"))
    }
}
