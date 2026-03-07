# Subscription Tiers Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add two-tier StoreKit 2 subscriptions (Plus $4.99/mo, Pro $9.99/mo) with daily AI workout generation limits and a paywall.

**Architecture:** Extend existing `SubscriptionService` to support two product IDs and tier resolution. Gate AI generation in `QuestionnaireViewModel` by checking tier + daily usage count from `GeneratedWorkoutRecord`. Free users get routed to `OfflineWorkoutGenerator`. Paywall presented as a `.sheet`.

**Tech Stack:** StoreKit 2, SwiftUI, SwiftData, Swift Testing

**Design doc:** `docs/plans/2026-03-07-subscription-tiers-design.md`

---

### Task 1: Update SubscriptionTier Enum

**Files:**
- Modify: `SundeeFundee/Services/SubscriptionService.swift:4-16`

**Step 1: Write the failing test**

Create: `SundeeFundeTests/SubscriptionServiceTests.swift`

```swift
import Testing
@testable import SundeeFundee

@Suite("SubscriptionTier")
struct SubscriptionTierTests {

    @Test func dailyLimits() {
        #expect(SubscriptionTier.free.dailyAILimit == 0)
        #expect(SubscriptionTier.plus.dailyAILimit == 1)
        #expect(SubscriptionTier.pro.dailyAILimit == 3)
    }

    @Test func displayNames() {
        #expect(SubscriptionTier.free.displayName == "Free")
        #expect(SubscriptionTier.plus.displayName == "Plus")
        #expect(SubscriptionTier.pro.displayName == "Pro")
    }

    @Test func productIDs() {
        #expect(SubscriptionTier.plus.productID == "com.sundeefundee.plus.monthly")
        #expect(SubscriptionTier.pro.productID == "com.sundeefundee.pro.monthly")
    }

    @Test func tierFromProductID() {
        #expect(SubscriptionTier.from(productID: "com.sundeefundee.plus.monthly") == .plus)
        #expect(SubscriptionTier.from(productID: "com.sundeefundee.pro.monthly") == .pro)
        #expect(SubscriptionTier.from(productID: "com.sundeefundee.unknown") == .free)
    }

    @Test func highestTierResolution() {
        #expect(SubscriptionTier.highest([]) == .free)
        #expect(SubscriptionTier.highest([.free]) == .free)
        #expect(SubscriptionTier.highest([.plus]) == .plus)
        #expect(SubscriptionTier.highest([.plus, .pro]) == .pro)
        #expect(SubscriptionTier.highest([.free, .plus]) == .plus)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/SubscriptionTierTests`
Expected: FAIL — `dailyAILimit`, `productID`, `from(productID:)`, `highest` don't exist yet.

**Step 3: Write minimal implementation**

Replace `SubscriptionTier` enum in `SundeeFundee/Services/SubscriptionService.swift:4-16`:

```swift
enum SubscriptionTier: String, Sendable, Comparable {
    case free
    case plus
    case pro

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Plus"
        case .pro: return "Pro"
        }
    }

    var dailyAILimit: Int {
        switch self {
        case .free: 0
        case .plus: 1
        case .pro: 3
        }
    }

    var productID: String? {
        switch self {
        case .free: nil
        case .plus: "com.sundeefundee.plus.monthly"
        case .pro: "com.sundeefundee.pro.monthly"
        }
    }

    static let allProductIDs: Set<String> = [
        "com.sundeefundee.plus.monthly",
        "com.sundeefundee.pro.monthly"
    ]

    static func from(productID: String) -> SubscriptionTier {
        switch productID {
        case "com.sundeefundee.plus.monthly": .plus
        case "com.sundeefundee.pro.monthly": .pro
        default: .free
        }
    }

    static func highest(_ tiers: [SubscriptionTier]) -> SubscriptionTier {
        tiers.max() ?? .free
    }

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        let order: [SubscriptionTier] = [.free, .plus, .pro]
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/SubscriptionTierTests`
Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Services/SubscriptionService.swift SundeeFundeTests/SubscriptionServiceTests.swift
git commit -m "feat: update SubscriptionTier enum with Plus/Pro tiers and daily limits"
```

---

### Task 2: Update SubscriptionService for Multi-Tier

**Files:**
- Modify: `SundeeFundee/Services/SubscriptionService.swift:18-104`
- Modify: `SundeeFundeTests/SubscriptionServiceTests.swift`

**Step 1: Write the failing test**

Append to `SundeeFundeTests/SubscriptionServiceTests.swift`:

```swift
@Suite("SubscriptionService")
struct SubscriptionServiceTests {

