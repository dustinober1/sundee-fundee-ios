# Feature Research

**Domain:** Free app launch -- paywall removal + App Store submission for a cycle-aware strength training iOS app
**Researched:** 2026-04-08
**Confidence:** HIGH

## Executive Summary

The paywall removal involves six categories of work: (1) removing subscription gating from all UI views, (2) removing subscription infrastructure code, (3) updating tests, (4) App Store Connect configuration, (5) App Store listing assets, and (6) a polish/audit pass. The paywall is deeply embedded -- 33 files reference subscription concepts, with gate logic concentrated in seven view/view model files and the `SubscriptionTier` enum serving as the central gatekeeper via capability flags like `hasAIBuilder`, `hasExportShare`, etc.

## Feature Landscape

### Table Stakes (Users and App Review Expect These)

Features required for a successful free app launch. Missing any of these causes rejection or a bad first impression.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Remove all subscription UI** | Dead-end paywalls in a free app confuse users and Apple reviewers will reject | MEDIUM | Remove SubscriptionView, upgrade prompts in Dashboard, lock icons in Analytics/Export. 7 view files affected |
| **Remove StoreKit 2 code** | Dead IAP code can trigger App Review questions about missing subscription management | MEDIUM | Delete StoreKitClient, SubscriptionClientProtocol, SubscriptionClientFactory, SubscriptionError, SubscriptionTier, MockSubscriptionClient. 6 files in Subscription/ directory |
| **Remove StoreKit import from App.swift** | App entry point still initializes StoreKitClient and starts transaction listener | LOW | Lines 13-17 of App.swift need cleanup |
| **Remove "Cleared for Sale" from App Store Connect** | Active subscriptions will auto-renew if not disabled | LOW | Must be done in App Store Connect UI, not code. Set all subscription products to not cleared for sale |
| **Privacy Policy URL** | Required for all apps, especially health/fitness. Apple rejects without it | LOW | Must be a real, hosted URL. Already declared in PrivacyInfo.xcprivacy for HealthKit and fitness data |
| **Support URL** | Required field in App Store Connect. Reviewers check it | LOW | Must be a reachable URL -- a simple webpage or GitHub issues page |
| **App description** | Required. First 3 lines are visible before "More" -- they must sell the app | LOW | 4000 char max. Emphasize "free" and "cycle-aware strength training" positioning |
| **Keywords** | Required. 100 char max, comma-separated. Drives App Store search discovery | LOW | Include: "women,strength,cycle,workout,period,training,barbell,CrossFit,benchmarks" |
| **Screenshots (required sizes)** | Required for all supported device sizes. Minimum 3 per size | MEDIUM | iPhone 6.7" (1290x2796) and iPhone 6.5" (1284x2778) at minimum. ScreenshotSeeder already exists |
| **App icon** | 1024x1024, no alpha channel, no rounded corners | LOW | Already configured per CLAUDE.md. Verify in project.yml |
| **Age rating questionnaire** | Required. Health/fitness apps get scrutinized for medical claims | LOW | Declare "FREQUENT_OR_INTENSE" for healthOrWellnessTopics. Avoid medical treatment claims |
| **App review contact info** | Required: first name, last name, email, phone | LOW | Must be real contact info for the review team |
| **Content rights declaration** | Required. App uses original content | LOW | Declare DOES_NOT_USE_THIRD_PARTY_CONTENT |
| **Guest mode still works** | Free app must work without sign-in. Guest mode bypasses CloudKit | LOW | Already implemented. Verify no subscription gates block guest users |
| **No crashes on launch** | Obvious but critical. Reviewers test on real devices | LOW | Full QA pass needed on physical device or simulator |

### Differentiators (Competitive Advantage for App Store)

