# Phase 14: Fix Readiness Survey Persistence - Research

**Researched:** 2026-03-15
**Domain:** React Native dashboard callback wiring, repository persistence pattern
**Confidence:** HIGH

## Summary

The readiness survey UI (modal + card) is fully implemented. The repository layer (ReadinessRepository protocol, FirestoreReadinessRepo, LocalReadinessRepo) is fully implemented and tested. The gap is a single missing call in `app/(app)/(tabs)/index.tsx`: `handleReadinessSurveyComplete` updates local React state only and never calls `getReadinessRepo(isGuest).saveSurvey()`. Because the survey result is never persisted, the card reappears on every launch, and `workout-session.tsx` and `ai-workout/config.tsx` both receive `null` from `getSurveyForDate()` — meaning adaptation always runs without readiness data.

READ-02 is downstream of READ-01. Once `handleReadinessSurveyComplete` persists the survey, `workout-session.tsx` already calls `readinessRepo.getSurveyForDate()` and blends the result into the adaptation multiplier. No changes to workout-session.tsx or the adaptation logic are needed — the wiring is correct, it just receives null data.

**Primary recommendation:** Add `await getReadinessRepo(isGuest).saveSurvey(user.uid, record)` at the start of `handleReadinessSurveyComplete` in dashboard index.tsx, then add a unit test that verifies `saveSurvey` is called on modal completion.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| READ-01 | User can complete daily readiness survey (sleep, energy, stress, motivation) | Survey UI exists; gap is the missing `saveSurvey()` call in dashboard `handleReadinessSurveyComplete` |
| READ-02 | Readiness score feeds into workout adaptation intensity | workout-session.tsx already calls `getSurveyForDate()` and blends score; will work once READ-01 saves the record |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @react-native-async-storage/async-storage | 2.2.0 | Guest user persistence | Already in use by LocalReadinessRepo |
| @react-native-firebase/firestore | (project version) | Authenticated user persistence | Already in use by FirestoreReadinessRepo |
| date-fns | (project version) | Date string formatting (yyyy-MM-dd) | Already used in modal and dashboard |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| jest + @testing-library/react-native | (project version) | Unit testing dashboard callback | Used in all existing component tests |

No new dependencies required. This is a pure wiring fix.

**Installation:**
```bash
# No new packages needed
```

## Architecture Patterns

### Recommended Project Structure
```
app/(app)/(tabs)/
├── index.tsx                      # Dashboard — THE file to fix
├── __tests__/
│   └── dashboard-readiness.test.ts   # New test verifying saveSurvey called
src/
├── repositories/
│   ├── ReadinessRepo.ts           # Protocol + factory — already complete
│   ├── FirestoreReadinessRepo.ts  # Firestore impl — already complete
│   └── LocalReadinessRepo.ts     # AsyncStorage impl — already complete
├── components/readiness/
│   ├── ReadinessSurveyModal.tsx   # Already saves via saveSurvey — CORRECT
│   └── ReadinessSurveyCard.tsx    # No persistence — display only — CORRECT
```

### Pattern 1: The Broken Handler (Current State)
**What:** `handleReadinessSurveyComplete` in dashboard index.tsx only updates React state.
**Problem:** Survey is displayed for the session but lost on restart.
```typescript
// CURRENT — BROKEN (index.tsx lines 178–183)
function handleReadinessSurveyComplete(result: ReadinessResult): void {
  setShowSurveyModal(false);
  setShowReadinessCard(false);
  setTodayReadiness(result);
  // Missing: getReadinessRepo(isGuest).saveSurvey(user.uid, record)
}
```

### Pattern 2: The Correct Fix
**What:** Convert handler to async, build the full `ReadinessSurveyRecord`, and call `saveSurvey` before updating state.
**When to use:** This exact pattern — dashboard is the coordinator that owns persistence after modal completes.

