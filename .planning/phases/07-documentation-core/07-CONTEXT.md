# Phase 7: Documentation Core - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning
**Mode:** Auto-generated (discuss skipped — ROADMAP spec is detailed)

<domain>
## Phase Boundary

Core project documentation reflects iOS-only architecture. CLAUDE.md and README.md are completely rewritten. This is the critical documentation phase.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion. Use the existing CLAUDE.md iOS sections as the foundation.

### Content Decisions
- CLAUDE.md must contain NO references to web app, Firebase, Stripe, or Cloud Functions
- CLAUDE.md must accurately describe SundeeFundeeKit and SundeeFundeeApp structure
- README.md must provide clear overview for iOS-only repository
- README.md must include setup instructions for Xcode + Swift Package Manager

</decisions>

<code_context>
## Existing Code Insights

The current CLAUDE.md has extensive iOS-specific documentation in its "iOS App (Native SwiftUI)" and "Architecture" sections that can be preserved. The web-specific sections need to be removed entirely.

Key iOS architecture:
- SundeeFundee/ — Swift Package (SundeeFundeeKit): domain logic, views, viewmodels, auth, CloudKit
- SundeeFundeeApp/ — Xcode project that imports the package
- Auth: Apple Sign-In + guest mode + CloudKit
- Data: DataClientProtocol with CloudKit/Local/Mock implementations
- Theme: Art Deco (cream/navy/orange)

</code_context>

<specifics>
## Specific Ideas

- Use existing CLAUDE.md iOS sections as foundation
- Add archive location reference: `sundee-fundee-archive-2026-04-08.zip`
- Document xcodebuild, swift test commands
- Include iOS-specific patterns from current CLAUDE.md

</specifics>

<deferred>
## Deferred Ideas

- MIGRATION.md is Phase 8
- CHANGELOG.md is Phase 10

</deferred>
