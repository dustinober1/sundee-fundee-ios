# Phase 05: Rebrand - Research

**Researched:** 2025-01-30
**Domain:** Text-only brand rename (Next.js App Router metadata + UI copy + config files)
**Confidence:** HIGH

## Summary

Phase 05 is a surgical text-replacement rebrand with zero new packages and zero functional risk — provided the frozen identifiers are never touched. The codebase uses "Strength" in two distinct ways: (1) **brand-name** appearances (app title, welcome copy, package.json) that must be replaced with "Sundee-Fundee", and (2) **domain/code identifiers** (function names, DB constants, fitness terms) that are permanently frozen.

A complete grep audit of `src/` found exactly **2 brand-name occurrences** inside source code (layout.tsx title and onboarding welcome text), plus 3 config/docs files (package.json, README.md, CLAUDE.md). There is no `manifest.ts` or PWA manifest file in this project, so the phase description's mention of it is inapplicable. There are no per-route `metadata` exports — only the single root `layout.tsx` controls browser tab titles for all routes.

The 11 existing Playwright E2E tests reference `'StrengthApp'` only in `pr-celebration.spec.ts` (the frozen IndexedDB name) and `'Positional Strength'` (program data, fitness term) — neither conflicts with the rebrand. No E2E test checks for the old brand title "Strength - Workout Tracker" or "Welcome to Strength", so all tests pass without modification.

**Primary recommendation:** Make 5 targeted file edits; run `grep -r "Strength" src/` to verify only frozen identifiers remain; run Playwright suite to confirm zero regression.

---

## Standard Stack

No new packages needed. All changes are pure text edits in existing files.

### Files to Change (Complete Exhaustive List)

| File | Line | Old Value | New Value |
|------|------|-----------|-----------|
| `src/app/layout.tsx` | 18 | `"Strength - Workout Tracker"` | `"Sundee-Fundee"` |
| `src/app/layout.tsx` | 19 | `"Track your workouts, build strength"` | `"Track your workouts and fitness goals"` |
| `src/components/onboarding/onboarding-wizard.tsx` | 60 | `'Welcome to Strength'` | `'Welcome to Sundee-Fundee'` |
| `package.json` | 2 | `"name": "strength"` | `"name": "sundee-fundee"` |
| `README.md` | 1 | `# Strength - Workout Tracking App` | `# Sundee-Fundee - Workout Tracking App` |
| `CLAUDE.md` | ~6 | `**Strength** is a mobile-first...` | `**Sundee-Fundee** is a mobile-first...` |

### Files Confirmed NOT to Change

| File | Reason |
|------|--------|
| `src/lib/db/dexie.ts` | `super('StrengthApp')` and `StrengthDatabase` are permanently frozen — changing destroys all user data |
| `src/types/user.ts` | `'strength'` in `PrimaryGoal` union is a fitness term, not a brand name |
| `src/components/onboarding/onboarding-wizard.tsx` line 115 | `<SelectItem value="strength">Build Strength</SelectItem>` is frozen fitness term |
| `src/lib/cycle-calculations.ts` | `analyzeStrengthPatterns`, `predictStrengthWindow`, `PhaseStrengthProfile` are domain identifiers |
| `src/types/cycle.ts` | `PhaseStrengthProfile` interface — domain type |
| `src/contexts/cycle-context.tsx` | `strengthProfile`, `PhaseStrengthProfile` — domain usage |
| `src/components/progress/weight-progress-chart.tsx` | `"strength progress"` lowercase — fitness term, not brand |
| `src/lib/cycle-calculations.ts` lines 141–173 | `"Building strength and endurance"` — fitness guidance text, not brand |
| `tests/e2e/pr-celebration.spec.ts` | `indexedDB.open('StrengthApp')` — frozen DB name; do NOT change |
| No `manifest.ts` | File does not exist in this project |

---

## Architecture Patterns

### Next.js App Router Metadata (HIGH confidence)

The entire app uses a single root metadata export in `src/app/layout.tsx`. There are **no per-route metadata exports** — confirmed by searching all `page.tsx` and `layout.tsx` files. Changing the root title/description propagates to all routes automatically.

```typescript
// Source: src/app/layout.tsx (verified)
export const metadata: Metadata = {
  title: "Sundee-Fundee",
  description: "Track your workouts and fitness goals",
};
```

Next.js App Router `metadata` export is the correct mechanism (not `<Head>` from Pages Router). No `generateMetadata` function is needed for simple static titles.

### Onboarding Welcome Text (HIGH confidence)

```typescript
// Source: src/components/onboarding/onboarding-wizard.tsx line 60 (verified)
// BEFORE:
{step === 1 && 'Welcome to Strength'}
// AFTER:
{step === 1 && 'Welcome to Sundee-Fundee'}
```

The `primaryGoal: 'strength'` default value on line 26 is a data value (frozen fitness term) — do NOT change this.

### package.json name field (HIGH confidence)

The `name` field in package.json is used by npm internally. It does NOT appear in browser UI. Changing it to `"sundee-fundee"` satisfies BRAND-03 with no functional side effects.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Finding all brand occurrences | Manual search | `grep -r "Strength" src/` | Deterministic, fast, citable |
| Verifying no regressions | Manual testing | Existing Playwright suite | 11 tests already cover all routes |

---

## Common Pitfalls