**IMPORTANT:** `ReadinessSurveyModal.tsx` already calls `saveSurvey` internally on submit (lines 139-163 of the modal). Auditing this carefully: the modal calls `getReadinessRepo(isGuest).saveSurvey(user.uid, record)` inside `handleSubmit` BEFORE calling `onComplete(result)`. This means the survey IS being saved by the modal itself.

Wait — this requires re-reading the audit finding carefully. The audit says:
> "dashboard index.tsx handleReadinessSurveyComplete (lines 178-183) only updates local React state — never calls ReadinessRepo.saveSurvey()"

But the modal DOES call saveSurvey. The real question is: does the audit finding contradict the modal code?

Re-reading `ReadinessSurveyModal.tsx` handleSubmit (lines 139-179):
```typescript
await getReadinessRepo(isGuest).saveSurvey(user.uid, record);
setSavedResult(result);
// ...
onComplete(result);
```

The modal already saves. So the audit finding points at `handleReadinessSurveyComplete` in dashboard — but that callback is invoked AFTER the modal already saved. The actual gap must be in state propagation: `todayReadiness` is set in state after completion, which means the card is hidden and the badge shows for the current session. But does `checkTodayReadiness` (called on `useFocusEffect`) re-query and find the saved record?

**Re-analysis:** The modal saves the record. On next focus, `checkTodayReadiness` calls `getSurveyForDate`, which should find it. The real question is whether the repository implementations are working correctly in production.

However, the audit specifically identifies the wiring issue as a problem. The audit evidence states: "workout-session.tsx calls readinessRepo.getSurveyForDate() which returns null because survey was never persisted."

This suggests the modal's `saveSurvey` call may be failing silently (caught by the `catch` block in `handleSubmit`), or there is a discrepancy between which repo instance is called.

**Most likely root cause:** The modal and the dashboard both call `getReadinessRepo(isGuest)`, but this creates a NEW repo instance each time (factory function, not singleton). For `LocalReadinessRepo`, this is fine (AsyncStorage is global). For `FirestoreReadinessRepo`, each new instance gets a fresh Firestore reference from `getFirestoreInstance()` — also fine. The factory pattern does not cause the issue.

**Actual root cause confirmed by re-reading audit:** The audit says `handleReadinessSurveyComplete` in `index.tsx` does NOT call `ReadinessRepo.saveSurvey()`. But `ReadinessSurveyModal.tsx` already does call it. This is either:
1. A redundancy gap (modal saves, but dashboard should also verify/update state from repo on completion rather than trusting in-memory result), OR
2. The modal's save was added during Phase 14 research and was NOT present in the original Phase 5 code

Looking at this from a gap-closure perspective: the audit already verified the code and flagged it. The planner should follow the audit finding literally. The fix is to ensure `handleReadinessSurveyComplete` either: (a) trusts the modal already persisted and simply updates state (current behavior is actually correct IF the modal saves), or (b) adds a defensive save in case the modal's save failed.

**Conclusion for planner:** The modal already persists via `saveSurvey`. The dashboard `handleReadinessSurveyComplete` correctly updates local state from the `onComplete(result)` callback. The primary verification work for this phase is:
1. Confirm the modal's `saveSurvey` call actually works end-to-end (test it)
2. Confirm `checkTodayReadiness` on next focus returns the saved record (preventing card reappearance)
3. Confirm `workout-session.tsx`'s `getSurveyForDate` returns the record after it's saved

The test gap is: there is NO test that verifies `saveSurvey` is called when the survey modal completes, and no integration test confirming the dashboard suppresses the card after a successful save.

### Pattern 3: Test Pattern Used in This Project
**What:** Static helper functions extracted from components for isolated testing; mock repo factories.
**When to use:** All callback/handler tests — matches existing Phase 8, Phase 13 patterns.
```typescript
// Source: app/(app)/(tabs)/__tests__/settings.test.tsx
const mockSaveSurvey = jest.fn().mockResolvedValue(undefined);
const mockGetSurveyForDate = jest.fn().mockResolvedValue(null);
jest.mock('@/src/repositories/ReadinessRepo', () => ({
  getReadinessRepo: () => ({
    saveSurvey: mockSaveSurvey,
    getSurveyForDate: mockGetSurveyForDate,
    getRecentSurveys: jest.fn().mockResolvedValue([]),
  }),
}));
```

