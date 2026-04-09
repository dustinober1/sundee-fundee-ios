# Domain Pitfalls

**Domain:** Removing StoreKit subscription paywall, making app 100% free, first App Store submission
**Researched:** 2026-04-08
**Confidence:** HIGH (based on code analysis), MEDIUM (App Store rejection patterns from training data)

## Critical Pitfalls

Mistakes that cause rewrites, App Store rejections, or broken builds.

### Pitfall 1: Dead Subscription Code Leaves Broken Imports and Runtime Crashes

**What goes wrong:**
Removing StoreKit imports and subscription files without tracing every downstream reference causes compile errors or, worse, runtime crashes when views try to present `SubscriptionView` or check `subscriptionClient.getSubscriptionInfo()`.

**Why it happens:**
The subscription system is deeply woven through the codebase. There are at least 7 view models, 5+ views, the app entry point, and domain-layer types (`CoachContext`) that depend on subscription types. A simple "delete the Subscription folder" approach will leave 30+ broken references. Developers underestimate the blast radius because the protocol-based architecture (`SubscriptionClientProtocol`) spreads the dependency far from its source.

**Consequences:**
- Xcode build failures across view models and views
- Runtime crashes if subscription protocol calls are not fully removed
- Tests fail (AnalyticsViewModelTests, other VM tests inject `subscriptionClient`)
- CoachContext and CoachContextBuilder need tier references updated
- AuthViewModel has hardcoded `StoreKitClient` casts that must be removed

**How to avoid:**
1. Do NOT delete subscription files first. Instead, start by making `SubscriptionTier` always return "unlocked" values.
2. Trace every file that references `SubscriptionClientProtocol`, `SubscriptionTier`, `SubscriptionInfo`, or `SubscriptionClientFactory` (grep found 20+ files).
3. Remove subscription parameters from view model initializers one at a time, building after each change.
4. Remove `SubscriptionView`, `SubscriptionViewModel`, `TierBadge`, and all "upgrade" card UI from views.
5. Remove the `import StoreKit` from `StoreKitClient.swift` last, then delete the entire `Subscription/` directory.
6. Run tests after each file modification.

**Warning signs:**
- `SubscriptionClientFactory.shared.client` appears in a file you did not touch
- Any view still has `showingSubscription` state variable or `.sheet(isPresented: $showingSubscription)`
- `CoachContext` still has a `tier` parameter
- `SubscriptionTier` enum still exists but nothing gates on it

**Phase to address:** Phase 1 (Strip Subscription Gating) -- The subscription removal must be systematic, not surgical. Remove references from consumers first, delete providers last.

---

### Pitfall 2: Orphaned StoreKit Configuration in App Store Connect Causes Rejection

**What goes wrong:**
The app has StoreKit subscription products configured in App Store Connect (`sundee_plus_monthly`, `sundee_plus_annual`, `sundee_premium_monthly`, `sundee_premium_annual`). If these in-app purchase products remain in App Store Connect but the app binary no longer implements StoreKit, Apple's review process may flag an inconsistency. Alternatively, if the products are deleted before the new binary is submitted, existing subscribers have no way to manage or cancel.

**Why it happens:**
App Store Connect products and the app binary are managed independently. There is no automatic synchronization. Developers focus on the code side and forget the App Store Connect configuration side. Additionally, `StoreKitClient` contains hardcoded product IDs (`sundee_plus_monthly`, etc.) that will become dead references.

**Consequences:**
- App Store review rejection for orphaned IAP products with no purchase flow in the binary
- Existing paid subscribers cannot cancel or manage their subscription through the app
- Apple may reject if subscription products are listed but the app does not implement `StoreKit`
- If products are deleted prematurely, existing subscribers get errors when trying to manage billing

**How to avoid:**
1. Before removing StoreKit code, check if any real users have active subscriptions. If yes, communicate the transition and let subscriptions naturally expire.
2. Remove subscription products from App Store Connect AFTER the new free binary is approved and live.
3. In the interim build, remove the purchase flow but keep a minimal "manage subscription" path that redirects to `https://apps.apple.com/account/subscriptions` for any existing subscribers.
4. Set the app to "Free" in App Store Connect monetization settings before submission.

