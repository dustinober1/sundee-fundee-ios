# STRUCTURE

## Purpose
Map of the repository layout and where to find the important subsystems.

## Top-level folders (quick)
- `src/` — web app (Next.js App Router)
  - `app/` — route entry points and pages
  - `components/` — UI components grouped by feature
  - `contexts/` — React Context providers
  - `data/` — static program/exercise JSON and metadata
  - `lib/` — calculations, DB, recommendations, utils
  - `types/` — core TS types
- `apps/mobile/` — Expo React Native mobile app
- `tests/` — unit/integration/e2e tests
- `docs/` — design & implementation plans

## Important files
- `src/app/layout.tsx`, `src/app/page.tsx` — web entry points
- `src/lib/db/dexie.ts` — IndexedDB schema
- `src/lib/calculations.ts` — domain calculations (weight, volume, PR detection)
- `src/data/programs/` — program definitions (JSON)
- `CLAUDE.md` — project overview & developer notes

## Routing (high level)
- `/` → Onboarding or Dashboard
- `/programs` → Browse programs
- `/workout/[id]` → Workout logger
- `/progress` → Charts and stats

## Tests
- `tests/unit/` — unit tests (Vitest)
- `tests/integration/` — component/context integration tests
- `tests/e2e/` — Playwright E2E flows

---
Tip: start from `src/contexts/` and `src/lib/` when tracing domain logic.