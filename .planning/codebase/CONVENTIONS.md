# CONVENTIONS

## Purpose
Coding, naming and testing conventions used across the repository.

## Code style
- TypeScript-first (strict types in `src/types/`)
- Functional React components + hooks (hook names start with `use`)
- Component files: `PascalCase` for components, `kebab-case` for data files

## State & contexts
- Single responsibility per context (e.g., `UserContext`, `RestTimerContext`)
- Context providers live in `src/contexts/` and expose actions + selectors

## File & folder conventions
- Feature grouping under `components/<feature>/` and `src/app/<route>/`
- Static domain data in `src/data/` (program JSON)

## Testing
- Unit tests in `tests/unit/` with Vitest
- Integration tests for contexts and providers in `tests/integration/`
- E2E flows in `tests/e2e/` (Playwright, mobile viewport)
- Use `fake-indexeddb` in tests that touch Dexie (see `tests/setup.ts`)

## Commits & branches
- Follow conventional commit-like messages for feature clarity (e.g., `feat:`, `fix:`, `docs:`)

---
Enforcement: run `npm run lint` and include test coverage on PRs.