# Gemini-Powered AI Workout Generation — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace `OfflineWorkoutGenerator` as the primary workout engine with Gemini Flash Lite via a Cloudflare Worker proxy, falling back to offline generation on failure.

**Architecture:** A new `GeminiWorkoutService` builds a prompt from `WorkoutGenerationContext`, POSTs it to a Cloudflare Worker proxy (which injects the Gemini API key), parses the structured JSON response into `GeneratedWorkout`, and falls back to `OfflineWorkoutGenerator` on any error. The proxy lives in a separate repo.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, URLSession, Cloudflare Workers (JavaScript), Gemini API (`gemini-flash-lite-latest`)

**Design doc:** `docs/plans/2026-03-06-gemini-workout-generation-design.md`

---

### Task 1: Create feature branch

**Step 1: Create and switch to feature branch**

Run: `git checkout -b feature/gemini-workout-generation`

**Step 2: Verify clean branch**

Run: `git status`

---

### Task 2: Create `GeminiPromptBuilder` (pure domain, no dependencies)

**Files:**
- Create: `SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift`
- Create: `SundeeFundeTests/GeminiPromptBuilderTests.swift`

**Step 1: Write failing tests**

Create `SundeeFundeTests/GeminiPromptBuilderTests.swift`:

```swift
import Testing
import Foundation
@testable import SundeeFundee

@Suite("GeminiPromptBuilder")
struct GeminiPromptBuilderTests {

    private func makeContext(
        timeMinutes: Int = 45,
        focus: WorkoutFocus = .fullBody,
        energyLevel: EnergyLevel = .medium,
        equipment: EquipmentAccess = .fullGym,
        maxes: [ExerciseMax] = [],
        cyclePhase: String? = nil,
        readinessTier: String? = nil,
        injuries: [InjurySummary] = []
    ) -> WorkoutGenerationContext {
        WorkoutGenerationContext(
            userID: "user-1",
            timeMinutes: timeMinutes,
            focus: focus,
            energyLevel: energyLevel,
            equipment: equipment,
            maxes: maxes,
            recentWorkouts: [],
            cyclePhase: cyclePhase,
            readinessTier: readinessTier,
            activeInjuries: injuries,
            experienceLevel: "intermediate",
            primaryGoal: "strength",
            gender: "female",
            weightUnit: "kg"
        )
    }

    @Test func systemPromptIsNotEmpty() {
        let prompt = GeminiPromptBuilder.systemPrompt
        #expect(!prompt.isEmpty)
        #expect(prompt.contains("strength"))
    }

    @Test func userPromptContainsBasicFields() {
        let context = makeContext(timeMinutes: 60, focus: .upperBody, energyLevel: .high, equipment: .homeDumbbells)
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("60"))
        #expect(prompt.contains("upper_body") || prompt.contains("Upper Body"))
        #expect(prompt.contains("high"))
        #expect(prompt.contains("home"))
    }

    @Test func userPromptIncludesMaxes() {
        let context = makeContext(maxes: [ExerciseMax(name: "Back Squat", weightKg: 100)])
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("Back Squat"))
        #expect(prompt.contains("100"))
    }

    @Test func userPromptIncludesInjuries() {
        let context = makeContext(injuries: [InjurySummary(location: "knee", phase: "rehab", restrictions: ["squat"])])
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("knee"))
        #expect(prompt.contains("rehab"))
    }

    @Test func userPromptIncludesCyclePhase() {
        let context = makeContext(cyclePhase: "ovulation", readinessTier: "high")
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(prompt.contains("ovulation"))
        #expect(prompt.contains("high"))
    }

    @Test func userPromptOmitsCyclePhaseWhenNil() {
        let context = makeContext(cyclePhase: nil)
        let prompt = GeminiPromptBuilder.userPrompt(from: context)
        #expect(!prompt.contains("Cycle phase"))
    }

    @Test func responseSchemaIsValidJSON() throws {
        let schema = GeminiPromptBuilder.responseSchema
        #expect(schema["type"] as? String == "object")
        let properties = schema["properties"] as? [String: Any]
        #expect(properties?["coachingSummary"] != nil)
        #expect(properties?["exercises"] != nil)
    }
}
```

