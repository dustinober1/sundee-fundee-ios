# Project Research Summary

**Project:** Sundee Fundee v1.1 Free App Launch
**Domain:** iOS app -- removing StoreKit paywall and submitting free app to App Store
**Researched:** 2026-04-08
**Confidence:** HIGH

## Executive Summary

Sundee Fundee is a native iOS cycle-aware strength training app built with SwiftUI and Swift 6. The v1.1 milestone is a **reduction milestone**: removing the entire StoreKit 2 subscription layer and shipping a 100% free app to the App Store. No new frameworks, libraries, or SaaS tools are needed. The work is purely removal and simplification of existing code, followed by App Store submission.

The recommended approach is a **protocol-replacement strategy**: keep `SubscriptionClientProtocol` and `SubscriptionClientFactory` intact, flip all `SubscriptionTier` capability flags to return `true`, swap `StoreKitClient` for a new `FreeSubscriptionClient` in the app entry point, and then surgically remove all paywall UI (upgrade prompts, lock icons, subscription sheets). This minimizes blast radius -- the protocol/factory pattern is used in 7+ view models and 21 files total, so replacing the implementation rather than deleting the abstraction layer avoids touching every consumer simultaneously.

The key risks are (1) incomplete feature unlock leaving dead gates in the app, (2) orphaned StoreKit configuration in App Store Connect causing review rejection, (3) placeholder or stub code triggering Guideline 2.1 rejections, and (4) privacy nutrition label mismatches between the binary manifest and App Store Connect. All are preventable with systematic grep-based auditing and a manual QA pass before submission.

## Key Findings

### Recommended Stack

No new technologies are needed. The core stack (Swift 6, SwiftUI, CloudKit, HealthKit, Keychain, WidgetKit, XcodeGen) remains unchanged. The single stack change is **removing StoreKit 2** and its entitlements. App Store submission uses tools already configured in the project: Blitz MCP for build/upload/form-filling, `asc` CLI for API operations, and `blitz-iphone` for simulator screenshots.

**Core technologies:**
- **FreeSubscriptionClient (NEW):** Actor-based stub conforming to `SubscriptionClientProtocol` -- returns full access for all subscription checks. One new file.
- **SubscriptionTier (MODIFIED):** All 12 capability flags return `true`, all 4 quantitative limits return `nil`/unlimited. Central gatekeeper change.
- **Blitz MCP + asc CLI (EXISTING):** Handles build, upload, metadata fill, screenshot capture, and submission. Already configured.

### Expected Features

This milestone has no new user-facing features. The work is entirely about **unlocking existing features** and **removing barriers**.

**Must have (table stakes for free app launch):**
- Remove all subscription UI (upgrade prompts, lock icons, tier badges, subscription sheets) -- 7 view files affected
- Remove StoreKit 2 code layer -- 6 files in Subscription/ directory, plus references in 15+ other files
- Unlock all gated features unconditionally -- 12 capability flags and 4 quantitative limits
- App Store metadata (title, subtitle, description, keywords, screenshots, age rating, privacy policy URL, support URL)
- Privacy manifest verification (PrivacyInfo.xcprivacy)
- QA pass verifying all features work in guest mode and signed-in mode

**Should have (competitive advantage):**
- "100% Free" positioning in App Store listing -- rare in fitness category
- Subtitle emphasizing "Cycle-Smart Strength Training" (29 chars)
- Screenshot storytelling showing narrative flow across 3-5 screenshots
- Art Deco visual identity leveraged in screenshots for distinctiveness

**Defer (v1.2+):**
- App Store preview video -- production-intensive, ship without it
- Comprehensive accessibility audit -- multi-week effort, not launch-critical
- Localization -- English-only for launch
- Monetization strategy (tip jar, patron model) -- deferred entirely

### Architecture Approach

The architecture strategy is **layer-by-layer removal from consumers inward**: first flip the `SubscriptionTier` flags (foundation), then create `FreeSubscriptionClient` (infrastructure), then swap the app entry point (bootstrap), then remove paywall UI from views (presentation), then clean up entitlements and tests. This dependency-aware order prevents cascading build failures because each layer's consumers are updated before the layer itself is modified.