**Warning signs:**
- App Store Connect shows active subscription products with no corresponding code
- No manage-subscription UI for existing paid users
- Reviewer sees IAP products listed but no purchase buttons in the app

**Phase to address:** Phase 1 (Strip Subscription Gating) for code changes, Phase 4 (App Store Submission) for App Store Connect cleanup.

---

### Pitfall 3: Incomplete Feature Unlock Leaves Users With a Worse Experience Than Before

**What goes wrong:**
Removing the paywall but forgetting to actually unlock all gated features. Users who previously had free-tier access still see locked states because the code that checks `tier.hasAIBuilder`, `tier.hasAdvancedInsights`, `tier.hasExportShare`, etc. was not updated to always return `true`.

**Why it happens:**
The `SubscriptionTier` enum has 12 capability flags (`hasCustomBenchmarks`, `hasPainTrends`, `hasAdvancedInsights`, `hasAIBuilder`, `hasRecoveryAdjustments`, `hasAdaptivePlanner`, `hasCoachMemory`, `hasSmartSubstitutions`, `hasPlateauDetection`, `hasPreferenceLearning`, `hasWeeklyRecap`, `hasExportShare`) and 4 quantitative limits (`maxLifts`, `maxInjuries`, `maxHistoryDays`, `dailyAIGenerations`). These are spread across view models, views, and domain logic. It is easy to remove the subscription UI but miss a capability check deep in a view model.

**Consequences:**
- Users see features that are still locked despite the app being "free"
- `maxLifts` still limits to 5 lifts even though there is no upgrade path
- `dailyAIGenerations` returns 0 for free tier, blocking AI features entirely
- `canGenerateAIWorkout` returns false in DashboardView
- Export is gated behind `hasExportShare` which returns false
- PainTrackingViewModel skips substitution suggestions because `hasSmartSubstitutions` is false

**How to avoid:**
1. The cleanest approach: delete the `SubscriptionTier` enum entirely and remove all tier checks. Replace gated code paths with the unlocked behavior.
2. The safer transitional approach: make `SubscriptionTier` a single case (no `.free`/`.plus`/`.premium` distinction) where all capability flags return `true` and all limits return `nil` (unlimited).
3. Audit every usage of these properties:
   - `DashboardView.loadSubscriptionInfo()` checks `hasAIBuilder` and `hasCoachMemory`
   - `AnalyticsViewModel` checks `hasAdvancedInsights`
   - `ExportViewModel.canExport` checks `hasExportShare`
   - `PainTrackingViewModel.loadSubstitutionSuggestions()` checks `hasSmartSubstitutions`
   - `DashboardView.upgradePrompts` checks `tier == .free` and `tier == .plus`
   - `DashboardView.coachingInsightsCard` checks `tier == .premium`
4. Run the app after changes and manually verify every previously-gated feature works.

**Warning signs:**
- Any view still shows a lock icon or "Unlock with Plus/Pro" button
- Feature count limits are still enforced (e.g., "5 lifts max")
- Any capability flag still returns `false`
- Analytics charts still show upgrade cards

**Phase to address:** Phase 1 (Strip Subscription Gating) -- Feature unlocking must happen in the same pass as subscription code removal.

---

### Pitfall 4: App Store Rejection for Missing or Inaccurate Privacy Nutrition Labels

**What goes wrong:**
The app collects HealthKit data, stores data in CloudKit, and uses Apple Sign-In. The existing `PrivacyInfo.xcprivacy` declares health data, fitness data, and user ID. But App Store Connect requires a separate "App Privacy" nutrition label that must match. If the privacy manifest in the binary does not match the App Store Connect privacy labels, or if required fields are missing, Apple rejects the submission.

**Why it happens:**
Apple has two separate privacy declaration systems: (1) the `PrivacyInfo.xcprivacy` file in the binary, and (2) the App Store Connect privacy nutrition label questionnaire. They are not automatically synchronized. The binary manifest declares API usage (e.g., `NSPrivacyAccessedAPICategoryUserDefaults`), while App Store Connect asks about data collection (what data, is it linked to identity, is it used for tracking). A mismatch between these two causes rejection. Additionally, Apple's "required reason API" rules mandate that every accessed API has a declared reason in the privacy manifest.