**Step 2: Run tests to verify they fail**

Run:
```bash
xcodegen generate && xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/GeminiPromptBuilderTests \
  2>&1 | tail -20
```

Expected: Compile error — `GeminiPromptBuilder` doesn't exist.

**Step 3: Implement `GeminiPromptBuilder`**

Create `SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift`:

```swift
import Foundation

enum GeminiPromptBuilder {

    static let systemPrompt: String = """
        You are an experienced strength and conditioning coach. Design a workout that:
        - Prioritizes compound movements appropriate for the athlete's experience level
        - Respects all injury restrictions — never program contraindicated movements
        - Accounts for menstrual cycle phase when provided (adjust intensity/volume)
        - Applies energy level to load selection
        - Avoids repeating exercises from recent workouts when possible
        - Uses the athlete's known maxes to calculate working weights (prescribe specific kg values)
        - Provides brief reasoning for each exercise choice
        - Includes a coaching summary explaining the overall session design
        """

    static func userPrompt(from context: WorkoutGenerationContext) -> String {
        var lines: [String] = []

        lines.append("Design a \(context.focus.displayName) workout.")
        lines.append("Duration: \(context.timeMinutes) minutes.")
        lines.append("Energy level: \(context.energyLevel.rawValue).")
        lines.append("Equipment: \(context.equipment.displayName).")
        lines.append("Experience: \(context.experienceLevel).")
        lines.append("Goal: \(context.primaryGoal).")
        lines.append("Weight unit preference: \(context.weightUnit).")

        if !context.maxes.isEmpty {
            lines.append("")
            lines.append("Known one-rep maxes (use these to calculate working weights):")
            for max in context.maxes {
                lines.append("- \(max.name): \(max.weightKg) kg")
            }
            lines.append("Prefer programming exercises the athlete has maxes for.")
        }

        if let phase = context.cyclePhase {
            lines.append("")
            lines.append("Cycle phase: \(phase).")
            if let readiness = context.readinessTier {
                lines.append("Readiness: \(readiness).")
            }
        }

        if !context.activeInjuries.isEmpty {
            lines.append("")
            lines.append("Active injuries (DO NOT program contraindicated movements):")
            for injury in context.activeInjuries {
                lines.append("- \(injury.location) (\(injury.phase)): avoid \(injury.restrictions.joined(separator: ", "))")
            }
        }

        if !context.recentWorkouts.isEmpty {
            lines.append("")
            lines.append("Recent workouts (avoid repeating these exercises):")
            for recent in context.recentWorkouts.prefix(5) {
                lines.append("- \(recent.focus): \(recent.exercises.joined(separator: ", "))")
            }
        }

        return lines.joined(separator: "\n")
    }

    static let responseSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "coachingSummary": ["type": "string"],
            "exercises": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "sets": ["type": "integer"],
                        "reps": ["type": "string"],
                        "weightKg": ["type": "number"],
                        "restMinutes": ["type": "number"],
                        "notes": ["type": "string"],
                        "reasoning": ["type": "string"],
                        "bodyweightOnly": ["type": "boolean"],
                    ],
                    "required": ["name", "sets", "reps", "bodyweightOnly"],
                ] as [String: Any],
            ] as [String: Any],
        ] as [String: Any],
        "required": ["coachingSummary", "exercises"],
    ]
}
```

**Step 4: Run tests to verify they pass**

Run:
```bash
xcodegen generate && xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/GeminiPromptBuilderTests \
  2>&1 | xcpretty
```

Expected: All pass.

**Step 5: Commit**

```bash
git add SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift SundeeFundeTests/GeminiPromptBuilderTests.swift
git commit -m "feat: add GeminiPromptBuilder for LLM workout generation prompts"
```

---

### Task 3: Create `GeminiResponseParser` (pure domain, no dependencies)

**Files:**
- Create: `SundeeFundee/Repositories/Gemini/GeminiResponseParser.swift`
- Create: `SundeeFundeTests/GeminiResponseParserTests.swift`

**Step 1: Write failing tests**