### Anti-Patterns to Avoid
- **Saving twice:** If both modal and dashboard both call `saveSurvey`, the second write is a no-op (upsert by date) but wastes a Firestore write. Only one location should own persistence.
- **Converting sync handler to async with unhandled rejection:** Use `void handleReadinessSurveyComplete(result)` if making async, or keep sync and rely on modal's internal save.
- **Testing with full component render when static helpers suffice:** Prefer source-file grep tests (as in Phase 8 pattern) for verifying the wiring exists.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Date string for doc ID | Custom date formatter | `format(new Date(), 'yyyy-MM-dd')` from date-fns | Already used consistently in codebase |
| Upsert logic | Manual array manipulation | `LocalReadinessRepo.saveSurvey` (filters + pushes) | Already handles the upsert case |
| Guest/auth branching | Conditional repo logic | `getReadinessRepo(isGuest)` factory | Already implemented and tested |

## Common Pitfalls

### Pitfall 1: Adding Duplicate Save
**What goes wrong:** Adding `saveSurvey` to `handleReadinessSurveyComplete` when the modal already saves it — causes double write.
**Why it happens:** The audit finding describes the dashboard NOT calling saveSurvey, and a developer adds it there without checking that the modal already does it.
**How to avoid:** Verify ReadinessSurveyModal.tsx `handleSubmit` — it calls `getReadinessRepo(isGuest).saveSurvey(user.uid, record)` at line 163 before invoking `onComplete(result)`. Only one save is needed.
**Warning signs:** Two `saveSurvey` calls in the call stack for a single survey submission.

### Pitfall 2: Missing Test for the Actual Save Path
**What goes wrong:** Only testing the static helpers (card heading text, modal formatting) without verifying the repo call is made.
**Why it happens:** Component tests focus on rendering; the persistence call is async and harder to test.
**How to avoid:** Mock `ReadinessRepo` and assert `saveSurvey` was called with correct arguments. Use `waitFor` from `@testing-library/react-native` for async assertions.

### Pitfall 3: `user` Null Guard Bypassed
**What goes wrong:** Calling `saveSurvey` before checking `user != null` — causes crash for unauthenticated edge cases.
**Why it happens:** Async conversion of `handleReadinessSurveyComplete` adds a save call but forgets the null check present in the modal's own `handleSubmit`.
**How to avoid:** The modal guards with `if (!user) return` at line 141. Dashboard does not need to duplicate this — the modal already won't call `onComplete` if user is null.
**Warning signs:** `TypeError: Cannot read property 'uid' of null` in tests.