**Consequences:**
- Rejection under Guideline 5.1.1 (Privacy and Data Collection)
- Delays of 24-48+ hours per rejection-resubmission cycle
- May require binary update if the manifest is wrong (cannot fix in App Store Connect alone)

**How to avoid:**
1. Audit the existing `PrivacyInfo.xcprivacy` for completeness:
   - Current: Health data, Fitness data, User ID, UserDefaults API -- verify these are accurate
   - Missing: Check if CloudKit triggers any additional declarations
   - Verify all "required reason API" declarations (UserDefaults is declared with `CA92.1`)
2. Fill out App Store Connect privacy nutrition labels to match the manifest exactly
3. Declare HealthKit data collection as "Linked to Identity" (it is -- CloudKit stores it per user)
4. Ensure the app does NOT track users across apps (already declared `NSPrivacyTracking: false`)
5. Note: Privacy Nutrition Labels must be set manually in App Store Connect -- this is not exposed via API

**Warning signs:**
- Privacy manifest lists data types not declared in App Store Connect
- App Store Connect nutrition label says "No Data Collected" but the app uses HealthKit
- Missing "required reason API" entries in the manifest

**Phase to address:** Phase 4 (App Store Submission) -- Privacy labels must be verified before submitting for review.

---

### Pitfall 5: App Store Rejection for Incomplete App or Placeholder Content

**What goes wrong:**
The app contains placeholder text, stub implementations, or incomplete features that Apple reviewers will flag. The DashboardViewModel has `generateAIWorkout()` with a `try? await Task.sleep` and a comment "In real implementation, this would call the AI service." Reviewers test all app flows and will find non-functional buttons or screens that show empty states with no data.

**Why it happens:**
Apple's Guideline 2.1 (Performance: App Completeness) requires that every feature in the app is fully functional. Placeholder implementations, "coming soon" sections, or buttons that do nothing are automatic rejections. The app has several stub implementations that were acceptable during development but are not shippable.

**Consequences:**
- Immediate rejection under Guideline 2.1
- Reviewer sends a screenshot of the broken flow with "This feature does not work"
- Each rejection cycle costs 24-48 hours
- Multiple rejections for different issues compound the delay

**How to avoid:**
1. Audit every user-facing flow for completeness:
   - `DashboardViewModel.generateAIWorkout()` -- either implement or remove the AI workout button
   - `DashboardView.suggestedWorkoutCard` -- verify the "Generate" button leads to a working flow
   - `PainTrackingViewModel.deletePainLog()` -- has comment "In a full implementation..." and only removes from local array, not CloudKit
   - `PainTrackingViewModel.deleteInjury()` -- same issue
   - Any NavigationLink that leads to `Text("Workout Detail")` placeholder views
2. Remove or fully implement stub functions
3. Remove debug-only features (the `proTestEmails` hardcoded list in StoreKitClient is already `#if DEBUG` gated, but verify)
4. Test every tab and every navigation path as a reviewer would -- fresh install, guest mode, signed-in mode

**Warning signs:**
- Comments containing "TODO", "In real implementation", "placeholder", "stub"
- NavigationLinks to `Text("...")` views
- Buttons that call `Task.sleep` and do nothing
- Delete operations that only update local state without persisting
- Empty list states with no onboarding or guidance

**Phase to address:** Phase 2 (Full App Audit) -- Every stub and placeholder must be found and either completed or removed before submission.

---

## Technical Debt Patterns

Shortcuts that seem reasonable during paywall removal but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep `SubscriptionTier` enum but make all flags return true | Faster removal, fewer files to edit | Dead code that confuses future contributors, unnecessary complexity | Never -- remove the enum entirely or collapse to a single "all access" state |
| Comment out StoreKit code instead of deleting it | Easy rollback if something goes wrong | Dead imports, binary still links StoreKit framework, confusing codebase | Only during active debugging; delete before commit |
| Keep `SubscriptionView` but hide it behind a flag | Avoids touching all the sheet presentations | View still compiles into binary, accessibility scanner finds hidden views | Never -- remove the view and all sheet presentations |
| Hardcode `tier: .premium` everywhere instead of removing tier checks | Quick way to "unlock everything" | Every view model still has a dead `subscriptionClient` dependency | Acceptable as a first pass during removal, but must be cleaned up before Phase 3 |