Features that make the app stand out in the Health & Fitness category. Not expected but drive downloads and ratings.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **"100% Free" positioning** | Rare in fitness apps. Most competitors charge $10-30/mo. This is a strong differentiator in the listing | LOW | Emphasize in subtitle, description, and promotional text. No hidden paywalls |
| **App Store preview video** | 15-30 second video showing app in action. Apps with video get more downloads | HIGH | Requires screen recording of simulator or device. Must show cycle-aware workout flow |
| **Subtitle highlighting uniqueness** | "Cycle-Aware Strength Training" in 30 chars tells users exactly what this is | LOW | App Store subtitle is prime real estate. Currently undefined |
| **Onboarding flow quality** | First-time user experience determines whether someone keeps the app. Smooth onboarding = better retention | MEDIUM | OnboardingView already exists. Audit for friction: too many steps, unclear value prop |
| **Accessibility support** | VoiceOver, Dynamic Type, contrast. Apple rewards accessible apps in featuring | MEDIUM | Audit all views for accessibility labels, trait overrides, and Dynamic Type support |
| **Art Deco visual identity** | Distinctive design stands out in screenshots. Most fitness apps look identical | LOW | Already built. Leverage in screenshots and preview video |
| **Screenshot storytelling** | Screenshots that show a narrative ("Track your cycle", "Get smart workouts", "See progress") rather than raw screens | MEDIUM | Use ScreenshotSeeder utility. 3-5 screenshots showing key flows per device size |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good for this milestone but create problems or scope creep.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Tip jar / one-time IAP** | "If the app is free, at least let people pay" | Adds StoreKit complexity back, requires IAP configuration in App Store Connect, extends review scope | Defer monetization to a future milestone entirely |
| **Ad-supported free model** | "Free app needs revenue" | Requires ad SDK (privacy manifest implications, App Tracking Transparency), degrades UX, extends review scope | Ship free with no ads. Monetization deferred to v2 |
| **Migration messaging for paid users** | "Tell existing subscribers the app is free" | There are no existing paying users -- app has never launched on the App Store. Pure web-to-native transition | No migration messaging needed. This is a first launch |
| **In-app announcement banner** | "Announce that everything is now free" | App has never been paid on iOS. Banner would confuse new users | Skip announcement. Free is the default state |
| **Comprehensive accessibility audit** | "Make it perfect before shipping" | Full accessibility audit is a multi-week effort. Not a launch blocker | Ship with basic accessibility. Schedule full audit for v1.2 |
| **Localization** | "Reach global audience" | Adds translation cost, QA complexity, and App Store Connect configuration for multiple locales | Ship English-only. Add locales based on demand |
| **iPad-optimized layout** | "Support all devices" | iPad requires separate screenshot sizes (2048x2732), layout testing, and potentially different navigation | Ship iPhone-only. iPad runs iPhone apps via compatibility mode |

## Feature Dependencies

```
Remove SubscriptionTier enum
    -> Remove all UI gates (Dashboard, Analytics, Export, Settings)
           -> Remove SubscriptionView
           -> Remove SubscriptionViewModel
    -> Remove SubscriptionClientFactory
           -> Remove StoreKitClient
           -> Remove MockSubscriptionClient
           -> Remove SubscriptionClientProtocol
    -> Remove SubscriptionError
    -> Remove StoreKit import from App.swift
    -> Remove Subscription/ from Package.swift targets

Remove subscription UI gates
    -> All features unlocked by default
           -> ExportView: remove upgradeSection, show dataCategoriesSection always
           -> DashboardView: remove upgradePrompts, coachingInsightsCard always visible
           -> AnalyticsView: remove CycleCorrelationChart gating, show always
           -> PainTrackingView: smart substitutions always available
           -> SettingsView: remove membership section entirely
           -> CoachContext: always use premium-tier features
           -> ExportViewModel: canExport always true

Remove StoreKit subscription products
    -> App Store Connect: set "Cleared for Sale" = No for all products
    -> Existing paid users: none (app never launched with subscriptions)

App Store submission
    -> Paywall removal complete (all code changes)
    -> QA pass complete (no crashes, no dead ends)
    -> Metadata ready (description, keywords, screenshots, age rating)
    -> Privacy manifest verified (PrivacyInfo.xcprivacy)
    -> Build archived and uploaded
```

### Dependency Notes

