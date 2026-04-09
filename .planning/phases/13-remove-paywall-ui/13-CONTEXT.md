# Phase 13: Remove Paywall UI - Context

**Gathered:** 2026-04-09
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase)

<domain>
## Phase Boundary

Users see no subscription-related UI anywhere in the app. Remove all upgrade prompts, lock icons, tier badges, subscription sheets, and subscription-checking code from views and view models. Delete the entire Subscription/ directory.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — the phase is pure infrastructure (code deletion). Use ROADMAP phase goal, success criteria, and codebase conventions to guide decisions.

Key targets identified from Phase 12 research:
- DashboardView: Remove upgrade prompts (lines with `tier == .free`, coaching insights gating)
- AnalyticsView: Remove `hasAccess` gating on CycleCorrelationChart
- SettingsView: Remove "Manage Subscription" button and entire SubscriptionView
- ExportView: Remove subscription gating
- View Models: Remove subscriptionClient references from AnalyticsViewModel, ExportViewModel, PainTrackingViewModel, AuthViewModel
- Subscription/ directory: Delete entirely (StoreKitClient.swift, MockSubscriptionClient.swift, SubscriptionClientFactory.swift, etc.)
- Keep only FreeSubscriptionClient.swift and SubscriptionTier.swift (modified in Phase 12)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- FreeSubscriptionClient.swift — created in Phase 12, stays
- SubscriptionTier.swift — modified in Phase 12, stays
- SubscriptionClientProtocol — needed by FreeSubscriptionClient, stays

### Established Patterns
- Protocol-based DI for subscription client
- SwiftUI views reference subscription tier for conditional UI

### Integration Points
- Views that import or reference subscription types
- View models that hold subscriptionClient property

</code_context>

<specifics>
## Specific Ideas

No specific requirements — infrastructure phase. Delete all subscription UI and unused subscription code.

</specifics>

<deferred>
## Deferred Ideas

- Subscription-related test updates — deferred to Phase 14

</deferred>