## Integration Gotchas

Common mistakes when connecting to external services during this transition.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| StoreKit | Removing `StoreKitClient` but leaving `import StoreKit` in other files | Grep for `import StoreKit` and remove all occurrences before deleting the Subscription directory |
| CloudKit | Assuming removing subscriptions means removing CloudKit | CloudKit is the data persistence layer, NOT the subscription layer. Keep CloudKit, only remove StoreKit |
| HealthKit | Assuming HealthKit permission requests will be automatically approved by reviewers | Reviewers test with a fresh device; HealthKit authorization requires explicit user approval. Ensure the app works even if HealthKit is denied |
| App Store Connect | Deleting IAP products before the new binary is live | Submit the free binary first, get it approved, THEN remove IAP products from App Store Connect |
| App Store Connect | Setting app to "Free" but leaving subscription products in "Ready to Submit" state | Subscription products in App Store Connect must be removed or moved to "Developer Removed from Sale" before the free binary is reviewed |
| Auth | Removing subscription identity from `AuthViewModel` but breaking the auth flow | `AuthViewModel` calls `StoreKitClient.identify()` on sign-in and `logout()` on sign-out. Remove these calls but ensure auth flow still works without them |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Removing subscription checks but leaving async `getSubscriptionInfo()` calls | View models still make unnecessary async calls on load that add latency | Remove the subscription check entirely, not just the gating logic | On first launch -- every view model will still await a subscription check that returns free tier |
| Keeping `CoachContextBuilder` subscription fetch | Coach context assembly still calls `loadSubscription()` unnecessarily | Remove the subscription fetch from context builder, hardcode tier or remove the tier field | Every time coach insights are generated |

## Security Mistakes

Domain-specific security issues for this transition.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Leaving `proTestEmails` in production code | Hardcoded test emails bypass subscription (moot after removal, but looks unprofessional to reviewers) | Remove the `#if DEBUG` proTestEmails block entirely -- it serves no purpose in a free app |
| Removing subscription but keeping debug logging of subscription state | Console logs may leak user IDs or email addresses | Remove all `print("[StoreKit]...")` debug logging |
| Forgetting to remove StoreKit product IDs from binary | Product IDs (`sundee_plus_monthly`, etc.) in the binary may trigger App Store Connect warnings | Remove all product ID string constants |

## UX Pitfalls