### Pitfall 1: Accidentally touching `super('StrengthApp')`
**What goes wrong:** Renaming the Dexie DB name silently creates a new IndexedDB database. All existing user data (workouts, cycles, programs) becomes inaccessible. No error is thrown.
**Why it happens:** `StrengthApp` looks like a brand name but is actually a storage key.
**How to avoid:** Never edit `src/lib/db/dexie.ts` during this phase. The `StrengthDatabase` class name and `super('StrengthApp')` call are both off-limits.
**Warning signs:** E2E test `pr-celebration.spec.ts` would fail because it explicitly opens `indexedDB.open('StrengthApp')`.

### Pitfall 2: Treating `'strength'` PrimaryGoal value as brand copy
**What goes wrong:** Renaming the `PrimaryGoal` union value `'strength'` to `'sundee-fundee'` would break type checks, stored user preferences, and all tests that use `primaryGoal: 'strength'`.
**How to avoid:** The value `'strength'` is fitness terminology (meaning "build muscular strength"). Leave it frozen.

### Pitfall 3: Missing the `description` field in layout.tsx
**What goes wrong:** `description: "Track your workouts, build strength"` contains "build strength" — lowercase, so it won't appear in `grep -r "Strength"`. It's ambiguous (fitness term vs brand flavor text).
**How to avoid:** Update the description to neutral fitness language. Recommended: `"Track your workouts and fitness goals"`.

### Pitfall 4: Assuming manifest.ts exists
**What goes wrong:** Phase requirements mention `manifest.ts` name/short_name. This file does **not exist** in the project. No action needed.
**Evidence:** `find . -name "manifest*" | grep -v node_modules` returns nothing.

### Pitfall 5: Thinking E2E tests reference brand strings
**What goes wrong:** Assuming "Welcome to Strength" or "Strength - Workout Tracker" are asserted in E2E tests, and that updating them would break tests.
**Evidence:** `grep -r "Welcome to Strength\|Strength - Workout" tests/` returns nothing. E2E tests do not check the app title or onboarding welcome string directly.

---

## Code Examples

### Complete layout.tsx after change
```typescript
// Source: src/app/layout.tsx (verified current state + target change)
export const metadata: Metadata = {
  title: "Sundee-Fundee",
  description: "Track your workouts and fitness goals",
};
```

### Complete onboarding title line after change
```tsx
// Source: src/components/onboarding/onboarding-wizard.tsx line 60
{step === 1 && 'Welcome to Sundee-Fundee'}
{step === 2 && 'Training Experience'}
{step === 3 && 'Your Goals'}
```

### Verification command after all changes
```bash
# Should return ONLY frozen identifiers - zero brand-name hits
grep -r "Strength" src/
# Expected surviving lines:
#   src/lib/db/dexie.ts: super('StrengthApp')
#   src/lib/db/dexie.ts: export class StrengthDatabase
#   src/lib/db/dexie.ts: export const db = new StrengthDatabase()
#   src/lib/cycle-calculations.ts: analyzeStrengthPatterns (function)
#   src/lib/cycle-calculations.ts: predictStrengthWindow (function)
#   src/lib/cycle-calculations.ts: PhaseStrengthProfile (type ref)
#   src/types/cycle.ts: PhaseStrengthProfile (interface)
#   src/contexts/cycle-context.tsx: strengthProfile, PhaseStrengthProfile (domain)
#   src/components/progress/weight-progress-chart.tsx: [lowercase "strength"] - not matched by capital-S grep
```

---

## State of the Art

No framework changes involved. This is purely content editing.

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `<Head>` in `_app.tsx` (Pages Router) | `export const metadata` in `layout.tsx` (App Router) | Next.js 13+ | Metadata in App Router is RSC-only, no `'use client'` in layout needed |

---

## Open Questions

1. **Title format: "Sundee-Fundee" vs "Sundee-Fundee - Workout Tracker"**
   - What we know: Phase says "browser tab titles read Sundee-Fundee". Could be bare name or include subtitle.
   - What's unclear: Whether the success criteria requires exact string match or just presence of the brand name.
   - Recommendation: Use bare `"Sundee-Fundee"` to satisfy the literal requirement. A subtitle can be added later if desired.

2. **`layout.tsx` description field: update or leave as-is?**
   - What we know: `"Track your workouts, build strength"` — lowercase "strength" (fitness term). Won't hit `grep -r "Strength"` test.
   - What's unclear: Whether the phase owner considers this brand-adjacent copy requiring update.
   - Recommendation: Update to `"Track your workouts and fitness goals"` as a clean neutral description. Low risk.

3. **`CLAUDE.md` further cleanup**
   - What we know: CLAUDE.md references `"Framework: Next.js 16"` but the project uses Next.js 15. Pre-existing inaccuracy.
   - Recommendation: Fix only the brand name (`**Strength**` → `**Sundee-Fundee**`). Don't touch unrelated inaccuracies during this phase.

---

## Sources

### Primary (HIGH confidence)
- Direct file inspection: `src/app/layout.tsx` — confirmed single metadata export
- Direct file inspection: `src/components/onboarding/onboarding-wizard.tsx` — confirmed line 60
- Direct file inspection: `src/lib/db/dexie.ts` — confirmed frozen `super('StrengthApp')`
- `grep -r "Strength" src/` — exhaustive audit, verified all 6 files
- `grep -r "Strength\|strength" tests/` — verified no E2E tests assert brand strings

### Secondary (MEDIUM confidence)
- Next.js App Router docs: `export const metadata` is the correct pattern for static titles in App Router
- No `manifest.ts` file found — confirmed by `find . -name "manifest*" | grep -v node_modules`

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all changes are text edits
- Architecture: HIGH — verified by direct file inspection
- Pitfalls: HIGH — frozen identifiers confirmed by grep audit and E2E test inspection

**Research date:** 2025-01-30
**Valid until:** Until codebase changes (stable; text changes don't expire)
