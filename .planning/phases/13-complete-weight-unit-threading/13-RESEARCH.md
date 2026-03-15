# Phase 13: Complete Weight Unit Threading - Research

**Researched:** 2026-03-15
**Domain:** React Native / Expo Router — weight unit preference propagation across screens
**Confidence:** HIGH

## Summary

Phase 13 closes PLAT-05 (user can switch between lbs and kg) by threading the `weightUnit` setting into
the two remaining screens that hardcode "lbs" suffixes: `HistoryCard.tsx` and `exercise-detail.tsx`.

The infrastructure is fully in place. `formatWeight` and `formatWeightNumeric` utilities are working and
well-tested. `AppSettings.weightUnit` is persisted via `SettingsRepository` and already consumed by
`maxes.tsx` (ExerciseRow), `workout-detail.tsx`, `workout-session.tsx`, and the export pipeline. The gap
is narrow: two locations did not receive the unit prop when those screens were originally built.

**Primary recommendation:** Add a `weightUnit?: WeightUnit` prop to `HistoryCard.formatVolume` and update
`exercise-detail.tsx` to load settings and pass the unit to all weight display calls. Follow the exact
pattern used in `workout-detail.tsx` (load settings in `useEffect`, default to `'lb'`).

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLAT-05 | User can switch between lbs and kg | `weightUnit` is stored in `AppSettings`, `formatWeight` converts correctly, only rendering gaps remain |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `formatWeight` | internal | Convert stored-lbs to display string with unit suffix | Already used in workout-detail, maxes, export, workout-session |
| `formatWeightNumeric` | internal | Convert stored-lbs to numeric for numeric display (no suffix) | Used in maxes ExerciseRow |
| `getSettingsRepo` / `AppSettings` | internal | Load persisted weightUnit preference | Same factory used in all weight-aware screens |
| `WeightUnit` type | `src/domain/types/index.ts` | `'lb' | 'kg'` type alias | Used across the codebase consistently |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `DEFAULT_SETTINGS` | internal | Fallback when settings load fails | Always default to `'lb'` on catch — backward compatible |
| `useEffect` (React) | React 19 | Load settings on mount | Same pattern as workout-detail, maxes |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Prop threading | React Context for weightUnit | Context would avoid prop drilling but adds indirection; prop threading is simpler for 2 affected files and matches existing patterns in this codebase |

**No additional installation required.** All dependencies already in package.json.

## Architecture Patterns

### Recommended Project Structure
No new files needed. Changes are surgical modifications to two existing files plus new test files.

```
app/(app)/exercise-detail.tsx           ← add settings load + pass weightUnit
src/components/history/HistoryCard.tsx  ← update formatVolume signature + add WeightUnit import
app/(app)/(tabs)/history.tsx            ← pass weightUnit prop down to HistoryCard
app/(app)/__tests__/exercise-detail.test.tsx   ← NEW (Wave 0 gap)
src/components/history/__tests__/HistoryCard.test.ts  ← NEW (Wave 0 gap)
```

### Pattern 1: Settings Load on Mount (established)
**What:** Load `weightUnit` from `SettingsRepository` in `useEffect`, default to `'lb'`
**When to use:** Any screen that needs to display weights

The established pattern from `workout-detail.tsx`:

```typescript
// Source: app/(app)/workout-detail.tsx (lines 107–123)
const [weightUnit, setWeightUnit] = useState<WeightUnit>('lb');

useEffect(() => {
  if (!user) return;
  async function loadSettings(): Promise<void> {
    if (!user) return;
    try {
      const settings = await getSettingsRepo(isGuest).getSettings(user.uid);
      if (settings) {
        setWeightUnit(settings.weightUnit);
      }
    } catch (err) {
      console.error('[ExerciseDetail] Settings load failed:', err);
    }
  }
  void loadSettings();
}, [user, isGuest]);
```

### Pattern 2: formatVolume with weightUnit (the change)
**What:** `HistoryCard.formatVolume` currently hardcodes " lbs". It must accept a `WeightUnit` param.

Current (broken):
```typescript
// Source: src/components/history/HistoryCard.tsx (lines 53–59)
export function formatVolume(volume: number | undefined): string | null {
  if (volume === undefined) return null;
  if (volume >= 1000) {
    return `${(volume / 1000).toFixed(1)}k lbs`;
  }
  return `${volume} lbs`;
}
```

