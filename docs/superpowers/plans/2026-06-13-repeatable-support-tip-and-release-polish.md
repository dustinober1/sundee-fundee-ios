# Repeatable Support Tip and Release Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a repeatable $1.99 optional Support the Developer tip in Settings and finish the next-release polish items that make the large v2 feature set easier to find, safer to review, and cleaner in App Store submission.

**Architecture:** Keep purchase logic behind a small StoreKit boundary so Settings UI and unit tests do not depend directly on `Product`. The purchase is a consumable in-app purchase, because the user approved repeatable support tips, and it must not change feature access or app behavior. Release polish stays additive: expose existing capabilities more clearly, tighten loading/error/accessibility states, add widget freshness copy, update release metadata, and verify the complete App Review path without submitting.

**Tech Stack:** Swift 6 strict concurrency, SwiftUI, StoreKit 2, XCTest, Xcode StoreKit configuration, XcodeGen, Fastlane metadata, iOS 18+.

---

## Scope Check

This plan covers one release slice with four related outcomes:

- A repeatable optional support tip in Settings.
- Clear release communication for the v2 feature set.
- UX polish on loading, errors, haptics, and discoverability.
- App Review rehearsal and metadata alignment.

The existing v2 domain work is already present in the tree, including daily decisions, deloads, quick workouts, equipment conversion, station swaps, warmups, rest guidance, data trust, buddy check-ins, and monthly review. This plan does not rebuild those services; it makes them more discoverable and verifies them for release.

## StoreKit Product Contract

Use these exact App Store Connect values:

| Field | Value |
|---|---|
| Product type | Consumable |
| Product ID | `com.sundeefundee.app.support.tip199` |
| Reference name | `Support the Developer Tip 1.99` |
| Display name | `Support the Developer` |
| Description | `An optional tip to support ongoing Sundee Fundee development. It is not required for any feature.` |
| Price | `$1.99` |
| Placement | `Settings -> Support` only |
| Restore purchases | Not shown for this item |

Do not use charity, fundraiser, or medical-benefit language. Use `support` or `tip` language in the app UI and App Review notes.

## File Structure

**Create:**

- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Support/SupportTipProduct.swift` - product ID, copy, pure offer/result models, protocol, and user-facing error mapping.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/SupportTipViewModel.swift` - testable MainActor state machine for loading and purchasing the support tip.
- `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/StoreKit/StoreKitSupportTipStore.swift` - real StoreKit 2 product loading, purchase handling, transaction finishing, and transaction-update listener.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SupportDeveloperSection.swift` - Settings-only SwiftUI section for the optional support tip.
- `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/SupportTipViewModelTests.swift` - state-machine coverage using a mock purchase store.
- `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/SupportTipProductTests.swift` - product contract and copy coverage.
- `SundeeFundeeApp/StoreKit/SundeeFundee.storekit` - local StoreKit configuration for simulator testing.
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Release/ReleaseNotesContent.swift` - in-app release notes content.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/WhatsNewView.swift` - Settings destination for release notes.
- `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReleaseNotesContentTests.swift` - coverage that release notes mention the support tip and current v2 capabilities.

**Modify:**

- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift` - add Support section and What's New navigation; group account/support rows.
- `SundeeFundeeApp/SundeeFundee/App.swift` - start StoreKit transaction-update listener from the real app entry point.
- `SundeeFundeeApp/project.yml` - include StoreKit configuration folder as a project source folder.
- `SundeeFundeeApp/fastlane/metadata/en-US/release_notes.txt` - add support-tip and polish release notes.
- `SundeeFundeeApp/fastlane/metadata/review_information/notes.txt` - update review path and IAP explanation.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Train/TrainHubView.swift` - surface existing in-gym features better.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ProgressHubView.swift` - make monthly review, buddy check-ins, analytics, and export clearer.
- `SundeeFundeeApp/SundeeFundeeWidgets/RecoveryScoreWidget.swift` - add freshness text for stale/no-data recovery snapshots.
- `SundeeFundeeApp/SundeeFundeeWidgets/CyclePhaseWidget.swift` - add freshness text for stale/no-data cycle snapshots.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/AnalyticsView.swift` - replace bare loading spinner.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/BuddyCheckInHistoryView.swift` - replace bare loading spinner and large fixed icon sizing.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/MonthlyReviewDetailView.swift` - replace bare loading spinner.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryScoreCard.swift` - add loading label and preserve Dynamic Type-friendly icon sizing.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleSettingsView.swift` - replace bare saving spinners and raw user-facing errors.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift` - replace raw error messages.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/PainTrackingViewModel.swift` - replace raw error messages.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AnalyticsViewModel.swift` - replace raw error messages.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift` - replace raw user-facing auth/delete errors while keeping raw logs.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ExportViewModel.swift` - replace raw export error message.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/SubstitutionPickerSheet.swift` - replace raw substitution error message.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutDetailView.swift` - replace raw workout error messages.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift` - replace raw workout-save error message.
- `SundeeFundeeApp/SundeeFundeeUITests/SundeeFundeeScreenshotTests.swift` - add a Settings support-path smoke assertion.

---

### Task 1: Add the Pure Support Tip Contract

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Support/SupportTipProduct.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/SupportTipProductTests.swift`

