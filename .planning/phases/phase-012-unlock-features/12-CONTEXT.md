# Phase 12: Unlock Features - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning

<domain>
## Phase Boundary

All features are functionally unlocked in the app, even though paywall UI may still exist visually. This phase swaps the subscription backend from StoreKit to a free-access implementation, making all tier-gated capabilities return "unlocked" without removing any UI elements.

</domain>

<decisions>
## Implementation Decisions

### FreeSubscriptionClient Implementation
- New standalone struct (not extending MockSubscriptionClient) — cleaner separation from test-only code
- dailyAIGenerations returns 999 (effectively unlimited, avoids Int.max edge cases)
- purchase() and restorePurchases() silently succeed as no-ops — avoids error states if code still calls these before Phase 13 removes them

### SubscriptionTier Enum Treatment
- Keep existing SubscriptionTier enum with modified methods — all capability flags return premium-equivalent values
- CoachContext keeps tier property but always receives .premium — Phase 13 removes it entirely, avoiding double-touch

### Prior Decisions (from STATE.md)
- Protocol-replacement strategy: keep SubscriptionClientProtocol, create FreeSubscriptionClient, swap implementation
- Subscription/ directory deleted entirely in Phase 13 (not Phase 12)
- App.swift swaps StoreKitClient for FreeSubscriptionClient

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- SubscriptionClientProtocol — protocol stays intact, new implementation conforms to it
- SubscriptionClientFactory — singleton pattern reused, just swaps default client
- MockSubscriptionClient — reference for protocol conformance, but NOT extended

### Established Patterns
- Protocol-based dependency injection for subscription client
- Factory singleton pattern (SubscriptionClientFactory.shared.client)
- SubscriptionTier enum with computed properties for capability flags

### Integration Points
- App.swift init() — where StoreKitClient is instantiated and transaction listener started
- CoachContext.loadSubscription() — where tier is fetched and injected
- View models: AnalyticsViewModel, ExportViewModel, PainTrackingViewModel, AuthViewModel — all accept subscriptionClient
- DashboardView, AnalyticsView, SettingsView, ExportView — reference tier for UI gating (Phase 13 removes UI)

</code_context>

<specifics>
## Specific Ideas

No specific requirements — implementation follows protocol-replacement strategy from STATE.md decisions.

</specifics>

<deferred>
## Deferred Ideas

- Removing Subscription/ directory entirely — deferred to Phase 13
- Removing subscription UI (paywall, upgrade prompts, manage subscription) — deferred to Phase 13
- Subscription-related test updates — deferred to Phase 14

</deferred>