- **Remove SubscriptionTier before removing UI gates:** The `SubscriptionTier` enum defines all capability flags (`hasAIBuilder`, `hasExportShare`, etc.). Two approaches: (A) remove the enum entirely and hardcode everything to enabled, or (B) keep the enum but collapse it to a single "full access" state. Approach A is cleaner long-term but requires more file changes. Approach B is safer as a middle step.
- **Recommend Approach A (full removal):** Since the app has never launched with subscriptions, there are no existing subscribers to handle. Clean removal avoids dead code. Keep `SubscriptionTier` references in tests only during the transition, then remove those too.
- **Domain layer depends on SubscriptionTier:** `CoachContext` accepts a `tier` parameter. After removal, always pass `.premium`-equivalent (all features enabled) or refactor to remove the parameter.
- **DataLayer does NOT depend on subscriptions:** CloudKit, LocalDataClient, and SyncQueue have no subscription references. Safe to leave untouched.
- **SettingsView membership section conflicts with free app:** The entire "Membership" navigation link and `SubscriptionView` sheet must be removed, not just hidden.

## MVP Definition

### Launch With (v1.1 -- Free App Launch)

Minimum viable product -- what is needed to ship a 100% free app to the App Store.

- [ ] **Remove all subscription code** -- Delete `SundeeFundee/Sources/SundeeFundeeKit/Subscription/` directory entirely (6 files). Remove all imports and references in UI, Domain, and App layers.
- [ ] **Remove all subscription UI gates** -- Dashboard upgrade prompts, Export lock screen, Analytics chart gating, Settings membership section. All features unlocked unconditionally.
- [ ] **Remove StoreKit initialization from App.swift** -- Lines 13-17 creating `StoreKitClient` and starting transaction listener.
- [ ] **Update AuthViewModel** -- Remove `SubscriptionClientFactory` casting and `identify`/`logout` calls for StoreKit.
- [ ] **Update DashboardViewModel** -- Remove subscription checks, set `canGenerateAIWorkout = true` always, show coaching insights always.
- [ ] **Update ExportViewModel** -- Set `canExport = true` always, remove subscription check.
- [ ] **Update AnalyticsViewModel** -- Set `hasCycleAccess = true` always, remove subscription tier tracking.
- [ ] **Update PainTrackingViewModel** -- Remove subscription check for smart substitutions.
- [ ] **Update CoachContext** -- Remove subscription tier parameter or hardcode to full access.
- [ ] **Update SettingsView** -- Remove membership section, SubscriptionView, SubscriptionViewModel entirely.
- [ ] **Update Package.swift** -- Remove Subscription/ from source targets if needed.
- [ ] **Update/Remove subscription tests** -- AnalyticsViewModelTests references subscription. Update to remove subscription assertions.
- [ ] **Build and verify** -- `xcodebuild` must pass. All 60 existing tests must pass.
- [ ] **QA pass** -- Verify all features accessible in guest mode and signed-in mode. No dead ends, no crashes.
- [ ] **App Store metadata** -- Title, subtitle, description, keywords, support URL, privacy policy URL, age rating, review contact, content rights declaration.
- [ ] **Screenshots** -- Minimum 3 screenshots for iPhone 6.7" and iPhone 6.5" device sizes.
- [ ] **Archive and submit** -- Build, upload, and submit for review.

### Add After Launch (v1.2+)

Features to add once the app is live and validated.