- [ ] **Step 1: Write the failing product-contract tests**

Create `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/SupportTipProductTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

final class SupportTipProductTests: XCTestCase {
    func testProductContractUsesRepeatableSupportTipLanguage() {
        XCTAssertEqual(SupportTipProduct.id, "com.sundeefundee.app.support.tip199")
        XCTAssertEqual(SupportTipProduct.referenceName, "Support the Developer Tip 1.99")
        XCTAssertEqual(SupportTipProduct.displayName, "Support the Developer")
        XCTAssertEqual(
            SupportTipProduct.description,
            "An optional tip to support ongoing Sundee Fundee development. It is not required for any feature."
        )
        XCTAssertTrue(SupportTipProduct.description.localizedCaseInsensitiveContains("optional"))
    }

    func testFailureMessagesAreUserFacing() {
        XCTAssertEqual(
            SupportTipStoreError.productUnavailable.userMessage,
            "Support tips are unavailable right now. Please try again later."
        )
        XCTAssertEqual(
            SupportTipStoreError.unverifiedTransaction.userMessage,
            "The purchase could not be verified. Check your App Store purchase history or try again later."
        )
        XCTAssertEqual(
            SupportTipStoreError.unexpectedProductType.userMessage,
            "Support tips are unavailable right now. Please try again later."
        )
        XCTAssertFalse(SupportTipStoreError.storeKitFailure.userMessage.contains("localizedDescription"))
    }
}
```

- [ ] **Step 2: Run the failing tests**

Run:

```bash
cd SundeeFundee && swift test --filter SupportTipProductTests
```

Expected: compile failure because `SupportTipProduct` and `SupportTipStoreError` do not exist.

- [ ] **Step 3: Add the pure product contract**

Create `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Support/SupportTipProduct.swift`:

```swift
import Foundation

public enum SupportTipProduct {
    public static let id = "com.sundeefundee.app.support.tip199"
    public static let referenceName = "Support the Developer Tip 1.99"
    public static let displayName = "Support the Developer"
    public static let description = "An optional tip to support ongoing Sundee Fundee development. It is not required for any feature."
}

public struct SupportTipOffer: Sendable, Equatable {
    public let id: String
    public let displayName: String
    public let description: String
    public let displayPrice: String

    public init(id: String, displayName: String, description: String, displayPrice: String) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
    }
}

public enum SupportTipPurchaseOutcome: Sendable, Equatable {
    case purchased
    case pending
    case cancelled
    case unavailable
    case unverified
    case failed
}

public enum SupportTipStoreError: Error, Sendable, Equatable {
    case productUnavailable
    case unexpectedProductType
    case unverifiedTransaction
    case storeKitFailure

    public var userMessage: String {
        switch self {
        case .productUnavailable:
            return "Support tips are unavailable right now. Please try again later."
        case .unexpectedProductType:
            return "Support tips are unavailable right now. Please try again later."
        case .unverifiedTransaction:
            return "The purchase could not be verified. Check your App Store purchase history or try again later."
        case .storeKitFailure:
            return "The App Store could not complete the request. Please try again."
        }
    }
}

public protocol SupportTipStoreProtocol: Sendable {
    func loadSupportTip() async throws -> SupportTipOffer
    func purchaseSupportTip() async -> SupportTipPurchaseOutcome
}
```

- [ ] **Step 4: Run tests**

Run:

```bash
cd SundeeFundee && swift test --filter SupportTipProductTests
```

Expected: all `SupportTipProductTests` pass.

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Support/SupportTipProduct.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/SupportTipProductTests.swift
git commit -m "feat(support): define repeatable support tip contract"
```

---

### Task 2: Add the Support Tip View Model

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/SupportTipViewModel.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/SupportTipViewModelTests.swift`

- [ ] **Step 1: Write failing view-model tests**

