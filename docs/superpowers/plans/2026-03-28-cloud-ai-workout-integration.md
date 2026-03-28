# Cloud AI Workout Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the iOS app to call the `ai-coach` Cloudflare Worker for Plus/Premium users with a user-controlled toggle, JWT auth, and graceful fallback to on-device generation.

**Architecture:** Three new Domain/Repository files (CloudAIConfig for JWT creation, CloudAIUsageTracker for local daily limits, CloudAIWorkoutService for the network call), plus modifications to QuestionnaireView/ViewModel to add the cloud AI toggle and route to the correct service. All new code is tested via static helpers and protocol mocking.

**Tech Stack:** Swift 6, SwiftUI, CryptoKit (HMAC-SHA256), URLSession, UserDefaults

---

## File Structure

```
New files:
  SundeeFundee/Domain/AIWorkout/CloudAIConfig.swift       — JWT creation, worker URL, shared secret
  SundeeFundee/Domain/AIWorkout/CloudAIUsageTracker.swift  — Local daily cloud usage tracking
  SundeeFundee/Repositories/AIWorkout/CloudAIWorkoutService.swift — Network service conforming to AIWorkoutServiceProtocol

Modified files:
  SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift — Add cloud toggle state + routing
  SundeeFundee/Features/AIWorkout/QuestionnaireView.swift      — Add cloud AI toggle UI section
  SundeeFundee/Features/AIWorkout/AIWorkoutFlowView.swift      — Pass subscriptionTier, inject cloud service
  SundeeFundeTests/SubscriptionTests.swift                     — CloudAIConfig + CloudAIUsageTracker tests
  SundeeFundeTests/AIWorkoutViewModelTests.swift               — QuestionnaireViewModel cloud routing tests
```

---

### Task 1: CloudAIConfig — JWT Creation

**Files:**
- Create: `SundeeFundee/Domain/AIWorkout/CloudAIConfig.swift`
- Modify: `SundeeFundeTests/SubscriptionTests.swift` (append new test suite)

- [ ] **Step 1: Write tests**

Append to `SundeeFundeTests/SubscriptionTests.swift`:

```swift
// MARK: - CloudAIConfig Tests

@Suite("CloudAIConfig")
struct CloudAIConfigTests {

    @Test func workerURLIsValid() {
        let url = URL(string: CloudAIConfig.workerURL)
        #expect(url != nil)
        #expect(url?.host?.contains("sundeefundee") == true)
    }

    @Test func createJwtProducesThreeParts() async throws {
        let token = try await CloudAIConfig.createJwt(userID: "user-123", tier: .plus)
        let parts = token.split(separator: ".")
        #expect(parts.count == 3)
    }

    @Test func createJwtPayloadContainsCorrectFields() async throws {
        let token = try await CloudAIConfig.createJwt(userID: "user-456", tier: .premium)
        let parts = token.split(separator: ".")
        let payloadData = CloudAIConfig.base64UrlDecode(String(parts[1]))
        let payload = try JSONDecoder().decode(CloudAIConfig.JwtPayload.self, from: payloadData!)
        #expect(payload.sub == "user-456")
        #expect(payload.tier == "premium")
        #expect(payload.iat > 0)
    }

    @Test func createJwtUsesCorrectTierString() async throws {
        let plusToken = try await CloudAIConfig.createJwt(userID: "u1", tier: .plus)
        let premiumToken = try await CloudAIConfig.createJwt(userID: "u2", tier: .premium)
        let plusPayload = try CloudAIConfig.decodePayload(plusToken)
        let premiumPayload = try CloudAIConfig.decodePayload(premiumToken)
        #expect(plusPayload.tier == "plus")
        #expect(premiumPayload.tier == "premium")
    }

    @Test func createJwtIatIsRecent() async throws {
        let token = try await CloudAIConfig.createJwt(userID: "u1", tier: .plus)
        let payload = try CloudAIConfig.decodePayload(token)
        let now = Int(Date().timeIntervalSince1970)
        #expect(abs(now - payload.iat) < 5)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/CloudAIConfigTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: FAIL — CloudAIConfig doesn't exist yet

- [ ] **Step 3: Implement CloudAIConfig.swift**

```swift
import Foundation
import CryptoKit