- [ ] **App Store preview video** -- Record 15-30 second preview showing cycle-aware workout flow. Apps with video convert better.
- [ ] **Accessibility audit** -- VoiceOver labels, Dynamic Type, contrast ratios, reduced motion support.
- [ ] **App Store Optimization (ASO)** -- Iterate on keywords based on search analytics. A/B test screenshots.
- [ ] **Rating prompt** -- SKStoreReviewController after 3+ completed workouts. Ratings drive discovery.
- [ ] **iPad-optimized screenshots** -- Add 12.9" iPad screenshots for broader device coverage.
- [ ] **Localization** -- Add additional languages based on App Store analytics showing demand.

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Monetization strategy** -- Tip jar, patron model, or premium features. Only after understanding user base.
- [ ] **TestFlight public link** -- Beta testing channel for future updates.
- [ ] **App Store featuring submission** -- Apply for App Store featuring once ratings and retention are strong.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Remove subscription UI gates | HIGH (no confusion) | MEDIUM (7 files) | P1 |
| Remove subscription code layer | HIGH (clean codebase) | MEDIUM (6 files + references) | P1 |
| Remove StoreKit from App.swift | HIGH (no dead code) | LOW (5 lines) | P1 |
| Update view models | HIGH (all features work) | MEDIUM (5 VMs) | P1 |
| Update tests | MEDIUM (CI passes) | LOW (1 test file + references) | P1 |
| Build verification | HIGH (must ship) | LOW (one command) | P1 |
| QA pass | HIGH (no crashes) | MEDIUM (manual testing) | P1 |
| App Store metadata | HIGH (required for submission) | LOW (text fields) | P1 |
| Screenshots | HIGH (drives downloads) | MEDIUM (create + upload) | P1 |
| Age rating | HIGH (required) | LOW (questionnaire) | P1 |
| Privacy manifest verification | HIGH (required) | LOW (review existing) | P1 |
| Submit for review | HIGH (launch) | LOW (button click) | P1 |
| "100% Free" subtitle | MEDIUM (discovery) | LOW (text) | P2 |
| Screenshot storytelling | MEDIUM (conversion) | MEDIUM (design work) | P2 |
| App Store preview video | HIGH (conversion) | HIGH (production) | P2 |
| Accessibility audit | MEDIUM (reach) | HIGH (multi-pass) | P3 |
| Localization | MEDIUM (reach) | HIGH (translation) | P3 |
| Tip jar / monetization | LOW (future revenue) | MEDIUM (StoreKit again) | P3 |

**Priority key:**
- P1: Must have for launch -- submission will fail or app will be broken without it
- P2: Should have -- directly impacts downloads and conversion
- P3: Nice to have -- future milestones

## Paywall Removal: Gate Point Inventory

Every location where subscription tier is checked and must be updated.

### UI Layer -- Views (7 files)

| File | Gate | Current Behavior | Required Change |
|------|------|------------------|-----------------|
| `DashboardView.swift` | `viewModel.subscriptionTier == .free` shows upgrade prompts | Shows "Unlock with Plus" and "Unlock with Pro" cards | Remove `upgradePrompts` computed property entirely. Remove `lockedFeatureCard` helper. Show coaching insights always (remove `viewModel.subscriptionTier == .premium` guard) |
| `DashboardView.swift` | `canGenerateAIWorkout` from subscription | Controls AI workout button visibility | Set `canGenerateAIWorkout = true` unconditionally. Remove subscription check in `loadSubscriptionData()` |
| `AnalyticsView.swift` | `showingSubscription` state | (Declared but only used in CycleCorrelationChart) | Remove `@State private var showingSubscription` |
| `CycleCorrelationChart.swift` | `hasAccess` parameter + subscription sheet | Shows locked overlay when `!hasAccess`, presents SubscriptionView | Remove `hasAccess` parameter. Remove locked overlay. Remove subscription sheet. Always show chart |
| `ExportView.swift` | `viewModel.canExport` + subscription sheet | Shows lock icon + "Upgrade to Pro" when `!canExport` | Remove `upgradeSection`. Remove subscription sheet. Always show data categories and export |
| `PainTrackingView.swift` | Smart substitutions gated via ViewModel | ViewModel checks `hasSmartSubstitutions` | Remove subscription check in `loadSubstitutionSuggestions()`. Always load suggestions |
| `SettingsView.swift` | Membership section + SubscriptionView | Shows membership navigation link, SubscriptionView sheet, SubscriptionViewModel | Remove entire membership section from settings. Remove `SubscriptionView` struct. Remove `SubscriptionViewModel` class. Remove `SettingsViewModel.showingSubscription` and `loadSubscriptionTier()` |

### UI Layer -- View Models (5 files)