Create `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/SupportTipViewModelTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

@MainActor
final class SupportTipViewModelTests: XCTestCase {
    func testLoadOfferPublishesPriceAndReadyState() async {
        let store = MockSupportTipStore(
            offer: SupportTipOffer(
                id: SupportTipProduct.id,
                displayName: "Support the Developer",
                description: SupportTipProduct.description,
                displayPrice: "$1.99"
            ),
            purchaseOutcome: .purchased
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.loadOffer()

        XCTAssertEqual(viewModel.offer?.displayPrice, "$1.99")
        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertNil(viewModel.message)
    }

    func testSuccessfulPurchaseShowsThankYouAndAllowsRepeat() async {
        let store = MockSupportTipStore(
            offer: SupportTipOffer(
                id: SupportTipProduct.id,
                displayName: "Support the Developer",
                description: SupportTipProduct.description,
                displayPrice: "$1.99"
            ),
            purchaseOutcome: .purchased
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.purchase()
        await viewModel.purchase()

        XCTAssertEqual(store.purchaseCount, 2)
        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertEqual(viewModel.message, "Thank you for supporting Sundee Fundee.")
    }

    func testPendingPurchaseUsesClearCopy() async {
        let store = MockSupportTipStore(
            offer: nil,
            purchaseOutcome: .pending
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.purchase()

        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertEqual(viewModel.message, "The purchase is pending App Store approval.")
    }

    func testCancelledPurchaseDoesNotShowError() async {
        let store = MockSupportTipStore(
            offer: nil,
            purchaseOutcome: .cancelled
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.purchase()

        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertNil(viewModel.message)
    }

    func testUnavailableOfferShowsUserFacingError() async {
        let store = MockSupportTipStore(
            offer: nil,
            purchaseOutcome: .unavailable,
            loadError: SupportTipStoreError.productUnavailable
        )
        let viewModel = SupportTipViewModel(store: store)

        await viewModel.loadOffer()

        XCTAssertEqual(viewModel.state, .failed)
        XCTAssertEqual(viewModel.message, "Support tips are unavailable right now. Please try again later.")
    }
}

private final class MockSupportTipStore: SupportTipStoreProtocol, @unchecked Sendable {
    private let offer: SupportTipOffer?
    private let purchaseOutcome: SupportTipPurchaseOutcome
    private let loadError: Error?
    private(set) var purchaseCount = 0

    init(
        offer: SupportTipOffer?,
        purchaseOutcome: SupportTipPurchaseOutcome,
        loadError: Error? = nil
    ) {
        self.offer = offer
        self.purchaseOutcome = purchaseOutcome
        self.loadError = loadError
    }

    func loadSupportTip() async throws -> SupportTipOffer {
        if let loadError {
            throw loadError
        }
        guard let offer else {
            throw SupportTipStoreError.productUnavailable
        }
        return offer
    }

    func purchaseSupportTip() async -> SupportTipPurchaseOutcome {
        purchaseCount += 1
        return purchaseOutcome
    }
}
```

- [ ] **Step 2: Run the failing tests**

Run:

```bash
cd SundeeFundee && swift test --filter SupportTipViewModelTests
```

Expected: compile failure because `SupportTipViewModel` does not exist.

- [ ] **Step 3: Add the view model**

Create `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/SupportTipViewModel.swift`:

```swift
import SwiftUI

public enum SupportTipViewState: Sendable, Equatable {
    case idle
    case loading
    case ready
    case purchasing
    case failed
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class SupportTipViewModel: ObservableObject {
    @Published public private(set) var offer: SupportTipOffer?
    @Published public private(set) var state: SupportTipViewState = .idle
    @Published public var message: String?

    private let store: SupportTipStoreProtocol

    public init(store: SupportTipStoreProtocol = StoreKitSupportTipStore()) {
        self.store = store
    }

    public var priceText: String {
        offer?.displayPrice ?? "$1.99"
    }

    public var isPurchaseDisabled: Bool {
        state == .loading || state == .purchasing || offer == nil
    }

    public func loadOffer() async {
        guard state != .loading else { return }
        state = .loading
        message = nil

        do {
            offer = try await store.loadSupportTip()
            state = .ready
        } catch let error as SupportTipStoreError {
            state = .failed
            message = error.userMessage
        } catch {
            state = .failed
            message = SupportTipStoreError.storeKitFailure.userMessage
        }
    }

    public func purchase() async {
        state = .purchasing
        message = nil

        let outcome = await store.purchaseSupportTip()

        switch outcome {
        case .purchased:
            state = .ready
            message = "Thank you for supporting Sundee Fundee."
        case .pending:
            state = .ready
            message = "The purchase is pending App Store approval."
        case .cancelled:
            state = .ready
            message = nil
        case .unavailable:
            state = .failed
            message = SupportTipStoreError.productUnavailable.userMessage
        case .unverified:
            state = .failed
            message = SupportTipStoreError.unverifiedTransaction.userMessage
        case .failed:
            state = .failed
            message = SupportTipStoreError.storeKitFailure.userMessage
        }
    }
}
```

- [ ] **Step 4: Temporarily add a compile shim**

If Task 2 is run before Task 3, add this temporary type at the bottom of `SupportTipViewModel.swift` so tests can compile:

```swift
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct StoreKitSupportTipStore: SupportTipStoreProtocol {
    func loadSupportTip() async throws -> SupportTipOffer {
        throw SupportTipStoreError.productUnavailable
    }

    func purchaseSupportTip() async -> SupportTipPurchaseOutcome {
        .unavailable
    }
}
```

Remove this private shim in Task 3 when the real `StoreKitSupportTipStore` is added.

- [ ] **Step 5: Run tests**

Run:

```bash
cd SundeeFundee && swift test --filter SupportTipViewModelTests
```

Expected: all `SupportTipViewModelTests` pass.

- [ ] **Step 6: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/SupportTipViewModel.swift SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/SupportTipViewModelTests.swift
git commit -m "feat(support): add support tip state model"
```

---

### Task 3: Add the StoreKit 2 Implementation

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/StoreKit/StoreKitSupportTipStore.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/SupportTipViewModel.swift`
- Modify: `SundeeFundeeApp/SundeeFundee/App.swift`

- [ ] **Step 1: Add the real StoreKit store**

Create `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/StoreKit/StoreKitSupportTipStore.swift`:

```swift
import Foundation
import StoreKit
import os.log

private let supportTipLogger = Logger(subsystem: "com.sundeefundee.app", category: "SupportTip")

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor StoreKitSupportTipStore: SupportTipStoreProtocol {
    private var cachedProduct: Product?

    public init() {}

    public func loadSupportTip() async throws -> SupportTipOffer {
        let product = try await supportProduct()
        return SupportTipOffer(
            id: product.id,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice
        )
    }

    public func purchaseSupportTip() async -> SupportTipPurchaseOutcome {
        do {
            let product = try await supportProduct()
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                return await handleTransaction(verificationResult)
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed
            }
        } catch let error as SupportTipStoreError {
            supportTipLogger.error("Support tip purchase failed: \(String(describing: error))")
            switch error {
            case .productUnavailable:
                return .unavailable
            case .unexpectedProductType:
                return .failed
            case .unverifiedTransaction:
                return .unverified
            case .storeKitFailure:
                return .failed
            }
        } catch {
            supportTipLogger.error("Support tip purchase failed: \(String(describing: error))")
            return .failed
        }
    }

    public func handleTransactionUpdate(_ verificationResult: VerificationResult<Transaction>) async {
        _ = await handleTransaction(verificationResult)
    }

    private func supportProduct() async throws -> Product {
        if let cachedProduct {
            return cachedProduct
        }

        let products = try await Product.products(for: [SupportTipProduct.id])
        guard let product = products.first else {
            throw SupportTipStoreError.productUnavailable
        }
        guard product.type == .consumable else {
            throw SupportTipStoreError.unexpectedProductType
        }

        cachedProduct = product
        return product
    }

    private func handleTransaction(_ verificationResult: VerificationResult<Transaction>) async -> SupportTipPurchaseOutcome {
        switch verificationResult {
        case .verified(let transaction):
            guard transaction.productID == SupportTipProduct.id else {
                await transaction.finish()
                return .failed
            }
            await transaction.finish()
            return .purchased
        case .unverified:
            return .unverified
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class SupportTipTransactionListener: ObservableObject {
    private let store: StoreKitSupportTipStore
    private var updatesTask: Task<Void, Never>?

    public init(store: StoreKitSupportTipStore = StoreKitSupportTipStore()) {
        self.store = store
    }

    public func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [store] in
            for await verificationResult in Transaction.updates {
                await store.handleTransactionUpdate(verificationResult)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }
}
```

- [ ] **Step 2: Remove the temporary shim**

If Task 2 added the private `StoreKitSupportTipStore` shim in `SupportTipViewModel.swift`, delete it. The default initializer should now resolve to the public StoreKit implementation.

- [ ] **Step 3: Start the transaction listener in the app entry point**

Modify `SundeeFundeeApp/SundeeFundee/App.swift`.

Add this state object to `SundeeFundeeMain`:

```swift
@StateObject private var supportTipTransactionListener = SupportTipTransactionListener()
```

Update the existing root `.task` block to start the listener before screenshot seeding:

```swift
.task {
    supportTipTransactionListener.start()
    if Self.isScreenshotMode {
        await ScreenshotSeeder.seed()
        authViewModel.isGuest = true
        authViewModel.userID = AuthViewModel.guestUserID
        authViewModel.userName = "Sarah"
        authViewModel.isAuthenticated = true
        authViewModel.needsOnboarding = false
    }
}
```

- [ ] **Step 4: Verify compile and tests**

Run:

```bash
cd SundeeFundee && swift test --filter SupportTip
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: support-tip tests pass and the app builds.

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DataLayer/StoreKit/StoreKitSupportTipStore.swift SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/SupportTipViewModel.swift SundeeFundeeApp/SundeeFundee/App.swift
git commit -m "feat(support): handle repeatable StoreKit tips"
```

---