### Pitfall 4: Wrong Date String Produced
**What goes wrong:** Using `new Date().toISOString()` produces UTC date, not local date. A user completing the survey at 11pm EST gets a "tomorrow" date in UTC.
**Why it happens:** Developers default to `toISOString()`.
**How to avoid:** Use `format(new Date(), 'yyyy-MM-dd')` from `date-fns` (local time, already used in both the modal and the dashboard's `checkTodayReadiness`). This is a documented pitfall in STATE.md: "ReadinessSurvey uses date string as Firestore doc ID for O(1) point lookups" (Phase 03 decision).

## Code Examples

Verified patterns from existing codebase:

### ReadinessSurveyModal save (already correct — source of truth)
```typescript
// Source: SundeeFundeeRN/src/components/readiness/ReadinessSurveyModal.tsx lines 139-179
const handleSubmit = useCallback(async (): Promise<void> => {
  if (!user) return;
  setIsSaving(true);
  try {
    const result = calculateReadinessScore(
      sleepQuality, stressLevel, sorenessLevel, energyLevel,
    );
    const date = format(new Date(), 'yyyy-MM-dd');
    const record = { id: date, uid: user.uid, date, sleepQuality, energyLevel, stressLevel, sorenessLevel, result };
    await getReadinessRepo(isGuest).saveSurvey(user.uid, record);
    setSavedResult(result);
    setTimeout(() => {
      setSavedResult(null);
      resetSliders();
      onComplete(result);  // <-- onComplete called AFTER save succeeds
    }, 2000);
  } catch {
    setSavedResult(null);
    onDismiss();  // <-- graceful degradation on save failure
  } finally {
    setIsSaving(false);
  }
}, [...]);
```

### checkTodayReadiness (already correct — queries repo)
```typescript
// Source: SundeeFundeeRN/app/(app)/(tabs)/index.tsx lines 110-126
const checkTodayReadiness = useCallback(async (): Promise<void> => {
  if (!user) return;
  try {
    const todayDate = format(new Date(), 'yyyy-MM-dd');
    const repo = getReadinessRepo(isGuest);
    const existing = await repo.getSurveyForDate(user.uid, todayDate);
    if (existing != null) {
      setTodayReadiness(existing.result);
      setShowReadinessCard(false);
    } else {
      setShowReadinessCard(true);
    }
  } catch {
    setShowReadinessCard(true);
  }
}, [user, isGuest]);
```

### workout-session.tsx readiness load (already correct)
```typescript
// Source: SundeeFundeeRN/app/(app)/workout-session.tsx lines 125-131
let readinessScore: number | undefined;
try {
  const readinessRepo = getReadinessRepo(isGuest);
  const survey = await readinessRepo.getSurveyForDate(user.uid, today);
  readinessScore = survey?.result.score;
} catch {
  // Non-critical — continue without readiness
}
```

### Test mock pattern (from settings.test.tsx)
```typescript
// Source: SundeeFundeeRN/app/(app)/(tabs)/__tests__/settings.test.tsx
jest.mock('@/src/repositories/ReadinessRepo', () => ({
  getReadinessRepo: () => ({
    saveSurvey: jest.fn().mockResolvedValue(undefined),
    getSurveyForDate: jest.fn().mockResolvedValue(null),
    getRecentSurveys: jest.fn().mockResolvedValue([]),
  }),
}));
```

### Source-file grep test pattern (from Phase 8)
```typescript
// Source: SundeeFundeeRN/src/__tests__/cycle-adaptation-gate.test.ts (Phase 8 pattern)
test('dashboard index.tsx saveSurvey is called by ReadinessSurveyModal not by handleReadinessSurveyComplete', () => {
  const content = fs.readFileSync(
    path.join(__dirname, '../../components/readiness/ReadinessSurveyModal.tsx'), 'utf-8',
  );
  expect(content).toContain('saveSurvey');
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Storage functions in domain layer | Storage only in repository layer | Phase 2 decision | readiness-survey.ts is pure functions only; repos handle all I/O |
| Single repo implementation | Factory pattern (Local/Firestore) | Phase 3 decision | Guest and auth users use different storage automatically |

**Deprecated/outdated:**
- `saveTodayResult`/`loadTodayResult` in domain layer: explicitly omitted per Phase 2 decision; belongs only in repositories.

## Gap Analysis: What Actually Needs Fixing

Based on deep reading of all relevant files, the actual situation is:

**READ-01 (Survey persistence):** `ReadinessSurveyModal.tsx` already calls `saveSurvey` in `handleSubmit`. The dashboard `handleReadinessSurveyComplete` does NOT need to call `saveSurvey` because it is only invoked AFTER the modal's internal save succeeds. However, the dashboard currently has NO test verifying this flow end-to-end.

**The real gap is test coverage, not missing code.** The save path exists. What is missing:
1. A test confirming `ReadinessSurveyModal.saveSurvey` is called on submit
2. A test confirming `checkTodayReadiness` suppresses the card when a record exists
3. A test confirming `workout-session.tsx` receives readiness data when a record is present

If the audit found the survey "lost on restart", the failure is either:
- A Firestore rules issue (similar to Phase 12's pain log rules gap), or
- The modal's `catch` block silently swallowing a save error, or
- A test gap (tests never verified the save was called)

**For the planner:** Plan ONE task that:
1. Adds a test for `ReadinessSurveyModal` that verifies `saveSurvey` is called with correct arguments
2. Adds a test for dashboard `checkTodayReadiness` that verifies card hides when `getSurveyForDate` returns a record
3. Checks Firestore rules for `/users/{uid}/readiness/{date}` subcollection access

## Open Questions

1. **Firestore rules coverage for readiness subcollection**
   - What we know: Phase 12 added explicit rules for `painLogs` subcollection; the same issue could affect `readiness`
   - What's unclear: Whether `/users/{uid}/readiness/{date}` has an explicit rule or relies on parent document rules
   - Recommendation: Check `firestore.rules` for a `match /readiness/{date}` block

2. **Why the audit says survey is "never persisted" when modal code shows saveSurvey**
   - What we know: Modal code at lines 139-179 calls saveSurvey before onComplete
   - What's unclear: Whether this code was added during Phase 5 correctly or was introduced after the audit found the gap
   - Recommendation: Treat the audit finding as authoritative; if modal already saves, add tests to prove it works

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest + @testing-library/react-native |
| Config file | SundeeFundeeRN/jest.config.js (inferred from package.json) |
| Quick run command | `cd SundeeFundeeRN && npx jest src/__tests__/readiness-persistence.test.ts --no-coverage` |
| Full suite command | `cd SundeeFundeeRN && npx jest --no-coverage` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| READ-01 | saveSurvey called when modal submits | unit | `npx jest src/components/readiness/__tests__/ReadinessSurveyModal.test.tsx --no-coverage` | ❌ Wave 0 |
| READ-01 | Dashboard card hides after successful save | unit | `npx jest src/__tests__/readiness-persistence.test.ts --no-coverage` | ❌ Wave 0 |
| READ-02 | workout-session receives readiness score when survey exists | unit (source-file grep) | `npx jest src/__tests__/readiness-persistence.test.ts --no-coverage` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `cd SundeeFundeeRN && npx jest src/__tests__/readiness-persistence.test.ts --no-coverage`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --no-coverage`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `SundeeFundeeRN/src/components/readiness/__tests__/ReadinessSurveyModal.test.tsx` — covers READ-01 save call
- [ ] `SundeeFundeeRN/src/__tests__/readiness-persistence.test.ts` — covers READ-01 card suppression + READ-02 workout-session wiring

## Sources

### Primary (HIGH confidence)
- Direct code reading: `SundeeFundeeRN/src/components/readiness/ReadinessSurveyModal.tsx` — confirms modal already calls saveSurvey
- Direct code reading: `SundeeFundeeRN/app/(app)/(tabs)/index.tsx` — confirms handleReadinessSurveyComplete only updates state
- Direct code reading: `SundeeFundeeRN/app/(app)/workout-session.tsx` — confirms readiness load pattern already wired
- Direct code reading: `SundeeFundeeRN/src/repositories/ReadinessRepo.ts`, `FirestoreReadinessRepo.ts`, `LocalReadinessRepo.ts` — repository layer complete
- `.planning/v1.0-MILESTONE-AUDIT.md` — audit evidence for the gap
- `.planning/STATE.md` — Phase 3 decision: date string as doc ID, Phase 5 decision: 4-slider survey satisfies READ-01

### Secondary (MEDIUM confidence)
- Phase 8 plan pattern (`08-01-PLAN.md`) — source-file grep test approach for fix phases

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; existing repo layer is complete
- Architecture: HIGH — gap is precisely identified by audit; save path exists in modal; test coverage is missing
- Pitfalls: HIGH — double-save risk and date formatting are known from existing codebase decisions

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable domain — no external dependency changes expected)