| File | Current Behavior | Required Change |
|------|------------------|-----------------|
| `DashboardViewModel` | Fetches subscription, sets `subscriptionTier`, `canGenerateAIWorkout`, controls coaching insights | Remove `subscriptionClient` dependency. Remove `subscriptionTier` property. Set `canGenerateAIWorkout = true` always. Always load coaching insights |
| `AnalyticsViewModel` | Fetches subscription, sets `subscriptionTier`, `hasCycleAccess` | Remove `subscriptionClient` dependency. Remove `subscriptionTier` property. Set `hasCycleAccess = true` always |
| `ExportViewModel` | Fetches subscription, sets `currentTier`, `canExport` | Remove `subscriptionClient` dependency. Remove `currentTier` property. Set `canExport = true` always. Remove `showingSubscription`. Remove `checkSubscription()` method |
| `PainTrackingViewModel` | Fetches subscription, checks `hasSmartSubstitutions` before loading suggestions | Remove `subscriptionClient` dependency. Always load substitution suggestions |
| `SettingsViewModel` | Fetches subscription tier for display | Remove `subscriptionClient` dependency. Remove `currentTier` property. Remove `loadSubscriptionTier()` method. Remove `showingSubscription` property |

### Domain Layer (1 file)

| File | Current Behavior | Required Change |
|------|------------------|-----------------|
| `CoachContext.swift` | Accepts `tier: SubscriptionTier` parameter, fetches subscription via `loadSubscription()` | Remove `tier` parameter or hardcode to full access. Remove `subscriptionClient` dependency. Remove `loadSubscription()` method |

### App Entry Point (1 file)

| File | Current Behavior | Required Change |
|------|------------------|-----------------|
| `App.swift` | Creates `StoreKitClient`, sets `SubscriptionClientFactory.shared.client`, starts transaction listener | Remove StoreKit import. Remove client creation and factory assignment. Remove transaction listener Task |

### Subscription Layer (entire directory -- 6 files to delete)

| File | Action |
|------|--------|
| `SubscriptionTier.swift` | DELETE |
| `SubscriptionClientProtocol.swift` | DELETE |
| `SubscriptionClientFactory.swift` | DELETE |
| `StoreKitClient.swift` | DELETE |
| `MockSubscriptionClient.swift` | DELETE |
| `SubscriptionError.swift` | DELETE |

### Tests (1 file + references)

| File | Current Behavior | Required Change |
|------|------------------|-----------------|
| `AnalyticsViewModelTests.swift` | Tests subscription-dependent behavior (13 references) | Update or remove subscription-related test cases |

### Auth Layer (1 file)

| File | Current Behavior | Required Change |
|------|------------------|-----------------|
| `AuthViewModel.swift` | Casts to `StoreKitClient` for `identify()` and `logout()` on sign-in/sign-out | Remove `SubscriptionClientFactory` casting. Remove `identify` and `logout` calls to subscription client |

## App Store Submission Checklist

Required items for first launch, mapped to the app's current state.

