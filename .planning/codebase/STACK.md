# STACK

## Purpose
High-level list of the main technologies, runtimes and developer tooling used by this repository.

## Core
- Framework: `Next.js` (App Router, Next 16)
- Language: `TypeScript` (strict typing)
- UI: `React 19`, `shadcn/ui`, `Tailwind CSS`
- Mobile: Expo / React Native app in `apps/mobile`

## State & Storage
- Local DB: `IndexedDB` via `Dexie.js` (primary, offline-first)
- Optional sync: `Supabase` (cloud backup / cross-device)

## Libraries & Features
- Animations: `Framer Motion` + custom animation components
- Charts: `Recharts`
- Fonts / design: Geist font + shadcn/ui components

## Testing & CI
- Unit / integration: `Vitest` + React Testing Library
- E2E: `Playwright` (mobile viewport)

## Dev / Build
- Package manager: `npm`
- Lint: ESLint (`eslint.config.mjs`)
- Build: `next build` / `npm run dev`

## Important files / entry points
- App root: `src/app/layout.tsx`, `src/app/page.tsx`
- Data & seeds: `src/data/programs/`, `src/data/exercises.ts`
- IndexedDB layer: `src/lib/db/dexie.ts`
- Business logic: `src/lib/calculations.ts`, `src/lib/cycle-calculations.ts`
- State providers: `src/contexts/*-context.tsx`
- Mobile app: `apps/mobile/`

## How to run (quick)
```bash
npm install
npm run dev        # web (Next.js)
# mobile (Expo)
cd apps/mobile && npm install && npm run start
```

---
Status: up-to-date with repository structure.