Corrected pattern — use `formatWeight`:
```typescript
import { formatWeight } from '@/src/utils/formatWeight';
import type { WeightUnit } from '@/src/domain/types';

export function formatVolume(
  volume: number | undefined,
  unit: WeightUnit = 'lb'
): string | null {
  if (volume === undefined) return null;
  return formatWeight(volume, unit);
}
```

The `k lbs` abbreviation is dropped in favor of the canonical `formatWeight` — volume can exceed 1000 lbs
but `formatWeight` already handles large values correctly and the abbreviated form wasn't unit-aware.

### Pattern 3: HistoryCard prop update
**What:** `HistoryCardProps` must expose `weightUnit` so `history.tsx` can pass it through.

```typescript
interface HistoryCardProps {
  item: HistoryItem;
  onPress: (item: HistoryItem) => void;
  onDelete: (item: HistoryItem) => void;
  weightUnit?: WeightUnit;   // default 'lb' — backward compatible
}
```

`history.tsx` (the parent) must load `weightUnit` from settings the same way `maxes.tsx` does (separate
`useEffect` calling `getSettingsRepo`).

### Pattern 4: exercise-detail.tsx — three hardcoded sites
Three places in `exercise-detail.tsx` use hardcoded "lbs":

1. **PR badge value:** `{Math.round(best1RM.weight)} lbs` → replace with `formatWeight(best1RM.weight, weightUnit)`
2. **1RM chart y-axis label:** `yLabel="lbs (estimated)"` → `yLabel={weightUnit === 'kg' ? 'kg (estimated)' : 'lbs (estimated)'}`
3. **Volume chart y-axis label:** `yLabel="total volume (lbs)"` → `yLabel={weightUnit === 'kg' ? 'total volume (kg)' : 'total volume (lbs)'}`

### Anti-Patterns to Avoid
- **Hardcoding `'lb'` as default inside HistoryCard render:** Always thread the prop from the parent; use `'lb'` only as a fallback default value in the prop type.
- **Using `k lbs` abbreviation in formatVolume:** The previous abbreviated form was not unit-aware. Use `formatWeight` directly — it handles all magnitudes correctly.
- **Loading settings twice in history.tsx:** One `useEffect` loading both history and settings is cleaner than two separate effects. Use the `maxes.tsx` approach: two separate `useEffect` hooks to keep concerns isolated.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| lbs→kg conversion | Custom math | `formatWeight(lbs, unit)` from `src/utils/formatWeight` | Already handles rounding to 0.5 kg increments, edge cases, suffix |
| Numeric conversion | Custom math | `formatWeightNumeric(lbs, unit)` | Same, but returns number |
| Settings persistence | Manual AsyncStorage | `getSettingsRepo(isGuest)` | Factory already chooses Firestore vs local |

**Key insight:** `formatWeight` is the single source of truth for weight display. Every weight shown to users must pass through it.

## Common Pitfalls

### Pitfall 1: Passing `weightUnit` to `formatVolume` callers
**What goes wrong:** `history.tsx` calls `HistoryCard` without a `weightUnit` prop — the prop is added to HistoryCard but never populated.
**Why it happens:** Settings load is omitted from `history.tsx`.
**How to avoid:** Add a `useEffect` in `history.tsx` identical to the one in `maxes.tsx` (lines 100–113).
**Warning signs:** Volume stat on history cards still shows "lbs" after switching unit in settings.

### Pitfall 2: HistoryCard has no tests yet
**What goes wrong:** `formatVolume` is exported but has no unit tests. The new signature could silently break callers if the default is wrong.
**Why it happens:** No `HistoryCard.test.ts` file exists.
**How to avoid:** Create `src/components/history/__tests__/HistoryCard.test.ts` covering `formatVolume(undefined)`, `formatVolume(500, 'lb')`, `formatVolume(500, 'kg')`, `formatVolume(1500, 'lb')`.

### Pitfall 3: exercise-detail.tsx has no test file
**What goes wrong:** Weight display changes in `exercise-detail.tsx` are untested. CI requires 100% line coverage on `src/**/*.{ts,tsx}`.
**Why it happens:** `exercise-detail.tsx` is in `app/`, not `src/`, so `collectCoverageFrom` does not apply. BUT a test is still needed for the pattern to match `workout-detail.test.tsx`.
**How to avoid:** Create `app/(app)/__tests__/exercise-detail.test.tsx` following the exact mock pattern in `workout-detail.test.tsx`. Test PR badge shows kg/lbs depending on setting.