| Item | Status | Action Needed |
|------|--------|---------------|
| App name (30 chars) | NEEDED | Define. "Sundee Fundee" fits (13 chars) |
| Subtitle (30 chars) | NEEDED | Define. E.g., "Cycle-Aware Strength Training" (31 chars -- too long). "Strength Training for Your Cycle" (31 chars). "Cycle-Smart Strength Training" (29 chars) |
| Description (4000 chars) | NEEDED | Write. Emphasize: free, cycle-aware, AI coaching, benchmarks, injury tracking |
| Keywords (100 chars) | NEEDED | Write. E.g., "women,strength,cycle,workout,period,training,barbell,fitness,benchmarks,powerlifting" (exactly 100 chars) |
| Privacy Policy URL | NEEDED | Must be hosted. Could use GitHub Pages or a static page |
| Support URL | NEEDED | Must be reachable. Could use GitHub Issues or a support email |
| Copyright | NEEDED | E.g., "2026 Dustin Ober" |
| Primary category | NEEDED | `HEALTH_AND_FITNESS` |
| Content rights declaration | NEEDED | `DOES_NOT_USE_THIRD_PARTY_CONTENT` |
| Age rating | NEEDED | `healthOrWellnessTopics: FREQUENT_OR_INTENSE`. All others: NONE or INFREQUENT_OR_MILD |
| Review contact info | NEEDED | Real name, email, phone |
| Screenshots (6.7" iPhone) | NEEDED | Minimum 3. Target 5. Use ScreenshotSeeder + simulator |
| Screenshots (6.5" iPhone) | NEEDED | Minimum 3. Target 5. Can reuse 6.7" assets if dimensions match |
| App icon (1024x1024) | EXISTS | Verify in project.yml |
| PrivacyInfo.xcprivacy | EXISTS | Verify completeness. Currently declares HealthData, FitnessData, UserID collection + UserDefaults API |
| NSHealthShareUsageDescription | EXISTS | "Sundee Fundee uses your health data to track workouts and adapt training to your menstrual cycle phase." |
| NSHealthUpdateUsageDescription | EXISTS | "Sundee Fundee saves your workout data to Apple Health to keep your fitness records in sync." |
| UIRequiredDeviceCapabilities | EXISTS | `arm64` only -- correct |
| Bundle ID | EXISTS | Defined in project.yml |
| Monetization | NEEDED | Set to free (`isFree: "true"`) |
| Remove subscription products | NEEDED | Set "Cleared for Sale" = No for all 4 subscription products in App Store Connect |
| Demo account (if login required) | NEEDED | App has guest mode -- document this in review notes. Provide reviewer instructions |
| Build archive | NEEDED | `xcodebuild archive` + export or use Blitz MCP `app_store_build` |

## Competitor Feature Analysis

Positioning against health/fitness apps in the App Store.

| Feature | Typical Fitness Apps | Sundee Fundee Approach |
|---------|---------------------|----------------------|
| Pricing | $9.99-29.99/mo subscription or freemium with heavy paywall | 100% free. No paywall. No ads. |
| Cycle awareness | Rarely offered. Most apps ignore menstrual cycle | Core differentiator. Cycle phase drives weight calculations, readiness, recommendations |
| AI coaching | Often cloud-dependent, limited free usage | On-device AI workout generation. No server costs. Privacy-first |
| Benchmark testing | Not offered in most apps | Built-in benchmark catalog with cycle-aware readiness scoring |
| Injury adaptation | Rarely offered | Injury tracking with automatic exercise regression and load modification |
| Design | Generic blue/white fitness aesthetic | Art Deco theme (cream/navy/orange). Visually distinctive in screenshots |

## Sources

**HIGH Confidence (Codebase analysis -- verified by reading source files)**
- `SundeeFundee/Sources/SundeeFundeeKit/Subscription/` -- 6 subscription files, all to be removed
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift` -- primary gate point for subscription tier checks
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift` -- contains SubscriptionView, SubscriptionViewModel, membership section
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Export/ExportView.swift` -- export gated behind hasExportShare
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/CycleCorrelationChart.swift` -- chart gated behind hasCycleAccess
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/` -- 5 view models reference subscription client
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Coach/CoachContext.swift` -- domain layer subscription reference
- `SundeeFundeeApp/SundeeFundee/PrivacyInfo.xcprivacy` -- privacy manifest already exists and declares HealthKit data types
- `SundeeFundeeApp/SundeeFundee/Info.plist` -- HealthKit usage descriptions already present
- `SundeeFundeeApp/SundeeFundee/App.swift` -- StoreKit initialization in app entry point

**MEDIUM Confidence (Apple documentation -- verified through official docs)**
- Apple App Store Review Guidelines (Guideline 2.1, 3.1.1, 5.1.1) -- required metadata, IAP rules, health data handling
- Apple Privacy Manifest requirements -- PrivacyInfo.xcprivacy required for health/fitness apps
- StoreKit 2 documentation -- subscription lifecycle management
- App Store Connect Help -- subscription product management, "Cleared for Sale" toggle

**LOW Confidence (Training data -- could not verify via web search)**
- App Store screenshot requirements for 2026 -- may have new required device sizes beyond 6.7"/6.5"
- App Store review timeline estimates -- historically 24-48 hours but may vary
- App Store featuring criteria -- based on general knowledge, not verified against 2026 guidelines

---
*Feature research for: Paywall removal and free App Store launch*
*Researched: 2026-04-08*
