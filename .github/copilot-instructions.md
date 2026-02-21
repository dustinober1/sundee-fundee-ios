# Copilot instructions — Strength (concise agent guide)

Actionable guide for AI coding agents working on the Sundee‑Fundee workout app. Before making changes, browse relevant files and tests for patterns.

## 🛠 Quick commands (exact scripts)

```bash
npm install                # install dependencies
npm run dev                # run web development server
npm run build              # build production bundle
npm run start              # production preview
npm run lint               # run ESLint (pre‑commit hook)
npm run test               # Vitest watch mode
npm run test:run           # Vitest once (CI)
npm run test:e2e           # Playwright end‑to‑end tests
```

> ⚠️ This repository also contains mobile clients under `flutter_app/` and
> `rn_app/`.  Those directories have independent build/test workflows which
> are documented in their respective `README.md` files; agents working there
> should follow the platform‑specific commands.  The web commands above apply
> only to the Next.js project.


## 🧱 Project snapshot

- **Next.js 16** (App Router) with **React 19** and **TypeScript**
- **Local‑first** data architecture: IndexedDB via Dexie, optional Supabase sync
- UI built with Tailwind CSS & [shadcn/ui]; animations in `src/components/animations`
- Key directories: `src/contexts/`, `src/lib/db/dexie.ts`, `src/data/programs/`, `src/lib/calculations.ts`

> The repo is polyglot; mobile clients exist in `flutter_app/` (Flutter) and
> `rn_app/` (React Native).  Work there follows the patterns in those
> subprojects' READMEs rather than the web instructions below.

## 💅 Code style & conventions

- TypeScript‑first; use `@/` imports (configured in `tsconfig.json`).
- Components: `PascalCase`; utility/data files: `kebab-case`.
- Context providers under `src/contexts/` (User, Exercise, RestTimer). Use wrapper helpers in tests.
- Tests under `tests/` with subfolders `unit/`, `integration/`, `e2e/`.
- `tests/setup.ts` must import `fake-indexeddb/auto` for Dexie tests.
- Always run `npm run lint` and `npm run test:run` before committing.
- Conventional commit prefixes required (`feat:`, `fix:`, `docs:`).
- **Warning:** running `npx shadcn@latest init` overwrites `src/lib/utils.ts`; re‑apply custom helpers afterwards.

## 🏗 Architecture overview

1. **UI layer** – React components in `src/components/` and routes under `src/app/`.
2. **State layer** – React Contexts (`UserContext`, `ExerciseContext`, `RestTimerContext`).
3. **Data layer** – Dexie database defined in `src/lib/db/dexie.ts`; static programs live in `src/data/programs/*.json`.
4. **Business logic** – calculation helpers in `src/lib/calculations.ts` and `src/lib/cycle-calculations.ts`.

> Use these files as entry points when exploring new features.

## 🔍 Testing strategy

- **Unit tests** (Vitest) cover calculations, hooks, db logic, data mutations.
- **Integration tests** for contexts and components (React Testing Library).
- **E2E tests** (Playwright) cover critical user flows with mobile emulation (iPhone 13).
- To run a specific test: `npx vitest run tests/unit/your.test.ts` or `npx playwright test tests/e2e/your.spec.ts`.

## 📋 Project‑specific rules

- Local‑first, sync‑later. Write to Dexie first; queue changes for Supabase.
- Program JSON schema is authoritative. Add/modify programs in `src/data/programs/*.json` and update related tests.
- When modifying DB schema, update `src/lib/db/dexie.ts` **and** add migration tests under `tests/unit/db/`.
- All logical changes require corresponding unit tests; update `tests/setup.ts` only if new test infrastructure is needed.
- Preserve mobile‑first and one‑handed design in UI work (see `CLAUDE.md` for UX rules if needed).

## 🔗 Integration & environment

- Supabase credentials via `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` (see `src/lib/supabase/`).
- Additional libs: `recharts` for charts, `canvas-confetti` for celebration effects.

## 🔐 Security & sensitive areas

- Never commit secrets or `.env*` files. Handle server keys carefully.
- IndexedDB quotas and Dexie transaction errors must be caught in the DB layer with retry/backoff.

## 🤖 How an AI agent should operate

1. Make a focused, atomic change and add/modify tests.
2. Run lint and tests locally; ensure CI passes.
3. Consult `CLAUDE.md` or `.planning/codebase/CONVENTIONS.md` for additional context.
4. For DB or program updates, write migration/unit tests in the appropriate folder.

## 📌 Where to look first

- `src/contexts/` – context providers & hooks
- `src/lib/db/dexie.ts` – database schema & migrations
- `src/lib/calculations.ts` – core numeric logic
- `src/data/programs/` – static program definitions
- `tests/` – copy patterns from existing test files

> For mobile‑specific work, open `flutter_app/lib/` or `rn_app/src/` and follow
> the conventions described in those subprojects' documentation.

---

> ⚠️ Firebase CLI is installed globally in this workspace.

If any section needs clarification (e.g. test patterns, DB migrations, UI conventions), ask for feedback before proceeding.
