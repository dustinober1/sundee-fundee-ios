# AI Workout Remote Generation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the iOS AI workout feature to call Gemini via the existing Cloudflare Worker proxy, with offline fallback.

**Architecture:** The iOS app builds a prompt from `WorkoutGenerationContext`, POSTs it to the Cloudflare Worker in Gemini-native format, parses the JSON response into `GeneratedWorkout`, and falls back to `OfflineWorkoutGenerator` on any failure. Three new/modified files, all behind the existing `AIWorkoutServiceProtocol`.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, URLSession, Codable, existing Cloudflare Worker (Gemini proxy)

**Spec:** `docs/superpowers/specs/2026-03-24-ai-workout-remote-generation-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `SundeeFundee/Domain/AIWorkout/RemoteWorkoutResponse.swift` | Create | Codable response struct + mapping to `GeneratedWorkout` |
| `SundeeFundee/Domain/AIWorkout/GeminiWorkoutPrompt.swift` | Create | Pure function: `WorkoutGenerationContext` → prompt string |
| `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift` | Modify | Try remote generation first, fall back to offline |
| `SundeeFundeTests/RemoteWorkoutResponseTests.swift` | Create | Tests for response parsing and mapping |
| `SundeeFundeTests/GeminiWorkoutPromptTests.swift` | Create | Tests for prompt construction |
| `SundeeFundeTests/AIWorkoutServiceRemoteTests.swift` | Create | Tests for remote/fallback integration |

---

### Task 1: RemoteWorkoutResponse — Response Parsing & Mapping

**Files:**
- Create: `SundeeFundee/Domain/AIWorkout/RemoteWorkoutResponse.swift`
- Create: `SundeeFundeTests/RemoteWorkoutResponseTests.swift`

- [ ] **Step 1: Write failing tests for response decoding and mapping**

```swift
import Testing
import Foundation
@testable import SundeeFundee

@Suite("RemoteWorkoutResponse")
struct RemoteWorkoutResponseTests {

    static let sampleJSON = """
    {
      "coachingSummary": "Great session targeting posterior chain.",
      "exercises": [
        {
          "name": "Back Squat",
          "sets": 4,
          "reps": "5",
          "weightKg": 80.0,
          "restMinutes": 3.0,
          "notes": "Brace core",
          "reasoning": "Primary compound lift",
          "bodyweightOnly": false
        },
        {
          "name": "Pull-Up",
          "sets": 3,
          "reps": "AMRAP",
          "weightKg": null,
          "restMinutes": 2.0,
          "notes": null,
          "reasoning": null,
          "bodyweightOnly": true
        }
      ]
    }
    """.data(using: .utf8)!

    @Test func decodesValidJSON() throws {
        let response = try JSONDecoder().decode(RemoteWorkoutResponse.self, from: Self.sampleJSON)
        #expect(response.coachingSummary == "Great session targeting posterior chain.")
        #expect(response.exercises.count == 2)
        #expect(response.exercises[0].name == "Back Squat")
        #expect(response.exercises[0].sets == 4)
        #expect(response.exercises[0].weightKg == 80.0)
        #expect(response.exercises[1].bodyweightOnly == true)
        #expect(response.exercises[1].weightKg == nil)
    }

    @Test func mapsToGeneratedWorkout() throws {
        let response = try JSONDecoder().decode(RemoteWorkoutResponse.self, from: Self.sampleJSON)
        let questionnaire = QuestionnaireAnswers(
            timeMinutes: 45,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .fullGym
        )
        let workout = response.toGeneratedWorkout(questionnaire: questionnaire)

        #expect(!workout.id.isEmpty)
        #expect(workout.coachingSummary == "Great session targeting posterior chain.")
        #expect(workout.exercises.count == 2)
        #expect(workout.exercises[0].name == "Back Squat")
        #expect(workout.exercises[0].sets == 4)
        #expect(workout.exercises[0].reps == "5")
        #expect(workout.exercises[0].weightKg == 80.0)
        #expect(workout.exercises[0].bodyweightOnly == false)
        #expect(!workout.exercises[0].id.isEmpty)
        #expect(workout.exercises[1].name == "Pull-Up")
        #expect(workout.exercises[1].bodyweightOnly == true)
        #expect(workout.questionnaire == questionnaire)
        #expect(workout.isFavorite == false)
    }