### Pitfall 4: Importing WeightUnit in HistoryCard
**What goes wrong:** WeightUnit is not currently imported in `HistoryCard.tsx` — adding it requires an import from `@/src/domain/types`.
**Why it happens:** HistoryCard previously had no weight display logic beyond the hardcoded `formatVolume`.
**How to avoid:** Add `import type { WeightUnit } from '@/src/domain/types';` and `import { formatWeight } from '@/src/utils/formatWeight';` at the top.

### Pitfall 5: AppSettings.weightUnit type vs WeightUnit domain type
**What goes wrong:** `AppSettings.weightUnit` is typed `'lb' | 'kg'` (inline union in `SettingsRepo.ts`). The domain `WeightUnit` from `src/domain/types/index.ts` is the same union. They are compatible but NOT the same import.
**Why it happens:** Two separate definitions exist.
**How to avoid:** Cast via `as WeightUnit` when assigning from `AppSettings.weightUnit`, or import `WeightUnit` from domain types and rely on structural compatibility. Both work; the existing pattern in `maxes.tsx` uses `import type { WeightUnit } from '@/src/domain/types'` and `useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit)`.

## Code Examples

### Full change for HistoryCard.formatVolume
```typescript
// Source: src/components/history/HistoryCard.tsx — updated
import { formatWeight } from '@/src/utils/formatWeight';
import type { WeightUnit } from '@/src/domain/types';

export function formatVolume(
  volume: number | undefined,
  unit: WeightUnit = 'lb'
): string | null {
  if (volume === undefined) return null;
  return formatWeight(volume, unit);
}
```

### Full change for history.tsx settings load
```typescript
// Source: app/(app)/(tabs)/history.tsx — new useEffect after existing one
const [weightUnit, setWeightUnit] = useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit);

// Load weight unit preference
useEffect(() => {
  if (!user) return;
  void (async () => {
    try {
      const repo = getSettingsRepo(isGuest);
      const stored = await repo.getSettings(user.uid);
      if (stored?.weightUnit) {
        setWeightUnit(stored.weightUnit);
      }
    } catch {
      // Keep default on error
    }
  })();
}, [user, isGuest]);
```

And in the `renderItem` of `SectionList`:
```typescript
<HistoryCard
  item={item}
  onPress={handleCardPress}
  onDelete={handleDelete}
  weightUnit={weightUnit}
/>
```