enum CloudAIConfig {

    static let workerURL = "https://ai-coach.sundeefundee.workers.dev/generate-workout"

    // Shared secret matching the Cloudflare Worker's JWT_SECRET.
    // Rotatable via `wrangler secret put JWT_SECRET` if compromised.
    private static let jwtSecret = "sundee-fundee-ai-coach-shared-secret-v1"

    struct JwtPayload: Codable {
        let sub: String
        let tier: String
        let iat: Int
    }

    static func createJwt(userID: String, tier: SubscriptionTier) async throws -> String {
        let tierString: String = switch tier {
        case .plus: "plus"
        case .premium: "premium"
        case .free: "free"
        }

        let payload = JwtPayload(
            sub: userID,
            tier: tierString,
            iat: Int(Date().timeIntervalSince1970)
        )

        let header = #"{"alg":"HS256","typ":"JWT"}"#
        let headerB64 = base64UrlEncode(Data(header.utf8))
        let payloadData = try JSONEncoder().encode(payload)
        let payloadB64 = base64UrlEncode(payloadData)

        let signingInput = "\(headerB64).\(payloadB64)"
        let key = SymmetricKey(data: Data(jwtSecret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(signingInput.utf8), using: key)
        let signatureB64 = base64UrlEncode(Data(signature))

        return "\(headerB64).\(payloadB64).\(signatureB64)"
    }

    // MARK: - Base64URL Helpers (internal for testing)

    static func base64UrlEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func base64UrlDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: base64)
    }

    static func decodePayload(_ token: String) throws -> JwtPayload {
        let parts = token.split(separator: ".")
        guard parts.count == 3, let data = base64UrlDecode(String(parts[1])) else {
            throw AIWorkoutServiceError.decodingFailed
        }
        return try JSONDecoder().decode(JwtPayload.self, from: data)
    }
}
```

- [ ] **Step 4: Regenerate Xcode project**

Run:
```bash
cd /Users/dustinober/Projects/Sundee-Fundee && xcodegen generate
```

- [ ] **Step 5: Run tests to verify they pass**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/CloudAIConfigTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Domain/AIWorkout/CloudAIConfig.swift SundeeFundeTests/SubscriptionTests.swift
git commit -m "feat: add CloudAIConfig with JWT creation for ai-coach worker"
```

---

### Task 2: CloudAIUsageTracker — Local Daily Limits

**Files:**
- Create: `SundeeFundee/Domain/AIWorkout/CloudAIUsageTracker.swift`
- Modify: `SundeeFundeTests/SubscriptionTests.swift` (append new test suite)

- [ ] **Step 1: Write tests**

Append to `SundeeFundeTests/SubscriptionTests.swift`:

