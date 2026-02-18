# CONCERNS & TECH DEBT

## Purpose
Call out known gaps, risks, and recommended mitigations so triage and planning are faster.

## Open / high-priority items
- Recommendations engine not finished — rules exist under `src/lib/recommendations/` but needs delivery and tests.
- Progress charts incomplete — `src/components/progress/` still missing charts and integration tests.
- Supabase sync is optional / incomplete — validate schema + conflict resolution before enabling for users.
- E2E test coverage is limited — expand Playwright flows for critical mobile flows.

## Technical risks
- IndexedDB quota limits → must implement graceful fallback / user messaging (see `CLAUDE.md` error handling priorities).
- Transaction conflicts in Dexie → add retries with exponential backoff for critical writes.
- Sync conflicts → current approach is last-write-by-timestamp; confirm merge strategy for concurrent edits.
- Animation complexity → may affect performance on older devices (test low-end mobile).

## Suggested mitigations
- Implement and test retry/backoff for Dexie transactions.
- Add Supabase staging run and a migration plan before enabling sync in production.
- Build Playwright E2E scenarios for offline → sync → conflict resolution.
- Add monitoring/telemetry for quota and sync failures (Sentry / similar).

## Quick wins
1. Add unit tests for `src/lib/recommendations/` (PR detection, plateau rules).
2. Create Playwright test for “complete workout → show PR” flow.
3. Add a small UX for IndexedDB quota-exceeded state.

---
Next step: pick one quick win and create a small implementation task.