**Major components to modify:**
1. **SubscriptionTier.swift** -- Flip all capability flags to `true`, remove quantitative limits. Single source of truth for feature gating.
2. **FreeSubscriptionClient.swift (NEW)** -- Actor-based stub returning `SubscriptionInfo(tier: .premium, status: .active)` for all protocol methods. Replaces StoreKitClient without changing any view model's subscription-checking code.
3. **App.swift** -- Replace `StoreKitClient()` initialization with `FreeSubscriptionClient()`. Remove transaction listener Task.
4. **Paywall UI views** -- DashboardView, SettingsView, ExportView, AnalyticsView, CycleCorrelationChart, PainTrackingView. Remove upgrade cards, subscription sheets, lock icons, and tier-gated conditional rendering.
5. **AuthViewModel** -- Remove three `StoreKitClient` cast-and-call sites (identify/logout on sign-in, sign-out, session restore).

### Critical Pitfalls

1. **Incomplete feature unlock** -- The `SubscriptionTier` enum has 12 boolean flags and 4 quantitative limits. Missing even one leaves a dead gate. Prevention: flip ALL flags in a single pass, grep for every flag name across the codebase, then manually test each previously-gated feature.

2. **Orphaned StoreKit configuration in App Store Connect** -- Subscription products (`sundee_plus_monthly`, `sundee_plus_annual`, `sundee_premium_monthly`, `sundee_premium_annual`) must be disabled AFTER the free binary is approved, not before. Prevention: submit free binary first, then set products to "Not Cleared for Sale."

3. **Placeholder/stub content causing Guideline 2.1 rejection** -- `generateAIWorkout()` has `try? await Task.sleep` with a "In real implementation" comment. `deletePainLog()` only removes from local array. Prevention: audit every user-facing flow for "TODO", "stub", "placeholder" comments; remove or fully implement all stubs.

4. **Privacy nutrition label mismatch** -- The binary's `PrivacyInfo.xcprivacy` and App Store Connect's privacy questionnaire are separate systems that must match. Prevention: audit the manifest, fill App Store Connect labels to match exactly, declare HealthKit as "Linked to Identity."

5. **Dead paywall strings surviving the removal** -- "Unlock with Plus", "Upgrade to Pro", `lock.fill` icons, `showingSubscription` state variables. Prevention: grep for "Unlock", "Pro", "Plus", "Upgrade", "lock.fill", "subscription" across all UI files after removal.

## Implications for Roadmap

Based on combined research, the work naturally groups into four phases ordered by dependency and risk.

### Phase 1: Strip Subscription Gating
**Rationale:** The subscription tier flags are the foundation that all other changes depend on. Flipping them first means every downstream change (UI removal, view model cleanup) can be tested against already-unlocked features. Creating `FreeSubscriptionClient` and swapping it in `App.swift` completes the infrastructure change.
**Delivers:** A buildable app where all features are functionally unlocked, even though dead paywall UI may still exist.
**Addresses:** SubscriptionTier flag flips, FreeSubscriptionClient creation, App.swift swap, AuthViewModel cleanup, entitlements removal.
**Avoids:** Pitfall 1 (dead code with broken imports) by working consumer-inward, Pitfall 3 (incomplete unlock) by flipping all flags in one pass.

### Phase 2: Remove Paywall UI and Audit Stubs
**Rationale:** With features unlocked, the dead paywall UI (upgrade cards, subscription sheets, tier badges) can be removed from all views without fear of accidentally hiding features. Simultaneously audit for placeholder implementations.
**Delivers:** A clean UI with no paywall remnants and no stub/placeholder code.
**Addresses:** DashboardView upgrade prompts, SettingsView subscription section, ExportView lock, AnalyticsView gating, CycleCorrelationChart lock overlay, PainTrackingView smart substitution gate.
**Avoids:** Pitfall 5 (placeholder content rejection) by auditing all user-facing flows, Pitfall UX issues (empty spaces where upgrade cards were).

### Phase 3: Tests and Build Verification
**Rationale:** All code changes are complete. Update tests to reflect the new unlocked-everything behavior, run the full test suite, and do a manual QA pass.
**Delivers:** Confirmed build, all tests passing, manual verification that every feature works in both guest and signed-in modes.
**Addresses:** AnalyticsViewModelTests updates, any other subscription-dependent test fixtures, full `swift test` run, `xcodebuild` build verification, manual QA pass.
**Avoids:** Pitfall of shipping with broken tests or undetected regressions.