```swift
// MARK: - CloudAIUsageTracker Tests

@Suite("CloudAIUsageTracker")
struct CloudAIUsageTrackerTests {

    @Test func initialCountIsZero() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.generatedToday == 0)
    }

    @Test func incrementIncreasesCount() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        tracker.recordGeneration()
        #expect(tracker.generatedToday == 1)
        tracker.recordGeneration()
        #expect(tracker.generatedToday == 2)
    }

    @Test func resetsOnNewDay() {
        let defaults = UserDefaults(suiteName: "test-\(UUID())")!
        let tracker = CloudAIUsageTracker(defaults: defaults)
        // Simulate yesterday's data
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let yesterdayKey = formatter.string(from: yesterday)
        defaults.set(5, forKey: "cloudAIUsage:\(yesterdayKey)")
        // Today should be 0
        #expect(tracker.generatedToday == 0)
    }

    @Test func remainingForPlusUser() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.remaining(for: .plus) == 1)
        tracker.recordGeneration()
        #expect(tracker.remaining(for: .plus) == 0)
    }

    @Test func remainingForPremiumUser() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.remaining(for: .premium) == 10)
        tracker.recordGeneration()
        #expect(tracker.remaining(for: .premium) == 9)
    }

    @Test func canGenerateRespectsLimit() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.canGenerate(for: .plus) == true)
        tracker.recordGeneration()
        #expect(tracker.canGenerate(for: .plus) == false)
        #expect(tracker.canGenerate(for: .premium) == true)
    }

    @Test func canGenerateAlwaysFalseForFree() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.canGenerate(for: .free) == false)
    }

    @Test func toggleLabelForTiers() {
        #expect(CloudAIUsageTracker.toggleLabel(for: .plus) == "Use Sundee AI")
        #expect(CloudAIUsageTracker.toggleLabel(for: .premium) == "Use Sundee AI Pro")
        #expect(CloudAIUsageTracker.toggleLabel(for: .free) == "")
    }

    @Test func subtitleTextShowsRemaining() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.subtitleText(for: .plus) == "1 of 1 remaining today")
        tracker.recordGeneration()
        #expect(tracker.subtitleText(for: .plus) == "Come back tomorrow")
    }

    @Test func subtitleTextPremium() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        #expect(tracker.subtitleText(for: .premium) == "10 of 10 remaining today")
    }

    @Test func setGeneratedTodayUpdatesCount() {
        let tracker = CloudAIUsageTracker(defaults: .init(suiteName: "test-\(UUID())")!)
        tracker.setGeneratedToday(5)
        #expect(tracker.generatedToday == 5)
        #expect(tracker.remaining(for: .premium) == 5)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/CloudAIUsageTrackerTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: FAIL — CloudAIUsageTracker doesn't exist yet

- [ ] **Step 3: Implement CloudAIUsageTracker.swift**

```swift
import Foundation

final class CloudAIUsageTracker: Sendable {

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Daily Count

    var generatedToday: Int {
        defaults.integer(forKey: todayKey)
    }

    func recordGeneration() {
        defaults.set(generatedToday + 1, forKey: todayKey)
    }

    func setGeneratedToday(_ count: Int) {
        defaults.set(count, forKey: todayKey)
    }

    // MARK: - Limits

    func remaining(for tier: SubscriptionTier) -> Int {
        let limit = AIWorkoutLimits.dailyCloudLimit(for: tier)
        return max(0, limit - generatedToday)
    }

    func canGenerate(for tier: SubscriptionTier) -> Bool {
        AIWorkoutLimits.canGenerateCloud(tier: tier, generatedToday: generatedToday)
    }

    // MARK: - UI Text

    static func toggleLabel(for tier: SubscriptionTier) -> String {
        switch tier {
        case .free: return ""
        case .plus: return "Use Sundee AI"
        case .premium: return "Use Sundee AI Pro"
        }
    }

    func subtitleText(for tier: SubscriptionTier) -> String {
        let limit = AIWorkoutLimits.dailyCloudLimit(for: tier)
        let rem = remaining(for: tier)
        if rem == 0 { return "Come back tomorrow" }
        return "\(rem) of \(limit) remaining today"
    }

    // MARK: - Private

    private var todayKey: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return "cloudAIUsage:\(formatter.string(from: Date()))"
    }
}
```

- [ ] **Step 4: Regenerate Xcode project**

Run:
```bash
cd /Users/dustinober/Projects/Sundee-Fundee && xcodegen generate
```

- [ ] **Step 5: Run tests to verify they pass**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/CloudAIUsageTrackerTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Domain/AIWorkout/CloudAIUsageTracker.swift SundeeFundeTests/SubscriptionTests.swift
git commit -m "feat: add CloudAIUsageTracker for local daily cloud AI limits"
```

