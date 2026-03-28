# Pricing & AI Model Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update subscription pricing from $6.99/$12.99 to $4.99/$9.99 (monthly) and replace Anthropic model references with Cloudflare Workers AI models under "Sundee AI" branding.

**Architecture:** No architectural changes. This is a string/value replacement across 5 files. TDD approach — update tests first to define the new expected values, verify they fail against old code, then update production code to make them pass.

**Tech Stack:** Swift 6, SwiftUI, StoreKit Configuration, Swift Testing

---

### Task 1: Update SubscriptionTier Tests

**Files:**
- Modify: `SundeeFundeTests/SubscriptionTests.swift:626-661`

- [ ] **Step 1: Update subscriptionDescription test assertions**

In the `SubscriptionTierCopyTests` suite, change the `subscriptionDescriptionCopy` test:

```swift
@Test func subscriptionDescriptionCopy() {
    #expect(SubscriptionTier.free.subscriptionDescription == "Core training tools with unlimited on-device AI.")
    #expect(SubscriptionTier.plus.subscriptionDescription == "Sundee AI-powered cloud workouts and custom programming tools.")
    #expect(SubscriptionTier.premium.subscriptionDescription == "Sundee AI Pro coach with persistent memory.")
}
```

- [ ] **Step 2: Update subscriptionDescriptions test in SubscriptionTierNewPropertiesTests**

In the `SubscriptionTierNewPropertiesTests` suite (line 644), change:

```swift
@Test func subscriptionDescriptions() {
    #expect(SubscriptionTier.free.subscriptionDescription == "Core training tools with unlimited on-device AI.")
    #expect(SubscriptionTier.plus.subscriptionDescription == "Sundee AI-powered cloud workouts and custom programming tools.")
    #expect(SubscriptionTier.premium.subscriptionDescription == "Sundee AI Pro coach with persistent memory.")
}
```

- [ ] **Step 3: Update aiModelIdentifier test**

In the `SubscriptionTierNewPropertiesTests` suite (line 650), change:

```swift
@Test func aiModelIdentifier() {
    #expect(SubscriptionTier.free.aiModelIdentifier == "on-device")
    #expect(SubscriptionTier.plus.aiModelIdentifier == "@cf/qwen/qwen3-30b-a3b-fp8")
    #expect(SubscriptionTier.premium.aiModelIdentifier == "@cf/nvidia/nemotron-3-120b-a12b")
}
```

- [ ] **Step 4: Run tests to verify they fail**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/SubscriptionTierCopyTests \
  -only-testing:SundeeFundeTests/SubscriptionTierNewPropertiesTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: FAIL — old production code still returns "Haiku"/"Sonnet"/"haiku"/"sonnet"

- [ ] **Step 5: Commit**

```bash
git add SundeeFundeTests/SubscriptionTests.swift
git commit -m "test: update SubscriptionTier assertions for Sundee AI branding and Cloudflare models"
```

---

### Task 2: Update SubscriptionTier Production Code

**Files:**
- Modify: `SundeeFundee/Domain/Subscription/SubscriptionTier.swift:30-72`

- [ ] **Step 1: Update subscriptionDescription property**

Change lines 35 and 37:

```swift
/// Short descriptive copy used in subscription surfaces.
var subscriptionDescription: String {
    switch self {
    case .free:
        return "Core training tools with unlimited on-device AI."
    case .plus:
        return "Sundee AI-powered cloud workouts and custom programming tools."
    case .premium:
        return "Sundee AI Pro coach with persistent memory."
    }
}
```

- [ ] **Step 2: Update aiModelIdentifier property**

Change the comment on line 66 and values on lines 70-71:

```swift
/// Cloudflare Workers AI model identifier for cloud AI routing. "on-device" for free tier.
var aiModelIdentifier: String {
    switch self {
    case .free:    return "on-device"
    case .plus:    return "@cf/qwen/qwen3-30b-a3b-fp8"
    case .premium: return "@cf/nvidia/nemotron-3-120b-a12b"
    }
}
```

- [ ] **Step 3: Run the SubscriptionTier tests to verify they pass**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/SubscriptionTierCopyTests \
  -only-testing:SundeeFundeTests/SubscriptionTierNewPropertiesTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add SundeeFundee/Domain/Subscription/SubscriptionTier.swift