### Phase 4: App Store Submission
**Rationale:** Code is complete and verified. Now prepare all App Store Connect metadata, screenshots, and privacy declarations, then submit.
**Delivers:** App submitted for App Store review.
**Addresses:** App Store metadata (title, subtitle, description, keywords, support URL, privacy policy URL), age rating questionnaire, content rights declaration, screenshots, privacy nutrition labels, build archive and upload, submission for review.
**Avoids:** Pitfall 2 (orphaned StoreKit config) by managing App Store Connect products in the correct order, Pitfall 4 (privacy label mismatch) by auditing both systems.

### Phase Ordering Rationale

- **Phase 1 before Phase 2** because removing UI before unlocking features would hide features behind dead gates. Unlock first, then clean up.
- **Phase 2 before Phase 3** because test updates must reflect the final code state (both flag flips and UI removal).
- **Phase 3 before Phase 4** because App Store submission requires a verified, crash-free binary. Submitting before QA risks rejection for bugs.
- **Dependency-aware grouping:** Phase 1 handles the data/infrastructure layer, Phase 2 handles the presentation layer, Phase 3 validates, Phase 4 submits. Each phase's output is the next phase's prerequisite.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (App Store Submission):** App Store Connect metadata requirements, privacy nutrition label questionnaire, age rating specifics, and screenshot specifications may have changed since training data cutoff. Verify current requirements via Blitz MCP or Apple Developer documentation before submitting.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Strip Subscription Gating):** Well-documented codebase patterns. All 21 referencing files identified. Pure removal work.
- **Phase 2 (Remove Paywall UI):** Straightforward SwiftUI view modifications. All gate points inventoried.
- **Phase 3 (Tests and Build Verification):** Standard XCTest updates and build commands. No unknowns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No new technologies. Pure removal. All 21 referencing files identified via grep. Existing tooling handles submission. |
| Features | HIGH | Feature gate inventory is complete and verified against source code. Every check point in every file is documented. |
| Architecture | HIGH | Protocol-replacement strategy is sound. Source code fully audited. Build order respects dependency graph. |
| Pitfalls | HIGH (code) / MEDIUM (App Store) | Code pitfalls verified against actual source. App Store rejection patterns based on training data and community reports, not current Apple documentation. |

**Overall confidence:** HIGH for code changes, MEDIUM for App Store submission (Apple review is inherently unpredictable).

### Gaps to Address

- **App Store Connect current requirements:** Screenshot dimensions, required device sizes, and metadata field requirements may have changed. Verify via Apple Developer documentation or Blitz MCP before Phase 4.
- **Privacy nutrition label questionnaire:** Must be filled manually in App Store Connect (not available via API). Exact questions and options need verification during Phase 4.
- **Existing subscriber handling:** The app has never launched on iOS with subscriptions, so there are no existing subscribers. However, verify in App Store Connect that no subscription products were previously configured and left in an active state.
- **URL availability:** `sundeefundee.com/privacy` and `sundeefundee.com/terms` must resolve to live pages. Verify before submission.
- **Placeholder audit completeness:** The grep-based audit for stubs may miss semantic placeholders (code that works but provides a poor user experience, like empty state views with no guidance). Manual QA pass in Phase 3 should catch these.

## Sources

### Primary (HIGH confidence)
- Codebase analysis: 21 files referencing `SubscriptionTier`, all 6 files in `Subscription/` directory, all paywall UI views and view models
- Project configuration: `project.yml`, `Package.swift`, `SundeeFundee.entitlements`, `PrivacyInfo.xcprivacy`, `Info.plist`
- Blitz MCP documentation: `.claude/rules/blitz.md` and `SundeeFundeeApp/CLAUDE.md`

### Secondary (MEDIUM confidence)
- Apple App Store Review Guidelines (Guidelines 2.1, 3.1.1, 5.1.1) -- verified through official docs
- Apple Privacy Manifest Documentation -- required declarations for health/fitness apps
- StoreKit 2 documentation -- subscription lifecycle and product management
- App Store Connect Help -- subscription product management, metadata requirements

### Tertiary (LOW confidence)
- App Store screenshot requirements for 2026 -- may have new required device sizes beyond 6.7"/6.5"
- App Store review timeline estimates -- historically 24-48 hours but variable
- App Store featuring criteria -- based on general knowledge, not verified against 2026 guidelines
- Community rejection pattern reports (r/iOSProgramming, r/appledev) -- anecdotal

---
*Research completed: 2026-04-08*
*Ready for roadmap: yes*