    @Test @MainActor func defaultsToFree() {
        let service = SubscriptionService()
        #expect(service.currentTier == .free)
        #expect(service.isPremium == false)
    }

    @Test @MainActor func isPremiumTrueForPlus() {
        let service = SubscriptionService()
        service.setTierForTesting(.plus)
        #expect(service.isPremium == true)
        #expect(service.currentTier == .plus)
    }

    @Test @MainActor func isPremiumTrueForPro() {
        let service = SubscriptionService()
        service.setTierForTesting(.pro)
        #expect(service.isPremium == true)
        #expect(service.currentTier == .pro)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/SubscriptionServiceTests`
Expected: FAIL — `currentTier`, `setTierForTesting` don't exist.

**Step 3: Write minimal implementation**

Replace `SubscriptionService` class in `SundeeFundee/Services/SubscriptionService.swift:18-104`:

```swift
@Observable @MainActor
final class SubscriptionService {
    private static let tierKey = "com.sundeefundee.subscription.tier"

    private(set) var currentTier: SubscriptionTier = .free
    var isPremium: Bool { currentTier != .free }
    private var transactionTask: Task<Void, Never>?

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.tierKey) ?? "free"
        self.currentTier = SubscriptionTier(rawValue: raw) ?? .free
        startObservingTransactions()
    }

    func loadStatus() async {
        var activeTiers: [SubscriptionTier] = []
        for await verificationResult in Transaction.currentEntitlements {
            guard case .verified(let transaction) = verificationResult else { continue }
            if transaction.revocationDate == nil {
                activeTiers.append(SubscriptionTier.from(productID: transaction.productID))
            }
        }
        setTier(SubscriptionTier.highest(activeTiers))
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            setTier(SubscriptionTier.from(productID: transaction.productID))
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await loadStatus()
    }

    #if DEBUG
    func setTierForTesting(_ tier: SubscriptionTier) {
        setTier(tier)
    }
    #endif

    // MARK: - Private

    private func startObservingTransactions() {
        transactionTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = update {
                    let tier = SubscriptionTier.from(productID: transaction.productID)
                    if transaction.revocationDate == nil {
                        self.setTier(tier)
                    } else {
                        await self.loadStatus()
                    }
                    await transaction.finish()
                }
            }
        }
    }

    private func setTier(_ tier: SubscriptionTier) {
        self.currentTier = tier
        UserDefaults.standard.set(tier.rawValue, forKey: Self.tierKey)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.unverifiedTransaction
        case .verified(let safe):
            return safe
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/SubscriptionServiceTests`
Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Services/SubscriptionService.swift SundeeFundeTests/SubscriptionServiceTests.swift
git commit -m "feat: update SubscriptionService for multi-tier (Plus/Pro) with UserDefaults caching"
```

---

### Task 3: Wire SubscriptionService into App Environment

**Files:**
- Modify: `SundeeFundee/App/AppRootView.swift:53-68`
- Modify: `SundeeFundee/App/SundeeFundeeApp.swift`

**Step 1: No test needed — pure wiring**

This is environment injection; the SubscriptionManagementView already expects `@Environment(SubscriptionService.self)`.

**Step 2: Add SubscriptionService to AppRootView**

In `SundeeFundee/App/AppRootView.swift`, add a `@State` property and inject it into the environment:

Add after line 8 (`private let shouldRestoreSession: Bool`):
```swift
@State private var subscriptionService = SubscriptionService()
```

In `body`, change `.environment(appState)` (line 66) to chain:
```swift
.environment(appState)
.environment(subscriptionService)
.task { await subscriptionService.loadStatus() }
```

(Keep the existing `.task` for session restore as-is.)

**Step 3: Build to verify**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add SundeeFundee/App/AppRootView.swift
git commit -m "feat: wire SubscriptionService into SwiftUI environment"
```

---

### Task 4: Add Daily Usage Counting

**Files:**
- Modify: `SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift`
- Modify: `SundeeFundeTests/SubscriptionServiceTests.swift`

**Step 1: Write the failing test**

Append to `SundeeFundeTests/SubscriptionServiceTests.swift`:

```swift
@Suite("QuestionnaireViewModel Gating")
struct QuestionnaireViewModelGatingTests {

    @Test func canGenerateAIReturnsFalseForFree() {
        let result = QuestionnaireViewModel.canGenerateAI(tier: .free, todayCount: 0)
        #expect(result == .blocked(.needsSubscription))
    }

    @Test func canGenerateAIReturnsTrueForPlusUnderLimit() {
        let result = QuestionnaireViewModel.canGenerateAI(tier: .plus, todayCount: 0)
        #expect(result == .allowed)
    }

    @Test func canGenerateAIReturnsFalseForPlusAtLimit() {
        let result = QuestionnaireViewModel.canGenerateAI(tier: .plus, todayCount: 1)
        #expect(result == .blocked(.dailyLimitReached(upgradeAvailable: true)))
    }

    @Test func canGenerateAIReturnsTrueForProUnderLimit() {
        let result = QuestionnaireViewModel.canGenerateAI(tier: .pro, todayCount: 2)
        #expect(result == .allowed)
    }

    @Test func canGenerateAIReturnsFalseForProAtLimit() {
        let result = QuestionnaireViewModel.canGenerateAI(tier: .pro, todayCount: 3)
        #expect(result == .blocked(.dailyLimitReached(upgradeAvailable: false)))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/QuestionnaireViewModelGatingTests`
Expected: FAIL — `canGenerateAI`, `GenerationGateResult` don't exist.

**Step 3: Write minimal implementation**

Add to `SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift` (before `canGenerate` at line 196):

```swift
// MARK: - Generation Gating

enum GenerationBlockReason: Equatable {
    case needsSubscription
    case dailyLimitReached(upgradeAvailable: Bool)
}

enum GenerationGateResult: Equatable {
    case allowed
    case blocked(GenerationBlockReason)
}

static func canGenerateAI(tier: SubscriptionTier, todayCount: Int) -> GenerationGateResult {
    if tier == .free {
        return .blocked(.needsSubscription)
    }
    if todayCount >= tier.dailyAILimit {
        let canUpgrade = tier < .pro
        return .blocked(.dailyLimitReached(upgradeAvailable: canUpgrade))
    }
    return .allowed
}

static func countTodayGenerations(modelContext: ModelContext, userID: String) -> Int {
    let startOfDay = Calendar.current.startOfDay(for: Date())
    let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
        predicate: #Predicate { $0.userID == userID && $0.createdAt >= startOfDay }
    )
    return (try? modelContext.fetch(descriptor))?.count ?? 0
}
```

Also add a published state property at line 17 (after `var currentPage`):

```swift
var showPaywall = false
var generationBlockReason: GenerationBlockReason?
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/QuestionnaireViewModelGatingTests`
Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift SundeeFundeTests/SubscriptionServiceTests.swift
git commit -m "feat: add AI generation gating logic with daily usage counting"
```

---

### Task 5: Wire Gating into generateWorkout Flow

**Files:**
- Modify: `SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift:33-47`

**Step 1: Write the failing test**

Append to `SundeeFundeTests/SubscriptionServiceTests.swift`:

```swift
@Suite("QuestionnaireViewModel Generate with Gating")
struct QuestionnaireViewModelGenerateGatingTests {

    @Test @MainActor func freeUserShowsPaywall() async {
        let service = MockAIWorkoutService()
        let vm = QuestionnaireViewModel(aiService: service)
        vm.generateWorkoutGated(tier: .free, todayCount: 0)
        #expect(vm.showPaywall == true)
        #expect(vm.generationBlockReason == .needsSubscription)
        #expect(vm.generatedWorkout == nil)
    }

    @Test @MainActor func plusUserAtLimitShowsPaywall() async {
        let service = MockAIWorkoutService()
        let vm = QuestionnaireViewModel(aiService: service)
        vm.generateWorkoutGated(tier: .plus, todayCount: 1)
        #expect(vm.showPaywall == true)
        #expect(vm.generationBlockReason == .dailyLimitReached(upgradeAvailable: true))
    }

    @Test @MainActor func proUserAtLimitShowsAlert() async {
        let service = MockAIWorkoutService()
        let vm = QuestionnaireViewModel(aiService: service)
        vm.generateWorkoutGated(tier: .pro, todayCount: 3)
        #expect(vm.showPaywall == false)
        #expect(vm.generationBlockReason == .dailyLimitReached(upgradeAvailable: false))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/QuestionnaireViewModelGenerateGatingTests`
Expected: FAIL — `generateWorkoutGated` doesn't exist.

**Step 3: Write minimal implementation**

Add to `QuestionnaireViewModel`:

```swift
func generateWorkoutGated(tier: SubscriptionTier, todayCount: Int) {
    let gate = Self.canGenerateAI(tier: tier, todayCount: todayCount)
    switch gate {
    case .allowed:
        showPaywall = false
        generationBlockReason = nil
    case .blocked(let reason):
        generationBlockReason = reason
        switch reason {
        case .needsSubscription, .dailyLimitReached(upgradeAvailable: true):
            showPaywall = true
        case .dailyLimitReached(upgradeAvailable: false):
            showPaywall = false
            errorMessage = "You've reached today's limit. Come back tomorrow!"
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/QuestionnaireViewModelGenerateGatingTests`
Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift SundeeFundeTests/SubscriptionServiceTests.swift
git commit -m "feat: add generateWorkoutGated method with paywall trigger logic"
```

---

### Task 6: Create PaywallView

**Files:**
- Create: `SundeeFundee/Features/Subscription/PaywallView.swift`
- Modify: `SundeeFundeTests/SubscriptionServiceTests.swift`

**Step 1: Write the failing test**

Append to `SundeeFundeTests/SubscriptionServiceTests.swift`:

```swift
@Suite("PaywallView Statics")
struct PaywallViewStaticTests {

    @Test func headlineForNeedsSubscription() {
        let headline = PaywallView.headline(for: .needsSubscription)
        #expect(headline == "Unlock AI-Powered Workouts")
    }

    @Test func headlineForDailyLimit() {
        let headline = PaywallView.headline(for: .dailyLimitReached(upgradeAvailable: true))
        #expect(headline == "Need More Workouts?")
    }

    @Test func subtitleForNeedsSubscription() {
        let subtitle = PaywallView.subtitle(for: .needsSubscription)
        #expect(subtitle.contains("personalized"))
    }

    @Test func subtitleForDailyLimit() {
        let subtitle = PaywallView.subtitle(for: .dailyLimitReached(upgradeAvailable: true))
        #expect(subtitle.contains("Pro"))
    }
}
```

**Step 2: Run test to verify it fails**

Expected: FAIL — `PaywallView` doesn't exist.

**Step 3: Write minimal implementation**

Create `SundeeFundee/Features/Subscription/PaywallView.swift`:

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(\.dismiss) private var dismiss
    let reason: GenerationBlockReason
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        headerSection
                        featureComparison
                        productButtons
                        restoreLink
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppTheme.Colors.navy)
                    }
                }
            }
            .task { await loadProducts() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.Colors.accentOrange)

            Text(Self.headline(for: reason))
                .font(AppTheme.Fonts.heading)
                .foregroundStyle(AppTheme.Colors.navy)
                .multilineTextAlignment(.center)

            Text(Self.subtitle(for: reason))
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppTheme.Spacing.lg)
    }

    // MARK: - Feature Comparison

    private var featureComparison: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            featureRow("Offline workouts", free: true, plus: true, pro: true)
            featureRow("Crowdsourced workouts", free: true, plus: true, pro: true)
            featureRow("Cycle tracking", free: true, plus: true, pro: true)
            featureRow("AI workouts", free: false, plus: true, pro: true)
            featureRow("1 AI workout/day", free: false, plus: true, pro: true)
            featureRow("3 AI workouts/day", free: false, plus: false, pro: true)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }

    private func featureRow(_ label: String, free: Bool, plus: Bool, pro: Bool) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy)
            Spacer()
            checkmark(free)
            checkmark(plus)
            checkmark(pro)
        }
    }

    private func checkmark(_ included: Bool) -> some View {
        Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle")
            .foregroundStyle(included ? AppTheme.Colors.accentOrange : AppTheme.Colors.navy.opacity(0.2))
            .frame(width: 44)
    }

    // MARK: - Products

    private var productButtons: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(products.sorted(by: { $0.price < $1.price }), id: \.id) { product in
                Button {
                    purchaseProduct(product)
                } label: {
                    VStack(spacing: 4) {
                        Text(tierName(for: product))
                            .font(AppTheme.Fonts.subheading)
                        Text("\(product.displayPrice)/month")
                            .font(AppTheme.Fonts.caption)
                        Text("2-week free trial")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(AppTheme.Colors.accentOrange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                }
                .disabled(isLoading)
            }

            if let message {
                Text(message)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.error)
            }
        }
    }

    private var restoreLink: some View {
        Button("Restore Purchases") {
            Task {
                do {
                    try await subscriptionService.restorePurchases()
                    dismiss()
                } catch {
                    message = "Restore failed: \(error.localizedDescription)"
                }
            }
        }
        .font(AppTheme.Fonts.caption)
        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
    }

    // MARK: - Helpers

    static func headline(for reason: GenerationBlockReason) -> String {
        switch reason {
        case .needsSubscription:
            "Unlock AI-Powered Workouts"
        case .dailyLimitReached:
            "Need More Workouts?"
        }
    }

    static func subtitle(for reason: GenerationBlockReason) -> String {
        switch reason {
        case .needsSubscription:
            "Get personalized AI workouts tailored to your goals, maxes, and how you're feeling today."
        case .dailyLimitReached:
            "Upgrade to Pro for up to 3 AI workouts per day."
        }
    }

    private func tierName(for product: Product) -> String {
        let tier = SubscriptionTier.from(productID: product.id)
        return tier.displayName
    }

    private func loadProducts() async {
        do {
            products = try await Product.products(for: SubscriptionTier.allProductIDs)
        } catch {
            message = "Failed to load products."
        }
    }

    private func purchaseProduct(_ product: Product) {
        isLoading = true
        Task {
            do {
                try await subscriptionService.purchase(product)
                dismiss()
            } catch {
                message = "Purchase failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/PaywallViewStaticTests`
Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Subscription/PaywallView.swift SundeeFundeTests/SubscriptionServiceTests.swift
git commit -m "feat: add PaywallView with Art Deco styling and context-aware messaging"
```

---

### Task 7: Wire Paywall into QuestionnaireView

**Files:**
- Modify: `SundeeFundee/Features/AIWorkout/QuestionnaireView.swift:4-6,134-155`

**Step 1: No separate test — UI wiring**

The gating logic is already tested in Tasks 4-5. This wires the `.sheet` and injects the subscription service.

**Step 2: Update QuestionnaireView**

Add environment property after line 6:
```swift
@Environment(SubscriptionService.self) private var subscriptionService
```

Replace the Generate button action (lines 136-138) with:
```swift
Button {
    let todayCount = QuestionnaireViewModel.countTodayGenerations(
        modelContext: modelContext, userID: userID
    )
    viewModel.generateWorkoutGated(
        tier: subscriptionService.currentTier,
        todayCount: todayCount
    )
    if viewModel.generationBlockReason == nil {
        Task {
            await viewModel.generateWorkout(modelContext: modelContext, userID: userID)
        }
    }
}
```

Add `.sheet` modifier after `.navigationTitle("New Workout")` (line 37):
```swift
.sheet(isPresented: $viewModel.showPaywall) {
    if let reason = viewModel.generationBlockReason {
        PaywallView(reason: reason)
    }
}
```

**Step 3: Build to verify**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add SundeeFundee/Features/AIWorkout/QuestionnaireView.swift
git commit -m "feat: wire paywall sheet into questionnaire generate flow"
```

---

### Task 8: Update SubscriptionManagementView for Plus/Pro

**Files:**
- Modify: `SundeeFundee/Features/Settings/SubscriptionManagementView.swift`

**Step 1: No separate test — UI update**

Existing behavior is the same pattern, just showing two products instead of one.

**Step 2: Update SubscriptionManagementView**

Key changes:
- Replace `SubscriptionTier.premium.rawValue` product fetch with `SubscriptionTier.allProductIDs`
- Show current tier name (`subscriptionService.currentTier.displayName`)
- Show daily limit info
- Display both products when not at Pro tier
- If Plus, show upgrade-to-Pro option

Replace `loadProducts()`:
```swift
private func loadProducts() async {
    do {
        products = try await Product.products(for: SubscriptionTier.allProductIDs)
    } catch {
        message = "Failed to load products: \(error.localizedDescription)"
    }
}
```

Replace "Current Subscription" section text:
```swift
Text(subscriptionService.currentTier.displayName)
```

Replace "Upgrade to Premium" section — show products sorted by price, each with tier name and daily limit description. Only show products for tiers higher than current.

**Step 3: Build to verify**

Run: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add SundeeFundee/Features/Settings/SubscriptionManagementView.swift
git commit -m "feat: update SubscriptionManagementView for Plus/Pro tiers"
```

---

### Task 9: Update Dashboard AIWorkoutCTACard

**Files:**
- Modify: `SundeeFundee/Features/Dashboard/DashboardView.swift:707-744`
- Modify: `SundeeFundeTests/DashboardViewCoverageTests.swift`

**Step 1: Write the failing test**

Append to `SundeeFundeTests/SubscriptionServiceTests.swift`:

```swift
@Suite("AIWorkoutCTACard Statics")
struct AIWorkoutCTACardStaticTests {

    @Test func ctaTextForFree() {
        #expect(AIWorkoutCTACard.ctaText(for: .free) == "Upgrade to Unlock")
    }

    @Test func ctaTextForPlus() {
        #expect(AIWorkoutCTACard.ctaText(for: .plus) == "New AI Workout")
    }

    @Test func ctaTextForPro() {
        #expect(AIWorkoutCTACard.ctaText(for: .pro) == "New AI Workout")
    }

    @Test func subtitleForFree() {
        let subtitle = AIWorkoutCTACard.subtitleText(for: .free)
        #expect(subtitle.contains("Upgrade"))
    }

    @Test func subtitleForPaid() {
        let subtitle = AIWorkoutCTACard.subtitleText(for: .plus)
        #expect(subtitle.contains("personalized"))
    }
}
```

**Step 2: Run test to verify it fails**

Expected: FAIL — static methods don't exist.

**Step 3: Write minimal implementation**

Update `AIWorkoutCTACard` in `DashboardView.swift` to:
- Accept tier from environment
- Show "Upgrade to Unlock" for free users (opens paywall sheet)
- Show "New AI Workout" for paid users (current NavigationLink behavior)
- Add static helper methods for testability

```swift
struct AIWorkoutCTACard: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @State private var showPaywall = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI WORKOUT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                        .tracking(1.5)
                    Text("Custom Session")
                        .font(AppTheme.Fonts.subheading)
                        .foregroundStyle(AppTheme.Colors.navy)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
            }

            Text(Self.subtitleText(for: subscriptionService.currentTier))
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))