### Task 4: Add Settings Support UI

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SupportDeveloperSection.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift`
- Modify: `SundeeFundeeApp/SundeeFundeeUITests/SundeeFundeeScreenshotTests.swift`

- [ ] **Step 1: Add the Settings section view**

Create `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SupportDeveloperSection.swift`:

```swift
import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct SupportDeveloperSection: View {
    @StateObject private var viewModel: SupportTipViewModel

    public init(viewModel: SupportTipViewModel = SupportTipViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Section("Support") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Label("Support the Developer", systemImage: "heart.circle")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Text.primary)

                Text("Optional tip. All features stay free.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, AppTheme.Spacing.xs)

            Button {
                Task {
                    await viewModel.purchase()
                }
            } label: {
                HStack {
                    Text("Send \(viewModel.priceText) Tip")
                    Spacer()
                    if viewModel.state == .purchasing {
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isPurchaseDisabled)
            .accessibilityHint("Sends an optional repeatable tip. It is not required for any feature.")

            if let message = viewModel.message {
                Text(message)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(viewModel.state == .failed ? AppTheme.Semantic.error : AppTheme.Text.secondary)
            }
        }
        .task {
            await viewModel.loadOffer()
        }
    }
}
```

- [ ] **Step 2: Add the section to Settings**

Modify `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift`.

Place the support section after `Privacy` and before diagnostics/account:

```swift
SupportDeveloperSection()
```

The resulting high-level Settings order should be Training, Privacy, Support, Diagnostics when present, then Account.

- [ ] **Step 3: Add a UI smoke assertion**

Modify `SundeeFundeeApp/SundeeFundeeUITests/SundeeFundeeScreenshotTests.swift` inside `captureDataTrustCenter()` after Settings opens:

```swift
let supportDeveloper = app.staticTexts["Support the Developer"].firstMatch
XCTAssertTrue(
    scrollToElement(supportDeveloper, in: app.tables.firstMatch),
    "Missing Support the Developer row in Settings"
)
```

- [ ] **Step 4: Verify**

Run:

```bash
cd SundeeFundee && swift test --filter SupportTip
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests and build pass.

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SupportDeveloperSection.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift SundeeFundeeApp/SundeeFundeeUITests/SundeeFundeeScreenshotTests.swift
git commit -m "feat(settings): add optional developer support tip"
```

---

### Task 5: Add StoreKit Test Configuration and App Store Connect Setup

**Files:**

- Create: `SundeeFundeeApp/StoreKit/SundeeFundee.storekit`
- Modify: `SundeeFundeeApp/project.yml`

- [ ] **Step 1: Create the StoreKit configuration**

Create `SundeeFundeeApp/StoreKit/SundeeFundee.storekit` with Xcode's StoreKit Configuration editor using these values:

```text
Type: Consumable
Reference Name: Support the Developer Tip 1.99
Product ID: com.sundeefundee.app.support.tip199
Display Name: Support the Developer
Description: An optional tip to support ongoing Sundee Fundee development. It is not required for any feature.
Price: USD 1.99
Family Sharing: Disabled
```

After saving, inspect the file with:

```bash
plutil -p SundeeFundeeApp/StoreKit/SundeeFundee.storekit
```

Expected: the output includes `com.sundeefundee.app.support.tip199` and `Consumable`.

- [ ] **Step 2: Include the StoreKit folder in the project**

Add this to `SundeeFundeeApp/project.yml` under the `SundeeFundee` target `sources` list:

```yaml
      - path: StoreKit
        type: folder
```

Run:

```bash
cd SundeeFundeeApp && xcodegen generate
```

Verify the project references the file:

```bash
rg -n "SundeeFundee.storekit|StoreKit" SundeeFundee.xcodeproj
```

Expected: at least one match for `SundeeFundee.storekit` or `StoreKit`.

- [ ] **Step 3: Configure App Store Connect**

In App Store Connect, create this in-app purchase:

```text
Product type: Consumable
Reference name: Support the Developer Tip 1.99
Product ID: com.sundeefundee.app.support.tip199
Price: USD 1.99
Display name: Support the Developer
Description: An optional tip to support ongoing Sundee Fundee development. It is not required for any feature.
Review screenshot: Settings screen showing the Support section and Send $1.99 Tip button
```

Submit the in-app purchase with the next app version, not separately.

- [ ] **Step 4: Simulator-check the StoreKit flow**

In Xcode, edit the SundeeFundee scheme and set StoreKit Configuration to:

```text
SundeeFundeeApp/StoreKit/SundeeFundee.storekit
```

Run the app in a simulator, then verify:

```text
Settings -> Support -> Send $1.99 Tip
```

Expected:

- StoreKit purchase sheet appears.
- Completing the purchase shows `Thank you for supporting Sundee Fundee.`
- Tapping again starts a second purchase.
- Feature access stays unchanged after either purchase.

- [ ] **Step 5: Commit**

```bash
git add SundeeFundeeApp/StoreKit/SundeeFundee.storekit SundeeFundeeApp/project.yml
git commit -m "test(storekit): add support tip configuration"
```

---

### Task 6: Add What's New and Metadata Updates

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Release/ReleaseNotesContent.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/WhatsNewView.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReleaseNotesContentTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift`
- Modify: `SundeeFundeeApp/fastlane/metadata/en-US/release_notes.txt`
- Modify: `SundeeFundeeApp/fastlane/metadata/review_information/notes.txt`

- [ ] **Step 1: Write failing release-note tests**

Create `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReleaseNotesContentTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

final class ReleaseNotesContentTests: XCTestCase {
    func testCurrentReleaseNotesMentionSupportTipAndV2Surfaces() {
        let text = ReleaseNotesContent.current.items.map(\.body).joined(separator: " ")

        XCTAssertTrue(text.contains("Support the Developer"))
        XCTAssertTrue(text.contains("Best Next 20 Min"))
        XCTAssertTrue(text.contains("Data Trust Center"))
        XCTAssertTrue(text.contains("Monthly Review"))
        XCTAssertFalse(text.contains("NEW IN 1.4"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("fundraiser"))
    }
}
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
cd SundeeFundee && swift test --filter ReleaseNotesContentTests
```

Expected: compile failure because `ReleaseNotesContent` does not exist.

- [ ] **Step 3: Add release notes content**

Create `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Release/ReleaseNotesContent.swift`:

```swift
import Foundation

public struct ReleaseNoteItem: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let body: String

    public init(id: String, title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}

public struct ReleaseNotes: Sendable, Equatable {
    public let title: String
    public let items: [ReleaseNoteItem]

    public init(title: String, items: [ReleaseNoteItem]) {
        self.title = title
        self.items = items
    }
}

public enum ReleaseNotesContent {
    public static let current = ReleaseNotes(
        title: "What's New",
        items: [
            ReleaseNoteItem(
                id: "today",
                title: "Clearer daily guidance",
                body: "Today now explains whether to train, modify, or recover with cycle, recovery, and pain context."
            ),
            ReleaseNoteItem(
                id: "gym",
                title: "Better in-gym tools",
                body: "Best Next 20 Min, equipment conversion, warmups, station swaps, technique cues, and rest guidance are easier to find."
            ),
            ReleaseNoteItem(
                id: "trust",
                title: "Privacy and trust",
                body: "Data Trust Center, share privacy controls, sync status, export, and delete-account actions are grouped more clearly."
            ),
            ReleaseNoteItem(
                id: "reflection",
                title: "More progress context",
                body: "Monthly Review, buddy check-ins, cycle-aware progress, symptom trends, and return-to-lifting ramps help explain longer patterns."
            ),
            ReleaseNoteItem(
                id: "support",
                title: "Optional support",
                body: "Support the Developer is now available in Settings as a repeatable $1.99 tip. It is not required for any feature."
            )
        ]
    )
}
```

- [ ] **Step 4: Add the What's New view**

Create `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/WhatsNewView.swift`:

```swift
import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WhatsNewView: View {
    private let notes = ReleaseNotesContent.current

    public init() {}

    public var body: some View {
        List {
            Section {
                ForEach(notes.items) { item in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(item.title)
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Text.primary)
                        Text(item.body)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
            }
        }
        .navigationTitle(notes.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
```

- [ ] **Step 5: Add the Settings link**

Modify `SettingsView.swift` inside `Section("Account")`, immediately above `LabeledContent("Version")`:

```swift
NavigationLink {
    WhatsNewView()
} label: {
    Label("What's New", systemImage: "sparkles")
}
```

- [ ] **Step 6: Update release notes metadata**

Replace `SundeeFundeeApp/fastlane/metadata/en-US/release_notes.txt` with concise release notes:

```text
What's New:

- Clearer Today guidance with daily train, modify, or recover recommendations.
- Better in-gym tools: Best Next 20 Min, equipment conversion, warmups, station swaps, technique cues, and smarter rest guidance.
- More context for progress: Monthly Review, cycle-aware trends, symptom patterns, buddy check-ins, and return-to-lifting ramps.
- Privacy and trust polish: Data Trust Center, share privacy defaults, sync status, expanded export, and clearer account deletion.
- Optional Support the Developer tip in Settings. It is repeatable, costs $1.99, and does not change feature access.

All core features remain free.
```

- [ ] **Step 7: Update App Review notes**

Edit `SundeeFundeeApp/fastlane/metadata/review_information/notes.txt`.

Replace the stale `NEW IN 1.4` and `All features are free. There are no in-app purchases.` sections with:

```text
NEW IN THIS RELEASE:
- Today tab: daily train / modify / recover decision, quick workouts, recovery explanations, deload guidance, and missed-workout reshuffling.
- Train tab: Coach Plan, Build Your Own, workout history, programs, equipment conversion, warmups, technique cues, station-taken swaps, and smart rest guidance.
- Cycle tab: cycle confidence, symptom check-ins, pain tracking, and recovery context.
- Progress tab: Monthly Review, analytics, maxes, benchmarks, challenges, buddy check-ins, and export.
- Settings: Data Trust Center, share privacy defaults, reminders, What's New, account management, and optional developer support.

IN-APP PURCHASE:
- The app has one optional consumable in-app purchase in Settings -> Support: "Support the Developer" for $1.99.
- It is a repeatable tip for ongoing development.
- It is not required for features, content, access, badges, account status, or app behavior.
- All training features remain free for guest and signed-in users.
```

Keep the existing Sign In, HealthKit, and Data & Privacy sections.

- [ ] **Step 8: Verify**

Run:

```bash
cd SundeeFundee && swift test --filter ReleaseNotesContentTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: release-note tests pass and the app builds.

- [ ] **Step 9: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Release/ReleaseNotesContent.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/WhatsNewView.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReleaseNotesContentTests.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift SundeeFundeeApp/fastlane/metadata/en-US/release_notes.txt SundeeFundeeApp/fastlane/metadata/review_information/notes.txt
git commit -m "docs(release): update whats new and review notes"
```

---

### Task 7: Improve Feature Discoverability in Train and Progress

**Files:**

- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Train/TrainHubView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ProgressHubView.swift`

- [ ] **Step 1: Add Train entry points for existing in-gym capabilities**

Modify `TrainHubView.swift`:

Add state:

```swift
@State private var quickWorkout: Workout?
```

Add this button at the top of `Section("Start")`:

```swift
Button {
    quickWorkout = QuickWorkoutBuilder.build(
        request: QuickWorkoutRequest(
            timeMinutes: 20,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .fullGym,
            todayDecisionKind: .modify,
            recoveryScoreTotal: nil,
            painLogs: []
        )
    ).workout
} label: {
    Label("Best Next 20 Min", systemImage: "timer")
}
```

Add this full-screen cover after the existing covers:

```swift
.fullScreenCover(item: $quickWorkout) { workout in
    ActiveWorkoutView(
        viewModel: ActiveWorkoutSessionViewModel(workout: workout)
    )
}
```

`Workout` already conforms to `Identifiable`, so the item binding is valid.

- [ ] **Step 2: Add explanatory row copy without adding marketing clutter**

In `Section("Continue")`, add a short supporting row below Programs:

```swift
VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
    Text("During a workout")
        .font(AppTheme.Typography.labelMedium)
        .foregroundColor(AppTheme.Text.primary)
    Text("Use workout options for equipment conversion, station swaps, warmups, technique cues, and rest guidance.")
        .font(AppTheme.Typography.bodySmall)
        .foregroundColor(AppTheme.Text.secondary)
        .fixedSize(horizontal: false, vertical: true)
}
```

- [ ] **Step 3: Clarify Progress labels**

Modify `ProgressHubView.swift` labels:

```swift
Label("This Month", systemImage: "calendar.badge.clock")
```

to:

```swift
Label("Monthly Review", systemImage: "calendar.badge.clock")
```

Change:

```swift
Label("Export", systemImage: "square.and.arrow.up")
```

to:

```swift
Label("Export My Data", systemImage: "square.and.arrow.up")
```

- [ ] **Step 4: Verify**

Run:

```bash
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: app builds.

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Train/TrainHubView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ProgressHubView.swift
git commit -m "feat(train): surface in-gym tools"
```

---

### Task 8: Polish Loading, Errors, Haptics, and Accessibility

**Files:**

- Modify the loading/error/accessibility files listed in the File Structure section.

- [ ] **Step 1: Replace bare loading spinners**

Apply these exact replacements:

| File | Replace | With |
|---|---|---|
| `AnalyticsView.swift` | `ProgressView()` | `ProgressView("Loading analytics")` |
| `BuddyCheckInHistoryView.swift` | `ProgressView()` | `ProgressView("Loading buddy check-ins")` |
| `MonthlyReviewDetailView.swift` | `ProgressView()` | `ProgressView("Loading monthly review")` |
| `RecoveryScoreCard.swift` | `ProgressView()` | `ProgressView("Loading recovery score")` |
| `ChallengesView.swift` | bare loading `ProgressView()` | `ProgressView("Loading challenges")` |

- [ ] **Step 2: Replace raw user-facing errors**

Use these replacements while keeping existing logger calls:

```swift
errorMessage = "We couldn't load benchmark results. Check your connection and try again."
errorMessage = "We couldn't save your benchmark result. Check your connection and try again."
errorMessage = "We couldn't load analytics. Check your connection and try again."
errorMessage = "We couldn't load pain logs. Check your connection and try again."
errorMessage = "We couldn't save your pain log. Check your connection and try again."
errorMessage = "We couldn't load injuries. Check your connection and try again."
errorMessage = "We couldn't save your injury. Check your connection and try again."
errorMessage = "We couldn't generate your export file. Please try again."
errorMessage = "We couldn't save your workout. Check your connection and try again."
errorMessage = "We couldn't load that workout. Check your connection and try again."
errorMessage = "We couldn't update that workout. Check your connection and try again."
errorMessage = "We couldn't complete that workout. Check your connection and try again."
errorMessage = "We couldn't find alternatives. Please try again."
errorMessage = "Sign in failed. Please try again."
errorMessage = "We couldn't delete your account. Check your connection and try again."
```

Do not display `error.localizedDescription` directly in any user-facing `errorMessage`.

- [ ] **Step 3: Add haptics to support tip success**

In `SupportDeveloperSection.swift`, after a purchase completes successfully through the view model, add success feedback by checking the message after purchase:

```swift
await viewModel.purchase()
if viewModel.message == "Thank you for supporting Sundee Fundee." {
    HapticFeedback.success()
}
```

- [ ] **Step 4: Replace fixed large icon fonts where touched**

When editing files in this task, replace fixed semantic-compatible icon calls such as:

```swift
.font(.system(.largeTitle))
```

with semantic Dynamic Type-friendly styling where the icon is decorative:

```swift
.font(.largeTitle)
.accessibilityHidden(true)
```

Do not alter numeric workout timer fonts that intentionally use monospaced display sizing.

- [ ] **Step 5: Verify no raw user-facing error assignments remain in touched files**

Run:

```bash
rg -n "errorMessage = .*localizedDescription|loadError = error.localizedDescription|Text\\(error.localizedDescription" SundeeFundee/Sources/SundeeFundeeKit/UI
```

Expected: no matches in files touched by this task.

- [ ] **Step 6: Run tests and build**

Run:

```bash
cd SundeeFundee && swift test
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: package tests pass and app builds.

