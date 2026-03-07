# Subscription Tiers Design

## Overview

Add two-tier subscription model (Plus/Pro) with StoreKit 2, gating AI workout generation by daily limits. Free users retain access to offline-generated and crowdsourced workouts.

## Tiers

| | Free | Plus | Pro |
|--|------|------|-----|
| Product ID | -- | `com.sundeefundee.plus.monthly` | `com.sundeefundee.pro.monthly` |
| Price | $0 | $4.99/mo | $9.99/mo |
| Free Trial | -- | 2 weeks | 2 weeks |
| AI Workouts | 0/day | 1/day | 3/day |
| Offline Generator | Yes | Yes | Yes |
| Crowdsourced Workouts | Yes | Yes | Yes |
| Cycle Tracking | Yes | Yes | Yes |

## Architecture: StoreKit 2 + Local Usage Tracking

- Extend existing `SubscriptionService` to handle two product IDs
- Track daily AI generation count via `GeneratedWorkoutRecord` queries (count by userID + today's date)
- Gate at `QuestionnaireViewModel.generateWorkout()` -- check tier + daily count before calling Gemini
- Free users skip Gemini, go straight to `OfflineWorkoutGenerator`

### SubscriptionTier Enum

```swift
enum SubscriptionTier: String, Sendable {
    case free, plus, pro

    var dailyAILimit: Int {
        switch self {
        case .free: 0
        case .plus: 1
        case .pro: 3
        }
    }
}
```

### Daily Limit Logic

```
if tier == .free -> show paywall
if tier == .plus && todayCount >= 1 -> show paywall (upgrade to Pro)
if tier == .pro && todayCount >= 3 -> show "daily limit reached" alert
```

### Usage Counting

Query existing `GeneratedWorkoutRecord` by userID + startOfDay. No schema changes needed.

## Gating Flow

1. User fills out questionnaire, taps "Generate"
2. `QuestionnaireViewModel` checks `subscriptionService.currentTier`
3. Counts today's generations from SwiftData
4. If over limit -> set published property triggering paywall sheet
5. If free -> route to `OfflineWorkoutGenerator` (no Gemini call)
6. If within limit -> proceed to Gemini

## Paywall UI

- Presented as `.sheet` from questionnaire view
- Art Deco themed (cream/navy/orange)
- Feature comparison table (Free vs Plus vs Pro)
- Two subscription buttons with "2-week free trial" badge
- "Restore Purchases" link
- Dismissible

### Context-Aware Messaging

- Free user at "Generate": "Unlock AI-Powered Workouts"
- Plus user at daily limit: "Need more workouts? Upgrade to Pro"
- Pro user at daily limit: "You've reached today's limit, come back tomorrow" (no paywall)

## Dashboard CTA

Update existing `AIWorkoutCTACard`:
- Free users (post-trial): "Upgrade to unlock AI workouts" -> opens paywall
- Plus/Pro users: Current behavior (generate workout)

## File Changes

### Modified

| File | Change |
|------|--------|
| `Services/SubscriptionService.swift` | Multi-tier, two product IDs, tier resolution, daily limit |
| `Features/AIWorkout/QuestionnaireViewModel.swift` | Gate generation, trigger paywall or offline fallback |
| `Features/AIWorkout/QuestionnaireView.swift` | Add `.sheet` for paywall |
| `Features/Settings/SubscriptionManagementView.swift` | Show Plus/Pro tiers, upgrade paths |
| Dashboard CTA card | Context-aware messaging for free users |

### New

| File | Purpose |
|------|---------|
| `Features/Subscription/PaywallView.swift` | Reusable paywall sheet |
| `Features/Subscription/SubscriptionTier.swift` | Tier enum with daily limits |
| `SundeeFundee.storekit` | StoreKit configuration for local testing |

### Tests

| File | Coverage |
|------|----------|
| `SubscriptionServiceTests.swift` | Tier resolution, daily limits, transactions |
| `QuestionnaireViewModelTests.swift` (update) | Gating: free blocked, plus limited, pro limited |
| `PaywallViewTests.swift` | Static helpers, context messaging |

## Post-Deploy (App Store Connect)

1. Create subscription group "Sundee Fundee Premium"
2. Add Plus ($4.99/mo) and Pro ($9.99/mo) with 2-week introductory offers
3. Generate Offer Codes for testers (Pro tier, free redemption)

## Cost Analysis

At Gemini pricing ($0.50/1M input, $1.50/1M output):
- ~$0.0016 per workout generation
- Plus user at max: ~$0.05/mo API cost vs $4.24 revenue (after Apple 15%)
- Pro user at max: ~$0.14/mo API cost vs $8.49 revenue (after Apple 15%)