Create `SundeeFundeTests/GeminiResponseParserTests.swift`:

```swift
import Testing
import Foundation
@testable import SundeeFundee

@Suite("GeminiResponseParser")
struct GeminiResponseParserTests {

    private let questionnaire = QuestionnaireAnswers(
        timeMinutes: 45, focus: .fullBody, energyLevel: .medium, equipment: .fullGym
    )

    @Test func parsesValidGeminiResponse() throws {
        let json = """
        {
          "candidates": [{
            "content": {
              "parts": [{
                "text": "{\\"coachingSummary\\":\\"Great session\\",\\"exercises\\":[{\\"name\\":\\"Back Squat\\",\\"sets\\":4,\\"reps\\":\\"5\\",\\"weightKg\\":80,\\"restMinutes\\":3.0,\\"reasoning\\":\\"Compound quad builder\\",\\"bodyweightOnly\\":false}]}"
              }]
            }
          }]
        }
        """
        let data = Data(json.utf8)
        let workout = try GeminiResponseParser.parse(data: data, questionnaire: questionnaire)
        #expect(workout.coachingSummary == "Great session")
        #expect(workout.exercises.count == 1)
        #expect(workout.exercises[0].name == "Back Squat")
        #expect(workout.exercises[0].sets == 4)
        #expect(workout.exercises[0].weightKg == 80)
        #expect(workout.exercises[0].bodyweightOnly == false)
    }

    @Test func parsesBodyweightExercise() throws {
        let json = """
        {
          "candidates": [{
            "content": {
              "parts": [{
                "text": "{\\"coachingSummary\\":\\"Core work\\",\\"exercises\\":[{\\"name\\":\\"Plank Hold\\",\\"sets\\":3,\\"reps\\":\\"45s\\",\\"bodyweightOnly\\":true}]}"
              }]
            }
          }]
        }
        """
        let data = Data(json.utf8)
        let workout = try GeminiResponseParser.parse(data: data, questionnaire: questionnaire)
        #expect(workout.exercises[0].bodyweightOnly == true)
        #expect(workout.exercises[0].weightKg == nil)
    }

    @Test func throwsOnEmptyCandidates() {
        let json = """
        { "candidates": [] }
        """
        let data = Data(json.utf8)
        #expect(throws: GeminiParseError.self) {
            try GeminiResponseParser.parse(data: data, questionnaire: questionnaire)
        }
    }

    @Test func throwsOnMalformedJSON() {
        let data = Data("not json".utf8)
        #expect(throws: (any Error).self) {
            try GeminiResponseParser.parse(data: data, questionnaire: questionnaire)
        }
    }

    @Test func throwsOnMissingTextContent() {
        let json = """
        {
          "candidates": [{
            "content": {
              "parts": [{ "text": "not valid workout json" }]
            }
          }]
        }
        """
        let data = Data(json.utf8)
        #expect(throws: (any Error).self) {
            try GeminiResponseParser.parse(data: data, questionnaire: questionnaire)
        }
    }

    @Test func assignsUniqueIDsToExercises() throws {
        let json = """
        {
          "candidates": [{
            "content": {
              "parts": [{
                "text": "{\\"coachingSummary\\":\\"Test\\",\\"exercises\\":[{\\"name\\":\\"Squat\\",\\"sets\\":3,\\"reps\\":\\"5\\",\\"bodyweightOnly\\":false},{\\"name\\":\\"Bench\\",\\"sets\\":3,\\"reps\\":\\"8\\",\\"bodyweightOnly\\":false}]}"
              }]
            }
          }]
        }
        """
        let data = Data(json.utf8)
        let workout = try GeminiResponseParser.parse(data: data, questionnaire: questionnaire)
        #expect(workout.exercises[0].id != workout.exercises[1].id)
        #expect(!workout.exercises[0].id.isEmpty)
    }

    @Test func workoutHasGeneratedMetadata() throws {
        let json = """
        {
          "candidates": [{
            "content": {
              "parts": [{
                "text": "{\\"coachingSummary\\":\\"Test\\",\\"exercises\\":[{\\"name\\":\\"Squat\\",\\"sets\\":3,\\"reps\\":\\"5\\",\\"bodyweightOnly\\":false}]}"
              }]
            }
          }]
        }
        """
        let data = Data(json.utf8)
        let workout = try GeminiResponseParser.parse(data: data, questionnaire: questionnaire)
        #expect(!workout.id.isEmpty)
        #expect(workout.isFavorite == false)
        #expect(workout.questionnaire == questionnaire)
    }
}
```