---

### Task 3: CloudAIWorkoutService — Network Service

**Files:**
- Create: `SundeeFundee/Repositories/AIWorkout/CloudAIWorkoutService.swift`

- [ ] **Step 1: Implement CloudAIWorkoutService.swift**

```swift
import Foundation
import SwiftData

@MainActor
final class CloudAIWorkoutService: AIWorkoutServiceProtocol {

    private let modelContext: ModelContext
    private let urlSession: URLSession

    init(modelContext: ModelContext, urlSession: URLSession = .shared) {
        self.modelContext = modelContext
        self.urlSession = urlSession
    }

    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let prompt = AppleIntelligenceWorkoutService.buildPrompt(context: context)
        let systemInstruction = "You are a strength training coach. Return a JSON object with two fields: coachingSummary (string) and exercises (array of objects with name, sets, reps, weightKg, restMinutes, notes, bodyweightOnly). reps must be a string like \"8\" or \"AMRAP\". Return ONLY valid JSON, no markdown fences."

        let token = try await CloudAIConfig.createJwt(
            userID: context.userID,
            tier: currentTier(for: context.userID)
        )

        guard let url = URL(string: CloudAIConfig.workerURL) else {
            throw AIWorkoutServiceError.networkError(0)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let body: [String: String] = [
            "prompt": prompt,
            "systemInstruction": systemInstruction,
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIWorkoutServiceError.networkError(0)
        }

        guard httpResponse.statusCode == 200 else {
            throw AIWorkoutServiceError.networkError(httpResponse.statusCode)
        }

        let cloudResponse = try JSONDecoder().decode(CloudWorkoutResponse.self, from: data)

        let questionnaire = QuestionnaireAnswers(
            timeMinutes: context.timeMinutes,
            focus: context.focus,
            energyLevel: context.energyLevel,
            equipment: context.equipment
        )

        let exercises = cloudResponse.exercises.map { ex in
            GeneratedExercise(
                name: ex.name,
                sets: ex.sets,
                reps: ex.reps,
                weightKg: ex.weightKg,
                restMinutes: ex.restMinutes,
                notes: ex.notes,
                bodyweightOnly: ex.bodyweightOnly
            )
        }

        let workout = GeneratedWorkout(
            coachingSummary: cloudResponse.coachingSummary,
            exercises: exercises,
            questionnaire: questionnaire
        )

        guard let record = GeneratedWorkoutRecord.from(workout, userID: context.userID) else {
            throw AIWorkoutServiceError.encodingFailed
        }
        modelContext.insert(record)
        try? modelContext.save()

        return workout
    }

    // MARK: - History & Favorites (delegate to same SwiftData store)

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

    // MARK: - Private

    private func currentTier(for userID: String) -> SubscriptionTier {
        // In production, this would come from AppState.
        // For now, return .plus as a safe default — the worker validates server-side.
        .plus
    }
}

// MARK: - Response Types

private struct CloudWorkoutResponse: Codable {
    let coachingSummary: String
    let exercises: [CloudExercise]
}

private struct CloudExercise: Codable {
    let name: String
    let sets: Int
    let reps: String
    let weightKg: Double?
    let restMinutes: Double?
    let notes: String?
    let bodyweightOnly: Bool
}
```

- [ ] **Step 2: Regenerate Xcode project**

Run:
```bash
cd /Users/dustinober/Projects/Sundee-Fundee && xcodegen generate
```

- [ ] **Step 3: Build to verify it compiles**

Run:
```bash
xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add SundeeFundee/Repositories/AIWorkout/CloudAIWorkoutService.swift
git commit -m "feat: add CloudAIWorkoutService for ai-coach worker integration"
```

---

### Task 4: QuestionnaireViewModel — Cloud Routing

**Files:**
- Modify: `SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift`
- Modify: `SundeeFundeTests/AIWorkoutViewModelTests.swift` (append new test suite)