Common user experience mistakes when removing paywalls.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Removing "Manage Subscription" from Settings but existing paid users still need it | Existing subscribers cannot find how to cancel | Keep a "Manage Subscription" link that opens `https://apps.apple.com/account/subscriptions` for a transition period |
| Removing "Upgrade to Pro" labels but leaving empty space where upgrade cards were | Dashboard has awkward blank sections | Remove the entire `upgradePrompts` section and `coachingInsightsCard` conditional, not just the text |
| Settings still shows "TierBadge" next to user name | Badge says "Free" which is confusing when the app is entirely free | Remove the TierBadge component entirely |
| Export link in Settings still shows "Pro" label | Users think export is still locked | Remove the "Pro" text badge from the Export navigation link |
| Forgetting to update the onboarding flow if it mentions subscription tiers | New users see references to paid plans during first-run experience | Audit OnboardingView for any subscription or tier references |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- **Subscription removal:** `SubscriptionTier` enum deleted but `CoachContext` still has a `tier` parameter that won't compile
- **Subscription removal:** `SubscriptionClientFactory` deleted but `DashboardViewModel` still injects `subscriptionClient` in its init
- **Subscription removal:** All subscription code removed but tests still reference `MockSubscriptionClient` and `subscriptionClient` parameters
- **UI cleanup:** Upgrade cards removed but `showingSubscription` state variables and `.sheet(isPresented: $showingSubscription)` modifiers still exist in views
- **UI cleanup:** SubscriptionView removed but SettingsView "Manage Subscription" button still presents it
- **App metadata:** App description mentions "Plus" and "Pro" tiers and their pricing
- **App metadata:** Screenshots show locked/gated features or upgrade prompts
- **Privacy manifest:** Still accurate after StoreKit removal (StoreKit does NOT need to be declared, but verify no other APIs were added)
- **Build settings:** `StoreKit` framework is no longer linked in the Xcode project after removing all `import StoreKit`
- **Version string:** Info.plist `CFBundleShortVersionString` updated from 1.0.0 to 1.1.0 (or whatever the new version is)
- **App Store Connect:** What's New text does not reference new subscription features
- **URL links:** SettingsView links to `sundeefundee.com/privacy` and `sundeefundee.com/terms` -- verify these URLs actually resolve to live pages
- **Accessibility:** VoiceOver works on all views after removing subscription-related UI elements

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Missed subscription reference causes build failure | LOW | Grep for the specific error, remove the reference, rebuild |
| App Store rejection for placeholder content | MEDIUM | Fix the placeholder, resubmit. Cost: 24-48 hours per cycle |
| App Store rejection for privacy label mismatch | LOW | Update labels in App Store Connect, resubmit. No binary change needed if manifest is correct |
| Orphaned IAP products in App Store Connect | LOW | Remove products via App Store Connect. Can be done after approval |
| Existing subscriber complaints about removed features | HIGH | Communicate transition via email, offer support contact, ensure "manage subscription" still accessible |
| Feature still locked after paywall removal | MEDIUM | Find the specific capability flag check, fix it, rebuild and resubmit. Cost: 24-48 hours |
| Tests fail after subscription removal | LOW | Update test fixtures to remove subscription client injection, fix assertions. Straightforward |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Dead subscription code causes broken imports | Phase 1: Strip Subscription Gating | Build succeeds with zero StoreKit imports |
| Orphaned StoreKit config in App Store Connect | Phase 4: App Store Submission | App Store Connect shows no IAP products after submission |
| Incomplete feature unlock | Phase 1: Strip Subscription Gating | Manual test of every previously-gated feature |
| Privacy nutrition label mismatch | Phase 4: App Store Submission | App Store Connect privacy labels match PrivacyInfo.xcprivacy |
| Placeholder/stub content | Phase 2: Full App Audit | No "TODO", "stub", "placeholder" in user-facing code; all buttons functional |
| Missed subscription UI elements | Phase 3: Polish | App shows zero lock icons, upgrade cards, or tier badges |
| Test failures from subscription removal | Phase 1: Strip Subscription Gating | All 60+ tests pass with subscription code removed |
| UX regression from removed UI sections | Phase 3: Polish | Dashboard, Analytics, Settings, Export all render correctly without gaps |
| Hardcoded test emails in binary | Phase 2: Full App Audit | Grep for email addresses in source, verify none reach production binary |
| Broken external links (privacy/terms) | Phase 4: App Store Submission | `curl` both URLs and verify 200 response |
| App Store metadata mentions paid tiers | Phase 4: App Store Submission | App description, screenshots, keywords contain zero pricing/tier references |

## Sources

- **Apple App Store Review Guidelines:** [developer.apple.com/app-store/review/guidelines](https://developer.apple.com/app-store/review/guidelines/) (MEDIUM confidence -- training data, not current version)
- **Apple Privacy Manifest Documentation:** [developer.apple.com/documentation/bundleresources/privacy_manifest](https://developer.apple.com/documentation/bundleresources/privacy_manifest) (MEDIUM confidence)
- **Apple Required Reason API Documentation:** [developer.apple.com/documentation/bundleresources/privacy_manifest/describing_use_of_required_reason_api](https://developer.apple.com/documentation/bundleresources/privacy_manifest/describing_use_of_required_reason_api) (MEDIUM confidence)
- **Codebase analysis:** Full audit of 20+ files containing subscription references (HIGH confidence -- direct observation)
- **Community reports:** r/iOSProgramming, r/appledev rejection pattern reports (LOW confidence -- community anecdotes)
- **App Store Connect Help:** [help.apple.com/app-store-connect](https://help.apple.com/app-store-connect/) (MEDIUM confidence)

---
*Pitfalls research for: Removing StoreKit paywall and first App Store submission*
*Researched: 2026-04-08*