**Step 2: Run tests to verify they fail**

Run:
```bash
xcodegen generate && xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/GeminiResponseParserTests \
  2>&1 | tail -20
```

Expected: Compile error — `GeminiResponseParser` doesn't exist.

**Step 3: Implement `GeminiResponseParser`**

Create `SundeeFundee/Repositories/Gemini/GeminiResponseParser.swift`:

```swift
import Foundation

enum GeminiParseError: Error {
    case emptyCandidates
    case missingContent
    case invalidWorkoutJSON
}

enum GeminiResponseParser {

    /// Parses a Gemini API response into a `GeneratedWorkout`.
    ///
    /// Expected response shape:
    /// ```
    /// { "candidates": [{ "content": { "parts": [{ "text": "<JSON string>" }] } }] }
    /// ```
    static func parse(data: Data, questionnaire: QuestionnaireAnswers) throws -> GeneratedWorkout {
        let envelope = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let candidates = envelope["candidates"] as? [[String: Any]] ?? []

        guard let first = candidates.first else {
            throw GeminiParseError.emptyCandidates
        }

        let content = first["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        guard let text = parts?.first?["text"] as? String else {
            throw GeminiParseError.missingContent
        }

        let workoutData = Data(text.utf8)
        let raw = try JSONDecoder().decode(RawGeminiWorkout.self, from: workoutData)

        let exercises = raw.exercises.map { ex in
            GeneratedExercise(
                id: UUID().uuidString,
                name: ex.name,
                sets: ex.sets,
                reps: ex.reps,
                weightKg: ex.weightKg,
                restMinutes: ex.restMinutes,
                notes: ex.notes,
                reasoning: ex.reasoning,
                bodyweightOnly: ex.bodyweightOnly
            )
        }

        return GeneratedWorkout(
            coachingSummary: raw.coachingSummary,
            exercises: exercises,
            questionnaire: questionnaire
        )
    }
}

// MARK: - Raw Decodable (matches Gemini responseSchema output)

private struct RawGeminiWorkout: Decodable {
    let coachingSummary: String
    let exercises: [RawGeminiExercise]
}

private struct RawGeminiExercise: Decodable {
    let name: String
    let sets: Int
    let reps: String
    let weightKg: Double?
    let restMinutes: Double?
    let notes: String?
    let reasoning: String?
    let bodyweightOnly: Bool
}
```

**Step 4: Run tests to verify they pass**

Run:
```bash
xcodegen generate && xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/GeminiResponseParserTests \
  2>&1 | xcpretty
```

Expected: All pass.

**Step 5: Commit**

```bash
git add SundeeFundee/Repositories/Gemini/GeminiResponseParser.swift SundeeFundeTests/GeminiResponseParserTests.swift
git commit -m "feat: add GeminiResponseParser for structured Gemini API responses"
```

---

### Task 4: Create `GeminiWorkoutService` (network client with fallback)

**Files:**
- Create: `SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift`
- Create: `SundeeFundeTests/GeminiWorkoutServiceTests.swift`

**Step 1: Write failing tests**

Create `SundeeFundeTests/GeminiWorkoutServiceTests.swift`:

```swift
import Testing
import Foundation
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

// MARK: - GeminiWorkoutService Tests