- [ ] **Step 1: Write tests**

Append to `SundeeFundeTests/AIWorkoutViewModelTests.swift`:

```swift
// MARK: - QuestionnaireViewModel Cloud Toggle Tests

@Suite("QuestionnaireViewModel Cloud Toggle")
@MainActor
struct QuestionnaireViewModelCloudToggleTests {

    @Test func cloudToggleVisibleForPlus() {
        #expect(QuestionnaireViewModel.isCloudToggleVisible(tier: .plus) == true)
    }

    @Test func cloudToggleVisibleForPremium() {
        #expect(QuestionnaireViewModel.isCloudToggleVisible(tier: .premium) == true)
    }

    @Test func cloudToggleHiddenForFree() {
        #expect(QuestionnaireViewModel.isCloudToggleVisible(tier: .free) == false)
    }

    @Test func cloudToggleEnabledWhenHasRemaining() {
        #expect(QuestionnaireViewModel.isCloudToggleEnabled(remaining: 1) == true)
        #expect(QuestionnaireViewModel.isCloudToggleEnabled(remaining: 5) == true)
    }

    @Test func cloudToggleDisabledWhenAtLimit() {
        #expect(QuestionnaireViewModel.isCloudToggleEnabled(remaining: 0) == false)
    }

    @Test func fallbackMessageText() {
        #expect(QuestionnaireViewModel.cloudFallbackMessage == "Cloud AI unavailable — generated on-device instead.")
    }
}
```

- [ ] **Step 2: Update QuestionnaireViewModel.swift**

Replace the entire file:

```swift
import Foundation
import SwiftData

@MainActor
@Observable
final class QuestionnaireViewModel {
    // Questionnaire answers
    var timeMinutes: Int = 45
    var focus: WorkoutFocus = .fullBody
    var energyLevel: EnergyLevel = .medium
    var equipment: EquipmentAccess = .fullGym

    // Cloud AI toggle
    var useCloudAI: Bool = false

    // State
    var isGenerating = false
    var generatedWorkout: GeneratedWorkout?
    var errorMessage: String?
    var currentPage: Int = 0
    var showFallbackToast = false

    private let onDeviceService: any AIWorkoutServiceProtocol
    private let cloudService: (any AIWorkoutServiceProtocol)?
    private let usageTracker: CloudAIUsageTracker
    private let subscriptionTier: SubscriptionTier

    static let timeOptions: [Int] = [30, 45, 60, 75]
    static let cloudFallbackMessage = "Cloud AI unavailable — generated on-device instead."

    init(
        onDeviceService: any AIWorkoutServiceProtocol,
        cloudService: (any AIWorkoutServiceProtocol)? = nil,
        usageTracker: CloudAIUsageTracker = CloudAIUsageTracker(),
        subscriptionTier: SubscriptionTier = .free
    ) {
        self.onDeviceService = onDeviceService
        self.cloudService = cloudService
        self.usageTracker = usageTracker
        self.subscriptionTier = subscriptionTier
    }

    // MARK: - Cloud Toggle Helpers

    static func isCloudToggleVisible(tier: SubscriptionTier) -> Bool {
        tier != .free
    }

    static func isCloudToggleEnabled(remaining: Int) -> Bool {
        remaining > 0
    }

    var cloudRemaining: Int {
        usageTracker.remaining(for: subscriptionTier)
    }

    var cloudToggleLabel: String {
        CloudAIUsageTracker.toggleLabel(for: subscriptionTier)
    }

    var cloudToggleSubtitle: String {
        usageTracker.subtitleText(for: subscriptionTier)
    }

    var isCloudToggleVisible: Bool {
        Self.isCloudToggleVisible(tier: subscriptionTier)
    }

    var isCloudToggleEnabled: Bool {
        Self.isCloudToggleEnabled(remaining: cloudRemaining)
    }

    // MARK: - Generation

    func generateWorkout(modelContext: ModelContext, userID: String) async {
        guard !isGenerating else { return }

        isGenerating = true
        errorMessage = nil
        showFallbackToast = false

        let context = buildContext(modelContext: modelContext, userID: userID)

        if useCloudAI, let cloudService {
            do {
                generatedWorkout = try await cloudService.generateWorkout(context: context)
                usageTracker.recordGeneration()
            } catch let error as AIWorkoutServiceError {
                if case .networkError(429) = error {
                    usageTracker.setGeneratedToday(AIWorkoutLimits.dailyCloudLimit(for: subscriptionTier))
                }
                // Fall back to on-device
                showFallbackToast = true
                do {
                    generatedWorkout = try await onDeviceService.generateWorkout(context: context)
                } catch {
                    errorMessage = "Failed to generate workout. Please try again."
                }
            } catch {
                showFallbackToast = true
                do {
                    generatedWorkout = try await onDeviceService.generateWorkout(context: context)
                } catch {
                    errorMessage = "Failed to generate workout. Please try again."
                }
            }
        } else {
            do {
                generatedWorkout = try await onDeviceService.generateWorkout(context: context)
            } catch {
                errorMessage = "Failed to generate workout. Please try again."
            }
        }

        isGenerating = false
    }

    // MARK: - Context Building

    func buildContext(modelContext: ModelContext, userID: String) -> WorkoutGenerationContext {
        let userRepo = SwiftDataUserRepository(context: modelContext)
        let liftRepo = SwiftDataLiftRepository(context: modelContext)
        let cycleRepo = SwiftDataCycleRepository(context: modelContext)
        let injuryRepo = SwiftDataInjuryRepository(context: modelContext)
        let workoutRepo = SwiftDataWorkoutRepository(context: modelContext)

        let currentUser = try? userRepo.fetchCurrentUser()
        let maxes = buildMaxes(liftRepo: liftRepo)
        let recentWorkouts = buildRecentWorkouts(workoutRepo: workoutRepo)
        let cyclePhase = buildCyclePhase(cycleRepo: cycleRepo)
        let injuries = buildInjuries(injuryRepo: injuryRepo, userID: userID)

        return WorkoutGenerationContext(
            userID: userID,
            timeMinutes: timeMinutes,
            focus: focus,
            energyLevel: energyLevel,
            equipment: equipment,
            maxes: maxes,
            recentWorkouts: recentWorkouts,
            cyclePhase: cyclePhase,
            readinessTier: nil,
            activeInjuries: injuries,
            experienceLevel: currentUser?.experienceLevel.rawValue ?? "beginner",
            primaryGoal: currentUser?.primaryGoal.rawValue ?? "strength",
            gender: currentUser?.gender.rawValue ?? "prefer_not_to_say",
            weightUnit: currentUser?.weightUnit.rawValue ?? "lb"
        )
    }

    private func buildMaxes(liftRepo: SwiftDataLiftRepository) -> [ExerciseMax] {
        let orms = (try? liftRepo.fetchOneRepMaxes()) ?? []
        var seen = Set<String>()
        return orms.compactMap { orm in
            guard !seen.contains(orm.exerciseID) else { return nil }
            seen.insert(orm.exerciseID)
            return ExerciseMax(name: orm.exerciseID, weightKg: orm.weightKg)
        }
    }

    private func buildRecentWorkouts(workoutRepo: SwiftDataWorkoutRepository) -> [RecentWorkoutSummary] {
        let workouts = (try? workoutRepo.fetchWorkouts()) ?? []
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
        return workouts
            .filter { $0.completedAt >= twoWeeksAgo }
            .prefix(10)
            .map { workout in
                RecentWorkoutSummary(
                    date: workout.completedAt,
                    focus: workout.sessionID,
                    exercises: [],
                    durationMinutes: workout.durationSeconds / 60
                )
            }
    }

    private func buildCyclePhase(cycleRepo: SwiftDataCycleRepository) -> String? {
        let settings = try? cycleRepo.fetchCycleSettings()
        let logs = (try? cycleRepo.fetchPeriodLogs()) ?? []
        guard let settings else { return nil }
        let status = CycleCalculations.calculateCycleStatus(periodLogs: logs, settings: settings)
        return status?.currentPhase.rawValue
    }

    private func buildInjuries(injuryRepo: SwiftDataInjuryRepository, userID: String) -> [InjurySummary] {
        let injuries = (try? injuryRepo.fetchActiveInjuries(userID: userID)) ?? []
        return injuries.map { injury in
            InjurySummary(
                location: injury.location,
                phase: injury.recoveryPhase.rawValue,
                restrictions: InjuryAdaptationEngine.normalizedBodyRegions(from: [injury])
            )
        }
    }

    // MARK: - Validation

    var canGenerate: Bool {
        timeMinutes > 0
    }
}
```

