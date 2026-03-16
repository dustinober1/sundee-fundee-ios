# Phase 10: UI Polish Fixes - Research

**Researched:** 2026-03-15
**Domain:** React Native / Expo Router UI bug fixes — weight unit display, navigation, web export
**Confidence:** HIGH

## Summary

Phase 10 closes three concrete tech debt items identified during the post-launch audit. Each bug is
narrow and well-bounded:

1. **formatWeight missing in detail views** — `workout-detail.tsx` hard-codes `" lbs"` strings in
   `CompletedExerciseSection` and `AIExerciseSection` instead of calling `formatWeight(lbs, unit)`.
   The `formatWeight` utility already exists in `src/utils/formatWeight.ts` and is tested. The
   settings repo and `AppSettings.weightUnit` are already wired in other screens (workoutsession,
   maxes, ai-workout config). The fix is loading the user's setting via `getSettingsRepo` then
   threading it into the two sub-components — exactly the same pattern already used in
   `workout-session.tsx`.

2. **goodbye.tsx missing Stack.Screen declaration** — `app/(app)/_layout.tsx` declares every
   authenticated route via `<Stack.Screen name="...">` except `goodbye`. When `settings.tsx` calls
   `router.replace('/goodbye')` after account deletion, Expo Router falls back to its default
   presentation (which shows the system navigation bar and a back button). Adding
   `<Stack.Screen name="goodbye" options={{ headerShown: false }} />` fixes this without touching
   any other file.