### Full change for exercise-detail.tsx PR badge
```typescript
// Source: app/(app)/exercise-detail.tsx — updated PR badge
import { formatWeight } from '@/src/utils/formatWeight';
import type { WeightUnit } from '@/src/domain/types';
import { getSettingsRepo, DEFAULT_SETTINGS } from '@/src/repositories/SettingsRepo';

// ... in component state:
const [weightUnit, setWeightUnit] = useState<WeightUnit>(DEFAULT_SETTINGS.weightUnit);

// ... in render:
<Text style={styles.prBadgeValue}>{formatWeight(best1RM.weight, weightUnit)}</Text>

// ... chart labels:
yLabel={weightUnit === 'kg' ? 'kg (estimated)' : 'lbs (estimated)'}
yLabel={weightUnit === 'kg' ? 'total volume (kg)' : 'total volume (lbs)'}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded " lbs" suffix in formatVolume | `formatWeight(volume, unit)` respects setting | Phase 13 | History tab volume stat shows kg correctly |
| Hardcoded " lbs" in exercise-detail PR badge | `formatWeight(best1RM.weight, weightUnit)` | Phase 13 | PR value on detail screen respects setting |
| ProgressChart `yLabel` hardcoded "lbs" | Dynamic label based on `weightUnit` | Phase 13 | Chart axis label matches selected unit |
| No settings load in history.tsx | settings load useEffect mirrors maxes.tsx | Phase 13 | Unit preference flows to HistoryCard |

**Deprecated/outdated:**
- `k lbs` abbreviation in `formatVolume`: this abbreviated form had no unit-aware equivalent. Drop it; `formatWeight` returns `453.5 kg` or `1000.0 lbs` which is readable at any magnitude.

## Open Questions

1. **Should `k lbs` abbreviation be preserved for large volumes?**
   - What we know: The old `formatVolume` showed `1.5k lbs` for volumes >= 1000. `formatWeight` shows `1000.0 lbs` or `453.5 kg`.
   - What's unclear: Whether users prefer the abbreviated form.
   - Recommendation: Drop the abbreviation. `formatWeight` is the established contract; introducing a parallel abbreviated format creates inconsistency with every other weight display in the app. If desired in future, extend `formatWeight` itself.

2. **Does `RepRangePRTable` need unit threading?**
   - What we know: `RepRangePRTable` hardcodes `${pr.weight} lbs` on line 73. It is rendered inside `exercise-detail.tsx`.
   - What's unclear: Whether this was intentionally deferred or missed.
   - Recommendation: Include it in Phase 13. It is on the same `exercise-detail` screen and fixing it in the same plan avoids a follow-up. Add `weightUnit?: WeightUnit` to `RepRangePRTableProps` and use `formatWeight(pr.weight, unit)`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest (jest-expo preset) |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Quick run command | `cd SundeeFundeeRN && npx jest --testPathPattern="HistoryCard|exercise-detail" --no-coverage` |
| Full suite command | `cd SundeeFundeeRN && npx jest --coverage` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLAT-05 | `formatVolume` respects `weightUnit` prop | unit | `npx jest --testPathPattern="HistoryCard" --no-coverage` | Wave 0 |
| PLAT-05 | `HistoryCard` renders volume in kg when unit=kg | unit | `npx jest --testPathPattern="HistoryCard" --no-coverage` | Wave 0 |
| PLAT-05 | `exercise-detail` PR badge shows kg when unit=kg | component | `npx jest --testPathPattern="exercise-detail" --no-coverage` | Wave 0 |
| PLAT-05 | `exercise-detail` loads settings and passes unit to RepRangePRTable | component | `npx jest --testPathPattern="exercise-detail" --no-coverage` | Wave 0 |
| PLAT-05 | `RepRangePRTable` renders weight in kg when unit=kg | unit | `npx jest --testPathPattern="RepRangePRTable" --no-coverage` | Wave 0 |

### Sampling Rate
- **Per task commit:** `cd SundeeFundeeRN && npx jest --testPathPattern="HistoryCard|exercise-detail|RepRangePR" --no-coverage`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --coverage`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `SundeeFundeeRN/src/components/history/__tests__/HistoryCard.test.ts` — covers `formatVolume` with unit param (PLAT-05)
- [ ] `SundeeFundeeRN/app/(app)/__tests__/exercise-detail.test.tsx` — covers PR badge and chart label unit rendering (PLAT-05)
- [ ] `SundeeFundeeRN/src/components/charts/__tests__/RepRangePRTable.test.tsx` — covers weight cell rendering with unit param (PLAT-05)

## Sources

### Primary (HIGH confidence)
- Direct code inspection: `SundeeFundeeRN/src/utils/formatWeight.ts` — confirmed API and behavior
- Direct code inspection: `SundeeFundeeRN/src/components/history/HistoryCard.tsx` — confirmed hardcoded lbs locations
- Direct code inspection: `SundeeFundeeRN/app/(app)/exercise-detail.tsx` — confirmed 3 hardcoded lbs sites + RepRangePRTable gap
- Direct code inspection: `SundeeFundeeRN/app/(app)/workout-detail.tsx` — confirmed reference pattern for settings load
- Direct code inspection: `SundeeFundeeRN/app/(app)/(tabs)/maxes.tsx` — confirmed reference pattern for settings load in tab screen
- Direct code inspection: `SundeeFundeeRN/src/repositories/SettingsRepo.ts` — confirmed AppSettings.weightUnit type and factory

### Secondary (MEDIUM confidence)
- Cross-referenced STATE.md Phase 07 decision: "weightUnit defaults to lb everywhere via optional prop — backward compatible with callers that dont pass it" — confirms the opt-in default pattern used here

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all utilities are in production use; no new dependencies
- Architecture: HIGH — pattern is established in workout-detail.tsx and maxes.tsx; changes are mechanical
- Pitfalls: HIGH — identified by direct diff between working screens and broken screens

**Research date:** 2026-03-15
**Valid until:** Stable — no fast-moving dependencies; valid until codebase changes