- [ ] **Step 3: Run tests to verify they pass**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/QuestionnaireViewModelCloudToggleTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: PASS

- [ ] **Step 4: Run existing AIWorkoutViewModelTests to verify no regressions**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/WorkoutPreviewViewModelTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift SundeeFundeTests/AIWorkoutViewModelTests.swift
git commit -m "feat: add cloud AI toggle routing to QuestionnaireViewModel"
```

---

### Task 5: QuestionnaireView — Cloud Toggle UI

**Files:**
- Modify: `SundeeFundee/Features/AIWorkout/QuestionnaireView.swift`
- Modify: `SundeeFundee/Features/AIWorkout/AIWorkoutFlowView.swift`

- [ ] **Step 1: Update QuestionnaireView.swift**

Add `subscriptionTier` parameter and cloud toggle section. Replace the `init` and add the toggle section to page 2:

In the struct properties, add:

```swift
let subscriptionTier: SubscriptionTier
```

Update the init:

```swift
init(
    userID: String,
    subscriptionTier: SubscriptionTier = .free,
    onDeviceService: any AIWorkoutServiceProtocol,
    cloudService: (any AIWorkoutServiceProtocol)? = nil,
    onWorkoutGenerated: @escaping (GeneratedWorkout) -> Void = { _ in }
) {
    self.userID = userID
    self.subscriptionTier = subscriptionTier
    self.onWorkoutGenerated = onWorkoutGenerated
    self._viewModel = State(initialValue: QuestionnaireViewModel(
        onDeviceService: onDeviceService,
        cloudService: cloudService,
        subscriptionTier: subscriptionTier
    ))
}
```

In `page2`, add the cloud toggle section after the equipment section and before the closing of the VStack:

```swift
if viewModel.isCloudToggleVisible {
    cloudAIToggle
}
```

Add the `cloudAIToggle` computed property:

```swift
private var cloudAIToggle: some View {
    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
        sectionHeader("Cloud AI")

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.cloudToggleLabel)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text(viewModel.cloudToggleSubtitle)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }
            Spacer()
            Toggle("", isOn: $viewModel.useCloudAI)
                .labelsHidden()
                .tint(AppTheme.Colors.accentOrange)
                .disabled(!viewModel.isCloudToggleEnabled)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.card)
    }
}
```

Add a toast overlay to the body, after the `.onChange`:

```swift
.overlay(alignment: .bottom) {
    if viewModel.showFallbackToast {
        Text(QuestionnaireViewModel.cloudFallbackMessage)
            .font(AppTheme.Fonts.caption)
            .foregroundStyle(.white)
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.navy.opacity(0.9))
            .cornerRadius(AppTheme.CornerRadius.button)
            .padding(.bottom, 80)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation { viewModel.showFallbackToast = false }
                }
            }
    }
}
```

- [ ] **Step 2: Update AIWorkoutFlowView.swift**

Replace the body to inject both services and pass subscriptionTier:

```swift
import SwiftUI
import SwiftData