            if subscriptionService.currentTier == .free {
                Button {
                    showPaywall = true
                } label: {
                    Label(Self.ctaText(for: .free), systemImage: "lock.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                NavigationLink(value: StartAIWorkoutDestination()) {
                    Label(Self.ctaText(for: subscriptionService.currentTier), systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("start-ai-workout-button")
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        .sheet(isPresented: $showPaywall) {
            PaywallView(reason: .needsSubscription)
        }
    }

    static func ctaText(for tier: SubscriptionTier) -> String {
        tier == .free ? "Upgrade to Unlock" : "New AI Workout"
    }

    static func subtitleText(for tier: SubscriptionTier) -> String {
        tier == .free
            ? "Upgrade to unlock AI-powered workouts tailored to your goals."
            : "Generate a personalized workout based on your goals, maxes, and how you're feeling today."
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/AIWorkoutCTACardStaticTests`
Expected: PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Dashboard/DashboardView.swift SundeeFundeTests/SubscriptionServiceTests.swift
git commit -m "feat: update AIWorkoutCTACard with tier-aware messaging and paywall for free users"
```

---

### Task 10: Create StoreKit Configuration File

**Files:**
- Create: `SundeeFundee/Resources/SundeeFundee.storekit`

**Step 1: No test — configuration file**

Create a StoreKit configuration file for local testing. This is done in Xcode:

1. File > New > File > StoreKit Configuration File
2. Name: `SundeeFundee.storekit`
3. Save to: `SundeeFundee/Resources/`
4. Add subscription group: "Sundee Fundee Premium"
5. Add product: `com.sundeefundee.plus.monthly` — Auto-Renewable, $4.99, "Plus"
   - Introductory offer: Free, 2 weeks
6. Add product: `com.sundeefundee.pro.monthly` — Auto-Renewable, $9.99, "Pro"
   - Introductory offer: Free, 2 weeks
7. In scheme editor: Run > Options > StoreKit Configuration > select `SundeeFundee.storekit`

**Step 2: Add to project.yml**

Ensure the `.storekit` file is included in the project resources.

**Step 3: Commit**

```bash
git add SundeeFundee/Resources/SundeeFundee.storekit project.yml
git commit -m "feat: add StoreKit configuration file for local subscription testing"
```

---

### Task 11: Update Existing Tests for SubscriptionTier Changes

**Files:**
- Modify: Any test files that reference `SubscriptionTier.premium`

**Step 1: Search and update**

```bash
grep -rn "SubscriptionTier.premium" SundeeFundeTests/
```

Update any references from `.premium` to `.plus` or `.pro` as appropriate.

**Step 2: Run full test suite**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests`
Expected: All subscription-related tests PASS

**Step 3: Commit**

```bash
git add -A
git commit -m "test: update existing tests for Plus/Pro tier rename"
```

---

### Task 12: Post-Deploy — App Store Connect Setup

**No code changes. Manual steps in App Store Connect:**

1. Navigate to App Store Connect > Your App > Subscriptions
2. Create subscription group: **"Sundee Fundee Premium"**
3. Add subscription: **Plus**
   - Product ID: `com.sundeefundee.plus.monthly`
   - Price: $4.99
   - Duration: 1 month
   - Introductory Offer: Free for 2 weeks
4. Add subscription: **Pro**
   - Product ID: `com.sundeefundee.pro.monthly`
   - Price: $9.99
   - Duration: 1 month
   - Introductory Offer: Free for 2 weeks
5. Generate **Offer Codes** for Pro tier (for tester ladies)
   - Subscriptions > Pro > Offer Codes > Create
   - Number of codes: as needed
   - Distribute codes to testers
