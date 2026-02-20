# Project State

## Reference
See: .planning/PROJECT.md (updated 2026-02-19)

**Core value:** Users can reliably track their strength training progress offline and receive actionable insights to improve performance.
**Current focus:** Milestone v1.1 — Sundee-Fundee rebrand + PWA + Icon Enrichment

## Current Position
**Milestone**: v1.1 Sundee-Fundee
**Phase**: 8 — Install Experience + Icon Enrichment (complete)
**Plan**: 2 of 2 complete
**Status**: Phase 8 complete — Milestone v1.1 fully delivered

```
v1.1 Progress: [█] [██] [██] [██]   7/7 plans
               Ph5  Ph6  Ph7   Ph8
```

**Last activity**: 2026-02-20 — Completed 08-02 and phase verification passed (12/12 must-haves; all 11 E2E pass).

## Performance Metrics
- **Velocity**: v1.0 shipped in 4 days (2026-02-15 → 2026-02-19)
- **Blockers**: None
- **Open questions before Phase 6**: Source SVG/PNG for app icon; confirm `short_name` (≤12 chars — "Sundee-Fundee" is 13); confirm `start_url` auth behavior (`/dashboard` vs `/`)

## Accumulated Context

### Key Decisions (carried forward)
- Local-first Architecture: Ensures app works reliably in gyms with poor connectivity
- Dexie.js for Storage: Robust wrapper for IndexedDB with good TypeScript support
- Supabase for Sync: Easy integration, reliable auth/db solution for backup
- null Supabase client when env vars missing: Prevents prerender throw; app works offline-only
- localstorage offline queue: Survives page refreshes; no service worker needed (until PWA)

### v1.1 Critical Decisions
- `@serwist/turbopack` chosen (not `@serwist/next`) — only valid option for Next.js 16 Turbopack default
- `super('StrengthApp')` in `dexie.ts` is **permanently frozen** — changing it silently destroys all user data
- `serviceWorkers: 'block'` added to `playwright.config.ts` in Phase 6 (before SW exists) — guards all 11 tests
- Supabase routes configured as `NetworkOnly` in SW — auth-gated responses must never be cached
- `controllerchange` handled in layout to prevent mid-workout data loss on SW update
- `Activity` icon (not `ClipboardPlus`) used for bottom nav Workout tab — fitness-semantic, distinct from Dumbbell (Programs tab)

### v1.1 Rebrand Scope Boundaries
| Change ✓ | Freeze ✗ |
|----------|---------|
| `layout.tsx` title/description | `super('StrengthApp')` in `dexie.ts` |
| `package.json` name field | `PrimaryGoal` union value `'strength'` (fitness term) |
| Onboarding welcome text | Domain function names (`analyzeStrengthPatterns`, etc.) |
| `manifest.ts` name/short_name | `<SelectItem value="strength">Build Strength</SelectItem>` |
| `README.md`, `CLAUDE.md`, `.planning/` docs | E2E tests referencing `'StrengthApp'` IDB name |

## Session Continuity
- **Last session**: 2026-02-20 — Completed 08-02 (ICON-01–04 icon enrichment across 6 components)
- **Stopped at**: Completed 08-02-SUMMARY.md
- **Resume with**: Milestone v1.1 complete — next milestone planning or Lighthouse PWA audit