- [ ] **Step 7: Commit**

Stage only the files changed for this task:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/AnalyticsView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/BuddyCheckInHistoryView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/MonthlyReviewDetailView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryScoreCard.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Challenges/ChallengesView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleSettingsView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/PainTrackingViewModel.swift SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AnalyticsViewModel.swift SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ExportViewModel.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/SubstitutionPickerSheet.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutDetailView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SupportDeveloperSection.swift
git commit -m "fix(ui): polish loading errors and feedback"
```

---

### Task 9: Add Widget Freshness Copy

**Files:**

- Modify: `SundeeFundeeApp/SundeeFundeeWidgets/RecoveryScoreWidget.swift`
- Modify: `SundeeFundeeApp/SundeeFundeeWidgets/CyclePhaseWidget.swift`
- Modify: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/SharedSnapshotStoreTests.swift`

- [ ] **Step 1: Add freshness helpers to widget files**

In both widget files, add this private helper near the view helpers:

```swift
private func freshnessText(capturedAt: Date?) -> String {
    guard let capturedAt else { return "Open app to update" }
    let hours = Calendar.current.dateComponents([.hour], from: capturedAt, to: Date()).hour ?? 0
    if hours >= 24 { return "Open app to refresh" }
    return "Updated \(capturedAt.formatted(.relative(presentation: .numeric)))"
}
```