@Suite("GeminiWorkoutService")
struct GeminiWorkoutServiceTests {

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
        {
          "candidates": [{
            "content": {
              "parts": [{
                "text": "{\\"coachingSummary\\":\\"\(summary)\\",\\"exercises\\":[{\\"name\\":\\"\(exerciseName)\\",\\"sets\\":4,\\"reps\\":\\"5\\",\\"weightKg\\":80,\\"restMinutes\\":3.0,\\"bodyweightOnly\\":false}]}"
              }]
            }
          }]
        }
        """
        return Data(json.utf8)
    }

    @Test func successfulGenerationReturnsGeminiWorkout() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, geminiResponse())
        }

        let service = GeminiWorkoutService(session: makeSession())
        let workout = try await service.generate(from: makeContext())
        #expect(workout.coachingSummary == "AI session")
        #expect(workout.exercises.count == 1)
        #expect(workout.exercises[0].name == "Back Squat")
    }

    @Test func sendsCorrectHTTPMethod() async throws {
        MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, geminiResponse())
        }

        let service = GeminiWorkoutService(session: makeSession())
        _ = try await service.generate(from: makeContext())
    }

    @Test func requestBodyContainsPrompt() async throws {
        MockURLProtocol.requestHandler = { request in
            let body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            #expect(body.contains("Back Squat"))
            #expect(body.contains("strength"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, geminiResponse())
        }

        let service = GeminiWorkoutService(session: makeSession())
        _ = try await service.generate(from: makeContext())
    }

    @Test func throwsOnHTTP500() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let service = GeminiWorkoutService(session: makeSession())
        do {
            _ = try await service.generate(from: makeContext())
            Issue.record("Expected error")
        } catch {
            // Expected
        }
    }

    @Test func throwsOnHTTP429() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let service = GeminiWorkoutService(session: makeSession())
        do {
            _ = try await service.generate(from: makeContext())
            Issue.record("Expected error")
        } catch {
            // Expected
        }
    }

    @Test func throwsOnMalformedResponse() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("not json".utf8))
        }

        let service = GeminiWorkoutService(session: makeSession())
        do {
            _ = try await service.generate(from: makeContext())
            Issue.record("Expected error")
        } catch {
            // Expected
        }
    }

    @Test func proxyURLIsCorrect() {
        #expect(GeminiWorkoutService.proxyURL.absoluteString.contains("generate-workout"))
    }
}
```

**Step 2: Run tests to verify they fail**

Run:
```bash
xcodegen generate && xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/GeminiWorkoutServiceTests \
  2>&1 | tail -20
```

Expected: Compile error — `GeminiWorkoutService` doesn't exist.

**Step 3: Implement `GeminiWorkoutService`**

Create `SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift`:

```swift
import Foundation

enum GeminiServiceError: Error {
    case httpError(statusCode: Int)
    case invalidResponse
}

final class GeminiWorkoutService: Sendable {

    static let proxyURL = URL(string: "https://workout-proxy.sundee-fundee.workers.dev/generate-workout")!

    private let session: URLSession
    private let timeoutInterval: TimeInterval

    init(session: URLSession = .shared, timeoutInterval: TimeInterval = 15) {
        self.session = session
        self.timeoutInterval = timeoutInterval
    }

    func generate(from context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let body = buildRequestBody(from: context)
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: Self.proxyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        request.timeoutInterval = timeoutInterval

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw GeminiServiceError.httpError(statusCode: httpResponse.statusCode)
        }

        let questionnaire = QuestionnaireAnswers(
            timeMinutes: context.timeMinutes,
            focus: context.focus,
            energyLevel: context.energyLevel,
            equipment: context.equipment
        )

        return try GeminiResponseParser.parse(data: data, questionnaire: questionnaire)
    }

    private func buildRequestBody(from context: WorkoutGenerationContext) -> [String: Any] {
        [
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": GeminiPromptBuilder.userPrompt(from: context)]],
                ]
            ],
            "systemInstruction": [
                "parts": [["text": GeminiPromptBuilder.systemPrompt]]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": GeminiPromptBuilder.responseSchema,
            ],
        ]
    }
}
```

**Step 4: Run tests to verify they pass**

Run:
```bash
xcodegen generate && xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/GeminiWorkoutServiceTests \
  2>&1 | xcpretty
```

Expected: All pass.

**Step 5: Commit**

```bash
git add SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift SundeeFundeTests/GeminiWorkoutServiceTests.swift
git commit -m "feat: add GeminiWorkoutService with URLSession-based proxy client"
```

---

### Task 5: Integrate Gemini into `SwiftDataAIWorkoutService` with fallback

**Files:**
- Modify: `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift`
- Modify: `SundeeFundeTests/GeminiWorkoutServiceTests.swift` (add integration/fallback tests)

**Step 1: Write failing test for fallback behavior**

Add to `SundeeFundeTests/GeminiWorkoutServiceTests.swift`:

```swift
@Suite("SwiftDataAIWorkoutService Gemini Integration")
struct SwiftDataAIWorkoutServiceGeminiTests {

    @Test func fallsBackToOfflineOnNetworkError() async throws {
        // Configure mock to fail
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let failingSession = URLSession(configuration: config)
        let geminiService = GeminiWorkoutService(session: failingSession)

        let context = WorkoutGenerationContext(
            userID: "user-1",
            timeMinutes: 45,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .fullGym,
            maxes: [],
            recentWorkouts: [],
            cyclePhase: nil,
            readinessTier: nil,
            activeInjuries: [],
            experienceLevel: "intermediate",
            primaryGoal: "strength",
            gender: "female",
            weightUnit: "kg"
        )

        // Call the static fallback helper directly
        let workout = await SwiftDataAIWorkoutService.generateWithFallback(
            context: context,
            geminiService: geminiService
        )

        // Should get an offline-generated workout (summary starts with "Generated offline:")
        #expect(workout.coachingSummary.contains("offline"))
        #expect(!workout.exercises.isEmpty)
    }

    @Test func usesGeminiWhenAvailable() async throws {
        let json = """
        {
          "candidates": [{
            "content": {
              "parts": [{
                "text": "{\\"coachingSummary\\":\\"AI-powered session\\",\\"exercises\\":[{\\"name\\":\\"Goblet Squat\\",\\"sets\\":3,\\"reps\\":\\"10\\",\\"bodyweightOnly\\":false}]}"
              }]
            }
          }]
        }
        """
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let geminiService = GeminiWorkoutService(session: session)

        let context = WorkoutGenerationContext(
            userID: "user-1",
            timeMinutes: 45,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .fullGym,
            maxes: [],
            recentWorkouts: [],
            cyclePhase: nil,
            readinessTier: nil,
            activeInjuries: [],
            experienceLevel: "intermediate",
            primaryGoal: "strength",
            gender: "female",
            weightUnit: "kg"
        )

        let workout = await SwiftDataAIWorkoutService.generateWithFallback(
            context: context,
            geminiService: geminiService
        )

        #expect(workout.coachingSummary == "AI-powered session")
    }
}
```

**Step 2: Run tests to verify they fail**

Run:
```bash
xcodegen generate && xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/SwiftDataAIWorkoutServiceGeminiTests \
  2>&1 | tail -20
```

Expected: Compile error — `generateWithFallback` doesn't exist.

**Step 3: Modify `SwiftDataAIWorkoutService`**

Edit `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift`:

```swift
import Foundation
import SwiftData

// MARK: - AIWorkoutServiceError

enum AIWorkoutServiceError: Error {
    case notAuthenticated
    case encodingFailed
    case decodingFailed
}

// MARK: - SwiftDataAIWorkoutService

/// AI workout service backed by SwiftData + CloudKit.
///
/// Generates workouts via Gemini API (through proxy), falling back to
/// `OfflineWorkoutGenerator` on any error. Persists results to CloudKit
/// private database via SwiftData.
final class SwiftDataAIWorkoutService: AIWorkoutServiceProtocol, @unchecked Sendable {

    private let modelContext: ModelContext
    private let geminiService: GeminiWorkoutService

    init(modelContext: ModelContext, geminiService: GeminiWorkoutService = GeminiWorkoutService()) {
        self.modelContext = modelContext
        self.geminiService = geminiService
    }

    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let workout = await Self.generateWithFallback(context: context, geminiService: geminiService)
        guard let record = GeneratedWorkoutRecord.from(workout, userID: context.userID) else {
            throw AIWorkoutServiceError.encodingFailed
        }
        modelContext.insert(record)
        try? modelContext.save()
        return workout
    }

    /// Try Gemini, fall back to offline generator on any failure.
    static func generateWithFallback(
        context: WorkoutGenerationContext,
        geminiService: GeminiWorkoutService
    ) async -> GeneratedWorkout {
        do {
            return try await geminiService.generate(from: context)
        } catch {
            return OfflineWorkoutGenerator.generate(from: context)
        }
    }

    func fetchHistory(userID: String) async throws -> [GeneratedWorkout] {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        return records.compactMap { $0.toGeneratedWorkout() }
    }

    func toggleFavorite(workoutID: String, isFavorite: Bool) async throws {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.id == workoutID }
        )
        guard let record = try? modelContext.fetch(descriptor).first else { return }
        record.isFavorite = isFavorite
        try? modelContext.save()
    }

    func fetchFavorites(userID: String) async throws -> [GeneratedWorkout] {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.userID == userID && $0.isFavorite == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        return records.compactMap { $0.toGeneratedWorkout() }
    }
}
```

**Step 4: Run tests to verify they pass**

Run:
```bash
xcodegen generate && xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/SwiftDataAIWorkoutServiceGeminiTests \
  2>&1 | xcpretty
```

Expected: All pass.

**Step 5: Commit**

```bash
git add SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift SundeeFundeTests/GeminiWorkoutServiceTests.swift
git commit -m "feat: integrate Gemini into SwiftDataAIWorkoutService with offline fallback"
```

---

### Task 6: Fix any compilation or test breakage from init signature change

The `SwiftDataAIWorkoutService` init now takes an optional `geminiService` parameter. Existing call sites pass only `modelContext:`, so the default parameter handles this. But we must verify.

**Step 1: Run full test suite**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests \
  2>&1 | xcpretty
```

**Step 2: Fix any failures**

Check `MainTabView.swift:114` where `SwiftDataAIWorkoutService(modelContext: modelContext)` is called — the new default parameter means this still compiles. If any test or call site breaks, fix it.

Likely places to check:
- `SundeeFundee/Features/Shell/MainTabView.swift:114`
- `SundeeFundee/Features/AIWorkout/AIWorkoutFlowView.swift`
- `SundeeFundeTests/AIWorkoutViewModelTests.swift` (uses `MockAIWorkoutService`, unaffected)

**Step 3: Commit if fixes were needed**

```bash
git add -A
git commit -m "fix: resolve compilation issues from GeminiWorkoutService integration"
```

---

### Task 7: Create Cloudflare Worker proxy (separate repo)

**Files:**
- Create (in new repo): `sundee-fundee-proxy/wrangler.toml`
- Create (in new repo): `sundee-fundee-proxy/src/index.js`
- Create (in new repo): `sundee-fundee-proxy/package.json`

**Step 1: Create the proxy repo directory**

Run:
```bash
mkdir -p ~/Projects/sundee-fundee-proxy/src
cd ~/Projects/sundee-fundee-proxy
git init
```

**Step 2: Create `package.json`**

```json
{
  "name": "sundee-fundee-proxy",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy"
  },
  "devDependencies": {
    "wrangler": "^3.0.0"
  }
}
```

**Step 3: Create `wrangler.toml`**

```toml
name = "workout-proxy"
main = "src/index.js"
compatibility_date = "2024-01-01"

[vars]
GEMINI_MODEL = "gemini-flash-lite-latest"
RATE_LIMIT_MAX = 20

# Secret: GEMINI_API_KEY (set via `wrangler secret put GEMINI_API_KEY`)
```

**Step 4: Create `src/index.js`**

```javascript
const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta/models";

// Simple in-memory rate limiter (resets on worker restart)
const rateLimits = new Map();

function checkRateLimit(userID, maxRequests) {
  const now = Date.now();
  const windowMs = 60 * 60 * 1000; // 1 hour
  const key = userID || "anonymous";

  let entry = rateLimits.get(key);
  if (!entry || now - entry.windowStart > windowMs) {
    entry = { windowStart: now, count: 0 };
  }

  entry.count++;
  rateLimits.set(key, entry);

  return entry.count <= maxRequests;
}

export default {
  async fetch(request, env) {
    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
        },
      });
    }

    if (request.method !== "POST") {
      return Response.json({ error: "Method not allowed" }, { status: 405 });
    }

    const url = new URL(request.url);
    if (url.pathname !== "/generate-workout") {
      return Response.json({ error: "Not found" }, { status: 404 });
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return Response.json({ error: "Invalid JSON body" }, { status: 400 });
    }

    // Extract userID from the prompt for rate limiting
    const userID = body._userID || "anonymous";
    delete body._userID;

    const maxRequests = parseInt(env.RATE_LIMIT_MAX) || 20;
    if (!checkRateLimit(userID, maxRequests)) {
      return Response.json({ error: "Rate limit exceeded" }, { status: 429 });
    }

    // Forward to Gemini
    const model = env.GEMINI_MODEL || "gemini-flash-lite-latest";
    const geminiURL = `${GEMINI_BASE}/${model}:generateContent?key=${env.GEMINI_API_KEY}`;

    try {
      const geminiResponse = await fetch(geminiURL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      const responseData = await geminiResponse.text();

      return new Response(responseData, {
        status: geminiResponse.status,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    } catch (err) {
      return Response.json(
        { error: "Upstream error", detail: err.message },
        { status: 502 }
      );
    }
  },
};
```

**Step 5: Install dependencies and test locally**

Run:
```bash
cd ~/Projects/sundee-fundee-proxy
npm install
```

**Step 6: Commit**

Run:
```bash
cd ~/Projects/sundee-fundee-proxy
git add -A
git commit -m "feat: initial Cloudflare Worker proxy for Gemini API"
```

**Step 7: Set the API key secret (manual step)**

Run when ready to deploy:
```bash
cd ~/Projects/sundee-fundee-proxy
npx wrangler secret put GEMINI_API_KEY
# Paste your Gemini API key when prompted
npx wrangler deploy
```

---

### Task 8: Update proxy URL to match deployed worker

After deploying the Cloudflare Worker, update the URL in the iOS app if it differs from the placeholder.

**Files:**
- Modify: `SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift:5`

**Step 1: Update URL if needed**

If the deployed worker URL differs from `https://workout-proxy.sundee-fundee.workers.dev/generate-workout`, update the `proxyURL` constant in `GeminiWorkoutService.swift`.

**Step 2: Commit if changed**

```bash
git add SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift
git commit -m "chore: update proxy URL to deployed Cloudflare Worker endpoint"
```

---

### Task 9: Run full test suite and verify coverage

**Step 1: Run full test suite**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult \
  2>&1 | xcpretty
```

Expected: All tests pass.

**Step 2: Check coverage**

Run:
```bash
xcrun xccov view --report --json TestResults.xcresult | python3 -c "
import json, sys
report = json.load(sys.stdin)
target = next(t for t in report['targets'] if t['name'] == 'SundeeFundee.app')
for f in target.get('files', []):
    if 'Gemini' in f['name']:
        print(f'{f[\"name\"]}: {f[\"lineCoverage\"]*100:.1f}%')
print(f'Overall: {target[\"lineCoverage\"]*100:.2f}%')
"
```

**Step 3: Add missing tests if coverage gaps exist**

If any Gemini files are below 100%, add targeted tests.

**Step 4: Commit**

```bash
git add -A
git commit -m "test: ensure 100% coverage for Gemini workout generation"
```

---

### Task 10: End-to-end smoke test with deployed proxy

This is a manual verification step, not an automated test.

**Step 1: Run the app in simulator**

Run:
```bash
xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Step 2: Manual test flow**

1. Open app in simulator
2. Navigate to Dashboard -> AI Workout CTA
3. Fill questionnaire (45 min, Full Body, Medium energy, Full Gym)
4. Tap "Generate Workout"
5. Verify: workout appears with coaching summary that does NOT start with "Generated offline:"
6. Verify: exercises have reasoning text
7. Verify: exercises can be edited (weight, reps, sets)
8. Toggle airplane mode in simulator and generate again
9. Verify: offline fallback produces a workout (summary starts with "Generated offline:")

**Step 3: Final commit**

```bash
git add -A
git commit -m "chore: finalize Gemini workout generation integration"
```