3. **Web CSV export downloads separate files instead of a zip** — `exportData.ts` already imports
   and uses `react-native-zip-archive` for mobile, but the web branch intentionally downloaded each
   CSV file separately (the STATE.md decision reads: "Web export downloads individual CSV files —
   browser has no native zip API, react-native-zip-archive is mobile-only"). The audit identified
   this as a UX regression — 7 separate browser download dialogs is unacceptable. The fix is to use
   the `JSZip` library (pure JavaScript, browser-native, no native module required) on the web
   branch to bundle CSV files into a single zip blob download.

**Primary recommendation:** Three independent single-file (or near-single-file) edits. Implement
as one plan with three tasks; each task has its own test coverage requirement.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLAT-05 | User can switch between lbs and kg | formatWeight utility exists; SettingsRepo wired; bug is that workout-detail.tsx bypasses it with hardcoded " lbs" strings — fix threads weightUnit through detail view sub-components |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `expo-router` | already installed | File-system routing, Stack.Screen declarations | Project standard — all screens use it |
| `formatWeight` (local util) | n/a | Convert lbs → display string with unit | Already implemented, tested, used by workout-session + maxes |
| `getSettingsRepo` | n/a | Fetch AppSettings including weightUnit | Already wired in settings.tsx, workout-session.tsx |
| `JSZip` | ^3.10.x | Pure-JS zip library for web | Browser-safe; no native module; de-facto standard for web zip |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `react-native-zip-archive` | already installed | Native zip on iOS/Android | Already used in exportData.ts mobile path — do not replace |
| `expo-file-system/legacy` | already installed | Write files on mobile | Already used in exportData.ts — no change needed |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| JSZip | fflate, archiver | JSZip has widest web/RN compatibility; fflate is also fine but JSZip better documented for Blob-based download pattern |
| JSZip | Native browser FileSaver | FileSaver depends on `saveAs()` which is not standard — JSZip + URL.createObjectURL is safer |

**Installation (web zip only):**
```bash
cd SundeeFundeeRN && npm install jszip
cd SundeeFundeeRN && npm install --save-dev @types/jszip
```

## Architecture Patterns

### Recommended Project Structure

No new directories. All edits are in-place:
```
app/(app)/
├── _layout.tsx          ← add Stack.Screen name="goodbye"
├── workout-detail.tsx   ← load weightUnit from SettingsRepo, thread into sub-components
└── goodbye.tsx          ← no change needed (screen itself is correct)

src/export/
└── exportData.ts        ← replace web CSV branch with JSZip bundle
```

### Pattern 1: Load Settings and Thread Into Detail Screen
**What:** Async-load user settings on mount, pass weightUnit down to sub-components as prop.
**When to use:** Any detail screen that displays weight values without a live workout context.
**Example (matches workout-session.tsx pattern already in project):**
```typescript
// In WorkoutDetailScreen component:
const [weightUnit, setWeightUnit] = useState<'lb' | 'kg'>('lb');

useEffect(() => {
  if (!user) return;
  async function loadUnit(): Promise<void> {
    if (!user) return;
    try {
      const repo = getSettingsRepo(isGuest);
      const s = await repo.getSettings(user.uid);
      if (s?.weightUnit) setWeightUnit(s.weightUnit);
    } catch {
      // default lb remains
    }
  }
  void loadUnit();
}, [user, isGuest]);

// Then pass weightUnit into sub-components:
<CompletedExerciseSection exercise={exercise} weightUnit={weightUnit} />
<AIExerciseSection exercise={exercise} weightUnit={weightUnit} />
```

### Pattern 2: Stack.Screen Declaration for Authenticated Routes
**What:** Every route under `app/(app)/` needs an explicit `<Stack.Screen>` entry in
`app/(app)/_layout.tsx` to control presentation options.
**When to use:** Any screen that must suppress the system header or control presentation mode.
**Example:**
```typescript
// In AppLayout's Stack:
<Stack.Screen
  name="goodbye"
  options={{ headerShown: false }}
/>
```

### Pattern 3: JSZip Web Bundle
**What:** Collect multiple string-content files into a single zip Blob, then trigger download.
**When to use:** Web-only branch when multiple files must be bundled.
**Example (replaces the per-file loop in exportData.ts):**
```typescript
import JSZip from 'jszip';

// In exportUserData, isWeb + csv branch:
const jszip = new JSZip();
for (const file of csvFiles) {
  jszip.file(file.name, file.content);
}
const zipBlob = await jszip.generateAsync({ type: 'blob' });
const url = URL.createObjectURL(zipBlob);
const link = document.createElement('a');
link.href = url;
link.download = `sundee-fundee-export-${dateStr}.zip`;
document.body.appendChild(link);
link.click();
document.body.removeChild(link);
URL.revokeObjectURL(url);
```

### Anti-Patterns to Avoid
- **Hardcoding unit labels in detail views:** Always call `formatWeight(lbs, unit)` — never
  concatenate `" lbs"` directly. The bug being fixed is exactly this pattern.
- **Adding new routes without Stack.Screen:** Every `app/(app)/` route must have a matching
  `<Stack.Screen>` entry or Expo Router uses its own defaults unpredictably.
- **Importing `react-native-zip-archive` on web:** It is a native module and will crash the web
  bundle. The `Platform.OS === 'web'` branch in `exportData.ts` already guards against it; keep
  JSZip in the web-only code path.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Zip file in browser | Custom binary writer | JSZip | ZIP format has complex CRC/header requirements; JSZip handles all edge cases |
| Weight conversion | Custom conversion | `formatWeight` from `src/utils/formatWeight.ts` | Already handles lbs→kg rounding (0.5 kg increments), tested, consistent |
| Settings loading | Inline AsyncStorage reads | `getSettingsRepo(isGuest)` | Abstracts guest vs. Firestore; already tested in SettingsRepo tests |

**Key insight:** All three fixes reuse already-existing code — the work is wiring, not
building. No new domain logic is required.

## Common Pitfalls

### Pitfall 1: totalVolume displayed without unit conversion
**What goes wrong:** `workout-detail.tsx` line 157 renders `record.totalVolume` with hardcoded
`" lbs"` regardless of weightUnit. This is separate from the per-set display but equally wrong.
**Why it happens:** totalVolume is stored in lbs; the display label was not updated when the weight
unit setting was added.
**How to avoid:** Convert totalVolume through `formatWeight` or `formatWeightNumeric` just like
individual set weights.
**Warning signs:** Volume stat shows `"lbs"` suffix while set weights show `"kg"`.

### Pitfall 2: weightUnit loaded but user or isGuest changes mid-render
**What goes wrong:** If `useEffect` dependency array omits `isGuest`, a guest who upgrades to auth
mid-session sees the wrong repo.
**How to avoid:** Include both `user` and `isGuest` in the `useEffect` deps — matches the existing
pattern in the same file's workout-load `useEffect`.

### Pitfall 3: JSZip `generateAsync` returns a Promise — not awaiting it
**What goes wrong:** Calling `jszip.generateAsync(...)` without `await` causes the download link
to be set with an unresolved Promise reference.
**How to avoid:** Always `await jszip.generateAsync({ type: 'blob' })` before creating the object URL.

### Pitfall 4: goodbye screen accessible via back navigation after account deletion
**What goes wrong:** Without `headerShown: false`, the system back button appears. Pressing it
navigates to the deleted user's authenticated session — a broken state.
**How to avoid:** Combine `headerShown: false` with the existing `router.replace('/goodbye')` call
in settings.tsx (replace not push, so the back stack is cleared).

### Pitfall 5: JSZip on React Native (non-web) bundling
**What goes wrong:** If JSZip import is at module top-level, Metro bundles it into mobile builds
unnecessarily (adds ~100KB).
**How to avoid:** Import JSZip only inside the `if (isWeb)` branch using a dynamic import, or
guard with `Platform.OS === 'web'` at import time. Pattern used elsewhere in the project: dynamic
`require()` in platform-specific branches (see firestore.ts decision in STATE.md).

## Code Examples

Verified patterns from project codebase:

### Current bug location — per-set weight display
```typescript
// workout-detail.tsx line 222 (CURRENT — WRONG)
<Text style={[styles.setCell, styles.setWeightCell]}>
  {set.weight > 0 ? `${set.weight} lbs` : '—'}
</Text>

// FIXED:
<Text style={[styles.setCell, styles.setWeightCell]}>
  {set.weight > 0 ? formatWeight(set.weight, weightUnit) : '—'}
</Text>
```

### Current bug location — AI exercise weight
```typescript
// workout-detail.tsx lines 247-250 (CURRENT — WRONG)
const weightText =
  exercise.weightLb !== null && exercise.weightLb > 0
    ? `${exercise.weightLb} lbs`
    : ...

// FIXED:
const weightText =
  exercise.weightLb !== null && exercise.weightLb > 0
    ? formatWeight(exercise.weightLb, weightUnit)
    : ...
```

### Current bug location — totalVolume label
```typescript
// workout-detail.tsx line 156-158 (CURRENT — WRONG)
{record.totalVolume !== undefined && (
  <MetaStat label="Volume" value={`${record.totalVolume} lbs`} />
)}

// FIXED:
{record.totalVolume !== undefined && (
  <MetaStat label="Volume" value={formatWeight(record.totalVolume, weightUnit)} />
)}
```

### Missing Stack.Screen in _layout.tsx
```typescript
// app/(app)/_layout.tsx — ADD after the existing "ai-workout" entry:
<Stack.Screen
  name="goodbye"
  options={{ headerShown: false }}
/>
```

### JSZip web export replacement
```typescript
// src/export/exportData.ts — replace web CSV branch
if (isWeb) {
  const JSZip = (await import('jszip')).default;
  const zip = new JSZip();
  for (const file of csvFiles) {
    zip.file(file.name, file.content);
  }
  const zipBlob = await zip.generateAsync({ type: 'blob' });
  triggerWebDownload(zipBlob, `sundee-fundee-export-${dateStr}.zip`, 'application/zip');
  return;
}

// Update triggerWebDownload to accept Blob | string:
function triggerWebDownload(content: Blob | string, filename: string, mimeType: string): void {
  const blob = content instanceof Blob ? content : new Blob([content], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded "lbs" in detail views | `formatWeight(lbs, unit)` | Phase 7 added formatWeight | Detail screens missed the wiring |
| Web CSV: 7 individual downloads | Web CSV: single zip download | Phase 10 | 1 download dialog instead of 7 |
| No Stack.Screen for goodbye | Explicit `headerShown: false` | Phase 10 | No stray back button after account deletion |

**Phase 7 decision (from STATE.md):**
> "Web export downloads individual CSV files — browser has no native zip API, react-native-zip-archive is mobile-only"

This decision was pragmatic at the time. Phase 10 supersedes it by adding JSZip for the web path.
The mobile path is unchanged.

## Open Questions

1. **JSZip size impact on mobile bundle**
   - What we know: JSZip is pure JS, no native module, ~90KB minified
   - What's unclear: Whether dynamic import in the web branch is sufficient to tree-shake it from mobile builds in Metro
   - Recommendation: Use dynamic `import('jszip')` inside `if (isWeb)` block — Metro will still bundle it unless platform-split files are used. If bundle size is a concern, create `exportData.web.ts` + `exportData.native.ts` platform split. For Phase 10 the dynamic import approach is acceptable.

2. **totalVolume unit in workout records**
   - What we know: `WorkoutRecord.totalVolume` is stored in lbs (logged during workout-session)
   - What's unclear: Whether any existing records have totalVolume stored in kg (from a hypothetical old code path)
   - Recommendation: Safe to treat all stored values as lbs — storage is always lbs per `formatWeight.ts` design.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | jest-expo (Jest 29) |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Quick run command | `cd SundeeFundeeRN && npx jest --testPathPattern="workout-detail|goodbye|exportData" --passWithNoTests` |
| Full suite command | `cd SundeeFundeeRN && npx jest --coverage` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLAT-05 | workout-detail displays weights in user's unit (lbs or kg) | unit | `npx jest --testPathPattern="workout-detail"` | ❌ Wave 0 |
| PLAT-05 | goodbye screen registers in _layout Stack | unit | `npx jest --testPathPattern="goodbye"` | ❌ Wave 0 |
| PLAT-05 | web CSV export bundles into single zip | unit | `npx jest --testPathPattern="exportData"` | ✅ exists — needs new web-zip test case |

### Sampling Rate
- **Per task commit:** `cd SundeeFundeeRN && npx jest --testPathPattern="workout-detail|goodbye|exportData" --passWithNoTests`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --coverage`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `SundeeFundeeRN/app/(app)/__tests__/workout-detail.test.tsx` — covers PLAT-05 unit conversion in CompletedExerciseSection and AIExerciseSection
- [ ] `SundeeFundeeRN/app/(app)/__tests__/goodbye.test.tsx` — verifies screen renders and Done button navigates to /sign-in
- [ ] `exportData.test.ts` web section — add test case verifying single zip download call when `Platform.OS === 'web'` and format is `'csv'` (existing file, new test block)

## Sources

### Primary (HIGH confidence)
- Direct code inspection: `SundeeFundeeRN/app/(app)/workout-detail.tsx` — confirmed hardcoded " lbs" at lines 222, 247-250, 157
- Direct code inspection: `SundeeFundeeRN/app/(app)/_layout.tsx` — confirmed missing `goodbye` Stack.Screen entry
- Direct code inspection: `SundeeFundeeRN/src/export/exportData.ts` — confirmed web branch downloads individual CSVs, no zip
- Direct code inspection: `SundeeFundeeRN/src/utils/formatWeight.ts` — confirmed utility exists with correct signature
- Direct code inspection: `SundeeFundeeRN/src/repositories/SettingsRepo.ts` — confirmed `AppSettings.weightUnit` field and `getSettingsRepo` factory

### Secondary (MEDIUM confidence)
- STATE.md Phase 07 decisions — confirmed original rationale for individual web downloads and formatWeight rounding
- JSZip npm package — pure JavaScript, browser + Node compatible, widely used for client-side zip generation

### Tertiary (LOW confidence)
- Bundle size estimate for JSZip (~90KB) — from memory; verify with `npx bundlesize` if needed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all existing utilities confirmed via code inspection
- Architecture: HIGH — all three fixes are narrow rewires of existing patterns
- Pitfalls: HIGH — identified from actual code, not speculation

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable codebase, no fast-moving dependencies)
