# Copilot instructions — Strength (concise agent guide)

Purpose

A short, actionable guide for AI coding agents working on the Strength app. Reference examples in the repo before changing conventions.

## Quick commands (exact scripts)

- Install: `npm install`
- Dev server: `npm run dev`
- Build: `npm run build`
- Production preview: `npm run start`
- Lint: `npm run lint`
- Unit tests (watch): `npm run test`
- Unit tests (CI / run once): `npm run test:run`
- E2E tests: `npm run test:e2e`

## Project snapshot

- Framework: **Next.js 16 (App Router)**, React 19, TypeScript
- Data: **Local-first** (IndexedDB via Dexie) with optional Supabase sync
- UI: Tailwind + `shadcn/ui`; animations in `src/components/animations`
- Important files: `src/contexts/`, `src/lib/db/dexie.ts`, `src/data/programs/`, `src/lib/calculations.ts`

## Code style & conventions 🔧

- TypeScript-first. Use `@/` imports (see `tsconfig.json`).
- Components: `PascalCase`; data files: `kebab-case`; contexts live in `src/contexts/`.
- Tests live under `tests/` (unit, integration, e2e). Use `tests/setup.ts` for DB mocks.
- Run `npm run lint` + `npm run test:run` before opening PRs. Follow conventional commit prefixes (`feat:`, `fix:`, `docs:`).
- shadcn note: `npx shadcn@latest init` overwrites `src/lib/utils.ts` — reapply custom helpers after running it.

## Architecture (where to start) 📂

- UI → React components in `src/components/` and routes under `src/app/`.
- State → React Contexts (`src/contexts/`) — UserContext, ExerciseContext, RestTimerContext.
- Data → Dexie DB (`src/lib/db/dexie.ts`) is the authoritative local store; static programs live in `src/data/programs/`.
- Business logic → `src/lib/calculations.ts` and `src/lib/cycle-calculations.ts`.

## Build & test details ✅

- Vitest for unit/integration (`tests/unit/`, `tests/integration/`).
- `tests/setup.ts` imports `fake-indexeddb/auto` — required for Dexie tests under jsdom.
- Playwright E2E lives in `tests/e2e/`; `playwright.config.ts` uses a webServer and mobile emulation (iPhone 13).
- Run a single test: `npx vitest run tests/unit/your.test.ts` or `npx playwright test tests/e2e/your.spec.ts`.

## Project-specific rules (do this, not aspirational notes) 📋

- Local-first, sync-later: write to Dexie, queue sync to Supabase.
- Program JSON schema is authoritative — add/modify programs in `src/data/programs/*.json` following existing examples.
- When changing DB schema, update `src/lib/db/dexie.ts` and add migration tests.
- Add/adjust unit tests for all behavior changes; update `tests/setup.ts` only if required by test infra.

## Integration & environment 🔌

- Supabase (optional): env vars `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` (see `src/lib/supabase/`).
- UI/analytics: `recharts` for charts and `canvas-confetti` for PR celebrations.

## Security & sensitive areas ⚠️

- Never commit secrets or `.env*` files. Treat server-side keys with care.
- IndexedDB quota and Dexie transaction errors are handled in the DB layer — prefer retry/backoff logic when adding DB code.

## How an AI agent should operate (practical) 🤖

1. Make a single, focused change + tests. Keep PRs small.
2. Run `npm run lint` and `npm run test:run` locally (or via CI).
3. Reference `CLAUDE.md` and `.planning/codebase/CONVENTIONS.md` for architecture and conventions.
4. For DB or program changes, add migration/unit tests under `tests/unit/db` or `tests/unit/programs`.

## Where to look first (entry points)

- `src/contexts/` — context providers and hooks
- `src/lib/db/dexie.ts` — DB schema & migrations
- `src/lib/calculations.ts` — core logic
- `src/data/programs/` — program definitions
- `tests/` — test examples to copy patterns from

---

If any section is incomplete or you want more detail (tests, DB migrations, UI conventions), tell me which area and I will expand it.