git commit -m "feat: update SubscriptionTier to Sundee AI branding and Cloudflare model IDs"
```

---

### Task 3: Update PaywallView Tests

**Files:**
- Modify: `SundeeFundeTests/SubscriptionTests.swift:210-262`

- [ ] **Step 1: Update fallback price assertions**

In `PaywallViewStaticTests`, change the `fallbackPricesUpdated` test (line 210):

```swift
@Test func fallbackPricesUpdated() {
    #expect(PaywallView.fallbackPrice(tier: .plus, period: .monthly) == "$4.99")
    #expect(PaywallView.fallbackPrice(tier: .plus, period: .annual) == "$39.99")
    #expect(PaywallView.fallbackPrice(tier: .premium, period: .monthly) == "$9.99")
    #expect(PaywallView.fallbackPrice(tier: .premium, period: .annual) == "$79.99")
    #expect(PaywallView.fallbackPrice(tier: .free, period: .monthly) == "Free")
}
```

- [ ] **Step 2: Update tier highlights assertions**

Change the `tierHighlightsPlusUpdated` test (line 218):

```swift
@Test func tierHighlightsPlusUpdated() {
    let highlights = PaywallView.tierHighlights(for: .plus)
    #expect(highlights.count == 7)
    #expect(highlights.contains("Sundee AI cloud workouts (1/day)"))
    #expect(highlights.contains("Custom program builder"))
    #expect(highlights.contains("Periodization templates"))
}
```

Change the `tierHighlightsPremiumUpdated` test (line 226):

```swift
@Test func tierHighlightsPremiumUpdated() {
    let highlights = PaywallView.tierHighlights(for: .premium)
    #expect(highlights.count == 7)
    #expect(highlights.contains("Everything in Plus"))
    #expect(highlights.contains("Sundee AI Pro cloud workouts (10/day)"))
    #expect(highlights.contains("AI mesocycle plans"))
}
```

- [ ] **Step 3: Update savingsText test to use new prices**

Change the `savingsText` test (line 259):

```swift
@Test func savingsText() {
    let text = PaywallView.savingsText(monthlyPrice: 4.99, annualPrice: 39.99)
    #expect(text.contains("Save"))
}
```

- [ ] **Step 4: Run tests to verify they fail**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/PaywallViewStaticTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: FAIL — old fallback prices and Haiku/Sonnet highlights still in production code

- [ ] **Step 5: Commit**

```bash
git add SundeeFundeTests/SubscriptionTests.swift
git commit -m "test: update PaywallView assertions for new pricing and Sundee AI branding"
```

---

### Task 4: Update PaywallView Production Code

**Files:**
- Modify: `SundeeFundee/Features/Subscription/PaywallView.swift:317-377`

- [ ] **Step 1: Update fallbackPrice**

Change the `fallbackPrice` static method (line 317):

```swift
static func fallbackPrice(tier: SubscriptionTier, period: BillingPeriod) -> String {
    switch (tier, period) {
    case (.plus, .monthly):    return "$4.99"
    case (.plus, .annual):     return "$39.99"
    case (.premium, .monthly): return "$9.99"
    case (.premium, .annual):  return "$79.99"
    default:                   return "Free"
    }
}
```

- [ ] **Step 2: Update tierHighlights**

Change the `tierHighlights` static method (line 327):

```swift
static func tierHighlights(for tier: SubscriptionTier) -> [String] {
    switch tier {
    case .free:
        return []
    case .plus:
        return [
            "Sundee AI cloud workouts (1/day)",
            "Custom program builder",
            "Periodization templates",
            "Advanced analytics dashboard",
            "Full lift & history tracking",
            "Recovery trend insights",
            "Streaks & achievements",
        ]
    case .premium:
        return [
            "Everything in Plus",
            "Sundee AI Pro cloud workouts (10/day)",
            "Persistent AI coach memory",
            "AI mesocycle plans",
            "Plateau detection",
            "Weekly AI training reports",
            "Rehab coaching & data export",
        ]
    }
}
```

- [ ] **Step 3: Update comparisonRows AI Model row**

Change line 365 in the `comparisonRows` static method:

```swift
ComparisonRow(feature: "AI Model", free: "On-device", plus: "Sundee AI", premium: "Sundee AI Pro"),
```

- [ ] **Step 4: Run PaywallView tests to verify they pass**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/PaywallViewStaticTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add SundeeFundee/Features/Subscription/PaywallView.swift
git commit -m "feat: update PaywallView pricing to $4.99/$9.99 and Sundee AI branding"
```

---

### Task 5: Update ManageSubscriptionView Tests and Code

**Files:**
- Modify: `SundeeFundeTests/SubscriptionTests.swift:335-344`
- Modify: `SundeeFundee/Features/Subscription/ManageSubscriptionView.swift:85-91`

- [ ] **Step 1: Update test assertions**

In `ManageSubscriptionViewStaticTests` (line 339), change:

```swift
@Test func tierDescriptions() {
    #expect(ManageSubscriptionView.tierDescription(.free) == "Unlimited on-device AI workouts")
    #expect(ManageSubscriptionView.tierDescription(.plus) == "Sundee AI-powered cloud workouts and programming tools")
    #expect(ManageSubscriptionView.tierDescription(.premium) == "Sundee AI Pro personal coach")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/ManageSubscriptionViewStaticTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: FAIL

- [ ] **Step 3: Update production code**

Change the `tierDescription` static method in `ManageSubscriptionView.swift` (line 85):

```swift
static func tierDescription(_ tier: SubscriptionTier) -> String {
    switch tier {
    case .free:    return "Unlimited on-device AI workouts"
    case .plus:    return "Sundee AI-powered cloud workouts and programming tools"
    case .premium: return "Sundee AI Pro personal coach"
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/ManageSubscriptionViewStaticTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add SundeeFundeTests/SubscriptionTests.swift SundeeFundee/Features/Subscription/ManageSubscriptionView.swift
git commit -m "feat: update ManageSubscriptionView to Sundee AI branding"
```

---

### Task 6: Update StoreKit Configuration

**Files:**
- Modify: `SundeeFundee/Resources/SundeeFundee.storekit`

- [ ] **Step 1: Update Plus product prices and descriptions**

Change the Plus Monthly `displayPrice` (line 78) from `"6.99"` to `"4.99"`.

Change the Plus Monthly description (line 85) from:
```
"Enhanced cloud AI workouts with Haiku, programming tools, and unlimited tracking."
```
to:
```
"Sundee AI cloud workouts, programming tools, and unlimited tracking."
```

Change the Plus Annual `displayPrice` (line 103) from `"54.99"` to `"39.99"`.

Change the Plus Annual description (line 116) from:
```
"Enhanced cloud AI workouts with Haiku, programming tools, and unlimited tracking."
```
to:
```
"Sundee AI cloud workouts, programming tools, and unlimited tracking."
```

- [ ] **Step 2: Update Premium product prices and descriptions**

Change the Premium Monthly `displayPrice` (line 133) from `"12.99"` to `"9.99"`.

Change the Premium Monthly description (line 141) from:
```
"Sonnet-powered personal AI coach with persistent memory, mesocycle plans, and full feature access."
```
to:
```
"Sundee AI Pro personal coach with persistent memory, mesocycle plans, and full feature access."
```

Change the Premium Annual `displayPrice` (line 159) from `"99.99"` to `"79.99"`.

Change the Premium Annual description (line 166) from:
```
"Sonnet-powered personal AI coach with persistent memory, mesocycle plans, and full feature access."
```
to:
```
"Sundee AI Pro personal coach with persistent memory, mesocycle plans, and full feature access."
```

- [ ] **Step 3: Commit**

```bash
git add SundeeFundee/Resources/SundeeFundee.storekit
git commit -m "feat: update StoreKit config pricing to $4.99/$9.99 and Sundee AI descriptions"
```

---

### Task 7: Full Test Suite and Final Verification

**Files:**
- All modified files from Tasks 1-6

- [ ] **Step 1: Run the full test suite**

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

- [ ] **Step 2: Verify no remaining Haiku/Sonnet references in production code**

Run:
```bash
grep -rn "Haiku\|Sonnet\|haiku\|sonnet" SundeeFundee/ --include="*.swift" || echo "No references found"
```
Expected: No references found (StoreKit config is JSON, not Swift, so it won't match — and we already updated it)

- [ ] **Step 3: Verify no remaining old prices in production code**

Run:
```bash
grep -rn '6\.99\|12\.99\|54\.99\|99\.99' SundeeFundee/ --include="*.swift" || echo "No old prices found"
```
Expected: No old prices found

- [ ] **Step 4: Build the project**

Run:
```bash
xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Update TODO.md — check off the two completed items**

In `docs/TODO.md`, change:
```markdown
- [ ] **Update pricing in code** — ...
- [ ] **Switch AI model from Anthropic to Cloudflare Nemotron** — ...
```
to:
```markdown
- [x] **Update pricing in code** — Changed from $6.99/$12.99 to $4.99/$9.99 (monthly), $39.99/$79.99 (annual).
- [x] **Switch AI model from Anthropic to Cloudflare Nemotron** — Replaced Haiku/Sonnet with `@cf/qwen/qwen3-30b-a3b-fp8` (Plus) and `@cf/nvidia/nemotron-3-120b-a12b` (Premium). User-facing branding: "Sundee AI" / "Sundee AI Pro".
```

- [ ] **Step 6: Final commit**

```bash
git add docs/TODO.md
git commit -m "docs: mark pricing and AI model update tasks as complete"
```
