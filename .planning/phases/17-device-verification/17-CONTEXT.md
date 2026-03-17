# Phase 17: Device Verification - Context

**Gathered:** 2026-03-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Triage and resolve all ~30 v1.0 human verification items. Confirm core flows on iOS simulator, Android emulator (smoke test), and offline conditions. No new features — only verify, fix, and document what was built in v1.0.

</domain>

<decisions>
## Implementation Decisions

### Triage Process
- Group items by risk level: blockers (breaks core flow) → degraded (works but ugly/noisy) → cosmetic (polish)
- Fix blockers first, then sweep degraded, then cosmetic
- Claude automates testing via iOS simulator MCP tools first, then hands off a short list of items that truly need human eyes/hands
- Fix bugs immediately as found (not batched after full sweep)
- Physical-device-only items (haptics, real push notifications) explicitly deferred to Phase 18 when EAS dev build is available

### Testing Targets
- Primary iOS target: iPhone 16 Pro simulator
- Android: basic smoke test on emulator — confirm app launches, navigates, and completes a workout (not a full item-by-item sweep)
- Web: quick smoke test (`expo start --web`) — confirm app loads and navigates without crashes (no deep verification)

### Fix vs Document Threshold
- Bar: everything polished — all visual items (charts, toasts, animations) must look correct on simulator
- Only truly impossible items (physical device haptics, real push delivery) get deferred
- Firebase-dependent tests use Firebase Emulator (no risk of corrupting real data)
- Items that look correct on simulator marked as "verified on simulator" with a note that physical device confirmation happens in Phase 18
- Live Firebase validation deferred to Phase 18 EAS build

### Offline Verification
- Use simulator's network link conditioner to disable/enable network
- Key scenario: go offline → start workout → log sets → finish → go online → verify workout appears in history with correct data (covers VERIFY-03)
- Include app kill resilience: after completing workout offline, force-kill app, relaunch still offline, verify workout data persists, then go online and verify sync
- Scripted steps (not exploratory)

### Claude's Discretion
- Exact ordering of items within each risk tier
- Which simulator MCP tools to use for each verification item
- How to structure the triage checklist output
- Test data setup for offline scenarios

</decisions>

<specifics>
## Specific Ideas

- Claude should produce a clear triage report showing each item's status: verified, fixed, deferred (with rationale), or known limitation
- The ~30 items span 8 phases: Phase 1 (4 items), Phase 3 (5 items), Phase 4 (5 items), Phase 5 (5 items), Phase 6 (5 items), Phase 7 (4 items), Phase 12 (3 items), plus items from Phases 8-16

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- iOS Simulator MCP tools: screenshot, tap, swipe, get_ui_hierarchy, launch_app, type_text — can automate most visual verification
- Firebase Emulator: already configured for rules testing (Phase 12) — can reuse for auth and sync verification
- Existing test suite: 72 test files with domain + integration coverage — confirms code paths before runtime verification

### Established Patterns
- VERIFICATION.md files in each v1.0 phase contain the exact human verification items with "why_human" rationale
- Each item has a specific test description and expected behavior
- Phases 3, 4, 12 marked as `human_needed` status — these are the priority phases

### Integration Points
- Phase 17 outputs feed Phase 18: deferred physical-device items become Phase 18 verification checklist
- Firestore rules deploy (Phase 12 item) deferred to Phase 22 — do NOT attempt in Phase 17
- Any bugs found may touch code across multiple v1.0 phases

</code_context>

<deferred>
## Deferred Ideas

- Physical device verification (haptics, real push notifications, App Check) — Phase 18
- Firestore security rules production deploy — Phase 22
- Nyquist validation gap closure — separate effort, not Phase 17 scope

</deferred>

---

*Phase: 17-device-verification*
*Context gathered: 2026-03-16*