- [ ] **Step 2: Show freshness in Recovery widget**

In `RecoveryScoreWidgetEntryView.systemMedium`, replace:

```swift
Text(snapshot.capturedAt, style: .relative)
```

with:

```swift
Text(freshnessText(capturedAt: snapshot.capturedAt))
```

In `systemSmall`, add this below `Text(verdictText)`:

```swift
Text(freshnessText(capturedAt: entry.snapshot?.capturedAt))
    .font(.caption2)
    .foregroundStyle(.secondary)
    .lineLimit(1)
```

- [ ] **Step 3: Show freshness in Cycle widget**

In `CyclePhaseWidgetEntryView.systemSmall`, add this before `Spacer()`:

```swift
Text(freshnessText(capturedAt: entry.snapshot?.capturedAt))
    .font(.caption2)
    .foregroundStyle(.secondary)
    .lineLimit(1)
```

- [ ] **Step 4: Verify**

Run:

```bash
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: app and widgets build.

- [ ] **Step 5: Commit**

```bash
git add SundeeFundeeApp/SundeeFundeeWidgets/RecoveryScoreWidget.swift SundeeFundeeApp/SundeeFundeeWidgets/CyclePhaseWidget.swift
git commit -m "fix(widgets): show snapshot freshness"
```

---

### Task 10: Final Release Verification Without Submission

**Files:**

- No planned file changes. This task proves the release branch state.

- [ ] **Step 1: Regenerate the Xcode project**

Run:

```bash
cd SundeeFundeeApp && xcodegen generate
```

Expected: project generation succeeds.

- [ ] **Step 2: Run package tests**

Run:

```bash
cd SundeeFundee && swift test
```

Expected: all package tests pass.

- [ ] **Step 3: Build the app**

Run:

```bash
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: build succeeds.

