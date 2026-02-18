# TESTING

## Purpose
Describe the repository's testing strategy, where tests live, and how to run them locally.

## Test pyramid
- Unit (fast, many): `tests/unit/` — business logic, calculations, Dexie wrappers (fake-indexeddb)
- Integration (component + context): `tests/integration/`
- E2E (user flows): `tests/e2e/` — Playwright, mobile viewport

## Commands
- Install: `npm install`
- Run unit + integration: `npm run test:run`
- Run E2E: `npm run test:e2e`
- Lint: `npm run lint`

## Important files & setup
- Vitest config: `vitest.config.ts`
- Playwright config: `playwright.config.ts`
- Test setup: `tests/setup.ts` (includes `import 'fake-indexeddb/auto'` for Dexie tests)

## Testing notes / expectations
- Aim: Unit tests for core calculation utilities (`src/lib/calculations.ts`) and DB operations
- E2E covers critical flows (onboarding → start cycle → complete workout)
- Use React Testing Library for component tests and `renderHook` patterns for contexts

## Recommendations
- Add Playwright coverage for PR/workout-complete + offline recovery flows
- Maintain `fake-indexeddb` usage for deterministic DB tests

---
Status: test harness configured; E2E coverage still limited.