struct AIWorkoutFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    let userID: String
    let barbellWeightKg: Double
    let weightUnit: WeightUnit

    @State private var generatedWorkout: GeneratedWorkout?
    @State private var workoutToStart: GeneratedWorkout?

    init(
        userID: String,
        barbellWeightKg: Double = PlateCalculation.standardBarKg,
        weightUnit: WeightUnit = .pounds
    ) {
        self.userID = userID
        self.barbellWeightKg = barbellWeightKg
        self.weightUnit = weightUnit
    }

    var body: some View {
        let onDeviceService = AppleIntelligenceWorkoutService(modelContext: modelContext)
        let cloudService = CloudAIWorkoutService(modelContext: modelContext)
        QuestionnaireView(
            userID: userID,
            subscriptionTier: appState.subscriptionTier,
            onDeviceService: onDeviceService,
            cloudService: cloudService,
            onWorkoutGenerated: { workout in
                generatedWorkout = workout
            }
        )
        .navigationDestination(item: $generatedWorkout) { workout in
            WorkoutPreviewView(
                viewModel: WorkoutPreviewViewModel(workout: workout, aiService: onDeviceService),
                userID: userID,
                onStartWorkout: { workout in
                    workoutToStart = workout
                },
                onRegenerate: {
                    generatedWorkout = nil
                }
            )
        }
        .navigationDestination(item: $workoutToStart) { workout in
            WorkoutExecutionView(
                viewModel: WorkoutExecutionViewModel(
                    generatedWorkout: workout,
                    barbellWeightKg: barbellWeightKg,
                    weightUnit: weightUnit
                )
            )
        }
    }
}
```

- [ ] **Step 3: Regenerate Xcode project**

Run:
```bash
cd /Users/dustinober/Projects/Sundee-Fundee && xcodegen generate
```

- [ ] **Step 4: Build to verify it compiles**

Run:
```bash
xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Features/AIWorkout/QuestionnaireView.swift SundeeFundee/Features/AIWorkout/AIWorkoutFlowView.swift
git commit -m "feat: add cloud AI toggle to QuestionnaireView and wire in AIWorkoutFlowView"
```

---

### Task 6: Fix Test Call Sites and Full Verification

**Files:**
- Modify: `SundeeFundeTests/AIWorkoutViewModelTests.swift` (update existing test stub init)
- Modify: Any other test files that instantiate `QuestionnaireView` or `QuestionnaireViewModel`

The `QuestionnaireViewModel` init changed from `init(aiService:)` to `init(onDeviceService:cloudService:usageTracker:subscriptionTier:)`. The existing test stub `OfflineAIWorkoutService` needs to be passed as `onDeviceService`.

- [ ] **Step 1: Search for broken call sites**

Run:
```bash
grep -rn "QuestionnaireViewModel(aiService:" SundeeFundeTests/ --include="*.swift" || echo "No old call sites"
grep -rn "QuestionnaireView(userID:" SundeeFundeTests/ --include="*.swift" || echo "No QuestionnaireView test call sites"
```

Fix any call sites that use the old `aiService:` parameter name to use `onDeviceService:` instead.

- [ ] **Step 2: Run the full test suite**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30
```
Expected: ALL TESTS PASS

- [ ] **Step 3: Update TODO.md**

In `docs/TODO.md`, change:
```markdown
- [ ] **Cloud AI Workout Integration** — Wire iOS app to call the proxy for Plus/Premium users, edit-before-start flow, fallback to on-device if network unavailable
```
to:
```markdown
- [x] **Cloud AI Workout Integration** — Added CloudAIWorkoutService, CloudAIConfig (JWT), CloudAIUsageTracker, and cloud AI toggle in QuestionnaireView for Plus/Premium users. Falls back to on-device on failure.
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: complete cloud AI workout integration with fallback and tests"
```