- [ ] **Step 4: Run UI smoke tests**

Run:

```bash
cd SundeeFundeeApp && xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeeUITests/SundeeFundeeScreenshotTests/testAppStoreScreenshots
```

Expected: UI test passes or fails only on known screenshot timing. If it fails, capture the failing element and fix the relevant accessibility label or navigation path.

- [ ] **Step 5: Manual App Review rehearsal**

On a simulator with StoreKit configuration enabled, verify this exact path:

```text
Launch -> Continue as Guest -> complete onboarding if shown -> Today -> Settings -> Support -> Send $1.99 Tip
```

Expected:

- StoreKit sheet appears for `Support the Developer`.
- Purchase completes and thank-you message appears.
- Tapping again starts another purchase.
- No feature gates appear anywhere.
- HealthKit denial does not block core app usage.
- Export still works from Progress and Data Trust Center.
- Delete account confirmation still appears from Settings and Data Trust Center.

- [ ] **Step 6: Verify metadata references**

Run:

```bash
rg -n "There are no in-app purchases|NEW IN 1.4|charity|fundraiser" SundeeFundeeApp/fastlane SundeeFundee/Sources/SundeeFundeeKit
```

Expected: no matches.

Run:

```bash
rg -n "Support the Developer|support.tip199|optional consumable" SundeeFundeeApp/fastlane SundeeFundee/Sources/SundeeFundeeKit
```

Expected: matches in Settings/support code and App Review metadata.

- [ ] **Step 7: Confirm no verification fixes are pending**

Run:

```bash
git status --short
```

Expected: no unstaged or staged source changes from verification. If this command reports changes, stop this task, inspect the changed files, and create a separate fix task before continuing release verification.

- [ ] **Step 8: Stop before App Store submission**

Do not run `bundle exec fastlane release`, `asc review submit`, upload, or submit for review. This repo's instruction is explicit: never submit the app for App Store review unless the user explicitly asks.

---

## Self-Review Checklist

- The support tip is repeatable because it is a consumable in-app purchase.
- The support tip is Settings-only and does not change feature access.
- The UI uses support/tip language, not charity/fundraiser language.
- App Review notes disclose the in-app purchase and explain that all features remain free.
- Release notes no longer claim there are no in-app purchases.
- Existing v2 features are surfaced without rebuilding existing domain services.
- Verification stops before upload or App Store review submission.