    @Test func exerciseIDsAreUnique() throws {
        let response = try JSONDecoder().decode(RemoteWorkoutResponse.self, from: Self.sampleJSON)
        let questionnaire = QuestionnaireAnswers(timeMinutes: 30, focus: .push, energyLevel: .high, equipment: .fullGym)
        let workout = response.toGeneratedWorkout(questionnaire: questionnaire)

        let ids = workout.exercises.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func stripsMarkdownFences() throws {
        let wrapped = """
        ```json
        {"coachingSummary":"test","exercises":[]}
        ```
        """
        let cleaned = RemoteWorkoutResponse.stripMarkdownFences(wrapped)
        let response = try JSONDecoder().decode(RemoteWorkoutResponse.self, from: Data(cleaned.utf8))
        #expect(response.coachingSummary == "test")
        #expect(response.exercises.isEmpty)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/RemoteWorkoutResponseTests 2>&1 | tail -5`
Expected: Build failure — `RemoteWorkoutResponse` does not exist.

- [ ] **Step 3: Implement RemoteWorkoutResponse**

Create `SundeeFundee/Domain/AIWorkout/RemoteWorkoutResponse.swift`:

```swift
import Foundation

struct RemoteWorkoutResponse: Codable, Sendable {
    let coachingSummary: String
    let exercises: [RemoteExercise]

    func toGeneratedWorkout(questionnaire: QuestionnaireAnswers) -> GeneratedWorkout {
        GeneratedWorkout(
            coachingSummary: coachingSummary,
            exercises: exercises.map { $0.toGeneratedExercise() },
            questionnaire: questionnaire
        )
    }

    static func stripMarkdownFences(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^```(?:json)?\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*```$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct RemoteExercise: Codable, Sendable {
    let name: String
    let sets: Int
    let reps: String
    let weightKg: Double?
    let restMinutes: Double?
    let notes: String?
    let reasoning: String?
    let bodyweightOnly: Bool?

    func toGeneratedExercise() -> GeneratedExercise {
        GeneratedExercise(
            name: name,
            sets: sets,
            reps: reps,
            weightKg: weightKg,
            restMinutes: restMinutes,
            notes: notes,
            reasoning: reasoning,
            bodyweightOnly: bodyweightOnly ?? false
        )
    }
}
```

- [ ] **Step 4: Add file to project.yml and regenerate**

Add `SundeeFundee/Domain/AIWorkout/RemoteWorkoutResponse.swift` under the sources in `project.yml` if needed, then run `xcodegen generate`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/RemoteWorkoutResponseTests 2>&1 | tail -5`
Expected: All 4 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Domain/AIWorkout/RemoteWorkoutResponse.swift SundeeFundeTests/RemoteWorkoutResponseTests.swift
git commit -m "feat: add RemoteWorkoutResponse for Gemini AI workout parsing"
```

---

### Task 2: GeminiWorkoutPrompt — Prompt Construction

**Files:**
- Create: `SundeeFundee/Domain/AIWorkout/GeminiWorkoutPrompt.swift`
- Create: `SundeeFundeTests/GeminiWorkoutPromptTests.swift`

- [ ] **Step 1: Write failing tests for prompt construction**

```swift
import Testing
import Foundation
@testable import SundeeFundee

@Suite("GeminiWorkoutPrompt")
struct GeminiWorkoutPromptTests {

    private func makeContext(
        timeMinutes: Int = 45,
        focus: WorkoutFocus = .fullBody,
        energyLevel: EnergyLevel = .medium,
        equipment: EquipmentAccess = .fullGym,
        maxes: [ExerciseMax] = [],
        recentWorkouts: [RecentWorkoutSummary] = [],
        cyclePhase: String? = nil,
        activeInjuries: [InjurySummary] = [],
        experienceLevel: String = "intermediate",
        primaryGoal: String = "strength",
        gender: String = "female",
        weightUnit: String = "kg"
    ) -> WorkoutGenerationContext {
        WorkoutGenerationContext(
            userID: "test",
            timeMinutes: timeMinutes,
            focus: focus,
            energyLevel: energyLevel,
            equipment: equipment,
            maxes: maxes,
            recentWorkouts: recentWorkouts,
            cyclePhase: cyclePhase,
            readinessTier: nil,
            activeInjuries: activeInjuries,
            experienceLevel: experienceLevel,
            primaryGoal: primaryGoal,
            gender: gender,
            weightUnit: weightUnit
        )
    }

    @Test func includesBasicParameters() {
        let prompt = GeminiWorkoutPrompt.build(from: makeContext())
        #expect(prompt.contains("45 minutes"))
        #expect(prompt.contains("Full Body"))
        #expect(prompt.contains("medium"))
        #expect(prompt.contains("Full Gym"))
        #expect(prompt.contains("intermediate"))
        #expect(prompt.contains("strength"))
    }

    @Test func includesMaxesWhenPresent() {
        let ctx = makeContext(maxes: [ExerciseMax(name: "Back Squat", weightKg: 100)])
        let prompt = GeminiWorkoutPrompt.build(from: ctx)
        #expect(prompt.contains("Back Squat"))
        #expect(prompt.contains("100"))
    }

    @Test func omitsMaxesSectionWhenEmpty() {
        let prompt = GeminiWorkoutPrompt.build(from: makeContext())
        #expect(!prompt.contains("1RM Maxes"))
    }

    @Test func includesCyclePhaseWhenPresent() {
        let ctx = makeContext(cyclePhase: "luteal")
        let prompt = GeminiWorkoutPrompt.build(from: ctx)
        #expect(prompt.contains("luteal"))
    }

    @Test func includesInjuriesWhenPresent() {
        let ctx = makeContext(activeInjuries: [InjurySummary(location: "left knee", phase: "rehab", restrictions: ["squat"])])
        let prompt = GeminiWorkoutPrompt.build(from: ctx)
        #expect(prompt.contains("left knee"))
        #expect(prompt.contains("rehab"))
    }

    @Test func includesJSONSchemaInstruction() {
        let prompt = GeminiWorkoutPrompt.build(from: makeContext())
        #expect(prompt.contains("coachingSummary"))
        #expect(prompt.contains("exercises"))
        #expect(prompt.contains("JSON"))
    }

    @Test func systemInstructionIsStatic() {
        let system = GeminiWorkoutPrompt.systemInstruction
        #expect(system.contains("strength and conditioning"))
        #expect(system.contains("JSON"))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Build failure — `GeminiWorkoutPrompt` does not exist.

- [ ] **Step 3: Implement GeminiWorkoutPrompt**

Create `SundeeFundee/Domain/AIWorkout/GeminiWorkoutPrompt.swift`:

```swift
import Foundation

enum GeminiWorkoutPrompt {

    static let systemInstruction = "You are a certified strength and conditioning coach designing personalized workouts. Return valid JSON only. No markdown fences, no explanation outside the JSON."

    static func build(from context: WorkoutGenerationContext) -> String {
        var sections: [String] = []

        sections.append("""
        Design a personalized workout with these parameters:
        - Duration: \(context.timeMinutes) minutes
        - Focus: \(context.focus.displayName)
        - Energy level: \(context.energyLevel.rawValue)
        - Equipment: \(context.equipment.displayName)
        - Experience: \(context.experienceLevel)
        - Goal: \(context.primaryGoal)
        - Gender: \(context.gender)
        - Weight unit preference: \(context.weightUnit)
        """)

        if !context.maxes.isEmpty {
            let maxLines = context.maxes.map { "  - \($0.name): \($0.weightKg)kg" }.joined(separator: "\n")
            sections.append("1RM Maxes (use these to calculate working weights):\n\(maxLines)")
        }

        if !context.recentWorkouts.isEmpty {
            let recentLines = context.recentWorkouts.prefix(5).map { "  - \($0.focus) (\($0.durationMinutes)min)" }.joined(separator: "\n")
            sections.append("Recent workouts (avoid repeating these):\n\(recentLines)")
        }

        if let phase = context.cyclePhase {
            sections.append("Menstrual cycle phase: \(phase). Adjust intensity and exercise selection appropriately for this phase.")
        }

        if !context.activeInjuries.isEmpty {
            let injuryLines = context.activeInjuries.map { "  - \($0.location) (\($0.phase)): avoid \($0.restrictions.joined(separator: ", "))" }.joined(separator: "\n")
            sections.append("Active injuries — substitute or remove contraindicated exercises:\n\(injuryLines)")
        }

        sections.append("""
        Return a JSON object with this exact structure:
        {
          "coachingSummary": "2-3 sentences explaining the workout design choices",
          "exercises": [
            {
              "name": "Exercise Name",
              "sets": 4,
              "reps": "8-10",
              "weightKg": 60.0,
              "restMinutes": 2.0,
              "notes": "coaching cues",
              "reasoning": "why this exercise was chosen",
              "bodyweightOnly": false
            }
          ]
        }

        weightKg should be null for bodyweight exercises. Use the 1RM data to calculate appropriate working weights (typically 65-85% of 1RM depending on rep range). Return only valid JSON.
        """)

        return sections.joined(separator: "\n\n")
    }
}
```

- [ ] **Step 4: Add file to project.yml if needed and regenerate**

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/GeminiWorkoutPromptTests 2>&1 | tail -5`
Expected: All 7 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Domain/AIWorkout/GeminiWorkoutPrompt.swift SundeeFundeTests/GeminiWorkoutPromptTests.swift
git commit -m "feat: add GeminiWorkoutPrompt for AI workout prompt construction"
```

---

### Task 3: Wire Remote Generation into SwiftDataAIWorkoutService

**Files:**
- Modify: `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift`
- Create: `SundeeFundeTests/AIWorkoutServiceRemoteTests.swift`

- [ ] **Step 1: Write failing tests for remote generation and fallback**

```swift
import Testing
import Foundation
@testable import SundeeFundee

@Suite("AIWorkoutServiceRemote")
struct AIWorkoutServiceRemoteTests {

    // MARK: - Gemini Response Parsing

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
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Build failure — `GeminiResponseParser` does not exist.

- [ ] **Step 3: Rewrite FirebaseAIWorkoutService.swift with remote generation**

Replace the contents of `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift` with:

```swift
import Foundation
import SwiftData

// MARK: - AIWorkoutServiceError

enum AIWorkoutServiceError: Error {
    case notAuthenticated
    case encodingFailed
    case decodingFailed
    case networkError(Int)
    case noContent
}

// MARK: - GeminiResponseParser

enum GeminiResponseParser {
    struct GeminiResponse: Codable {
        struct Candidate: Codable {
            struct Content: Codable {
                struct Part: Codable {
                    let text: String
                }
                let parts: [Part]
            }
            let content: Content
        }
        let candidates: [Candidate]
    }

    static func extractText(from data: Data) throws -> String {
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = response.candidates.first?.content.parts.first?.text else {
            throw AIWorkoutServiceError.noContent
        }
        return text
    }
}

// MARK: - SwiftDataAIWorkoutService

final class SwiftDataAIWorkoutService: AIWorkoutServiceProtocol, @unchecked Sendable {

    private let modelContext: ModelContext
    private let workerURL: URL
    private let session: URLSession

    static let defaultWorkerURL = URL(string: "https://workout-proxy.sundeefundee.workers.dev/generate-workout")!

    init(
        modelContext: ModelContext,
        workerURL: URL = SwiftDataAIWorkoutService.defaultWorkerURL,
        session: URLSession = .shared
    ) {
        self.modelContext = modelContext
        self.workerURL = workerURL
        self.session = session
    }

    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let workout: GeneratedWorkout
        do {
            workout = try await generateRemotely(context: context)
        } catch {
            print("AI workout remote generation failed: \(error). Using offline generator.")
            workout = OfflineWorkoutGenerator.generate(from: context)
        }

        guard let record = GeneratedWorkoutRecord.from(workout, userID: context.userID) else {
            throw AIWorkoutServiceError.encodingFailed
        }
        modelContext.insert(record)
        try? modelContext.save()
        return workout
    }

    // MARK: - Remote Generation

    private func generateRemotely(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        var request = URLRequest(url: workerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let prompt = GeminiWorkoutPrompt.build(from: context)
        let body: [String: Any] = [
            "contents": [["role": "user", "parts": [["text": prompt]]]],
            "systemInstruction": ["parts": [["text": GeminiWorkoutPrompt.systemInstruction]]],
            "generationConfig": ["temperature": 0.7, "maxOutputTokens": 4096]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIWorkoutServiceError.networkError(
                (response as? HTTPURLResponse)?.statusCode ?? -1
            )
        }

        let rawText = try GeminiResponseParser.extractText(from: data)
        let cleaned = RemoteWorkoutResponse.stripMarkdownFences(rawText)
        let remoteResponse = try JSONDecoder().decode(RemoteWorkoutResponse.self, from: Data(cleaned.utf8))

        let questionnaire = QuestionnaireAnswers(
            timeMinutes: context.timeMinutes,
            focus: context.focus,
            energyLevel: context.energyLevel,
            equipment: context.equipment
        )
        return remoteResponse.toGeneratedWorkout(questionnaire: questionnaire)
    }

    // MARK: - History & Favorites (unchanged)

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

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/AIWorkoutServiceRemoteTests 2>&1 | tail -5`
Expected: All 3 tests PASS.

- [ ] **Step 5: Run full test suite to verify no regressions**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests 2>&1 | grep -E "(Test Suite|Executed|FAIL)" | tail -10`
Expected: All tests pass, no regressions.

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift SundeeFundeTests/AIWorkoutServiceRemoteTests.swift
git commit -m "feat: wire AI workout generation to Gemini via Cloudflare Worker proxy"
```

---

### Task 4: Build, Install, and Smoke Test on Simulator

**Files:** None (manual verification)

- [ ] **Step 1: Build the app**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "(error:|BUILD)" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Install and launch on simulator**

```bash
xcrun simctl terminate 391F0C0D-8431-42BA-93BF-F6BA4D484E94 com.sundeefundee.app 2>/dev/null
xcrun simctl install 391F0C0D-8431-42BA-93BF-F6BA4D484E94 /Users/dustinober/Library/Developer/Xcode/DerivedData/SundeeFundee-ghrbbkoxxhcnzlddvmgaenvjculu/Build/Products/Debug-iphonesimulator/SundeeFundee.app
xcrun simctl launch 391F0C0D-8431-42BA-93BF-F6BA4D484E94 com.sundeefundee.app
```

- [ ] **Step 3: Smoke test — generate an AI workout**

1. Tap "Continue without signing in"
2. Tap "New AI Workout" on the Dashboard
3. Fill out questionnaire (any values)
4. Tap "Generate"
5. Verify a workout is generated (check coaching summary — if it says "Generated offline:" the remote call failed and fell back; otherwise Gemini is working)

- [ ] **Step 4: Commit all remaining changes**

```bash
git add -A
git commit -m "chore: finalize AI workout remote generation"
```
