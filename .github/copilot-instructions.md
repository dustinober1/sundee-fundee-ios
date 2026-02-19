Copilot instructions for this repository

Purpose

This file helps future Copilot/Copilot-CLI sessions understand how to build, test, lint, and find architecture/conventions for the Strength app.

Quick commands (exact scripts)

- Install dependencies: npm install
- Development server: npm run dev
- Build (production): npm run build
- Production preview: npm run start
- Lint: npm run lint
- Unit tests (interactive/watch): npm run test  # runs vitest
- Unit tests (CI / run once): npm run test:run   # vitest run
- E2E tests: npm run test:e2e                    # playwright test

Run a single unit test file

- npx vitest run tests/unit/my-file.test.ts
- or: npm run test:run -- tests/unit/my-file.test.ts
- To run one test in interactive/watch mode: npx vitest tests/unit/my-file.test.ts

Run a single Playwright E2E file

- npx playwright test tests/e2e/example.spec.ts
- or: npm run test:e2e -- tests/e2e/example.spec.ts

Important test setup

- tests/setup.ts is loaded by Vitest (see vitest.config.ts). It already imports `fake-indexeddb/auto` and sets up a localStorage mock; keep that file if you modify tests that touch Dexie (IndexedDB).
- Vitest's include pattern: tests/**/*.test.{ts,tsx}; E2E tests live under tests/e2e/ (Playwright).
- Playwright config uses a webServer (npm run dev) and the iPhone 13 device emulation by default (see playwright.config.ts).

High-level architecture (summary)

- UI layer: Next.js 16 App Router (src/app), React 19, shadcn/ui + Tailwind CSS for design, Framer Motion for animations (src/components/animations).
- State layer: React Contexts (src/contexts/) e.g. UserContext, ExerciseContext, RestTimerContext.
- Data layer: IndexedDB via Dexie (src/lib/db/dexie.ts) is the primary offline store; static program JSON lives in src/data/programs/.
- Sync layer: Optional Supabase for cloud backup / cross-device sync (env vars: NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY).
- Utilities: calculation helpers in src/lib/calculations.ts; TypeScript types in src/types/.

Key conventions (repo-specific)

- Local-first, sync-later: prefer writing to Dexie and queuing sync to Supabase rather than assuming remote state.
- Program JSON format: programs are 8-week program objects stored in src/data/programs/*.json (id, name, durationWeeks, weeks -> days -> exercises with percent1RM, sets, reps).
- File & naming conventions (see .planning/codebase/CONVENTIONS.md): TypeScript-first; components in PascalCase; data files in kebab-case; features grouped under components/<feature>/ and src/app/<route>/; context providers in src/contexts/.
- shadcn/ui note: running `npx shadcn@latest init` will overwrite src/lib/utils.ts; re-add any custom utilities (roundToNearestFive, generateId, etc.) after running it.
- Tests touching Dexie must rely on fake-indexeddb; tests/setup.ts is required to ensure Dexie works under jsdom.
- Commits: follow conventional-commit-like messages for clarity (feat:, fix:, docs:, etc.) and run lint/tests before PRs.

Where to read more

- CLAUDE.md (root): in-repo guide with architecture, commands, and design documents.
- .planning/codebase/CONVENTIONS.md: coding and testing conventions.
- docs/plans/*.md: implementation plans and design docs.
- src/ (app/, components/, lib/, contexts/, data/) for concrete locations of functionality.

Notes for Copilot sessions

- Prefer referencing CLAUDE.md and CONVENTIONS.md for architecture and conventions rather than inferring from a single file.
- Check tests/setup.ts before modifying tests that access IndexedDB.
- Use the exact npm scripts above when suggesting commands to run.

If this file already exists, prefer editing/annotating it rather than wholesale replacement.
